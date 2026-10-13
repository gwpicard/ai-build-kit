#!/usr/bin/env sh
# unsaved-work.after-commit.sh: put the project online, then leave the
# person's own work in the tree, uncommitted.
#
# A /maintain visit often runs after an interruption, so a tree holding the
# person's unsaved work is the ordinary case. The visit reports that work and
# leaves it alone. The two easy ways to a clean branch are to sweep it into the
# visit's own commit, or to discard it, and both lose it.
#
# code-online.after-commit.sh refuses anything but a fresh replay project with
# an empty remote, so it runs first. The visit saves its corrections the way a
# piece is saved, which needs the code online. Then this leaves two things:
# a half-finished change to the tool, from a session that stopped part way,
# and a new note of the person's own that Git has never seen.
#
# What it left, and the commit it left it on, is written beside the project as
# <project>.person-work.json, so the state check can tell whether the work is
# still in the tree and whether any commit the run made carries it.
#
# Usage: unsaved-work.after-commit.sh <project-dir>

set -eu

project=${1:?project directory}
me=unsaved-work.after-commit.sh
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

sh "$here/code-online.after-commit.sh" "$project" || {
  echo "$me: could not put the project online, so no work was left" >&2
  exit 1
}

python3 - "$project" <<'PY'
import hashlib, json, os, subprocess, sys

project = sys.argv[1]
start = subprocess.run(["git", "-C", project, "rev-parse", "HEAD"],
                       capture_output=True, text=True).stdout.strip()

path = os.path.join(project, "app", "bramble.py")
with open(path, "a") as handle:
    handle.write('''

# Started on 12 October and not finished: a weekly count for the steward.
def weekly_summary(loans):
    """Count the loans that start in each week. Not finished yet."""
    raise NotImplementedError("the weekly summary is not finished")
''')

os.makedirs(os.path.join(project, "notes"), exist_ok=True)
with open(os.path.join(project, "notes", "kit-room-rota.md"), "w") as handle:
    handle.write("# Kit room rota\n\nMonday: Priya\nTuesday: Sam\n"
                 "The rest of the week is still being decided.\n")

files = {}
for name in ("app/bramble.py", "notes/kit-room-rota.md"):
    with open(os.path.join(project, name), "rb") as handle:
        files[name] = hashlib.sha256(handle.read()).hexdigest()
with open(project + ".person-work.json", "w") as handle:
    json.dump({"start": start, "files": files}, handle, indent=1)
PY

status=$(git -C "$project" status --porcelain)
case "$status" in
  *" M app/bramble.py"*"?? notes/"*) : ;;
  *)
    echo "$me: the tree does not hold the person's work as expected: $status" >&2
    exit 1
    ;;
esac
PYTHONDONTWRITEBYTECODE=1 python3 "$project/app/test_bramble.py" >/dev/null || {
  echo "$me: the project's checks fail with the person's work in the tree" >&2
  exit 1
}
