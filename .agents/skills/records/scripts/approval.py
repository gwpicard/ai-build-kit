#!/usr/bin/env python3
"""The one gate before a change that reaches something online.

A script that merges, launches, moves the live version, applies a migration
or sets a live setting calls `use` with the name of its change. It refuses
unless the person's approval for that exact change is recorded. An approval covers one
change, once: `use` spends it.

Usage, from inside the project:

    approval.py yes "<change>" --words "<the person's words>"
        Record the person's approval for one named change, with their words and
        today's date.
    approval.py use "<change>"
        Before acting: exit 0 and spend the approval when one is recorded for
        exactly this change, exit 1 when none is.
    approval.py list
        Print the approvals not yet spent.

Two callers at once cannot spend the same approval: every call holds a lock on the
record from the read to the write.

The record is local to the project and never committed: a file in the Git
folder, shared by linked worktrees. A change name is the script's name and its
arguments, such as `merge pull request 12` or `promote dpl_abc 1a2b3c4`. The
refusal names it exactly.

Exit 0 done, 1 refused, 2 could not run.
"""

import datetime
import fcntl
import os
import subprocess
import sys


def stop(message, code):
    print("approval: " + message, file=sys.stderr)
    return code


def record_file():
    try:
        done = subprocess.run(["git", "rev-parse", "--git-common-dir"],
                              capture_output=True, text=True)
    except OSError:
        return None
    if done.returncode:
        return None
    common = done.stdout.strip()
    if not os.path.isabs(common):
        common = os.path.join(os.getcwd(), common)
    return os.path.join(common, "ai-build-kit-approvals")


def read(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return [line.rstrip("\n").split("\t") for line in handle if line.strip()]
    except FileNotFoundError:
        return []


def write(path, rows):
    with open(path + ".new", "w", encoding="utf-8") as handle:
        handle.writelines("\t".join(row) + "\n" for row in rows)
    os.replace(path + ".new", path)


def clean(text):
    return " ".join(str(text).split())


def main(argv):
    if not argv or argv[0] not in ("yes", "use", "list"):
        return stop('usage: approval.py yes "<change>" --words "<words>" | use "<change>" | list', 2)
    path = record_file()
    if not path:
        return stop("this is not inside a project under Git, so no approval can be read or recorded", 2)
    try:
        lock = open(path + ".lock", "a")
        fcntl.flock(lock, fcntl.LOCK_EX)
    except OSError as error:
        return stop("the approval record could not be locked: " + str(error), 2)
    try:
        rows = read(path)
    except (OSError, UnicodeError) as error:
        return stop("the approval record could not be read: " + str(error), 2)
    if argv[0] == "list":
        for row in rows:
            print("\t".join(row))
        return 0
    if len(argv) < 2 or not clean(argv[1]):
        return stop("name the change", 2)
    change = clean(argv[1])
    try:
        if argv[0] == "yes":
            if len(argv) != 4 or argv[2] != "--words" or not clean(argv[3]):
                return stop("approval needs the person's words: --words \"<their words>\"", 2)
            rows.append([datetime.date.today().isoformat(), change, clean(argv[3])])
            write(path, rows)
            print("approval: recorded for %s" % change)
            return 0
        found = next((row for row in rows if len(row) == 3 and row[1] == change), None)
        if not found:
            return stop("no recorded approval for \"%s\". Ask the person. Then record their words with "
                        "approval.py yes \"%s\" --words \"<their words>\", and run this again."
                        % (change, change), 1)
        rows.remove(found)
        write(path, rows)
    except OSError as error:
        return stop("the approval record could not be written: " + str(error), 2)
    print("approval: using the approval of %s for %s: \"%s\"" % (found[0], change, found[2]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
