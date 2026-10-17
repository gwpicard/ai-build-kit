#!/usr/bin/env sh
# Seed interrupted work, a failing check and an unresolved review for case 60.
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
