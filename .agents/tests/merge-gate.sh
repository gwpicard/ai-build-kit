#!/usr/bin/env sh
# merge-gate.sh: merge.py honours GitHub JSON checks, review findings and the checked commit.
# The local gh stand-in follows the documented exit codes and JSON fields.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/merge/scripts/merge.py"
AREA="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin" "$WORK/project/.agents/hooks"
git -C "$WORK/project" init -q
cp "$AREA" "$WORK/project/.agents/hooks/check-sensitive-areas.sh"
printf 'Path: Explore privately\n' > "$WORK/project/masterplan.md"
cat > "$WORK/bin/gh" <<'SH'
#!/usr/bin/env sh
printf '%s\n' "$*" >> "$GH_LOG"
case "$1 $2" in
  "pr view") python3 -c 'import json,os; print(json.dumps({"body":os.environ.get("PR_BODY", ""), "headRefOid":"abc123", "baseRefOid":"base123"}))' ;;
  "pr checks")
    case "$GH_CASE" in
      red) printf '%s\n' '[{"name":"project-check","state":"FAILURE","bucket":"fail"}]'; exit 0 ;;
      pending) printf '%s\n' '[{"name":"project-check","state":"PENDING","bucket":"pending"}]'; exit 0 ;;
      pending-other) printf '%s\n' '[{"name":"lint","state":"PENDING","bucket":"pending"},{"name":"project-check","state":"SUCCESS","bucket":"pass"}]'; exit 0 ;;
      failed-other) printf '%s\n' '[{"name":"lint","state":"FAILURE","bucket":"fail"},{"name":"project-check","state":"SUCCESS","bucket":"pass"}]'; exit 0 ;;
      canceled) printf '%s\n' '[{"name":"lint","state":"CANCELLED","bucket":"cancel"},{"name":"project-check","state":"SUCCESS","bucket":"pass"}]'; exit 0 ;;
      skipping-project) printf '%s\n' '[{"name":"project-check","state":"SKIPPED","bucket":"skipping"}]'; exit 0 ;;
      neutral-other) printf '%s\n' '[{"name":"optional","state":"NEUTRAL","bucket":"skipping"},{"name":"project-check","state":"SUCCESS","bucket":"pass"}]'; exit 0 ;;
      missing) printf '%s\n' '[]'; exit 0 ;;
      name-other) printf '%s\n' '[{"name":"not-project-check","state":"SUCCESS","bucket":"pass"}]'; exit 0 ;;
      no-checks) echo "no checks reported on the 'main' branch" >&2; exit 1 ;;
      denied) echo "could not read" >&2; exit 4 ;;
      merge-fails) printf '%s\n' '[{"name":"project-check","state":"SUCCESS","bucket":"pass"}]';;
      *) printf '%s\n' '[{"name":"project-check","state":"SUCCESS","bucket":"pass"}]'; exit 0 ;;
    esac
    ;;
  "pr merge")
    [ "$GH_CASE" != merge-fails ] || { echo "Pull request is no longer mergeable" >&2; exit 1; }
    exit 0
    ;;
  *) exit 2 ;;
esac
SH
chmod +x "$WORK/bin/gh"
GH_LOG="$WORK/gh.log"
export GH_LOG
fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }
run() { (cd "$WORK/project" && PATH="$WORK/bin:$PATH" GH_CASE="$1" PR_BODY="$2" python3 "$SCRIPT" --approved 12); }
check_hold() {
  case_name=$1 body=$2 expected=$3
  : > "$GH_LOG"
  out=$(run "$case_name" "$body" 2>&1) && code=0 || code=$?
  [ "$code" -eq "$expected" ] && ! grep -q '^pr merge ' "$GH_LOG" \
    && pass "$case_name holds the merge with exit $expected" \
    || fail "$case_name returned $code or reached merge: $out / $(cat "$GH_LOG")"
}
check_merge() {
  body=$1
  : > "$GH_LOG"
  out=$(run success "$body" 2>&1) && code=0 || code=$?
  [ "$code" -eq 0 ] && grep -q '^pr merge 12 --merge --match-head-commit abc123$' "$GH_LOG" \
    && pass "a settled body allows the merge" \
    || fail "settled body returned $code or did not merge: $out / $(cat "$GH_LOG")"
}

out=$(PATH="$WORK/bin:$PATH" python3 "$SCRIPT" 12 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && pass "a missing yes refuses the merge" || fail "missing yes returned $code: $out"
out=$(PATH="$WORK/bin:$PATH" python3 "$SCRIPT" --approved x 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "an invalid pull request number is a usage error" || fail "invalid number returned $code: $out"

for case_name in red pending pending-other failed-other canceled skipping-project missing name-other; do
  check_hold "$case_name" '## Worth stopping for' 1
done
check_hold no-checks '## Worth stopping for' 1
check_hold denied '## Worth stopping for' 2
: > "$GH_LOG"
out=$(run neutral-other $'## Worth stopping for\n- [x] Settled' 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && grep -q '^pr merge 12 --merge --match-head-commit abc123$' "$GH_LOG" \
  && pass "skipping checks other than project-check do not hold the merge" \
  || fail "a skipped optional check blocked the merge or returned $code: $out"
check_hold success $'### Worth stopping for:\n  1. [ ] An open finding\n#### details\n- [x] nested item\n### Worth knowing\n- plain note' 1
check_hold success $'## Review\n### Worth stopping for\n+ [x] Settled\n* [ ] Still open\n## Worth knowing' 1
check_hold success $'## Worth stopping for\n- [x] Settled\n* plain finding\n## Worth knowing' 1
check_merge $'## Worth stopping for\n- [x] Settled\n## Worth knowing\n- plain note'
check_merge $'## Review\n- ordinary note'

: > "$GH_LOG"
out=$(run success '## Worth stopping for' 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && grep -q '^pr merge 12 --merge --match-head-commit abc123$' "$GH_LOG" \
  && pass "passed checks and a yes merge the checked commit" \
  || fail "success returned $code: $out / $(cat "$GH_LOG")"

out=$(run merge-fails '## Worth stopping for' 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && printf '%s' "$out" | grep -q 'Pull request is no longer mergeable' \
  && pass "a failed gh merge reports its message and exits 2" || fail "failed merge returned $code: $out"

out=$(cd "$WORK/project" && PATH="/usr/bin:/bin" python3 "$SCRIPT" --approved 12 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && printf '%s' "$out" | grep -q 'GitHub CLI (gh) is not installed' \
  && pass "a missing gh exits 2 without a traceback" || fail "missing gh returned $code: $out"

echo "merge-gate.sh: all checks passed"
