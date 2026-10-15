#!/usr/bin/env python3
"""Build a review packet and turn supported findings into pull-request boxes."""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path.cwd()
QUALITY = Path(os.environ.get("GATE_QUALITY_SCRIPT", Path(__file__).with_name("quality.py")))


def run(args, *, cwd=ROOT, timeout=90):
    try:
        result = subprocess.run(args, cwd=cwd, text=True, capture_output=True,
                                timeout=timeout)
        return result.returncode, result.stdout, result.stderr
    except (OSError, subprocess.TimeoutExpired) as error:
        return 2, "", str(error)


def stop(message, code=2):
    print(message, file=sys.stderr)
    return code


def gh(*args):
    code, out, err = run(["gh", *args])
    if code:
        raise RuntimeError((err or out or "GitHub CLI could not run").strip())
    return out


def piece(number):
    raw = json.loads(gh("issue", "view", str(number), "--json", "title,body"))
    if not isinstance(raw, dict) or not raw.get("title") or not raw.get("body"):
        raise ValueError("the piece has no readable title or body")
    body = raw["body"]
    so = re.search(r"(?ms)^#{2,3} So that\s*\n(.*?)(?=^#{2,3} |\Z)", body)
    done = re.search(r"(?ms)^#{2,3} Done when\s*\n(.*?)(?=^#{2,3} |\Z)", body)
    return raw["title"], so.group(1).strip() if so else None, done.group(1).strip() if done else None


def brief(args):
    limits = []
    sections = []
    try:
        title, so, done = piece(args.piece)
        sections.extend(["# Review packet", "", "## Piece", title, "",
                         "## So that", so or "[missing]", "",
                         "## Done when", done or "[missing]"])
        if so is None:
            limits.append("piece has no So that section")
        if done is None:
            limits.append("piece has no Done when section")
    except (RuntimeError, ValueError, json.JSONDecodeError) as error:
        title, so, done = "[unavailable]", None, None
        limits.append("piece agreement could not be read: " + str(error))
        sections.extend(["# Review packet", "", "## Piece", title])

    code, diff, error = run(["git", "diff", "--find-renames", "--binary", args.base + "...HEAD"])
    sections.extend(["", "## Full change", diff if code == 0 and diff else "[unavailable]"])
    if code or not diff:
        limits.append("full change could not be read" + (": " + error.strip() if error else ""))

    reads = [("Reach", [sys.executable, str(QUALITY), "reach", "--base", args.base, "--piece", str(args.piece)]),
             ("Tests read", [sys.executable, str(QUALITY), "tests", "--base", args.base, "--piece", str(args.piece)]),
             ("Trim", [sys.executable, str(QUALITY), "trim", "--base", args.base])]
    test_output = ""
    for label, command in reads:
        status, out, err = run(command, timeout=600)
        sections.extend(["", "## " + label, out.strip() or "[no output]"])
        if label == "Tests read":
            test_output = out
        if status == 2:
            limits.append(label.lower() + " read could not run" + (": " + err.strip() if err else ""))
        elif status == 1 and not out.strip():
            limits.append(label.lower() + " read returned a finding without output")
    strength_lines = [line for line in test_output.splitlines()
                      if line.startswith("strength\t") or line.startswith("not-checked\tstrength\t")]
    if strength_lines:
        sections.extend(["", "## Test strength", *strength_lines])
    try:
        checks = json.loads(gh("pr", "checks", "--json", "name,state,bucket"))
        project = [row for row in checks if row.get("name") == "project-check"]
        type_checks = [row for row in checks if "type" in str(row.get("name", "")).casefold()]
        lint_checks = [row for row in checks if "lint" in str(row.get("name", "")).casefold()]
        check_line = ", ".join(str(row.get("state", "unknown")) for row in project) or "project-check not reported"
        if not project:
            limits.append("project-check has no reported result")
    except (RuntimeError, ValueError, json.JSONDecodeError):
        check_line = "project-check could not be read"
        limits.append("project check results could not be read")
    result_lines = ["Project check: " + check_line]
    if type_checks:
        result_lines.append("Type: " + ", ".join(str(row.get("state", "unknown")) for row in type_checks))
    else:
        result_lines.append("Type: [no separate result]")
    if lint_checks:
        result_lines.append("Lint: " + ", ".join(str(row.get("state", "unknown")) for row in lint_checks))
    else:
        result_lines.append("Lint: [no separate result]")
        limits.append("separate lint result was missing; only the project-check result was available")
    if not type_checks:
        limits.append("separate type result was missing; only the project-check result was available")
    sections.extend(["", "## Type and lint results", *result_lines])
    sections.extend(["", "## Review limits", ""])
    sections.extend("- " + item for item in limits)
    if not limits:
        sections.append("- No packet inputs were missing")
    git_dir_code, git_dir, _ = run(["git", "rev-parse", "--git-path", "review-packet.md"])
    if git_dir_code:
        return stop("gate: could not locate the Git directory")
    target = ROOT / git_dir.strip()
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("\n".join(sections) + "\n", encoding="utf-8")
    except OSError as error:
        return stop("gate: could not write review packet: " + str(error))
    print("Review packet: " + str(target))
    if limits:
        print("Review limits: " + "; ".join(limits))
        return 2
    return 0


def supported(item):
    mark = str(item.get("mark", "")).casefold()
    if mark == "reproduced":
        command = item.get("command")
        output = item.get("output")
        failing_test = item.get("failing_test")
        return bool(failing_test or (isinstance(command, str) and command.strip()
                                     and isinstance(output, str) and output.strip()))
    if mark == "reasoned":
        scenario = item.get("scenario")
        if not isinstance(scenario, str):
            return False
        # A concrete scenario names an actor, an action, and a bad result.
        return bool(re.search(r"\b(who|user|person|visitor|member|owner|admin|customer|someone)\b", scenario, re.I)
                    and re.search(r"\b(when|if|does|clicks|opens|sends|changes|deletes|submits|tries|runs|visits)\b", scenario, re.I)
                    and re.search(r"\b(can|could|will|would|loses|leaks|exposes|breaks|fails|wrong|missing|corrupt|double|without|blocked)\b", scenario, re.I))
    return False


def test_passes(name):
    if not isinstance(name, str) or not re.fullmatch(r"[\w./:-]+", name):
        return False
    code, _, _ = run(["pytest", "-q", name], timeout=600)
    return code == 0


def record(args):
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, UnicodeError) as error:
        return stop("gate: review input is not valid JSON: " + str(error))
    if isinstance(data, dict):
        data = data.get("findings")
    if not isinstance(data, list) or any(not isinstance(row, dict) for row in data):
        return stop("gate: review input must be a JSON list of findings")
    kept, dropped = [], 0
    for row in data:
        if not supported(row):
            dropped += 1
            continue
        text = str(row.get("finding", row.get("text", ""))).strip()
        if not text:
            dropped += 1
            continue
        if row.get("refuted") is True:
            kept.append((False, text))
            continue
        stopping = row.get("worth_stopping_for", row.get("stopping", False)) is True
        kept.append((stopping, text))
    stopping = [text for is_stopping, text in kept if is_stopping]
    knowing = [text for is_stopping, text in kept if not is_stopping]
    try:
        old = json.loads(gh("pr", "view", str(args.pr), "--json", "title,body"))
        if not isinstance(old, dict) or not isinstance(old.get("body"), str):
            raise ValueError("GitHub returned an unreadable pull request")
        pr_title = str(old.get("title") or "pull request " + str(args.pr))
        original = old["body"].rstrip()

        def section(name):
            match = re.search(r"(?ims)^## " + re.escape(name) + r"\s*\n(.*?)(?=^## |\Z)", original)
            return match.group(1).strip().splitlines() if match else []

        settled = section("Worth stopping for")
        previous_open = sum(bool(re.match(r"\s*[-+*]\s+\[ \]\s+", line)) for line in settled)
        for index, line in enumerate(settled):
            if not re.match(r"\s*[-+*]\s+\[ \]\s+", line):
                continue
            text = re.sub(r"^\s*[-+*]\s+\[ \]\s+", "", line).strip()
            source = next((row for row in data if str(row.get("finding", row.get("text", ""))).strip() == text), None)
            if source and source.get("failing_test") and test_passes(source["failing_test"]):
                settled[index] = re.sub(r"\[ \]", "[x]", line, count=1)
        existing_open = [line for line in settled if re.match(r"\s*[-+*]\s+\[ \]\s+", line)]
        existing_other = [line for line in settled if line.strip() and not re.match(r"\s*(?:[-+*]\s+)?(?:None|Nothing worth stopping for)\.?\s*$", line, re.I)]
        stopping_lines = existing_other[:]
        known_text = {re.sub(r"^\s*[-+*]\s+(?:\[[ xX]\]\s*)?", "", line).strip() for line in stopping_lines}
        for text in stopping:
            if text not in known_text:
                stopping_lines.append("- [ ] " + text)
                known_text.add(text)
        open_count = sum(bool(re.match(r"\s*[-+*]\s+\[ \]\s+", line)) for line in stopping_lines)
        knowing_lines = section("Worth knowing")
        knowing_text = {re.sub(r"^\s*[-+*]\s+", "", line).strip() for line in knowing_lines
                        if line.strip() and not re.match(r"\s*(?:[-+*]\s+)?(?:None|Nothing worth knowing|Review limits:|Worth knowing findings:|Review record:)", line, re.I)}
        knowing_text.update(knowing)
        body = re.sub(r"(?im)^Review record:.*$", "", original)
        body = re.sub(r"(?ims)^## (?:Worth stopping for|Worth knowing)\s*\n.*?(?=^## |\Z)", "", body).rstrip()
        lines = [body, "", "## Worth stopping for"]
        lines.extend(stopping_lines or ["- None"])
        lines.extend(["", "## Worth knowing"])
        lines.extend("- " + text for text in sorted(known for known in knowing_text if known))
        lines.append("- Review limits: %d finding(s) dropped for missing evidence or a concrete scenario" % dropped)
        lines.append("- Worth knowing findings: %d" % len([item for item in knowing_text if item]))
        lines.append("Review record: reviewed=quality review; tried=%d; open=%d" %
                     (len(kept) + previous_open, open_count))
        gh("pr", "edit", str(args.pr), "--body", "\n".join(lines).strip())
    except (RuntimeError, ValueError) as error:
        return stop("gate: could not update the pull request: " + str(error))
    print("Review of %s: %d worth stopping for, %d worth knowing, %d dropped" %
          (pr_title, len(existing_open) + len(stopping), len(knowing_text), dropped))
    return 1 if open_count else 0


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    brief_parser = commands.add_parser("brief")
    brief_parser.add_argument("--base", required=True)
    brief_parser.add_argument("--piece", required=True)
    record_parser = commands.add_parser("record")
    record_parser.add_argument("--pr", required=True)
    args = parser.parse_args()
    return brief(args) if args.command == "brief" else record(args)


if __name__ == "__main__":
    sys.exit(main())
