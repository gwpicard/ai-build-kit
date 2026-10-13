#!/usr/bin/env sh
# save-records.sh: commit the named record files and nothing else.
#
# Usage: sh save-records.sh "<commit message>" <path> [<path> ...]
#
# A run that writes records, such as a changelog line or a corrected
# masterplan, often finds the person's own work lying uncommitted beside them.
# That work is theirs: it is never swept into the records commit and never
# thrown away. So this script stages only the paths it is given, and refuses
# when anything else is already staged, since a commit takes everything staged.
# Changes elsewhere in the folder stay exactly as they were.
#
# Run it from the project root, on the branch the save route chose.
#
# Exit 0: one new commit holds the named paths; its hash is printed.
# Exit 1: refused. Something else is staged, a path is outside the project, or
#         the named paths hold no change. Nothing was committed.
# Exit 2: usage error, or Git failed.

set -u

[ "$#" -ge 2 ] || { echo "usage: save-records.sh \"<commit message>\" <path> [<path> ...]" >&2; exit 2; }
message=$1
shift
[ -n "$message" ] || { echo "save-records: the commit message is empty" >&2; exit 2; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "save-records: this folder is not a Git repository" >&2; exit 2; }
top=$(CDPATH= cd -- "$(git rev-parse --show-toplevel)" && pwd -P)
[ "$top" = "$(pwd -P)" ] || { echo "save-records: run it from the project root, $top" >&2; exit 2; }

for path in "$@"; do
  case "$path" in
    /*|../*|*/../*|..) echo "save-records: $path is outside the project, so nothing was saved"; exit 1 ;;
  esac
done

# Anything staged that the named paths do not cover belongs to somebody else.
others=$(git diff --cached --name-only | while IFS= read -r staged; do
  covered=no
  for path in "$@"; do
    path=${path#./}
    path=${path%/}
    case "$staged" in ("$path"|"$path"/*) covered=yes ;; esac
  done
  [ "$covered" = yes ] || printf '%s\n' "$staged"
done)
if [ -n "$others" ]; then
  echo "save-records: other files are already staged, so nothing was saved:"
  printf '  %s\n' $others
  exit 1
fi

before=$(git rev-parse -q --verify HEAD || true)
git add -A -- "$@" || { echo "save-records: Git could not stage the named paths" >&2; exit 2; }
if git diff --cached --quiet; then
  echo "save-records: the named paths hold no change, so there is nothing to save"
  exit 1
fi
git commit -q -m "$message" || { echo "save-records: Git refused the commit" >&2; exit 2; }
after=$(git rev-parse HEAD)
[ "$after" != "$before" ] || { echo "save-records: no new commit was made" >&2; exit 2; }
echo "saved: $after"
exit 0
