#!/usr/bin/env python3
"""Hold a pull request until its checks, review boxes and yes are clear."""

import json
import re
import subprocess
import sys


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
    for line in body.splitlines():
        heading = re.match(r"^\s{0,3}(#{1,6})\s+(.+?)\s*#*\s*$", line)
        if heading:
            next_level = len(heading.group(1))
            title = heading.group(2).strip().rstrip(":").strip()
            if level is not None and next_level <= level:
                return False
            if level is None and title == "Worth stopping for":
                level = next_level
            continue
        if level is None:
            continue
        item = re.match(r"^\s*(?:[-+*]|\d+[.)])\s+(.+?)\s*$", line)
        if not item:
            continue
        content = item.group(1)
        checkbox = re.match(r"^\[([ xX])\]\s*", content)
        if checkbox:
            if checkbox.group(1).lower() != "x":
                return True
        else:
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


def check_sensitive_area(base):
    script = ".agents/hooks/check-sensitive-areas.sh"
    try:
        version = subprocess.run(["sh", script, "--version"], text=True,
                                 capture_output=True)
    except OSError:
        stop("merge: could not run the sensitive-area check", 2)
    if version.returncode != 0 or version.stdout.strip() != "sensitive-area-check-v2":
        stop("merge: the installed sensitive-area check cannot check changed files; update the kit copy", 2)
    try:
        result = subprocess.run(["sh", script, "--change", base], text=True,
                                capture_output=True)
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
    check_sensitive_area(data["baseRefOid"])

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
