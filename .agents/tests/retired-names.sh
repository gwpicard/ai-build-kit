#!/usr/bin/env sh
# retired-names.sh: the four retired commands and the three folded background
# skills stay retired.
#
# /fix, /queue, /sync and /ship were folded into other commands or renamed. A
# person sent to one of them types a command that does nothing. Only the
# maintain skill, which migrates older projects, and WORKFLOW.md may name them.
#
# change-triage, section-builder and screen-check folded into /shape and
# /implement. A skill told to load one of them finds nothing on a project
# updated past the fold, so no shipped file names them except the maintain
# skill's scripts, which recognise the old folders to remove them.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SKILLS="$ROOT/.agents/skills"
fail=0

for name in fix queue sync ship change-triage section-builder screen-check; do
  if [ -e "$SKILLS/$name" ]; then
    echo "FAIL: the retired $name skill folder is back"
    fail=1
  fi
  for adapter in "$ROOT/.claude/skills/$name" "$ROOT/.claude/commands/$name.md"; do
    if [ -e "$adapter" ]; then
      echo "FAIL: a generated adapter for the retired $name skill is back: $adapter"
      fail=1
    fi
  done
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

folded=$(grep -rlE 'change-triage|section-builder|screen-check' \
    "$SKILLS" "$ROOT/README.md" "$ROOT/llms.txt" "$ROOT/WORKFLOW.md" \
    "$ROOT/docs/COMPATIBILITY.md" "$ROOT/docs/PHILOSOPHY.md" "$ROOT/.agents/hooks" \
    "$ROOT/.agents/guard" "$ROOT/.claude-plugin" "$ROOT/agent-plugin" \
    "$ROOT/release-manifest.txt" 2>/dev/null \
  | grep -v "^$SKILLS/maintain/scripts/" || :)
if [ -n "$folded" ]; then
  echo "FAIL: a shipped file still names a folded background skill:"
  echo "$folded"
  fail=1
fi

[ "$fail" -eq 0 ] || exit 1
echo "retired-names.sh: all checks passed"
