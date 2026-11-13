#!/usr/bin/env sh
# Put this prepared fixture online without changing its repair history.
set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec sh "$here/calendar-feed.after-commit.sh" "${1:?project directory}"
