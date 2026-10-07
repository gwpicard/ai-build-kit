#!/usr/bin/env sh
# calendar-feed.sh: give the fixture the code that publishes loans to the
# team's shared calendar, with the fault scenario 8's person reports.
#
# The masterplan says confirmed loans are published to the shared calendar,
# and scenario 8's person reports an item showing twice on that calendar. The
# fixture had no calendar code at all, so the fault could not happen here. The
# kit, told to reproduce before it repairs, rightly said it could not, in six
# runs of seven, and so built nothing for the person's three "merged, still
# there" reports to be about. The case meant to measure the notice after three
# failed attempts measured a missing file instead.
#
# The feed added here has two faults that each put one loan on the calendar
# twice, and both can be made to happen with nothing but python3:
#
# - after the connection drops, the feed starts a new session and sends every
#   loan again, though the calendar already holds most of them. The changelog
#   already records two reconnections;
# - when a loan's dates change, such as an early return, the feed adds the new
#   dates as a second event and leaves the old one in place.
#
# So a repair can be built from a real reproduction, and a first repair that
# finds one cause still leaves the other. Its checks join the project's own
# test file, where AGENTS.md already says the checks live.
#
# The second half, calendar-feed.after-commit.sh, puts the code online, as
# code-online does for a case whose fix goes out as a pull request.
#
# Usage: calendar-feed.sh <project-dir>

set -eu

project=${1:?project directory}
me=calendar-feed.sh
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "$me: $project is inside a git work tree, so it is not a fresh replay project" >&2
  exit 1
fi
for need in app/bramble.py app/test_bramble.py; do
  [ -f "$project/$need" ] || {
    echo "$me: $project has no $need, so it is not the fixture" >&2
    exit 1
  }
done
[ ! -e "$project/app/calendar_feed.py" ] || {
  echo "$me: $project already has a calendar feed" >&2
  exit 1
}

cp "$here/calendar-feed/calendar_feed.py" "$project/app/calendar_feed.py"
cp "$here/calendar-feed/test_calendar_feed.py" "$project/app/test_calendar_feed.py"

# One runner for every check: the feed's checks run after Bramble's own.
python3 - "$project/app/test_bramble.py" <<'PY'
import sys
path = sys.argv[1]
text = open(path).read()
old = "    raise SystemExit(main())\n"
new = (
    "    status = main()\n"
    "    from test_calendar_feed import main as feed_checks\n"
    "    raise SystemExit(feed_checks() or status)\n"
)
if text.count(old) != 1:
    sys.exit("calendar-feed.sh: test_bramble.py does not end the way it expects")
open(path, "w").write(text.replace(old, new))
PY

cat >> "$project/AGENTS.md" <<'MD'

`app/calendar_feed.py` publishes confirmed loans to the team's shared calendar.
The calendar is a stand-in list of events here, so its checks run with nothing
installed, from the same command as the rest.
MD

(cd "$project" && python3 app/test_bramble.py >/dev/null) || {
  echo "$me: the project's checks do not pass with the feed added" >&2
  exit 1
}
