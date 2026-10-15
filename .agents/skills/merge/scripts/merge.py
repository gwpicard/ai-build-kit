#!/usr/bin/env python3
"""Hold a pull request until its checks, review boxes and yes are clear."""

import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path


def gh(*args):
    try:
        return subprocess.run(["gh", *args], text=True, capture_output=True)
    except FileNotFoundError:
        stop("merge: GitHub CLI (gh) is not installed", 2)


def stop(message, code=1):
    print(message, file=sys.stderr)
    raise SystemExit(code)


def read_json(result, label):
    try:
        return json.loads(result.stdout)
    except (ValueError, TypeError):
        stop("merge: GitHub returned unreadable " + label, 2)


def open_review_box(body):
    level = None
    fenced = False
    settled_indent = None
    for line in body.splitlines():
        if re.match(r"^\s{0,3}(?:```|~~~)", line):
            fenced = not fenced
            continue
        if fenced:
            continue
        heading = re.match(r"^\s{0,3}(#{1,6})\s+(.+?)\s*#*\s*$", line)
        bold = re.match(r"^\s{0,3}\*\*(.+?)\*\*\s*$", line)
        if heading:
            next_level = len(heading.group(1))
            title = heading.group(2).strip().rstrip(":").strip()
            if level is not None and next_level <= level:
                level = None
            if title.casefold() == "worth stopping for":
                level = next_level
            continue
        if bold:
            title = bold.group(1).strip().rstrip(":").strip()
            if title.casefold() == "worth stopping for":
                level = 7
                settled_indent = None
            elif level is not None:
                level = None
            continue
        if level is None:
            continue
        if re.match(r"^\s*(?:[-+*]\s+)?(?:None\.?|Nothing worth stopping for)\s*$", line, re.I):
            continue
        indent = len(line) - len(line.lstrip())
        if settled_indent is not None and indent > settled_indent:
            continue
        item = re.match(r"^\s*(?:[-+*]|\d+[.)])\s+(.+?)\s*$", line)
        if item and (settled_indent is None or indent <= settled_indent):
            settled_indent = None
        if item:
            content = item.group(1)
            checkbox = re.match(r"^\[([ xX])\]\s*", content)
            if checkbox:
                if checkbox.group(1).lower() != "x":
                    return True
                settled_indent = indent
            elif re.match(r"^(?:[-+*]|\d+[.)])\s+", content):
                continue
            else:
                return True
        elif line.strip():
            return True
    return False


def check_hold(rows):
    projects = [row for row in rows if row.get("name") == "project-check"]
    if not projects:
        stop("merge: project-check is missing; the pull request stays open")
    for row in rows:
        name = str(row.get("name") or "unnamed check")
        state = str(row.get("state") or "unknown")
        bucket = row.get("bucket")
        if bucket in ("fail", "cancel") or bucket == "pending":
            stop("merge: %s is %s; the pull request stays open" % (name, state))
        if name == "project-check" and bucket != "pass":
            stop("merge: project-check is %s; the pull request stays open" % state)


def kit_area_check():
    here = Path(__file__).resolve()
    for parent in here.parents:
        for candidate in (
                parent / "setup-ai-build-kit" / "templates" / "foundation" / "check-sensitive-areas.sh",
                parent / "skills" / "setup-ai-build-kit" / "templates" / "foundation" / "check-sensitive-areas.sh"):
            if candidate.is_file():
                return str(candidate)
    stop("merge: could not find the kit's sensitive-area check", 2)


def check_sensitive_area(base, head):
    script = kit_area_check()
    try:
        fetch = subprocess.run(["git", "fetch", "origin", base, head], text=True,
                               capture_output=True)
    except OSError:
        stop("merge: could not fetch the pull request commits", 2)
    if fetch.returncode != 0:
        detail = (fetch.stderr or fetch.stdout).strip()
        stop("merge: could not fetch the pull request commits" +
             (": " + detail if detail else ""), 2)
    plan = subprocess.run(["git", "show", head + ":masterplan.md"], text=True,
                          capture_output=True)
    if plan.returncode != 0:
        if "masterplan.md" in (plan.stderr or ""):
            return
        stop("merge: could not read the pull request's masterplan", 2)
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".md") as handle:
            handle.write(plan.stdout)
            handle.flush()
            result = subprocess.run(["sh", script, "--change", base, "--head", head,
                                     "--masterplan", handle.name],
                                    text=True, capture_output=True)
    except OSError:
        stop("merge: could not run the sensitive-area check", 2)
    if result.stdout:
        sys.stdout.write(result.stdout)
    if result.returncode == 1:
        stop("merge: the sensitive-area check is open; the pull request stays open")
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        stop("merge: could not run the sensitive-area check" +
             (": " + detail if detail else ""), 2)


def main(argv):
    if len(argv) == 1 and argv[0].isdigit():
        stop("merge: a yes naming this pull request is required", 1)
    if len(argv) != 2 or argv[0] != "--approved" or not argv[1].isdigit():
        stop("usage: merge.py --approved <pull request number>", 2)
    number = argv[1]

    pr = gh("pr", "view", number, "--json", "body,headRefOid,baseRefOid")
    if pr.returncode != 0:
        stop("merge: GitHub could not read the pull request: " +
             (pr.stderr or pr.stdout).strip(), 2)
    data = read_json(pr, "pull request")
    if not isinstance(data, dict) or not data.get("headRefOid"):
        stop("merge: GitHub returned an unreadable pull request head", 2)
    head = data["headRefOid"]
    if not data.get("baseRefOid"):
        stop("merge: GitHub returned an unreadable pull request base", 2)
    check_sensitive_area(data["baseRefOid"], head)

    checks = gh("pr", "checks", number, "--json", "name,state,bucket")
    if checks.returncode == 1 and not checks.stdout.strip() and "no checks reported" in checks.stderr:
        stop("merge: project-check is missing; the pull request stays open")
    if checks.returncode != 0:
        stop("merge: GitHub could not read the pull request checks: " +
             (checks.stderr or checks.stdout).strip(), 2)
    rows = read_json(checks, "pull request checks")
    if not isinstance(rows, list) or any(not isinstance(row, dict) for row in rows):
        stop("merge: GitHub returned unreadable pull request checks", 2)
    check_hold(rows)

    if open_review_box(data.get("body") or ""):
        stop("merge: a finding under Worth stopping for is open; the pull request stays open")

    merged = gh("pr", "merge", number, "--merge", "--match-head-commit", head)
    if merged.returncode != 0:
        detail = (merged.stderr or merged.stdout).strip()
        stop("merge: GitHub did not merge the pull request" + (": " + detail if detail else ""), 2)
    if merged.stdout:
        sys.stdout.write(merged.stdout)


if __name__ == "__main__":
    main(sys.argv[1:])
