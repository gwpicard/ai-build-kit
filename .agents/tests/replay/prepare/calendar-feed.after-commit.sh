#!/usr/bin/env sh
# calendar-feed.after-commit.sh: put the project's main online, as
# code-online.after-commit.sh does, since scenario 8's fixes go out as pull
# requests. The feed itself is in the first commit, written by calendar-feed.sh.
#
# Usage: calendar-feed.after-commit.sh <project-dir>

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ -f "${1:?project directory}/app/calendar_feed.py" ] || {
  echo "calendar-feed.after-commit.sh: $1 has no calendar feed, so calendar-feed.sh did not run" >&2
  exit 1
}
exec sh "$here/code-online.after-commit.sh" "$1"
