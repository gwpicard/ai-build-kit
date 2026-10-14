#!/usr/bin/env sh
# check-sensitive-areas.sh: report changed areas and hold when a decision is open.

exec python3 - "$@" <<'PY'
import os
import re
import subprocess
import sys

def fail(message):
    print(message, file=sys.stderr)

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
            caution = re.search(r"caution:\s*([^;]+)(?:;\s*(.*))?$", line)
            accepted = re.search(r";\s*accepted\s+(\d{4}-\d{2}-\d{2})\s*$", line, re.I)
            if accepted:
                current["decision"] = "accepted " + accepted.group(1)
            if caution:
                tail = caution.group(2) or ""
                date = re.search(r"\bdone\s+(\d{4}-\d{2}-\d{2})", tail, re.I)
                if date and not re.search(r"not yet done", tail, re.I):
                    current["decision"] = "caution done " + date.group(1)
        elif current:
            path_match = re.match(r"^\s+paths:\s*(.*)$", line)
            if path_match:
                current["paths"].extend(p.strip().removeprefix("./") for p in path_match.group(1).split(",") if p.strip())
            accepted = re.match(r"^\s+Accepted:.*?\b(\d{4}-\d{2}-\d{2})\s*$", line)
            if accepted:
                current["decision"] = "accepted " + accepted.group(1)
    if current:
        areas.append(finish(current))
    return areas

def finish(area):
    paths = [p.rstrip("/") for p in area["paths"] if p not in ("none", "")]
    return area["name"], paths, area["decision"]

def main(argv):
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], text=True, capture_output=True)
    if root.returncode:
        fail("Sensitive-area check: run this inside the project")
        return 2
    project = root.stdout.strip()
    plan = os.path.join(project, "masterplan.md")
    if not os.path.isfile(plan):
        return 0
    with open(plan, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    path_value = next((line.split(":", 1)[1].strip() for line in lines if line.startswith("Path:")), "")
    if path_value != "Build with care":
        return 0
    if not argv:
        return validate_map(project, lines)
    if len(argv) != 2 or argv[0] != "--change":
        fail("usage: check-sensitive-areas.sh [--change <base>]")
        return 2
    try:
        changed = subprocess.run(["git", "diff", "--name-only", "--diff-filter=ACDMRTUXB", "-z",
                                  argv[1]], cwd=project, check=True,
                                 capture_output=True).stdout.decode().split("\0")
    except (subprocess.CalledProcessError, UnicodeDecodeError):
        fail("Sensitive-area check: could not read the change")
        return 2
    changed = [p.replace("\\", "/") for p in changed if p]
    failed = False
    for name, paths, decision in parse_areas(lines):
        if any(path == prefix or path.startswith(prefix.rstrip("/") + "/")
               for path in changed for prefix in paths):
            print("Sensitive area: %s; %s" % (name, decision))
            failed = failed or decision == "open"
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
        if not os.path.exists(os.path.join(project, path)):
            fail("Sensitive-area map: %s is listed but does not exist. Say where it moved." % path)
            failed = True
    extensions = {".c", ".cc", ".cpp", ".cs", ".go", ".java", ".js", ".jsx", ".kt", ".php",
                  ".py", ".rb", ".rs", ".swift", ".ts", ".tsx"}
    ignored = {"build", "coverage", "dist", "docs", "node_modules", "test", "tests", "vendor"}
    for name in os.listdir(project):
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
