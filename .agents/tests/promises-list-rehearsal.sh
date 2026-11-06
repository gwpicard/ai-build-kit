#!/usr/bin/env sh
# promises-list-rehearsal.sh: missing checkers, missing scenario contracts and unreplayed scenarios cited as replays fail the inventory check.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
cp -R "$ROOT/.agents" "$WORK/.agents"
cp -R "$ROOT/docs" "$WORK/docs"
rm -f "$WORK/.agents/tests/mutate.sh" "$WORK/.agents/tests/run-all.sh"

REPORT=$(PROMISES_ROOT="$WORK" sh "$ROOT/.agents/tests/promises-list.sh")
printf '%s\n' "$REPORT" | grep -q 'scenario 5: runnable replay case'
printf '%s\n' "$REPORT" | grep -q 'scenario 3: written scenario contract'
sed 's/\.agents\/tests\/promises-list\.sh/.agents\/tests\/missing-checker.sh/' \
  "$WORK/docs/PROMISES.md" > "$WORK/docs/PROMISES.tmp"
mv "$WORK/docs/PROMISES.tmp" "$WORK/docs/PROMISES.md"
if PROMISES_ROOT="$WORK" sh "$ROOT/.agents/tests/promises-list.sh" >/dev/null 2>&1; then
  echo "FAIL: a missing named checker passed" >&2
  exit 1
fi
sed 's/not yet replayed: scenarios 3, 4 and 6/not yet replayed: scenarios 999, 4 and 6/' \
  "$ROOT/docs/PROMISES.md" > "$WORK/docs/PROMISES.md"
if PROMISES_ROOT="$WORK" sh "$ROOT/.agents/tests/promises-list.sh" >/dev/null 2>&1; then
  echo "FAIL: a missing named scenario contract passed" >&2
  exit 1
fi
sed 's/not yet replayed: scenarios 3, 4 and 6/not yet replayed: scenarios 4 and 6; replay scenario 3/' \
  "$ROOT/docs/PROMISES.md" > "$WORK/docs/PROMISES.md"
if PROMISES_ROOT="$WORK" sh "$ROOT/.agents/tests/promises-list.sh" >/dev/null 2>&1; then
  echo "FAIL: a scenario with no runnable case passed as replayed" >&2
  exit 1
fi
echo "promises-list-rehearsal.sh: missing checkers, missing scenario contracts and unreplayed scenarios cited as replays are caught"
