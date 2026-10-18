#!/usr/bin/env sh
# merge-gate.sh: merge.py honours GitHub JSON checks, review findings, a review record bound to the checked commit, and the checked commit.
# The local gh stand-in follows the documented exit codes and JSON fields.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/merge/scripts/merge.py"
AREA="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin" "$WORK/project/app"
git -C "$WORK/project" init -q -b main
git -C "$WORK/project" config user.name Rehearsal
git -C "$WORK/project" config user.email rehearsal@example.invalid
printf 'value = 1\n' > "$WORK/project/app/data.py"
printf 'Risk areas: none\n' > "$WORK/project/masterplan.md"
git -C "$WORK/project" add app/data.py
git -C "$WORK/project" add masterplan.md
git -C "$WORK/project" commit -q -m base
BASE=$(git -C "$WORK/project" rev-parse HEAD)
git -C "$WORK" init -q --bare remote.git
git -C "$WORK/project" remote add origin "$WORK/remote.git"
git -C "$WORK/project" push -q origin main
git -C "$WORK/project" checkout -q -b feature
printf 'value = 2\n' > "$WORK/project/app/data.py"
git -C "$WORK/project" commit -qam head
HEAD_SHA=$(git -C "$WORK/project" rev-parse HEAD)
git -C "$WORK/project" push -q origin feature
git -C "$WORK/project" checkout -q main
printf 'Risk areas: none\n' > "$WORK/project/masterplan.md"
cat > "$WORK/bin/gh" <<'SH'
#!/usr/bin/env sh
printf '%s\n' "$*" >> "$GH_LOG"
case "$1 $2" in
  "pr view") python3 -c 'import json,os; print(json.dumps({"body":os.environ.get("PR_BODY", ""), "headRefOid":os.environ["PR_HEAD_OID"], "baseRefOid":os.environ["PR_BASE_OID"]}))' ;;
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
    [ "$*" = "pr merge 12 --merge --match-head-commit $PR_HEAD_OID" ] || {
      echo "unexpected merge arguments: $*" >&2
      exit 2
    }
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
BOXES="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/review_boxes.py"
# sealed BODY HEAD [OPEN]: the body with the review record gate.py would write for HEAD.
sealed() {
  python3 -c '
import importlib.util, sys
spec = importlib.util.spec_from_file_location("review_boxes", sys.argv[1])
boxes = importlib.util.module_from_spec(spec)
spec.loader.exec_module(boxes)
body = sys.argv[2] + "\n\n## Worth knowing\n- None"
print(body + "\n" + boxes.record_line("quality review", 1, int(sys.argv[4]), sys.argv[3], False, body))
' "$BOXES" "$1" "$2" "${3:-0}"
}
APPROVAL="$ROOT/.agents/skills/records/scripts/approval.py"
run() {
  [ "${NO_YES:-0}" = 1 ] || (cd "$WORK/project" && python3 "$APPROVAL" yes "merge pull request 12" --words "merge it" >/dev/null)
  review_body=$2
  if [ "${3:-yes}" = yes ]; then
    review_body=$(sealed "$2" "$HEAD_SHA")
  fi
  (cd "$WORK/project" && PATH="$WORK/bin:$PATH" GH_CASE="$1" PR_BODY="$review_body" \
    PR_HEAD_OID="$HEAD_SHA" PR_BASE_OID="$BASE" GIT_TRACE="$WORK/git.trace" \
    EXPECTED_GH="$WORK/bin/gh" sh -c '
      [ "$(command -v gh)" = "$EXPECTED_GH" ] || exit 99
      exec python3 "$1" --approved 12
    ' sh "$SCRIPT")
}
run_auto() {
  review_body=$(sealed "$2" "$HEAD_SHA")
  (cd "$WORK/project" && PATH="$WORK/bin:$PATH" GH_CASE="$1" PR_BODY="$review_body" \
    PR_HEAD_OID="$HEAD_SHA" PR_BASE_OID="$BASE" sh -c 'exec python3 "$1" --auto 12' sh "$SCRIPT")
}
check_hold() {
  case_name=$1 body=$2 expected=$3
  : > "$GH_LOG"
  out=$(run "$case_name" "$body" "${4:-yes}" 2>&1) && code=0 || code=$?
  [ "$code" -eq "$expected" ] && ! grep -q '^pr merge ' "$GH_LOG" \
    && pass "$case_name holds the merge with exit $expected" \
    || fail "$case_name returned $code or reached merge: $out / $(cat "$GH_LOG")"
}
check_merge() {
  body=$1
  : > "$GH_LOG"
  out=$(run success "$body" 2>&1) && code=0 || code=$?
  [ "$code" -eq 0 ] && grep -Fq "pr merge 12 --merge --match-head-commit $HEAD_SHA" "$GH_LOG" \
    && pass "a settled body allows the merge" \
    || fail "settled body returned $code or did not merge: $out / $(cat "$GH_LOG")"
}

set_head_map() {
  git -C "$WORK/project" checkout -q feature
  cat > "$WORK/project/masterplan.md"
  git -C "$WORK/project" add masterplan.md
  git -C "$WORK/project" commit -q --amend --no-edit
  HEAD_SHA=$(git -C "$WORK/project" rev-parse HEAD)
  git -C "$WORK/project" push -q -f origin feature
  git -C "$WORK/project" checkout -q main
}

set_head_map <<'EOF'
Runs on its own: merge (decided 2026-10-15, "merge when everything passes")
EOF
: > "$GH_LOG"
out=$(run_auto success '## Worth stopping for' 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'main has no Runs on its own setting' \
  && ! grep -q '^pr merge ' "$GH_LOG" \
  && pass "a setting present only in the pull request cannot enable automatic merge" \
  || fail "pull-request-only setting returned $code: $out / $(cat "$GH_LOG")"
set_head_map <<'EOF'
Risk areas: none
EOF

out=$(PATH="$WORK/bin:$PATH" python3 "$SCRIPT" 12 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && pass "a missing yes refuses the merge" || fail "missing yes returned $code: $out"
out=$(PATH="$WORK/bin:$PATH" python3 "$SCRIPT" --approved x 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "an invalid pull request number is a usage error" || fail "invalid number returned $code: $out"

for case_name in red pending pending-other failed-other canceled skipping-project missing name-other; do
  check_hold "$case_name" '## Worth stopping for' 1
done
check_hold no-checks '## Worth stopping for' 1
check_hold denied '## Worth stopping for' 2
check_hold success "$(printf '%b' '## Worth stopping for\n- None')" 1 no
: > "$GH_LOG"
out=$(run neutral-other "$(printf '%b' '## Worth stopping for\n- [x] Settled')" 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && grep -Fq "pr merge 12 --merge --match-head-commit $HEAD_SHA" "$GH_LOG" \
  && pass "skipping checks other than project-check do not hold the merge" \
  || fail "a skipped optional check blocked the merge or returned $code: $out"
check_hold success "$(printf '%b' '### Worth stopping for:\n  1. [ ] An open finding\n#### details\n- [x] nested item\n### Worth knowing\n- plain note')" 1
check_hold success "$(printf '%b' '## Review\n### Worth stopping for\n+ [x] Settled\n* [ ] Still open\n## Worth knowing')" 1
check_hold success "$(printf '%b' '## Worth stopping for\n- [x] Settled\n* plain finding\n## Worth knowing')" 1
check_hold success "$(printf '%b' '## Worth knowing\n- fine\n## Worth STOPPING FOR\nA paragraph finding.')" 1
check_merge "$(printf '%b' '## Worth stopping for\n- [x] settled\n  - sub-bullet\n- None')"
check_merge "$(printf '%b' '## Worth stopping for\n- [x] settled\n  - sub-bullet\n- None')"
check_merge "$(printf '%b' '## Worth stopping for\n- None.')"
check_merge "$(printf '%b' '## Worth stopping for\nNothing worth stopping for')"
check_merge "$(printf '%b' '## Worth stopping for\n- [x] Settled\n\n  This is an indented continuation note.')"
check_merge "$(printf '%b' '## Worth knowing\n```md\n## Worth stopping for\n- [ ] example\n```')"
check_hold success "$(printf '%b' '## Worth knowing\n- fine\n**WORTH STOPPING FOR**\n- [ ] later finding')" 1
check_merge "$(printf '%b' '## Worth stopping for\n- [x] Settled\n## Worth knowing\n- plain note')"
check_merge "$(printf '%b' '## Review\n- ordinary note')"

: > "$GH_LOG"
out=$(run success '## Worth stopping for' 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && grep -Fq "pr merge 12 --merge --match-head-commit $HEAD_SHA" "$GH_LOG" \
  && printf '%s' "$out" | grep -q 'review of this version is unverified' \
  && pass "passed checks and a yes merge the checked commit, and an unverified review is called unverified" \
  || fail "success returned $code: $out / $(cat "$GH_LOG")"

# The one approval gate: no recorded yes for this merge, no merge, and a yes is spent once used.
rm -f "$WORK/project/.git/ai-build-kit-approvals"
: > "$GH_LOG"
out=$(NO_YES=1 run success '## Worth stopping for' 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'no recorded yes for "merge pull request 12"' && ! grep -q '^pr merge ' "$GH_LOG" \
  && pass "an approved merge with no recorded yes is refused before GitHub is asked" \
  || fail "a merge with no recorded yes returned $code: $out / $(cat "$GH_LOG")"
: > "$GH_LOG"
out=$(run success '## Worth stopping for' 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s' "$out" | grep -q 'using the yes of' \
  && ! (cd "$WORK/project" && python3 "$APPROVAL" list | grep -q 'merge pull request 12') \
  && pass "a recorded yes lets the named merge through once, and is spent" \
  || fail "a recorded yes did not merge once ($code): $out"

# The review record must name this head and be unedited.
check_record_hold() {
  label=$1 body=$2 words=$3
  : > "$GH_LOG"
  out=$(run success "$body" no 2>&1) && code=0 || code=$?
  [ "$code" -eq 1 ] && printf '%s' "$out" | grep -q "$words" && ! grep -q '^pr merge ' "$GH_LOG" \
    && pass "$label holds the merge" || fail "$label returned $code: $out / $(cat "$GH_LOG")"
}
check_record_hold "a push after the review" \
  "$(sealed '## Worth stopping for' 0123456789abcdef0123456789abcdef01234567)" 'earlier version'
OPEN_RECORD=$(sealed "$(printf '%b' '## Worth stopping for\n- [ ] Saving loses work')" "$HEAD_SHA" 1)
check_record_hold "a body edited to open=0 with no matching record" \
  "$(printf '%s' "$OPEN_RECORD" | sed -e 's/- \[ \]/- [x]/' -e 's/open=1;/open=0;/')" 'changed by hand'
check_record_hold "an older record with no commit" \
  "$(printf '%b' '## Worth stopping for\n- None\n## Worth knowing\n- None\nReview record: reviewed=quality review; tried=1; open=0')" 'older kit'
git -C "$WORK/project" notes --ref=refs/notes/ai-build-kit-approved-merges list | grep -q . \
  && pass "an approved merge writes its named-yes ledger record" \
  || fail "an approved merge did not record its approval"

out=$(run merge-fails '## Worth stopping for' 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && printf '%s' "$out" | grep -q 'no longer mergeable' \
  && pass "a failed gh merge reports its message and exits 2" || fail "failed merge returned $code: $out"

: > "$WORK/git.trace"
: > "$GH_LOG"
out=$(run success '## Worth stopping for' 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && grep -q 'fetch origin ' "$WORK/git.trace" \
  && pass "the merge reads the pull request head before deciding that no risk-area map applies" \
  || fail "the pull request head was not fetched ($code): $out / $(cat "$WORK/git.trace")"

set_head_map <<'EOF'
Risk areas:
  Health:
    paths: app
EOF
: > "$GH_LOG"
out=$(run success '## Worth stopping for' 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'Health' \
  && ! grep -q '^pr merge ' "$GH_LOG" \
  && pass "an open risk area holds the merge from main" \
  || fail "an open area did not hold the merge ($code): $out / $(cat "$GH_LOG")"

set_head_map <<'EOF'
Risk areas:
  Health:
    paths: app
    Accepted: yes, 2026-10-14
EOF
: > "$GH_LOG"
out=$(run success '## Worth stopping for' 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s' "$out" | grep -q 'accepted on 14 October 2026' \
  && grep -Fq "pr merge 12 --merge --match-head-commit $HEAD_SHA" "$GH_LOG" \
  && pass "an accepted risk area reports its line and allows the checked head to merge" \
  || fail "an accepted area did not merge its head ($code): $out / $(cat "$GH_LOG")"

# A folder with python3 and git only, since a runner may have gh in /usr/bin.
mkdir -p "$WORK/nogh"
ln -s "$(command -v python3)" "$WORK/nogh/python3"
ln -s "$(command -v git)" "$WORK/nogh/git"
out=$(cd "$WORK/project" && PATH="$WORK/nogh" "$WORK/nogh/python3" "$SCRIPT" --approved 12 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && printf '%s' "$out" | grep -q 'GitHub CLI (gh) is not installed' \
  && pass "a missing gh exits 2 without a traceback" || fail "missing gh returned $code: $out"

# The pull request is behind main, so no later check or merge command runs.
git -C "$WORK/project" checkout -q main
printf 'new main version\n' > "$WORK/project/app/new-version.txt"
git -C "$WORK/project" add app/new-version.txt
git -C "$WORK/project" commit -q -m 'advance main'
git -C "$WORK/project" push -q origin main
BASE=$(git -C "$WORK/project" rev-parse HEAD)
: > "$GH_LOG"
out=$(run success '## Worth stopping for' 2>&1) && code=0 || code=$?
 [ "$code" -eq 1 ] && printf '%s' "$out" | grep -Eqi 'behind|up to date' \
  && ! grep -q '^pr merge ' "$GH_LOG" && ! grep -q '^pr checks ' "$GH_LOG" \
  && pass "an approved merge holds a branch behind main before checks and merge" \
  || fail "a behind branch returned $code or ran checks: $out / $(cat "$GH_LOG")"

# Exercise the automatic-merge holds directly with controlled GitHub and Git results.
(cd "$WORK/project" && python3 - "$SCRIPT" <<'PY'
import importlib.util, json, sys, subprocess
REAL_RUN = subprocess.run
HEAD = "HEADSHA:feature"
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("merge", sys.argv[1])
merge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(merge)
class Hold(Exception):
    pass
merge.stop = lambda message, code=1: (_ for _ in ()).throw(Hold(str(code) + ":" + message))
setting = 'Runs on its own: merge (decided 2026-10-15, "merge when ready")\n'
state = {"paths": [], "issue": {"title": "Ordinary piece", "body": "## Done when\n- Works\n", "labels": []}, "env": 0, "head_plan": setting}
real_auto_setting = merge.auto_setting
merge.auto_setting = lambda main: "setting"
merge.touched_paths = lambda base, head: state["paths"]
def fake_git(*args):
    if args[0] == "show":
        return subprocess.CompletedProcess(args, 0, state["head_plan"] if args[1].startswith("HEADSHA:") else setting, "")
    return subprocess.CompletedProcess(args, 0, "", "")
merge.git = fake_git
merge.gh = lambda *args: subprocess.CompletedProcess(args, 0, json.dumps(state["issue"]), "")
merge.subprocess.run = lambda *args, **kwargs: subprocess.CompletedProcess(args[0], state["env"], "", "")
def sealed(body):
    return body + "\n" + merge.reviews.record_line("quality", 1, 0, HEAD, False, body)
def held(name, *, paths=None, issue=None, env=0, body=None, expected=None):
    state.update(paths=paths or [], issue=issue or {"title":"Ordinary piece", "body":"## Done when\n- Works\n", "labels":[]}, env=env, head_plan=setting)
    data = {"baseRefOid":"BASE", "body":body if body is not None else sealed("## Worth stopping for\n- None\n## Worth knowing\n- None"), "closingIssuesReferences":[{"number":7}]}
    try:
        merge.auto_holds(data, "MAIN", "HEADSHA:feature")
    except Hold as error:
        message = str(error)
        assert expected and expected in message, f"{name}: unexpected hold: {message}"
        print("ok: automatic hold for " + name)
        return
    raise AssertionError(name + " did not hold")
held("migration", paths=["db/migrations/001.sql"], expected="migration")
for path in [".github/workflows/extra.yml", ".claude/settings.local.json", ".agents/hooks/extra.sh", "package.json", "pnpm-lock.yaml", "Cargo.lock", "requirements/dev.txt"]:
    held("protected path " + path, paths=[path], expected="setting")
held("open review finding", body="## Worth stopping for\n- [ ] Fix access\nReview record: reviewed=quality; tried=1; open=0", expected="finding")
held("missing review record", body="## Worth stopping for\n- None\n", expected="no review recorded")
held("stale review record", body="## Worth stopping for\n- None\n## Worth knowing\nReview record: reviewed=quality; tried=1; open=0", expected="older kit")
held("repair", issue={"title":"Repair broken save", "body":"## Done when\n- Works\n", "labels":[]}, expected="repair")
held("live side need", issue={"title":"Piece", "body":"Live side needs: MAIL_KEY\n## Done when\n- Works\n", "labels":[]}, expected="live setting")
held("try-it item", issue={"title":"Piece", "body":"## Done when\n- Person confirms the result (try it)\n", "labels":[]}, expected="person to try it")
held("new setting", env=1, expected="adds a setting")
state.update(paths=[], issue={"title":"Ordinary piece", "body":"## Done when\n- Works\n", "labels":[]}, env=0, head_plan=setting.replace('merge (', 'off ('))
data={"baseRefOid":"BASE", "body":sealed("## Worth stopping for\n- None\n## Worth knowing\n- None"), "closingIssuesReferences":[{"number":7}]}
try:
    merge.auto_holds(data, "MAIN", "HEADSHA:feature")
except Hold as error:
    assert "changes its own-merge setting" in str(error)
    print("ok: automatic hold for a changed main setting")
else: raise AssertionError("changed setting did not hold")
# Earning auto mode uses records written by merge.py, not GitHub's review API.
merge.git = lambda *args: subprocess.CompletedProcess(args, 0, setting if args[0] == "show" else "", "")
merge.auto_setting = real_auto_setting
try: merge.auto_setting("MAIN")
except Hold as error:
    assert "three named-yes merges" in str(error)
    print("ok: automatic merge waits for three recorded approved merges")
else: raise AssertionError("empty merge ledger earned automatic merge")
# Pending checks are polled; they may settle, or time out without merging.
clock = iter([0, 0, 1, 1, 2])
merge.time.monotonic = lambda: next(clock)
merge.time.sleep = lambda _seconds: None
calls = iter([[{"name":"project-check", "bucket":"pending"}], [{"name":"project-check", "bucket":"pass"}]])
merge.gh = lambda *args: subprocess.CompletedProcess(args, 0, json.dumps(next(calls)), "")
rows = merge.wait_for_auto_checks("12", [{"name":"project-check", "bucket":"pending"}], timeout=5)
assert rows[0]["bucket"] == "pass"
print("ok: automatic merge waits for a pending check to settle")
# A red check on main writes a pause shared by linked worktrees.
merge.subprocess.run = REAL_RUN
merge.git = lambda *args: subprocess.run(["git", *args], text=True, capture_output=True)
merge.gh = lambda *args: subprocess.CompletedProcess(args, 0, '[{"status":"completed","conclusion":"failure","name":"project-check"}]', "")
try: merge.check_main_health()
except Hold as error: assert "paused" in str(error)
else: raise AssertionError("red main check did not pause automatic merge")
assert merge.pause_file().is_file()
linked = merge.Path.cwd().with_name("project-linked")
subprocess.run(["git", "worktree", "add", "-q", "--detach", str(linked), "HEAD"], check=True)
probe = '''import importlib.util, sys; sys.dont_write_bytecode=True; s=importlib.util.spec_from_file_location("m", sys.argv[1]); m=importlib.util.module_from_spec(s); s.loader.exec_module(m); print(m.pause_file().is_file())'''
shared = subprocess.run([sys.executable, "-c", probe, sys.argv[1]], cwd=linked,
                        text=True, capture_output=True, check=True)
assert shared.stdout.strip() == "True", "linked worktree did not see automatic pause"
try: merge.check_main_health()
except Hold as error: assert "paused" in str(error)
else: raise AssertionError("saved automatic pause was ignored")
merge.pause_file().unlink()
print("ok: red main pauses automatic merge across linked worktrees")
PY
) || fail "automatic-merge holds did not behave as expected"

echo "merge-gate.sh: all checks passed"
