#!/usr/bin/env sh
# Seed an existing project and a usable manual alternative for case 62.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu
project=${1:?project directory}
mkdir -p "$project/operations"
cat > "$project/operations/manual-loan-log.csv" <<'CSV'
item,borrower,due_date,returned
Camera 2,Priya,2026-10-21,no
Microphone 4,Sam,2026-10-19,yes
CSV
cat > "$project/operations/README.md" <<'TXT'
The team uses this shared sheet to track kit loans. When the sheet is unavailable,
the paper sign-out board in the kit room is still usable.
TXT
