#!/usr/bin/env sh
# repair-reset.sh: run section-builder's reset-attempt.sh in a throwaway
# project.
#
# A project's Claude Code settings refuse the plain commands that throw
# changes away, so a repair resets a failed attempt with this script alone. If
# it breaks, failed fixes stack on each other, or the reset takes the saved
# test that reproduces the fault, or a file nobody saved.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/section-builder/scripts/reset-attempt.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "ok: $1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
P="$WORK/project"
mkdir -p "$P/app"
git -C "$P" init -q
git -C "$P" config user.name Rehearsal
git -C "$P" config user.email rehearsal@example.invalid
git -C "$P" config commit.gpgsign false
printf 'total = a + b\n' > "$P/app/sum.js"
printf 'expect 3\n' > "$P/app/sum.test.js"
git -C "$P" add -A
git -C "$P" commit -q -m "Reproduce the wrong total"

run() { (cd "$P" && sh "$SCRIPT"); }

# A failed attempt: one edit unstaged, one staged, and a new scratch file.
printf 'total = a - b\n' > "$P/app/sum.js"
printf 'expect 4\n' > "$P/app/sum.test.js"
git -C "$P" add app/sum.test.js
printf 'debug\n' > "$P/app/debug.log"

out=$(run) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(cat "$P/app/sum.js")" = "total = a + b" ] && [ "$(cat "$P/app/sum.test.js")" = "expect 3" ] \
  && pass "the attempt's edits, staged and unstaged, go back to the saved state" \
  || fail "the reset did not restore the saved files, exit $code: $out"
[ -z "$(git -C "$P" diff HEAD --name-only)" ] \
  && pass "nothing saved differs from the last commit afterwards" \
  || fail "saved files still differ after the reset"
[ -f "$P/app/debug.log" ] && printf '%s' "$out" | grep -q 'app/debug.log' \
  && pass "a file never saved is left in place and named" \
  || fail "the reset removed or hid a file nobody saved"
printf '%s' "$out" | grep -q 'app/sum.js' \
  && pass "the reset names what it put back" \
  || fail "the reset did not say what it changed: $out"

head=$(git -C "$P" rev-parse HEAD)
out=$(run) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(git -C "$P" rev-parse HEAD)" = "$head" ] && printf '%s' "$out" | grep -q 'nothing to throw away' \
  && pass "a reset with nothing to undo changes nothing and says so" \
  || fail "a clean reset returned $code: $out"

out=$(cd "$WORK" && sh "$SCRIPT" 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "outside a Git repository it refuses" || fail "outside a repository it returned $code"

[ "$FAIL" -eq 0 ] || exit 1
echo "repair-reset.sh: all checks passed"
