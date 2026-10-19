#!/usr/bin/env sh
# mark-ready.sh: run the shape skill's mark-ready.sh against a stand-in for the
# GitHub command line tool.
#
# If this breaks, a piece reaches ready with no Done when, or loses its needs-
# label with nothing recorded about what settled the question, and /implement
# builds on a guess. Both have happened in real runs, and nothing on screen
# shows it until somebody reads the issue.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/records/scripts/mark-ready.sh"

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
  python3 - "$STANDIN_GH_STATE" <<'PY'
import json, sys
done = "## So that\nPeople see who has the camera.\n\n## Done when\n- The list shows who has each item.\n\nReaches: src/list.ts (1 file)\nRisk areas: none\n"
state = {
    "repo": "someone/kit-log",
    "labels": ["ready", "needs-clarification", "needs-research", "visual", "building"],
    "issues": {
        "1": {"body": done, "labels": ["visual"]},
        "2": {"body": "## So that\nSomething.\n", "labels": []},
        "3": {"body": done, "labels": ["needs-clarification", "visual"]},
        "4": {"body": done + "\n## Decided\nThe interview agreed one list for the whole team.\n",
              "labels": ["needs-clarification", "needs-research", "visual"]},
        "5": {"body": "### Done when\n\n_No response_\n", "labels": []},
        "6": {"body": done + "\n## Decided\n\n<!-- what settled it -->\n", "labels": ["needs-research"]},
        "7": {"body": "### So that\n\nA thing.\n\n### Done when\n\n- It works.\n\nReaches: src/list.ts\n\n### Risk areas\n\nnone\n", "labels": []},
        "8": {"body": "## So that\nA thing.\n\n## Done when\n- It works.\n", "labels": []},
        "9": {"body": "## So that\nA thing.\n\n## Done when\n- It works.\n\nRisk areas: none\n", "labels": []},
        "10": {"body": "## So that\nA thing.\n\n## Done when\n- It works.\n\nRisk areas: none\n", "labels": []},
        "11": {"body": "## So that\nA thing.\n\n## Done when\n- It works.\n\nReaches:\n\nMore notes.\n", "labels": []},
        "12": {"body": "## So that\nA thing.\n\n## Done when\n- It works.\n\n**Reaches:** src/list.ts\nRisk areas: none\n", "labels": []},
        "13": {"body": "## So that\nA thing.\n\n## Done when\n- It works.\n\n- Reaches: src/list.ts\nRisk areas: none\n", "labels": []},
        "14": {"body": "## So that\nA thing.\n\n## Done when\n- It works.\n\n**Reaches:**\n", "labels": []},
        "15": {"body": "## So that\nA thing.\n\n## Done when\n- It works.\n\nReaches:src/list.ts\nRisk areas: none\n", "labels": []},
        "16": {"body": "## So that\nA thing.\n\n## Done when\n- It works.\n\nReaches: src/list.ts\n", "labels": []},
        "17": {"body": "## So that\nA thing.\n\n## Done when\n- It works.\n\nReaches: src/list.ts\nRisk areas:\n\nMore notes.\n", "labels": []},
        "18": {"body": "## So that\nA thing.\n\n## Done when\n- It works.\n\nReaches: src/list.ts\nRisk areas: money, sign-in and permissions\n", "labels": []},
    },
}
json.dump(state, open(sys.argv[1], "w"))
PY
}

labels_of() {
  python3 -c 'import json,sys; print(" ".join(json.load(open(sys.argv[1]))["issues"][sys.argv[2]]["labels"]))' "$STANDIN_GH_STATE" "$1"
}

# Every run is from a throwaway project, whose printout helper only notes
# that it ran, so this repository's own helper is never called.
mkdir -p "$WORK/project/.agents/tools"
mkdir -p "$WORK/project/.agents/skills/quality-checks/scripts"
cp "$ROOT/.agents/skills/quality-checks/scripts/reaches_line.py" "$WORK/project/.agents/skills/quality-checks/scripts/"
mkdir -p "$WORK/project/src"
printf '%s\n' 'export const item = 1' > "$WORK/project/src/list.ts"
(cd "$WORK/project" && git init -q -b main)
printf '%s\n' 'echo refreshed >> refreshed.log' > "$WORK/project/.agents/tools/plan-refresh.sh"
run_at() { dir=$1; shift; (cd "$dir" && PATH="$WORK/bin:$PATH" sh "$SCRIPT" "$@"); }
run() { run_at "$WORK/project" "$@"; }
refreshes() { if [ -f "$WORK/project/refreshed.log" ]; then grep -c . "$WORK/project/refreshed.log"; else echo 0; fi; }

seed

out=$(run 1) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(labels_of 1)" = "visual ready" ] \
  && pass "a sized piece with no question is marked ready" \
  || fail "a sized piece was not marked ready: $code $out, labels $(labels_of 1)"

out=$(run 2) && code=0 || code=$?
[ "$code" -eq 1 ] && [ "$(labels_of 2)" = "" ] && printf '%s' "$out" | grep -q "Done when" \
  && pass "a piece with no Done when is refused and names the missing section" \
  || fail "a piece with no Done when was not refused: $code $out"

out=$(run 5) && code=0 || code=$?
[ "$code" -eq 1 ] && [ "$(labels_of 5)" = "" ] \
  && pass "an empty Done when from the issue form counts as missing" \
  || fail "an empty Done when was accepted: $code $out"

out=$(run 7) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(labels_of 7)" = "ready" ] \
  && pass "an issue form's Done when heading counts" \
  || fail "an issue form's Done when was not read: $code $out"

out=$(run 8) && code=0 || code=$?
[ "$code" -eq 1 ] && [ "$(labels_of 8)" = "" ] && printf '%s' "$out" | grep -q "Reaches" \
  && pass "a code project with no Reaches line is refused" \
  || fail "a code project without Reaches was not refused: $code $out"

mkdir -p "$WORK/plain" "$WORK/kit-only/.agents/skills"
(cd "$WORK/plain" && git init -q -b main && printf 'Notes\n' > README.md)
(cd "$WORK/kit-only" && git init -q -b main && printf 'print(1)\n' > .agents/skills/tool.py)
out=$(run_at "$WORK/plain" 9) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(labels_of 9)" = "ready" ] \
  && pass "a project with no code can be marked ready without a Reaches line" \
  || fail "a no-code project was refused without a Reaches line: $code $out"
seed
out=$(run_at "$WORK/kit-only" 10) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(labels_of 10)" = "ready" ] \
  && pass "kit-only Python files do not make a starter look like a code project" \
  || fail "a kit-only tree was treated as project code: $code $out"

out=$(run 11) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q "Reaches" \
  && pass "an empty Reaches line followed by another line is refused" \
  || fail "an empty Reaches line was accepted: $code $out"
out=$(run 12) && code=0 || code=$?
[ "$code" -eq 0 ] && pass "a bold Reaches label is accepted" \
  || fail "a bold Reaches label was refused: $code $out"
out=$(run 13) && code=0 || code=$?
[ "$code" -eq 0 ] && pass "a list-item Reaches label is accepted" \
  || fail "a list-item Reaches label was refused: $code $out"
out=$(run 14) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q "Reaches" \
  && pass "an empty bold Reaches label is refused" \
  || fail "an empty bold Reaches label was accepted: $code $out"
out=$(run 15) && code=0 || code=$?
[ "$code" -eq 0 ] && pass "Reaches text immediately after the colon is accepted" \
  || fail "Reaches without a space was refused: $code $out"

out=$(run 16) && code=0 || code=$?
[ "$code" -eq 1 ] && [ "$(labels_of 16)" = "" ] && printf '%s' "$out" | grep -q "Risk areas" \
  && pass "a piece that says nothing about risk areas is refused and the missing line is named" \
  || fail "a piece with no Risk areas line was not refused: $code $out"
out=$(run 17) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q "Risk areas" \
  && pass "an empty Risk areas line is refused" \
  || fail "an empty Risk areas line was accepted: $code $out"
out=$(run 18) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(labels_of 18)" = "ready" ] \
  && pass "a piece naming its risk areas is marked ready" \
  || fail "a piece naming risk areas was not marked ready: $code $out"

out=$(run 3) && code=0 || code=$?
[ "$code" -eq 1 ] && [ "$(labels_of 3)" = "needs-clarification visual" ] && printf '%s' "$out" | grep -q "Decided" \
  && pass "a piece whose question has no Decided record keeps its needs- label and is not ready" \
  || fail "a needs- label came off with nothing decided: $code $out, labels $(labels_of 3)"

out=$(run 6) && code=0 || code=$?
[ "$code" -eq 1 ] && [ "$(labels_of 6)" = "needs-research" ] \
  && pass "a Decided section holding only a comment counts as empty" \
  || fail "an empty Decided section was accepted: $code $out"

out=$(run 4) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(labels_of 4)" = "visual ready" ] \
  && pass "a settled piece loses every needs- label and gains ready in one change" \
  || fail "a settled piece did not end ready alone: $code $out, labels $(labels_of 4)"

# A label change GitHub accepts but does not show must not be reported as done.
seed
python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); s["lag"]=1; json.dump(s,open(sys.argv[1],"w"))' "$STANDIN_GH_STATE"
out=$(run 4) && code=0 || code=$?
[ "$code" -eq 2 ] \
  && pass "a change that does not read back is reported, not called ready" \
  || fail "a change that did not read back was reported as $code: $out"

# The person's list is refreshed after a piece is marked ready, and only then.
seed
rm -f "$WORK/project/refreshed.log"
run 2 >/dev/null 2>&1 || :
[ "$(refreshes)" -eq 0 ] \
  && pass "a refused piece leaves the printout alone" \
  || fail "a refused piece refreshed the printout"
out=$(run 1 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(refreshes)" -eq 1 ] \
  && pass "a piece marked ready refreshes the printout" \
  || fail "the printout was not refreshed after marking ready: $code $out"
printf '%s\n' 'exit 1' > "$WORK/project/.agents/tools/plan-refresh.sh"
seed
out=$(run 1 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s' "$out" | grep -q "printout was not refreshed" \
  && pass "a refresh that fails is said, and the piece stays ready" \
  || fail "a failed refresh was not said or changed the result: $code $out"

# GitHub makes the change at once, but its reads show the old labels for a
# moment. A change that worked must not be reported as a failure.
seed
python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); s["read_lag"]=2; json.dump(s,open(sys.argv[1],"w"))' "$STANDIN_GH_STATE"
out=$(run 4) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(labels_of 4)" = "visual ready" ] \
  && pass "a change whose read-back lags is waited for, and reported as ready" \
  || fail "a change that worked but read back late returned $code: $out"

out=$(run abc) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "a number that is not a number is a usage error" || fail "bad usage returned $code"

[ "$FAIL" -eq 0 ] || exit 1
echo "mark-ready.sh: all checks passed"
