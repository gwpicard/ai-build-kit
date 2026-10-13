#!/usr/bin/env sh
# implement-merges-on-a-yes.sh: run the shipped check-before-merge.sh against
# stand-in commands.
#
# If this breaks, a pre-merge check that could not run might hold a merge, or
# one that ran and failed might let a broken change go live.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
ok() { echo "  ok: $1"; pass=$((pass + 1)); }
fail() { echo "FAIL: $1" >&2; exit 1; }

CHECK="$ROOT/.agents/skills/implement/scripts/check-before-merge.sh"
[ -f "$CHECK" ] || fail "missing file $CHECK"
log="$WORK/cleanup.log"
run_check() {
  # run_check <expected exit> <description> <args>...
  want=$1; what=$2; shift 2
  : > "$log"
  set +e
  last=$(sh "$CHECK" "$@" 2>/dev/null)
  got=$?
  set -e
  [ "$got" -eq "$want" ] || fail "$what: exited $got, not $want ($last)"
  ok "$what"
}
run_check 0 "every command passing exits 0" --ready true true 'echo built'
run_check 0 "a cleanup that fails does not turn a pass into anything else" --cleanup false true
run_check 1 "a command that runs and fails exits 1" --ready true true false
run_check 1 "a failing read of a health route exits 1, not 2" 'sh -c "exit 22"'
run_check 2 "a ready command that fails exits 2" --ready false true
run_check 2 "a tool that is not installed exits 2" 'no-such-tool-for-this-check build'
run_check 2 "a ready command whose tool is missing exits 2" --ready 'no-such-tool-for-this-check info' true
run_check 2 "a tool past a leading ! or a setting is still looked for" 'FOO=1 ! no-such-tool-for-this-check'
run_check 2 "no command at all exits 2" --ready true
run_check 2 "a missing tool later in a line exits 2, not 1" 'true && no-such-tool-for-this-check'
run_check 2 "a ready option with no command exits 2, not 1" true --ready
run_check 2 "an option it does not have exits 2" --retries 3 true
run_check 0 "a program in quotes is found" '"sh" -c true'
run_check 0 "a program after a bracket is found" '(sh -c true)'
run_check 1 "a quoted program whose check fails still exits 1" '"sh" -c false'
set +e
sh "$CHECK" --cleanup "echo cleaned >> '$log'" true false 'echo never >> '"'$log'" >/dev/null 2>&1
set -e
[ "$(cat "$log")" = cleaned ] ||
  fail "after a failure the cleanup must run and no later command may"
ok "after a failure the cleanup runs, and no later command does"
: > "$log"
sh "$CHECK" --cleanup "echo cleaned >> '$log'" true >/dev/null 2>&1
[ "$(cat "$log")" = cleaned ] || fail "after a pass the cleanup must run"
ok "after a pass the cleanup runs too"
out=$(sh "$CHECK" --ready false true 2>/dev/null || true)
case $out in "could not run:"*) ok "a check that could not run says so on its last line" ;;
  *) fail "a check that could not run printed: $out" ;; esac
out=$(sh "$CHECK" true false 2>/dev/null || true)
case $out in "failed: false exited 1") ok "a failed check names the command that failed" ;;
  *) fail "a failed check printed: $out" ;; esac

echo
echo "$(basename -- "$0"): all $pass checks passed"
