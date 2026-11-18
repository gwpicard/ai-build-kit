#!/usr/bin/env sh
# Put one red pull request in the local remote for case 61.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu
project=${1:?project directory}
git -C "$project" checkout -q -B main
git -C "$project" push -q origin main
git -C "$project" checkout -q -b auto-merge-exceeds
printf '%s\n' 'change awaiting merge' > "$project/app/overdue-list.txt"
git -C "$project" add app/overdue-list.txt
git -C "$project" commit -q -m 'Show days late on overdue list'
git -C "$project" push -q origin auto-merge-exceeds
git -C "$project" checkout -q main
