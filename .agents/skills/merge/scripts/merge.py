#!/usr/bin/env python3
"""Hold a pull request until its project check, review boxes and yes are clear."""

import json
import subprocess
import sys


def gh(*args):
    return subprocess.run(["gh", *args], text=True, capture_output=True)


def stop(message, code=1):
    print(message, file=sys.stderr)
    raise SystemExit(code)


def main(argv):
    if len(argv) == 1 and argv[0].isdigit():
        stop("merge: a yes naming this pull request is required", 1)
    if len(argv) != 2 or argv[0] != "--approved" or not argv[1].isdigit():
        stop("usage: merge.py --approved <pull request number>", 2)
    number = argv[1]

    checks = gh("pr", "checks", number, "--json", "name,state,bucket")
    if checks.returncode not in (0, 1, 8):
        stop("merge: GitHub could not read the pull request checks", 2)
    try:
        rows = json.loads(checks.stdout)
        if not isinstance(rows, list):
            raise ValueError()
    except (ValueError, TypeError):
        stop("merge: GitHub returned unreadable pull request checks", 2)

    project = [row for row in rows if row.get("name") == "project-check"]
    if not project:
        stop("merge: project-check is missing; the pull request stays open")
    if checks.returncode == 8 or any(row.get("state") != "SUCCESS" or row.get("bucket") != "pass"
                                     for row in rows):
        stop("merge: a check is red or still running; the pull request stays open")
    if any(row.get("state") != "SUCCESS" for row in project):
        stop("merge: project-check has not passed; the pull request stays open")
    if checks.returncode != 0:
        stop("merge: GitHub could not read the pull request checks", 2)

    pr = gh("pr", "view", number, "--json", "body")
    if pr.returncode != 0:
        stop("merge: GitHub could not read the pull request body", 2)
    try:
        body = json.loads(pr.stdout).get("body") or ""
    except (ValueError, TypeError, AttributeError):
        stop("merge: GitHub returned an unreadable pull request body", 2)

    section = None
    for line in body.splitlines():
        if line.startswith("## "):
            if section is not None:
                break
            section = line[3:].strip()
            continue
        if section == "Worth stopping for" and line.lstrip().startswith(("- [ ]", "* [ ]")):
            stop("merge: a box under Worth stopping for is unticked; the pull request stays open")

    merged = gh("pr", "merge", number, "--merge")
    if merged.returncode != 0:
        detail = (merged.stderr or merged.stdout).strip()
        stop("merge: GitHub did not merge the pull request" + (": " + detail if detail else ""), merged.returncode or 1)
    if merged.stdout:
        sys.stdout.write(merged.stdout)


if __name__ == "__main__":
    main(sys.argv[1:])
