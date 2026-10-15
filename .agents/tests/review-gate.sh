#!/usr/bin/env sh
# review-gate.sh: prove the review packet, record and pull-request hold decisions.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
GATE="$ROOT/.agents/skills/quality-checks/scripts/gate.py"
CHECK="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-review.sh"
PARSER="$ROOT/.agents/skills/merge/scripts/review_boxes.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
export GH_EDIT_FILE="$WORK/edits"
PROJECT="$WORK/project"
mkdir -p "$PROJECT/.agents/skills/merge/scripts" "$WORK/bin"
cp "$PARSER" "$PROJECT/.agents/skills/merge/scripts/review_boxes.py"
git -C "$PROJECT" init -q -b main
git -C "$PROJECT" config user.name Rehearsal
git -C "$PROJECT" config user.email rehearsal@example.invalid
printf 'value = 1\n' > "$PROJECT/app.py"
git -C "$PROJECT" add app.py
git -C "$PROJECT" commit -qm base
BASE=$(git -C "$PROJECT" rev-parse HEAD)
printf 'value = 2\n' > "$PROJECT/app.py"
git -C "$PROJECT" commit -qam change
cat > "$WORK/quality.py" <<'PY'
import sys
print("quality evidence")
if len(sys.argv) > 1 and sys.argv[1] == "tests":
    print("strength\t1 mutant missed")
raise SystemExit(0)
PY
cat > "$WORK/bin/gh" <<'SH'
#!/usr/bin/env sh
case "$*" in
  "issue view 7 --json title,body")
    if [ "${PIECE_CASE:-complete}" = missing ]; then
      printf '%s\n' '{"title":"Example","body":"## So that\nIt works.\n"}'
    else
      printf '%s\n' '{"title":"Example","body":"## So that\nIt works.\n\n## Done when\n- It passes\n"}'
    fi
    ;;
  "pr checks --json name,state,bucket") printf '%s\n' '[{"name":"project-check","state":"SUCCESS","bucket":"pass"},{"name":"type-check","state":"SUCCESS","bucket":"pass"},{"name":"lint","state":"SUCCESS","bucket":"pass"}]' ;;
  "pr view 9 --json title,body") printf '%s\n' '{"title":"Example pull request","body":"Summary"}' ;;
  "pr edit 9 --body "*) printf '%s\n' "$*" >> "$GH_EDIT_FILE" ;;
  "pr view 9 --json body --jq .body")
    [ "${GH_VIEW_FAIL:-0}" = 0 ] || { echo "could not read pull request" >&2; exit 1; }
    printf '%s\n' "${REVIEW_BODY:-## Worth stopping for\n- None\n}"
    ;;
  *) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
SH
chmod +x "$WORK/bin/gh"
cat > "$WORK/bin/python3-quality" <<'SH'
#!/usr/bin/env sh
exec python3 "$GATE" "$@"
SH
chmod +x "$WORK/bin/python3-quality"
fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }

out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" GATE_QUALITY_SCRIPT="$WORK/quality.py" GH_EDIT_FILE="$WORK/edits" python3 "$GATE" brief --base "$BASE" --piece 7 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && grep -q '## Full change' "$PROJECT/.git/review-packet.md" \
  && grep -q '## Piece' "$PROJECT/.git/review-packet.md" \
  && grep -q '## So that' "$PROJECT/.git/review-packet.md" \
  && grep -q '## Done when' "$PROJECT/.git/review-packet.md" \
  && grep -q '## Type and lint results' "$PROJECT/.git/review-packet.md" \
  && grep -q '## Test strength' "$PROJECT/.git/review-packet.md" \
  && grep -q 'value = 1' "$PROJECT/.git/review-packet.md" \
  && grep -q '## Review limits' "$PROJECT/.git/review-packet.md" \
  && pass "brief writes a complete packet and exits 0" || fail "brief clean returned $code: $out"

out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" PIECE_CASE=missing GATE_QUALITY_SCRIPT="$WORK/quality.py" python3 "$GATE" brief --base "$BASE" --piece 7 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && grep -q 'Done when' "$PROJECT/.git/review-packet.md" \
  && grep -q 'no Done when section' "$PROJECT/.git/review-packet.md" \
  && pass "brief reports missing agreement as exit 2" || fail "brief missing section returned $code: $out"

out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" GH_EDIT_FILE="$WORK/edits" python3 "$GATE" record --pr 9 <<'JSON'
[{"mark":"reproduced","finding":"The save fails","command":"python3 app.py","output":"Traceback","worth_stopping_for":true},{"mark":"reasoned","finding":"A visitor sees private data","scenario":"A visitor opens the page and exposes private data","worth_stopping_for":false},{"mark":"reproduced","finding":"The refuter disproved this","command":"python3 app.py","output":"No failure","worth_stopping_for":true,"refuted":true},{"mark":"reasoned","finding":"Maybe bad","scenario":"unclear"}]
JSON
) && code=0 || code=$?
[ "$code" -eq 1 ] && grep -q '\- \[ \] The save fails' "$WORK/edits" \
  && grep -q 'finding(s) dropped' "$WORK/edits" \
  && grep -q 'The refuter disproved this' "$WORK/edits" \
  && grep -A4 '## Worth knowing' "$WORK/edits" | grep -q 'The refuter disproved this' \
  && ! grep -q 'Maybe bad' "$WORK/edits" \
  && pass "record keeps evidence, drops unsupported findings and exits 1 for open boxes" || fail "record returned $code: $out"

out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" python3 "$GATE" record --pr 9 <<'JSON'
[]
JSON
) && code=0 || code=$?
[ "$code" -eq 0 ] && pass "record exits 0 when there are no stopping findings" || fail "record clean returned $code: $out"

out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" python3 "$GATE" record --pr 9 <<'JSON'
not-json
JSON
) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "record exits 2 when review input cannot be read" || fail "record invalid input returned $code: $out"

run_check() {
  body=$1
  view_fail=${2:-0}
  (cd "$PROJECT" && PATH="$WORK/bin:$PATH" PR_NUMBER=9 REVIEW_BODY="$body" GH_VIEW_FAIL="$view_fail" sh "$CHECK")
}
out=$(run_check '## Worth stopping for
- None' 0 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && pass "check-review passes after findings are cleared" || fail "check-review clean returned $code: $out"
out=$(run_check '## Worth stopping for
- [ ] Broken save' 0 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && pass "check-review holds an unticked finding" || fail "check-review open returned $code: $out"
out=$(run_check '' 1 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "check-review reports unreadable pull-request state as exit 2" || fail "check-review unavailable returned $code: $out"
