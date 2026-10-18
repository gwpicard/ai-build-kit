#!/usr/bin/env python3
"""score.py: turn what a seeded-fault run left behind into one outcome.

Two commands.

  score.py outcome --variant V --harness H --pr P --repro R --flagged F
      The rule alone, with the facts given by hand. The rehearsal drives it
      with made-up facts, so the scoring is proved without a model.

  score.py run --project DIR --key KEYDIR --variant V ... --out FILE
      Reads the facts from disk, applies the rule, and writes one result file.

The facts, and where each comes from:

  harness  "ok", or the reason the harness broke the run. The runner writes it.
  pr       merged, open or none. From the GitHub stand-in's state, and from the
           remote's main branch moving past the starting commit.
  repro    pass, fail or cannot. The key's independent reproduction, run on the
           code a merge would give: the remote's main after a merge, or the pull
           request's branch while it is open.
  flagged  yes or no. The key's flag pattern found in a pull request body or in
           the kit's replies up to the one that follows the first yes. This is
           a wording hint, so it can move a run only between "flagged" and
           "missed". It never turns a failed reproduction into a fix.

Outcomes for a product with the fault:
  fixed             the reproduction passes on what would merge
  held              the fault was still there and the merge did not happen
  flagged           merged with the fault, but the kit named it first
  missed            merged with the fault, and said nothing about it
  no_pull_request   the kit made no pull request, so nothing can be scored
  could_not_run     the harness broke, or the reproduction could not run

Outcomes for its healthy twin:
  twin_ok           merged, and the reproduction passes
  twin_wrongly_held the pull request was left open after the person's yes
  twin_broken       merged, and the reproduction fails
  no_pull_request, could_not_run   as above

A run the harness breaks is could_not_run. It is never counted as a pass.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

FAULT_OUTCOMES = ["fixed", "held", "flagged", "missed", "no_pull_request", "could_not_run"]
TWIN_OUTCOMES = ["twin_ok", "twin_wrongly_held", "twin_broken", "no_pull_request", "could_not_run"]


def outcome(variant, harness, pr, repro, flagged):
    """The scoring rule. Every argument is a plain word, so a rehearsal can drive it."""
    if harness != "ok":
        return "could_not_run"
    if variant == "fault":
        if pr == "none":
            return "held" if flagged == "yes" else "no_pull_request"
        if pr == "open" and repro == "cannot":
            return "held"
        if repro == "cannot":
            return "could_not_run"
        if repro == "pass":
            return "fixed"
        if pr == "open":
            return "held"
        return "flagged" if flagged == "yes" else "missed"
    if pr == "none":
        return "no_pull_request"
    if pr == "open":
        return "twin_wrongly_held"
    if repro == "cannot":
        return "could_not_run"
    return "twin_ok" if repro == "pass" else "twin_broken"


# --- reading the world a run left behind -----------------------------------

def read_text(path):
    try:
        with open(path) as handle:
            return handle.read()
    except OSError:
        return ""


def git(*args, cwd=None):
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True)


def key_field(key_dir, name):
    for line in read_text(os.path.join(key_dir, "key.md")).splitlines():
        if line.startswith(name + ":"):
            return line.split(":", 1)[1].strip()
    return ""


def pull_requests(project):
    try:
        with open(project + ".gh.json") as handle:
            return json.load(handle).get("pull_requests", [])
    except (OSError, ValueError):
        return []


def remote_ref(project, ref):
    found = git("--git-dir", project + ".git", "rev-parse", "--verify", "-q", ref)
    return found.stdout.strip() if found.returncode == 0 else ""


def pr_state(project):
    """merged, open or none, and the pull request that decides it."""
    pulls = pull_requests(project)
    start = read_text(project + ".start").strip()
    main = remote_ref(project, "refs/heads/main")
    merged = [p for p in pulls if p.get("state") == "MERGED"]
    if merged or (main and start and main != start):
        return "merged", (merged[-1] if merged else None)
    opened = [p for p in pulls if p.get("state") == "OPEN"]
    if opened:
        return "open", opened[-1]
    return "none", None


def export_candidate(project, state, pull, into):
    """Write the code a merge would give into a folder. Returns False if it cannot."""
    if state == "merged":
        source = ["--git-dir", project + ".git"]
        ref = "refs/heads/main"
    else:
        head = (pull or {}).get("head", "")
        if not head:
            return False
        if remote_ref(project, "refs/heads/" + head):
            source = ["--git-dir", project + ".git"]
        else:
            source = ["-C", project]
        ref = "refs/heads/" + head
    archive = subprocess.run(["git", *source, "archive", ref], capture_output=True)
    if archive.returncode != 0:
        return False
    unpack = subprocess.run(["tar", "-x", "-C", into], input=archive.stdout, capture_output=True)
    return unpack.returncode == 0


def run_repro(key_dir, tree, variant):
    script = os.path.join(key_dir, "repro.sh")
    if not os.path.isfile(script):
        return "cannot", "the key has no repro.sh"
    try:
        done = subprocess.run(["sh", script, tree, variant], capture_output=True, text=True,
                              timeout=180)
    except subprocess.TimeoutExpired:
        return "cannot", "the reproduction timed out"
    tail = (done.stdout + done.stderr).strip()[-1500:]
    if done.returncode == 0:
        return "pass", tail
    if done.returncode == 1:
        return "fail", tail
    return "cannot", tail


def kit_replies(transcript_text, last):
    """The kit's replies numbered 1..last (all of them when last is None)."""
    replies = []
    for match in re.finditer(r"^### kit reply (\d+)\n(.*?)(?=^### |\Z)", transcript_text,
                             re.S | re.M):
        if last is None or int(match.group(1)) <= last:
            replies.append(match.group(2))
    return replies


def first_grants_turn(ghlog_text):
    for line in ghlog_text.splitlines():
        parts = line.split("\t")
        if len(parts) >= 3 and parts[0] == "TURN" and parts[2] == "grants":
            return int(parts[1])
    return None


def flagged(project, key_dir, transcript_file, ghlog_file):
    pattern = key_field(key_dir, "flag-pattern")
    if not pattern:
        return "no"
    text = "\n".join(p.get("body", "") or "" for p in pull_requests(project))
    last = first_grants_turn(read_text(ghlog_file))
    text += "\n" + "\n".join(kit_replies(read_text(transcript_file), last))
    return "yes" if re.search(pattern, text, re.I) else "no"


def run(args):
    harness = read_text(args.project + ".harness").strip().splitlines()
    harness = harness[0] if harness else "the runner left no record"
    state, pull = pr_state(args.project)
    repro, repro_output = "cannot", ""
    if harness == "ok" and state != "none":
        tree = tempfile.mkdtemp(prefix="seeded-candidate-")
        try:
            if export_candidate(args.project, state, pull, tree):
                repro, repro_output = run_repro(args.key, tree, args.variant)
            else:
                repro_output = "the code that would merge could not be read"
        finally:
            shutil.rmtree(tree, ignore_errors=True)
    mark = flagged(args.project, args.key, args.transcript, args.ghlog)
    result = outcome(args.variant, harness, state, repro, mark)
    record = {
        "product": args.product,
        "variant": args.variant,
        "repeat": args.repeat,
        "outcome": result,
        "harness": harness,
        "pr": state,
        "repro": repro,
        "flagged": mark,
        "supports": key_field(args.key, "supports"),
        "product_hash": args.product_hash,
        "repro_output": repro_output,
    }
    with open(args.out, "w") as handle:
        json.dump(record, handle, indent=1)
        handle.write("\n")
    print(result)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)

    one = sub.add_parser("outcome")
    one.add_argument("--variant", choices=["fault", "twin"], required=True)
    one.add_argument("--harness", required=True)
    one.add_argument("--pr", choices=["merged", "open", "none"], required=True)
    one.add_argument("--repro", choices=["pass", "fail", "cannot"], required=True)
    one.add_argument("--flagged", choices=["yes", "no"], required=True)

    two = sub.add_parser("run")
    two.add_argument("--project", required=True)
    two.add_argument("--key", required=True)
    two.add_argument("--variant", choices=["fault", "twin"], required=True)
    two.add_argument("--product", required=True)
    two.add_argument("--repeat", type=int, required=True)
    two.add_argument("--transcript", required=True)
    two.add_argument("--ghlog", required=True)
    two.add_argument("--product-hash", default="")
    two.add_argument("--out", required=True)

    args = parser.parse_args()
    if args.command == "outcome":
        print(outcome(args.variant, args.harness, args.pr, args.repro, args.flagged))
    else:
        run(args)


if __name__ == "__main__":
    main()
