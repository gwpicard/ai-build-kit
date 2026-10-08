#!/usr/bin/env sh
# masterplan-trued.sh: the first half of a preparation that puts the fixture's
# code online and marks its masterplan as checked against that code. Its work
# happens after the first commit, in masterplan-trued.after-commit.sh, so this
# half only refuses a folder that is not a fresh replay project.
#
# Scenario 45 measures a build moving the masterplan's trued-against mark on to
# the code it saved. The fixture's masterplan had no mark, so the build had
# nothing to move: it could only say the page had never been checked, and the
# case measured that instead.
#
# Usage: masterplan-trued.sh <project-dir>

set -eu

project=${1:?project directory}

if git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "masterplan-trued.sh: $project is inside a git work tree, so it is not a fresh replay project" >&2
  exit 1
fi
[ -f "$project/masterplan.md" ] || {
  echo "masterplan-trued.sh: $project has no masterplan.md, so it is not the fixture" >&2
  exit 1
}
if grep -q '^Trued against:' "$project/masterplan.md"; then
  echo "masterplan-trued.sh: $project's masterplan already carries a mark" >&2
  exit 1
fi
