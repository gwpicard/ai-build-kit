#!/usr/bin/env sh
# ready-piece.sh: the first half of a preparation that leaves one ready piece on
# the fixture's list and puts the code online, for the /implement behaviour
# scenarios. The piece shows the days late beside each overdue loan. An unrelated
# payroll export sits in the project, so a build that strays outside the piece
# leaves a mark on it. The code goes online in ready-piece.after-commit.sh.
#
# Usage: ready-piece.sh <project-dir>

set -eu

project=${1:?project directory}

if git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ready-piece.sh: $project is inside a git work tree, so it is not a fresh replay project" >&2
  exit 1
fi
[ -f "$project/.gh-fixture.json" ] && [ -f "$project/app/bramble.py" ] || {
  echo "ready-piece.sh: $project is not the fixture" >&2
  exit 1
}

cat > "$project/app/payroll_export.py" <<'PY'
# Existing payroll export. The days-late piece does not own this file.
def export_payroll(rows):
    return "existing export"
PY

python3 - "$project/.gh-fixture.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path))
number = data.get("next", 13)
data["issues"].append({
    "number": number,
    "title": "Show how late each overdue loan is",
    "body": (
        "## So that\na steward sees at a glance which loans are most overdue\n\n"
        "## Done when\n- D1: Each loan on the overdue list shows how many days late it is\n\n"
        "## Evidence\nautomated behaviour check\n\n"
        "## Masterplan change\nnothing\n\n"
        "## Not in this piece\nThe payroll export and any download of the list.\n\n"
        "Risk areas: none\n\n"
        "<details><summary>Under the hood</summary>\n\n"
        "Reaches: app/bramble.py, app/test_bramble.py\n</details>\n"),
    "state": "open",
    "labels": ["behaviour", "ready"],
    "assignees": [],
    "blocked_by": [],
})
data["next"] = number + 1
json.dump(data, open(path, "w"), indent=2)
PY
