#!/usr/bin/env sh
# Seed an agreed overdue-age piece and an unrelated export surface for case 63.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu
project=${1:?project directory}
cat > "$project/app/overdue.py" <<'PY'
def days_late(due_date, today):
    return max(0, (today - due_date).days)
PY
cat > "$project/app/payroll_export.py" <<'PY'
# Existing payroll export. The agreed overdue-list piece does not own this file.
def export_payroll(rows):
    return "existing export"
PY
