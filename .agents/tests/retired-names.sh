#!/usr/bin/env sh
# retired-names.sh: the four retired commands stay retired.
#
# /fix, /queue, /sync and /ship were folded into other commands or renamed. A
# person sent to one of them types a command that does nothing. Only the
# maintain skill, which migrates older projects, and WORKFLOW.md may name them.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SKILLS="$ROOT/.agents/skills"
fail=0

for name in fix queue sync ship; do
  if [ -e "$SKILLS/$name" ]; then
    echo "FAIL: the retired $name skill folder is back"
    fail=1
  fi
done

stale=$(grep -rlE '/(fix|queue|sync|ship)([^a-z/-]|$)' \
    "$SKILLS" "$ROOT/README.md" "$ROOT/llms.txt" "$ROOT/docs/COMPATIBILITY.md" \
    "$ROOT/.agents/hooks" 2>/dev/null \
  | grep -v "^$SKILLS/maintain/" || :)
if [ -n "$stale" ]; then
  echo "FAIL: a shipped file still sends the person to a retired command:"
  echo "$stale"
  fail=1
fi

[ "$fail" -eq 0 ] || exit 1
echo "retired-names.sh: all checks passed"
