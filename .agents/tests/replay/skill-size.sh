#!/usr/bin/env sh
# skill-size.sh: count source words by skill at a Git ref.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
if [ "$#" -ne 1 ]; then
  echo "usage: skill-size.sh <git-ref>" >&2
  exit 2
fi
git -C "$ROOT" rev-parse --verify "$1^{commit}" >/dev/null 2>&1 || {
  echo "FAIL: not a Git ref: $1" >&2
  exit 2
}
python3 - "$ROOT" "$1" <<'PY'
import subprocess
import sys

root, ref = sys.argv[1:]
paths = subprocess.check_output(
    ["git", "-C", root, "ls-tree", "-r", "--name-only", ref, "--", ".agents/skills"],
    text=True).splitlines()
counts = {}
for path in paths:
    if not path.endswith(".md") or "/templates/" in path or "/recipes/" in path:
        continue
    parts = path.split("/")
    if len(parts) < 4:
        continue
    skill = parts[2]
    content = subprocess.check_output(["git", "-C", root, "show", "%s:%s" % (ref, path)])
    counts[skill] = counts.get(skill, 0) + len(content.decode("utf-8", errors="replace").split())
for skill in sorted(counts):
    print("%-32s %6d" % (skill, counts[skill]))
print("TOTAL                            %6d" % sum(counts.values()))
PY
