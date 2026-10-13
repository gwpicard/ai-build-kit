#!/usr/bin/env sh
# piece-labels.sh: run section-builder's piece-labels.sh against a stand-in for
# the GitHub command line tool.
#
# If this breaks, two people start the same piece because it still reads
# ready, or a closed piece keeps building or ready and the printout offers
# finished work as the next thing to build. A real build closed pieces still
# carrying both.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/section-builder/scripts/piece-labels.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "ok: $1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"
ln -s "$ROOT/.agents/tests/lib/stand-in-gh" "$WORK/bin/gh"
STANDIN_GH_STATE="$WORK/state.json"
STANDIN_GH_LOG="$WORK/gh.log"
export STANDIN_GH_STATE STANDIN_GH_LOG

seed() {
  python3 - "$STANDIN_GH_STATE" "$1" <<'PY'
import json, sys
state = {
    "repo": "someone/kit-log",
    "labels": ["ready", "building", "visual"],
    "lag": int(sys.argv[2]),
    "issues": {"1": {"body": "", "labels": ["visual", "ready"], "assignees": []}},
}
json.dump(state, open(sys.argv[1], "w"))
PY
}
field() {
  python3 -c 'import json,sys; print(" ".join(json.load(open(sys.argv[1]))["issues"]["1"][sys.argv[2]]))' "$STANDIN_GH_STATE" "$1"
}
run() { PATH="$WORK/bin:$PATH" sh "$SCRIPT" "$@"; }

seed 0
out=$(run start 1) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(field labels)" = "visual building" ] && [ "$(field assignees)" = "@me" ] \
  && pass "start swaps ready for building and assigns the builder" \
  || fail "start left $(field labels) / $(field assignees), exit $code: $out"

out=$(run start 1) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(field labels)" = "visual building" ] \
  && pass "starting again changes nothing" \
  || fail "a second start changed the labels: $(field labels)"

out=$(run merged 1) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(field labels)" = "visual" ] \
  && pass "merged takes building off and leaves the person's own labels" \
  || fail "merged left $(field labels), exit $code: $out"

# GitHub accepts a change and shows the old labels for a moment.
seed 2
out=$(run start 1) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(field labels)" = "visual building" ] \
  && pass "a change slow to show is read back and repeated until it holds" \
  || fail "a slow change was not repeated: $(field labels), exit $code"

python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); s["issues"]["1"]["labels"].append("ready"); s["lag"]=5; json.dump(s,open(sys.argv[1],"w"))' "$STANDIN_GH_STATE"
out=$(run merged 1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q "after three tries" \
  && pass "a change that never shows is reported after three tries, not called done" \
  || fail "a change that never showed returned $code: $out"

out=$(run finish 1 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "an unknown step is a usage error" || fail "an unknown step returned $code"

[ "$FAIL" -eq 0 ] || exit 1
echo "piece-labels.sh: all checks passed"
