#!/usr/bin/env sh
# Seed the failed check and waiting review for cases 60, 79 and 81.
# returning-work.after-commit.sh leaves the person's repair unsaved.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu
project=${1:?project directory}
mkdir -p "$project/review"
printf '%s\n' 'status: waiting' 'finding: duplicate loan records still appear after the attempted fix' > "$project/review/pending.md"
printf '%s\n' '# Check result' 'status: failing' 'command: python3 app/test_replay_failure.py' > "$project/check-result.md"
printf '%s\n' 'assert False, "known failing check from interrupted work"' > "$project/app/test_replay_failure.py"
cat >> "$project/AGENTS.md" <<'TXT'

The interrupted repair check is `python3 app/test_replay_failure.py`; it is
currently failing and must be restored before the repair is treated as ready.
TXT
printf '%s\n' 'status: interrupted' 'change: repair is incomplete and uncommitted' > "$project/.replay-returning-state"
