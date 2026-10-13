#!/usr/bin/env sh
# found-save.sh: save founding's first checkpoint on this computer, then mark
# the masterplan as checked against it.
#
# Usage, from the project root:  sh found-save.sh ["<checkpoint message>"]
#
# It does four things, in order, and pushes nothing:
#   1. Makes the folder a Git repository on a branch called main, if it is not
#      one yet, and points Git at the project's push guard.
#   2. Sets a save name and email only where none is set, to the neutral
#      "Local project user", inside this project only. It never copies the
#      last commit's author, who may be somebody else entirely.
#   3. Saves every file as the founding checkpoint.
#   4. Writes that checkpoint's hash into the masterplan's "Trued against:" line
#      and saves it in a second, records-only checkpoint, then checks the mark
#      with trued-mark.sh.
#
# Output lines have fields separated by tabs:
#   identity    kept | neutral
#   checkpoint  HASH
#   trued       HASH
#
# Exit 0: both checkpoints exist and the mark is usable.
# Exit 1: no new checkpoint was made, or the mark could not be written or read
#         back. The line printed says which.
# Exit 2: usage error.

set -u

SKILL_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
message=${1:-Found the project}
[ "$#" -le 1 ] || { echo "usage: found-save.sh [\"<checkpoint message>\"]" >&2; exit 2; }
[ -f masterplan.md ] || { echo "found-save: there is no masterplan.md here; run it from the project root" >&2; exit 2; }
count=$(grep -c '^Trued against:' masterplan.md || true)
[ "$count" -eq 1 ] || { echo "found-save: the masterplan has $count Trued against: lines, so nothing was saved"; exit 1; }

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -q || { echo "found-save: Git could not start a repository here"; exit 1; }
  git symbolic-ref HEAD refs/heads/main
fi
top=$(CDPATH= cd -- "$(git rev-parse --show-toplevel)" && pwd -P)
[ "$top" = "$(pwd -P)" ] || {
  echo "found-save: this folder sits inside the Git repository at $top, so nothing was saved"
  exit 1
}
sh "$SKILL_ROOT/scripts/use-push-guard.sh" . ||
  echo "found-save: the push guard is not on, so only the coding agent's own settings stop a push to main" >&2

name=$(git config --get user.name || true)
email=$(git config --get user.email || true)
if [ -n "$name" ] && [ -n "$email" ]; then
  echo "identity	kept"
else
  [ -n "$name" ] || git config --local user.name "Local project user"
  [ -n "$email" ] || git config --local user.email "local-project-user@localhost"
  echo "identity	neutral"
fi

before=$(git rev-parse -q --verify HEAD || true)
git add -A
git commit -q -m "$message" || { echo "found-save: no new checkpoint was made, because nothing was waiting to be saved"; exit 1; }
checkpoint=$(git rev-parse HEAD)
[ "$checkpoint" != "$before" ] || { echo "found-save: no new checkpoint was made"; exit 1; }
echo "checkpoint	$checkpoint"

python3 - "$checkpoint" <<'PY' || { echo "found-save: the mark could not be written"; exit 1; }
import sys
path = "masterplan.md"
with open(path, encoding="utf-8", newline="") as handle:
    lines = handle.readlines()
for index, line in enumerate(lines):
    if line.startswith("Trued against:"):
        ending = line[len(line.rstrip("\r\n")):]
        lines[index] = "Trued against: " + sys.argv[1] + ending
with open(path, "w", encoding="utf-8", newline="") as handle:
    handle.writelines(lines)
PY
git add masterplan.md
git commit -q -m "Mark the masterplan as checked against the founding checkpoint" -- masterplan.md ||
  { echo "found-save: the mark was written but not saved"; exit 1; }
[ "$(git rev-parse HEAD)" != "$checkpoint" ] || { echo "found-save: no records-only checkpoint was made"; exit 1; }

mark=$(sh "$SKILL_ROOT/scripts/trued-mark.sh" masterplan.md) || { echo "found-save: $mark"; exit 1; }
echo "trued	${mark#usable: }"
exit 0
