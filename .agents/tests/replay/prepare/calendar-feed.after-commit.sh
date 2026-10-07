#!/usr/bin/env sh
# calendar-feed.after-commit.sh: put the project's main online, as
# code-online.after-commit.sh does, since scenario 8's fixes go out as pull
# requests. The feed itself is in the first commit, written by calendar-feed.sh.
#
# Usage: calendar-feed.after-commit.sh <project-dir>

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ -f "${1:?project directory}/app/calendar_feed.py" ] || {
  echo "calendar-feed.after-commit.sh: $1 has no calendar feed, so calendar-feed.sh did not run" >&2
  exit 1
}
exec sh "$here/code-online.after-commit.sh" "$1"
