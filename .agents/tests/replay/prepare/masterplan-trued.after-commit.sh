#!/usr/bin/env sh
# masterplan-trued.after-commit.sh: put the project's main online, then mark
# the masterplan as checked against the harness's first commit, as a /maintain
# visit would have left it, and put that on main too.
#
# The mark is a records-only commit on top of the first one, since a commit
# cannot name its own hash. code-online.after-commit.sh refuses anything but a
# fresh replay project with an empty remote, so it runs first, and only then
# is the mark added and pushed.
#
# The project then starts with two commits rather than one. state-check.sh
# reads more than one commit as work the run saved, which matters only where a
# contract allows an acceptance or asks for a local checkpoint. Scenario 45
# does neither.
#
# Usage: masterplan-trued.after-commit.sh <project-dir>

set -eu

project=${1:?project directory}
me=masterplan-trued.after-commit.sh
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

sh "$here/code-online.after-commit.sh" "$project" || {
  echo "$me: could not put the project online, so no mark was added" >&2
  exit 1
}

first=$(git -C "$project" rev-parse HEAD)
plan="$project/masterplan.md"
awk -v mark="Trued against: $first" '
  { print }
  !done && /^# / { print ""; print mark; done = 1 }
' "$plan" > "$plan.trued"
mv "$plan.trued" "$plan"
grep -qx "Trued against: $first" "$plan" || {
  echo "$me: the masterplan has no title line to put the mark beside" >&2
  exit 1
}
git -C "$project" add masterplan.md
git -C "$project" commit -q -m "Record that the masterplan was checked against the code"
git -C "$project" push -q origin main
