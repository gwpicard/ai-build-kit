#!/usr/bin/env sh
# Seed three surviving repair attempts for a fresh-chat recovery check.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu
project=${1:?project directory}
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sh "$here/calendar-feed.sh" "$project"
mkdir -p "$project/notes"
cat > "$project/notes/calendar-repair.md" <<'MD'
# Calendar repair

The same duplicate loan survived three repair attempts. The first kept the
connection's memory, the second changed catch-up, the third changed date updates.
All three were tried and the person reported the duplicate again each time.
The cause is still unestablished. No risk notice or acceptance was recorded.
Next check: reconnect and date-change paths separately.
MD
cat >> "$project/CHANGELOG.md" <<'MD'

## Repair still unfinished

Three attempted repairs of the duplicate calendar loan failed. The team still
sees two entries for one loan. See notes/calendar-repair.md for each attempt.
MD
python3 - "$project/.gh-fixture.json" <<'CODE'
import json, sys
p = sys.argv[1]
s = json.load(open(p))
n = s["next"]
s["issues"].append({"number": n, "title": "Stop duplicate calendar loans", "body": "## Done when\n- One confirmed loan appears once after reconnecting or changing dates\n\n## Evidence\nThe duplicate survives three attempts. Read notes/calendar-repair.md.\n\nRisk areas: none\n", "state": "open", "labels": ["broken", "ready", "behaviour"], "assignees": [], "blocked_by": []})
s["next"] = n + 1
json.dump(s, open(p, "w"), indent=2)
CODE
