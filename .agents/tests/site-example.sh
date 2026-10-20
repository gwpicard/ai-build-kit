#!/usr/bin/env sh
# site-example.sh: checks recorded example data names real kit commands and skills, and holds no local paths or secrets.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$ROOT"

python3 - <<'PY'
import json
import pathlib
import re
import subprocess
import sys

root = pathlib.Path.cwd()
skill_root = root / ".agents/skills"
valid_skills = {}
for folder in skill_root.iterdir():
    file = folder / "SKILL.md"
    if not file.is_file():
        continue
    front = file.read_text(encoding="utf-8").split("---", 2)
    invocable = len(front) >= 3 and not re.search(r"^user-invocable:\s*false\s*$", front[1], re.M)
    valid_skills[folder.name] = invocable

files = sorted(file for file in (root / "site/data/example").glob("*.json") if file.name != "story.json")
if not files:
    print("site example: no transcript steps found", file=sys.stderr)
    raise SystemExit(1)

command_pattern = re.compile(r"(?<![A-Za-z0-9_.:/-])(/[a-z][a-z0-9-]*)\b")
local_pattern = re.compile(r"/private/var|/var/tmp|/private/tmp|/Users/|~/|(?:abk-(?:tmp|try|preview|replay)[A-Za-z0-9._-]*|tmp-[A-Za-z0-9._-]+)", re.I)

for file in files:
    try:
        data = json.loads(file.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"site example: cannot read {file.relative_to(root)}: {error}", file=sys.stderr)
        raise SystemExit(1)
    if data.get("held") is not True or data.get("candidate") != "1.0" or not data.get("turns"):
        print(f"site example: {file.name} is not a held 1.0 candidate transcript", file=sys.stderr)
        raise SystemExit(1)
    for skill in data.get("skills", []):
        if skill not in valid_skills:
            print(f"site example: skill {skill} in {file.name} is missing from .agents/skills/", file=sys.stderr)
            raise SystemExit(1)
    transcript_text = "\n".join(turn.get("text", "") for turn in data["turns"])
    for command in sorted(set(command_pattern.findall(transcript_text))):
        name = command[1:]
        if name not in valid_skills or not valid_skills[name]:
            print(f"site example: command {command} in {file.name} is missing from user-invocable .agents/skills/", file=sys.stderr)
            raise SystemExit(1)
    if local_pattern.search(transcript_text):
        print(f"site example: local path or temporary folder remains in {file.name}", file=sys.stderr)
        raise SystemExit(1)
    scan = subprocess.run(
        [sys.executable, str(root / ".agents/skills/setup-ai-build-kit/templates/foundation/scan-secrets.py"), "--text", file.name],
        input=file.read_bytes(), capture_output=True,
    )
    if scan.returncode:
        print(f"site example: secret scanner rejected {file.name}", file=sys.stderr)
        raise SystemExit(1)

print(f"site example: checked {len(files)} held transcript steps, commands, skills, paths and secret scan")
PY
