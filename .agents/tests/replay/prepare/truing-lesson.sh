#!/usr/bin/env sh
# Seed two recorded instances of the same mistaken calendar assessment.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu
project=${1:?project directory}
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sh "$here/calendar-feed.sh" "$project"
cat >> "$project/CHANGELOG.md" <<'MD'

## 2026-06-19

The agent said the calendar showed one event per loan after checking only the
booking records. Sam corrected it: the shared calendar still showed duplicates.
No application change was made.

## 2026-06-20

The agent again said the shared calendar was correct based only on booking
records. Priya checked the feed and found duplicates again. This was the same
assessment mistake twice; no application change was made.
MD
