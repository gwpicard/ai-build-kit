#!/usr/bin/env sh
# standing-lines-rehearsal.sh: run the shipped line count on throwaway files and prove it decides the trim offer at the 200-line ceiling.
#
# If this breaks, a monthly visit could offer no trim to a project whose
# standing instructions have grown past the ceiling, or offer one below it.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/maintain/scripts/standing-lines.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

lines() { awk -v n="$1" 'BEGIN { for (i = 1; i <= n; i++) print "line " i }'; }

run() {
  set +e
  out=$(sh "$SCRIPT" "$1" 2>/dev/null)
  code=$?
  set -e
}

lines 199 > "$WORK/under.md"
run "$WORK/under.md"
[ "$code" -eq 0 ] && [ "$out" = "lines 199" ] || fail "199 lines: expected exit 0 and 'lines 199', got $code '$out'"

lines 200 > "$WORK/at.md"
run "$WORK/at.md"
[ "$code" -eq 1 ] && [ "$out" = "lines 200" ] || fail "200 lines: expected exit 1, got $code '$out'"

# A last line with no newline still counts, and so do blank lines.
{ lines 198; echo; printf 'last line'; } > "$WORK/no-newline.md"
run "$WORK/no-newline.md"
[ "$code" -eq 1 ] && [ "$out" = "lines 200" ] || fail "198 lines, a blank and an unterminated last line: expected 200 and exit 1, got $code '$out'"

run "$WORK/missing.md"
[ "$code" -eq 2 ] || fail "a missing file: expected exit 2, got $code"

# A file it cannot read is exit 2 too. Root reads any file, so skip it there.
if [ "$(id -u)" -ne 0 ]; then
  lines 12 > "$WORK/locked.md"
  chmod 000 "$WORK/locked.md"
  run "$WORK/locked.md"
  chmod 600 "$WORK/locked.md"
  [ "$code" -eq 2 ] || fail "an unreadable file: expected exit 2, got $code"
fi

# Run from a project root with no argument, it reads AGENTS.md there.
mkdir "$WORK/project"
lines 12 > "$WORK/project/AGENTS.md"
set +e
out=$(cd "$WORK/project" && sh "$SCRIPT")
code=$?
set -e
[ "$code" -eq 0 ] && [ "$out" = "lines 12" ] || fail "default file: expected 'lines 12', got $code '$out'"

echo "standing-lines-rehearsal.sh: the line count decides the trim offer at 200 lines"
