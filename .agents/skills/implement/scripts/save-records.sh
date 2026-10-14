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
# Exit 1: refused. Something else is staged, a path is not one file inside the
#         project, or the named paths hold no change. Nothing was committed.
# Exit 2: usage error, or Git failed.

set -u

[ "$#" -ge 2 ] || { echo "usage: save-records.sh \"<commit message>\" <path> [<path> ...]" >&2; exit 2; }
message=$1
shift
[ -n "$message" ] || { echo "save-records: the commit message is empty" >&2; exit 2; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "save-records: this folder is not a Git repository" >&2; exit 2; }
top=$(CDPATH= cd -- "$(git rev-parse --show-toplevel)" && pwd -P)
[ "$top" = "$(pwd -P)" ] || { echo "save-records: run it from the project root, $top" >&2; exit 2; }

command -v python3 >/dev/null 2>&1 || { echo "save-records: python3 is needed to check the paths" >&2; exit 2; }

# Each path must name one file inside the project, written plainly. A folder,
# the project itself, Git's own pathspec forms such as :/ or :(top), and a
# pattern such as *.md could each sweep the person's work into the commit, so
# they are refused. A file the records route deletes counts while Git tracks it.
files=$(python3 - "$top" "$@" <<'PY'
import os, subprocess, sys
top, paths = sys.argv[1], sys.argv[2:]
out = []
for path in paths:
    norm = os.path.normpath(path)
    full = os.path.join(top, norm)
    real = os.path.realpath(full)
    inside = real == top or real.startswith(top + os.sep)
    tracked = subprocess.run(["git", "ls-files", "--error-unmatch", "--", ":(literal)" + norm],
                             cwd=top, capture_output=True).returncode == 0
    if (path.startswith(":") or os.path.isabs(path) or norm in (".", "") or norm.startswith("..")
            or not inside or norm.split(os.sep)[0] == ".git"
            or os.path.isdir(full) or not (os.path.isfile(full) or tracked)):
        print("save-records: %s is not one file inside the project, so nothing was saved" % path)
        sys.exit(1)
    out.append(norm)
print("\n".join(out))
PY
) || { printf '%s\n' "$files"; exit 1; }

# Anything staged that the named files are not belongs to somebody else.
others=$(git diff --cached --name-only | while IFS= read -r staged; do
  printf '%s\n' "$files" | grep -qxF -- "$staged" || printf '%s\n' "$staged"
done)
if [ -n "$others" ]; then
  echo "save-records: other files are already staged, so nothing was saved:"
  printf '%s\n' "$others" | sed 's/^/  /'
  exit 1
fi

set --
while IFS= read -r file; do
  set -- "$@" ":(literal)$file"
done <<EOF
$files
EOF

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
