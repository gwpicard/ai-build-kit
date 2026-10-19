#!/usr/bin/env sh
# site-workflow-map.sh: checks the companion workflow data points to real kit files and skills.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$ROOT"

python3 - <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path.cwd()
data_path = root / "site/data/workflow.json"
llms_path = root / "llms.txt"
skills_root = root / ".agents/skills"

def fail(message):
    print(f"site workflow: {message}", file=sys.stderr)
    raise SystemExit(1)

try:
    stages = json.loads(data_path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as error:
    fail(f"cannot read site/data/workflow.json: {error}")

placed = set()
for stage in stages:
    command = stage.get("command")
    if command and command.startswith("/"):
        placed.add(command[1:])
    source = stage.get("source", "")
    if source.startswith(".agents/skills/") and source.endswith("/SKILL.md"):
        if not (root / source).is_file():
            fail(f"path {source} in site/data/workflow.json does not exist")
        placed.add(source.split("/")[2])
    for skill in stage.get("skills", []):
        skill_path = skills_root / skill / "SKILL.md"
        if not skill_path.is_file():
            fail(f"skill {skill} in site/data/workflow.json is missing from .agents/skills/")
        placed.add(skill)
    for check in stage.get("checks", []):
        path = root / check.get("path", "")
        if not path.is_file():
            fail(f"path {check.get('path', '(missing)')} in site/data/workflow.json does not exist")

for skill_dir in sorted(path for path in skills_root.iterdir() if path.is_dir()):
    if (skill_dir / "SKILL.md").is_file() and skill_dir.name not in placed:
        fail(f"skill {skill_dir.name} in .agents/skills/ has no workflow stage")

counts = {"command": 0, "background": 0}
for skill_dir in skills_root.iterdir():
    metadata = skill_dir / "SKILL.md"
    if not metadata.is_file():
        continue
    frontmatter = metadata.read_text(encoding="utf-8").split("---", 2)
    if len(frontmatter) < 3:
        fail(f"skill {skill_dir.name} has no readable front matter")
    if re.search(r"^user-invocable:\s*false\s*$", frontmatter[1], re.MULTILINE):
        counts["background"] += 1
    else:
        counts["command"] += 1

llms = llms_path.read_text(encoding="utf-8")
match = re.search(r"It installs (\d+) skills: (\d+) commands .* and (\d+) background skills", llms)
if not match:
    fail("llms.txt does not state the command and background skill counts")
total, commands, background = map(int, match.groups())
if (total, commands, background) != (sum(counts.values()), counts["command"], counts["background"]):
    fail("llms.txt skill counts do not match .agents/skills/")

print(f"site workflow: {len(placed)} skills placed; llms.txt matches {commands} commands and {background} background skills")
PY
