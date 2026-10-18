#!/usr/bin/env sh
# result-vocabulary.sh: a check that never ran, lost its runner or crashed reports NOT_RUN, never PASS, in quality.py, gate.py and merge.py alike.
#
# The five results and the table of what each does to a merge live in one
# place, quality-checks/scripts/results.py. Each script maps its own exit codes
# or GitHub's check rows onto them where it reports. This runs each script with
# the thing it needs taken away and reads the result it names.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPTS="$ROOT/.agents/skills/quality-checks/scripts"
QUALITY="$SCRIPTS/quality.py"
GATE="$SCRIPTS/gate.py"
MERGE="$ROOT/.agents/skills/merge/scripts/merge.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
FAILED=0
fail() { echo "FAIL: $1" >&2; FAILED=1; }
pass() { echo "ok: $1"; }

# --- the one table ----------------------------------------------------------
PYTHONDONTWRITEBYTECODE=1 python3 - "$SCRIPTS" <<'PY' && pass "the table names all five results: FAIL and NOT_RUN stop a merge, INCONCLUSIVE asks for a review" || fail "the result table is incomplete or lets a result through"
import sys
sys.path.insert(0, sys.argv[1])
import results
assert set(results.POLICY) == {"PASS", "FAIL", "NOT_RUN", "INCONCLUSIVE", "NOT_APPLICABLE"}
assert results.blocks("FAIL") and results.blocks("NOT_RUN")
assert results.POLICY["INCONCLUSIVE"] == "review"
assert not results.blocks("PASS") and not results.blocks("NOT_APPLICABLE")
assert results.from_exit(2) == "NOT_RUN" and results.from_exit(127) == "NOT_RUN"
assert results.from_exit(0) == "PASS" and results.from_exit(1) == "FAIL"
assert results.from_github({"bucket": "pending"}) == "NOT_RUN"
assert results.from_github({}) == "NOT_RUN"
PY

# --- quality.py -------------------------------------------------------------
mkdir -p "$WORK/plain"
out=$(cd "$WORK/plain" && python3 "$QUALITY" trim --base HEAD 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && printf '%s' "$out" | grep -qx 'Result: NOT_RUN' && ! printf '%s' "$out" | grep -q 'Result: PASS' \
  && pass "a read outside a project names NOT_RUN" || fail "a read outside a project returned $code: $out"

git -C "$WORK" init -q project
git -C "$WORK/project" config user.name Rehearsal
git -C "$WORK/project" config user.email rehearsal@example.invalid
printf 'value = 1\n' > "$WORK/project/app.py"
git -C "$WORK/project" add app.py
git -C "$WORK/project" commit -qm base
BASE=$(git -C "$WORK/project" rev-parse HEAD)
printf 'value = 2\n' > "$WORK/project/app.py"
git -C "$WORK/project" commit -qam change

out=$(cd "$WORK/project" && QUALITY_TEST_PIECE_FILE="$WORK/piece.md" python3 "$QUALITY" tests --base "$BASE" --piece 1 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && printf '%s' "$out" | grep -qx 'Result: NOT_RUN' \
  && pass "a test read with no runner names NOT_RUN" || fail "a test read with no runner returned $code: $out"

out=$(cd "$WORK/project" && PYTHONDONTWRITEBYTECODE=1 python3 - "$SCRIPTS" 2>&1 <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
sys.argv = ["quality.py", "trim", "--base", "HEAD"]
import quality
def crash():
    raise RuntimeError("engine fell over")
quality.main = crash
raise SystemExit(quality.reported())
PY
) && code=0 || code=$?
[ "$code" -eq 2 ] && printf '%s' "$out" | grep -q 'not-checked	all	the read stopped with RuntimeError' \
  && printf '%s' "$out" | grep -qx 'Result: NOT_RUN' \
  && pass "a read that crashes names NOT_RUN and exits 2" || fail "a crashed read returned $code: $out"

# --- gate.py ----------------------------------------------------------------
mkdir -p "$WORK/bin"
printf '#!/usr/bin/env sh\necho "gh is not reachable here" >&2\nexit 4\n' > "$WORK/bin/gh"
chmod +x "$WORK/bin/gh"
out=$(cd "$WORK/project" && PATH="$WORK/bin:$PATH" GATE_QUALITY_SCRIPT="$WORK/missing-quality.py" \
  python3 "$GATE" brief --base "$BASE" --piece 1 2>&1) && code=0 || code=$?
packet="$WORK/project/.git/review-packet.md"
[ "$code" -eq 2 ] && [ "$(grep -c '^Result: NOT_RUN$' "$packet")" -eq 3 ] && ! grep -q '^Result: PASS$' "$packet" \
  && pass "a review packet whose reads have no runner shows each as NOT_RUN" \
  || fail "the packet showed a read without a runner as something else ($code): $out / $(cat "$packet" 2>/dev/null)"

# --- merge.py ---------------------------------------------------------------
out=$(cd "$WORK/project" && PYTHONDONTWRITEBYTECODE=1 python3 - "$MERGE" 2>&1 <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("merge", sys.argv[1])
merge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(merge)
said = []
def stop(message, code=1):
    said.append(message)
    raise SystemExit(code)
merge.stop = stop
for rows in ([], [{"name": "project-check", "state": "PENDING", "bucket": "pending"}],
             [{"name": "project-check", "state": "QUEUED"}],
             [{"name": "project-check", "state": "FAILURE", "bucket": "fail"}],
             [{"name": "project-check", "state": "SUCCESS", "bucket": "pass"},
              {"name": "optional", "state": "SKIPPED", "bucket": "skipping"}]):
    try:
        merge.check_hold(rows)
        said.append("allowed")
    except SystemExit:
        pass
print("\n".join(said))
PY
) || true
expected='merge: project-check is missing (NOT_RUN); the pull request stays open
merge: project-check is PENDING (NOT_RUN); the pull request stays open
merge: project-check is QUEUED (NOT_RUN); the pull request stays open
merge: project-check is FAILURE (FAIL); the pull request stays open
allowed'
[ "$out" = "$expected" ] \
  && pass "merge names a missing or unstarted check NOT_RUN and holds, and a skipped optional check only informs" \
  || fail "merge check results were: $out"

[ "$FAILED" -eq 0 ] && echo "result-vocabulary.sh: all checks passed"
exit "$FAILED"
