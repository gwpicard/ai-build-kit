#!/usr/bin/env sh
# promises-list-rehearsal.sh: a missing named checker fails the inventory check.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
cp -R "$ROOT/.agents" "$WORK/.agents"
cp -R "$ROOT/docs" "$WORK/docs"
rm -f "$WORK/.agents/tests/mutate.sh" "$WORK/.agents/tests/run-all.sh"

PROMISES_ROOT="$WORK" sh "$ROOT/.agents/tests/promises-list.sh" >/dev/null
sed 's/\.agents\/tests\/promises-list\.sh/.agents\/tests\/missing-checker.sh/' \
  "$WORK/docs/PROMISES.md" > "$WORK/docs/PROMISES.tmp"
mv "$WORK/docs/PROMISES.tmp" "$WORK/docs/PROMISES.md"
if PROMISES_ROOT="$WORK" sh "$ROOT/.agents/tests/promises-list.sh" >/dev/null 2>&1; then
  echo "FAIL: a missing named checker passed" >&2
  exit 1
fi
sed 's/replay scenarios 3, 4, 5 and 6/replay scenarios 999, 4, 5 and 6/' \
  "$ROOT/docs/PROMISES.md" > "$WORK/docs/PROMISES.md"
if PROMISES_ROOT="$WORK" sh "$ROOT/.agents/tests/promises-list.sh" >/dev/null 2>&1; then
  echo "FAIL: a missing named replay scenario passed" >&2
  exit 1
fi
echo "promises-list-rehearsal.sh: missing checkers and replay scenarios are caught"
