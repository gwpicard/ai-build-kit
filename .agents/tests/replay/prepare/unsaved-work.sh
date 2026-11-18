#!/usr/bin/env sh
# unsaved-work.sh: the first half of a preparation whose work all happens after
# the first commit. It writes nothing.
#
# Scenario 48 runs a /maintain visit on a project whose tree holds the
# person's own uncommitted work. See unsaved-work.after-commit.sh for what it
# leaves and why.
#
# Usage: unsaved-work.sh <project-dir>

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu

project=${1:?project directory}

# The harness runs this before the project's first commit, so a folder already
# inside a git work tree is not a replay project.
if git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "unsaved-work.sh: $project is inside a git work tree, so it is not a fresh replay project" >&2
  exit 1
fi
[ -f "$project/app/bramble.py" ] || {
  echo "unsaved-work.sh: $project has no app/bramble.py, so it is not the fixture" >&2
  exit 1
}
