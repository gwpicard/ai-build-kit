#!/usr/bin/env sh
# code-online.sh: the first half of a preparation whose work all happens after
# the first commit. It writes nothing.
#
# A case that saves its piece as a pull request needs the project's code
# already on GitHub. See code-online.after-commit.sh for why.
#
# Usage: code-online.sh <project-dir>

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu

project=${1:?project directory}

# The harness runs this before the project's first commit, so a folder already
# inside a git work tree is not a replay project.
if git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "code-online.sh: $project is inside a git work tree, so it is not a fresh replay project" >&2
  exit 1
fi
