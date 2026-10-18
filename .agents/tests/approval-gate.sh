#!/usr/bin/env sh
# approval-gate.sh: the one approval gate lets a named online change through only on the person's recorded yes for exactly that change, once.
#
# merge.py and the recipe steps that change something live call it, and their
# own rehearsals prove they stop without it. This proves the gate itself: a
# yes needs the person's words, names one change, is spent when used, and is
# kept in the project's Git folder, never in a tracked file.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
GATE="$ROOT/.agents/skills/records/scripts/approval.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
FAILED=0
fail() { echo "FAIL: $1" >&2; FAILED=1; }
pass() { echo "ok: $1"; }

git -C "$WORK" init -q project
cd "$WORK/project"

out=$(python3 "$GATE" use "promote dpl_1 abc" 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'no recorded yes for "promote dpl_1 abc"' \
  && pass "a change with no recorded yes is refused, and the refusal names the change" \
  || fail "no yes returned $code: $out"

out=$(python3 "$GATE" yes "promote dpl_1 abc" 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "a yes without the person's words is not recorded" || fail "a yes with no words returned $code: $out"

python3 "$GATE" yes "promote dpl_1 abc" --words "yes, put that build live" >/dev/null
out=$(python3 "$GATE" use "promote dpl_2 def" 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && pass "a yes for one change does not open another" || fail "another change returned $code: $out"

out=$(python3 "$GATE" use "promote dpl_1 abc" 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s' "$out" | grep -q 'yes, put that build live' \
  && pass "the named change goes through on its yes, quoting the person's words" || fail "the named change returned $code: $out"
out=$(python3 "$GATE" use "promote dpl_1 abc" 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && pass "a yes is spent once used" || fail "a spent yes returned $code: $out"

[ -f .git/ai-build-kit-approvals ] && [ -z "$(git status --porcelain)" ] \
  && pass "the record lives in the Git folder, so nothing tracked changes" || fail "the record was not kept in the Git folder"

# Callers at once must not both spend one yes. Each round records one yes and
# starts four callers together. Exactly one may pass.
cd "$WORK"
RACE=$(mktemp)
cat > "$RACE" <<'RACE_END'
import subprocess, sys, tempfile, threading
gate = sys.argv[1]
for _ in range(40):
    with tempfile.TemporaryDirectory() as folder:
        subprocess.run(["git", "init", "-q", folder], check=True)
        subprocess.run(["python3", gate, "yes", "publish", "--words", "yes"], cwd=folder,
                       stdout=subprocess.DEVNULL, check=True)
        start = threading.Barrier(5)
        codes = []
        def use():
            start.wait()
            codes.append(subprocess.run(["python3", gate, "use", "publish"], cwd=folder,
                                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode)
        workers = [threading.Thread(target=use) for _ in range(4)]
        for worker in workers:
            worker.start()
        start.wait()
        for worker in workers:
            worker.join()
        if codes.count(0) != 1:
            sys.exit(1)
RACE_END
python3 "$RACE" "$GATE" && pass "four simultaneous callers spend one yes only once" \
  || fail "one yes was spent more than once by simultaneous callers"
rm -f "$RACE"
cd "$WORK/project"

mkdir -p "$WORK/plain"
out=$(cd "$WORK/plain" && python3 "$GATE" use "merge pull request 1" 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "outside a project the gate could not run, and nothing goes through" || fail "outside a project returned $code: $out"

[ "$FAILED" -eq 0 ] && echo "approval-gate.sh: all checks passed"
exit "$FAILED"
