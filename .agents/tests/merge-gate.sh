#!/usr/bin/env sh
# merge-gate.sh: merge.py refuses a red, pending, missing or unticked check.
# The local gh stand-in follows the documented exit codes.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/merge/scripts/merge.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"
cat > "$WORK/bin/gh" <<'SH'
#!/usr/bin/env sh
printf '%s\n' "$*" >> "$GH_LOG"
case "$1 $2" in
  "pr checks")
    case "$GH_CASE" in
      red) printf '%s\n' '[{"name":"project-check","state":"FAILURE","bucket":"fail"}]'; exit 1 ;;
      pending) printf '%s\n' '[{"name":"project-check","state":"PENDING","bucket":"pending"}]'; exit 8 ;;
      missing) printf '%s\n' '[]'; exit 0 ;;
      denied) echo "could not read" >&2; exit 4 ;;
      *) printf '%s\n' '[{"name":"project-check","state":"SUCCESS","bucket":"pass"}]'; exit 0 ;;
    esac
    ;;
  "pr view")
    case "$GH_CASE" in
      unticked) printf '%s\n' '{"body":"## Worth stopping for\n- [ ] Resolve this"}';;
      *) printf '%s\n' '{"body":"## Worth stopping for\n- [x] Resolved"}';;
    esac
    ;;
  "pr merge") exit 0 ;;
  *) exit 2 ;;
esac
SH
chmod +x "$WORK/bin/gh"
GH_LOG="$WORK/gh.log"
export GH_LOG
fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }
run() { PATH="$WORK/bin:$PATH" GH_CASE="$1" python3 "$SCRIPT" --approved 12; }

out=$(PATH="$WORK/bin:$PATH" python3 "$SCRIPT" 12 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && pass "a missing yes refuses the merge" || fail "missing yes returned $code: $out"
out=$(PATH="$WORK/bin:$PATH" python3 "$SCRIPT" --approved x 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "an invalid pull request number is a usage error" || fail "invalid number returned $code: $out"

for case_name in red pending missing unticked; do
  : > "$GH_LOG"
  out=$(run "$case_name" 2>&1) && code=0 || code=$?
  [ "$code" -eq 1 ] && ! grep -q '^pr merge ' "$GH_LOG" \
    && pass "$case_name checks hold the merge" \
    || fail "$case_name returned $code or reached merge: $out / $(cat "$GH_LOG")"
done

: > "$GH_LOG"
out=$(run success 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && grep -q '^pr merge 12 --merge$' "$GH_LOG" \
  && pass "passed checks and a yes run a merge commit" \
  || fail "success returned $code: $out / $(cat "$GH_LOG")"

out=$(run denied 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "an unreadable check is not treated as a pass" || fail "unreadable checks returned $code: $out"

echo "merge-gate.sh: all checks passed"
