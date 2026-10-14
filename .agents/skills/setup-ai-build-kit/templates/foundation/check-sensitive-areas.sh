#!/usr/bin/env sh
# check-sensitive-areas.sh: report changed areas and hold when a decision is open.

exec python3 - "$@" <<'PY'
import fnmatch
import datetime
import os
import re
import shutil
import subprocess
import sys


def fail(message):
    print(message, file=sys.stderr)


def git(*args, cwd=None):
    if not shutil.which("git"):
        raise RuntimeError("git is not installed")
    return subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True)


def parse_areas(lines):
    areas = []
    inside = False
    current = None
    for line in lines:
        if line.strip() == "Sensitive areas:":
            inside = True
            continue
        if inside and line.startswith("## "):
            break
        if not inside:
            continue
        match = re.match(r"^  ([^ :][^:]*):", line)
        if match:
            if current:
                areas.append(finish(current))
            current = {"name": match.group(1).strip(), "paths": [], "decision": "open"}
            accepted = re.search(r";\s*accepted\s+(\d{4}-\d{2}-\d{2})\s*$", line, re.I)
            if accepted:
                current["decision"] = "accepted " + accepted.group(1)
            caution = re.search(r"caution:\s*([^;]+)(?:;\s*(.*))?$", line)
            if caution:
                tail = caution.group(2) or ""
                date = re.search(r"\bdone\s+(\d{4}-\d{2}-\d{2})", tail, re.I)
                if date and not re.search(r"not yet done", tail, re.I):
                    current["decision"] = "caution done " + date.group(1)
        elif current:
            path_match = re.match(r"^\s+paths:\s*(.*)$", line)
            if path_match:
                current["paths"].extend(p.strip().removeprefix("./")
                                        for p in path_match.group(1).split(",") if p.strip())
            accepted = re.match(r"^\s+Accepted:.*?\b(\d{4}-\d{2}-\d{2})\s*$", line)
            if accepted:
                current["decision"] = "accepted " + accepted.group(1)
    if current:
        areas.append(finish(current))
    return areas


def finish(area):
    paths = [p.rstrip("/") for p in area["paths"] if p not in ("none", "")]
    return area["name"], paths, area["decision"]


def plain_date(value):
    return datetime.datetime.strptime(value, "%Y-%m-%d").strftime("%d %B %Y").lstrip("0")


def matches(path, pattern):
    if not any(char in pattern for char in "*?["):
        return path == pattern or path.startswith(pattern.rstrip("/") + "/")
    parts = path.split("/")
    return any(fnmatch.fnmatchcase("/".join(parts[:i]), pattern)
               for i in range(1, len(parts) + 1))


def main(argv):
    if argv == ["--version"]:
        print("sensitive-area-check-v2")
        return 0
    try:
        root = git("rev-parse", "--show-toplevel")
    except (OSError, RuntimeError) as error:
        fail("Sensitive-area check: could not run Git: %s" % error)
        return 2
    if root.returncode:
        fail("Sensitive-area check: run this inside the project")
        return 2
    project = root.stdout.strip()
    plan = os.path.join(project, "masterplan.md")
    if not os.path.isfile(plan):
        return 0
    try:
        with open(plan, encoding="utf-8") as handle:
            lines = handle.read().splitlines()
    except (OSError, UnicodeError) as error:
        fail("Sensitive-area check: could not read masterplan.md: %s" % error)
        return 2
    path_value = next((line.split(":", 1)[1].strip() for line in lines if line.startswith("Path:")), "")
    if path_value != "Build with care":
        return 0
    if not any(line.strip() == "Sensitive areas:" for line in lines):
        fail("Sensitive-area check: the sensitive-area map is missing")
        return 2
    if not argv:
        return validate_map(project, lines)
    if len(argv) not in (2, 4) or argv[0] != "--change" or (len(argv) == 4 and argv[2] != "--head"):
        fail("usage: check-sensitive-areas.sh [--change <base> [--head <commit>]]")
        return 2
    if not argv[1]:
        fail("Sensitive-area check: the base commit is empty")
        return 2
    head = argv[3] if len(argv) == 4 else "HEAD"
    if not head:
        fail("Sensitive-area check: the head commit is empty")
        return 2
    try:
        changed = git("diff", "--no-renames", "--name-only", "--diff-filter=ACDMRTUXB",
                      "-z", argv[1] + "..." + head, cwd=project)
        if changed.returncode:
            raise RuntimeError(changed.stderr.strip() or "git diff failed")
        paths_changed = changed.stdout.split("\0")
    except (OSError, RuntimeError) as error:
        fail("Sensitive-area check: could not read the change: %s" % error)
        return 2
    paths_changed = [p.replace("\\", "/") for p in paths_changed if p]
    failed = False
    for name, paths, decision in parse_areas(lines):
        if any(matches(path, pattern) for path in paths_changed for pattern in paths):
            if decision.startswith("accepted "):
                try:
                    date = plain_date(decision.split(" ", 1)[1])
                except ValueError:
                    fail("Sensitive-area check: the accepted date for %s is unreadable" % name)
                    return 2
                print("This changes %s, which you accepted on %s." % (name, date))
            elif decision.startswith("caution done "):
                try:
                    date = plain_date(decision.rsplit(" ", 1)[1])
                except ValueError:
                    fail("Sensitive-area check: the caution date for %s is unreadable" % name)
                    return 2
                print("This changes %s; its caution was completed on %s." % (name, date))
            else:
                print("This changes %s, which still needs your decision." % name)
                failed = True
    return 1 if failed else 0


def validate_map(project, lines):
    listed = []
    assigned = set()
    inside = False
    for line in lines:
        if line.strip() == "Sensitive areas:":
            inside = True
            continue
        if inside and line.startswith("## "):
            break
        if inside:
            match = re.match(r"^\s+(?:paths|none):\s*(.*)$", line)
            if match:
                listed.extend(p.strip().removeprefix("./") for p in match.group(1).split(",") if p.strip())
    failed = False
    for path in listed:
        if path == "none":
            continue
        assigned.add(path.split("/")[0])
        if any(char in path for char in "*?["):
            continue
        if not os.path.exists(os.path.join(project, path)):
            fail("Sensitive-area map: %s is listed but does not exist. Say where it moved." % path)
            failed = True
    extensions = {".c", ".cc", ".cpp", ".cs", ".go", ".java", ".js", ".jsx", ".kt", ".php",
                  ".py", ".rb", ".rs", ".swift", ".ts", ".tsx"}
    ignored = {"build", "coverage", "dist", "docs", "node_modules", "test", "tests", "vendor"}
    try:
        names = os.listdir(project)
    except OSError as error:
        fail("Sensitive-area map: could not read the project: %s" % error)
        return 2
    for name in names:
        folder = os.path.join(project, name)
        if name.startswith(".") or name in ignored or not os.path.isdir(folder):
            continue
        source = any(os.path.splitext(file)[1] in extensions
                     for current, _, files in os.walk(folder) for file in files)
        if source and name not in assigned:
            fail("Sensitive-area map: %s is a source folder with no area or none line. Say where it belongs." % name)
            failed = True
    return 1 if failed else 0


sys.exit(main(sys.argv[1:]))
PY
