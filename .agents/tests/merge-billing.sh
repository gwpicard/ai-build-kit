#!/usr/bin/env sh
# merge-billing.sh: when billing alone stopped GitHub's project-check, an approved merge runs the same steps on a clean copy of the commit, and holds on anything else.
# The local gh stand-in returns GitHub's billing notice for a check run that never started.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/merge/scripts/merge.py"
APPROVAL="$ROOT/.agents/skills/records/scripts/approval.py"
BOXES="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/review_boxes.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }

mkdir -p "$WORK/bin" "$WORK/project/.github/workflows"
P="$WORK/project"
git -C "$P" init -q -b main
git -C "$P" config user.name Rehearsal
git -C "$P" config user.email rehearsal@example.invalid
printf 'Risk areas: none\n' > "$P/masterplan.md"
git -C "$P" add masterplan.md
git -C "$P" commit -q -m base
BASE=$(git -C "$P" rev-parse HEAD)
git -C "$WORK" init -q --bare remote.git
git -C "$P" remote add origin "$WORK/remote.git"
git -C "$P" push -q origin main

# commit_checks FILE: put FILE on the feature branch as the checks workflow.
commit_checks() {
  git -C "$P" checkout -q -B feature main
  mkdir -p "$P/.github/workflows"
  cp "$1" "$P/.github/workflows/checks.yml"
  git -C "$P" add .github/workflows/checks.yml
  git -C "$P" commit -q -m head
  HEAD_SHA=$(git -C "$P" rev-parse HEAD)
  git -C "$P" push -q -f origin feature
  git -C "$P" checkout -q main
}

cat > "$WORK/good.yml" <<'YML'
name: checks
on:
  pull_request:
jobs:
  project-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - uses: actions/setup-python@v6
        with:
          python-version: '3.14'
      - id: probe
        name: Probe
        run: |
          echo 'ready=yes' >> "$GITHUB_OUTPUT"
      - name: Same commit, no unsaved files
        env:
          HEAD_SHA: ${{ github.event.pull_request.head.sha || github.event.after }}
          GH_TOKEN: ${{ github.token }}
        run: |
          test "$(git rev-parse HEAD)" = "$HEAD_SHA"
          test ! -e unsaved.txt
          test -z "${GH_TOKEN:-}"
      - name: Push only
        if: github.event_name == 'push'
        run: exit 1
      - name: Tests
        if: steps.probe.outputs.ready == 'yes'
        run: |
          test -z "${FAIL_STEP:-}"
          touch "$MARK"
YML
printf '%s\n' 'jobs:' '  project-check:' '    runs-on: ubuntu-latest' \
  '    services:' '      db: postgres' '    steps:' '      - run: touch "$MARK"' > "$WORK/odd.yml"

cat > "$WORK/bin/gh" <<'SH'
#!/usr/bin/env sh
printf '%s\n' "$*" >> "$GH_LOG"
case "$1 $2" in
  "pr view") python3 -c 'import json,os; print(json.dumps({"body":os.environ["PR_BODY"], "headRefOid":os.environ["PR_HEAD_OID"], "baseRefOid":os.environ["PR_BASE_OID"]}))' ;;
  "pr checks")
    row='{"name":"project-check","state":"FAILURE","bucket":"fail","link":"https://github.com/o/r/actions/runs/1/job/111"}'
    if [ "$GH_CASE" = other-blocked ]; then
      printf '[%s,%s]\n' "$row" '{"name":"lint","state":"FAILURE","bucket":"fail","link":"https://github.com/o/r/actions/runs/2/job/222"}'
    else
      printf '[%s]\n' "$row"
    fi ;;
  "api repos/{owner}/{repo}/check-runs/111/annotations"|"api repos/{owner}/{repo}/check-runs/222/annotations")
    if [ "$GH_CASE" = real-failure ]; then
      printf '%s\n' '[{"annotation_level":"failure","message":"Process completed with exit code 1."}]'
    else
      printf '%s\n' '[{"annotation_level":"failure","message":"The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the '"'"'Billing & plans'"'"' section in your settings"}]'
    fi ;;
  "pr merge") exit 0 ;;
  *) exit 2 ;;
esac
SH
chmod +x "$WORK/bin/gh"
GH_LOG="$WORK/gh.log"
MARK="$WORK/steps-ran"
export GH_LOG MARK

sealed() {
  python3 -c '
import importlib.util, sys
spec = importlib.util.spec_from_file_location("review_boxes", sys.argv[1])
boxes = importlib.util.module_from_spec(spec)
spec.loader.exec_module(boxes)
body = "## Worth stopping for\n- None\n\n## Worth knowing\n- None"
print(body + "\n" + boxes.record_line("quality review", 1, 0, sys.argv[2], False, body))
' "$BOXES" "$1"
}
run() {
  : > "$GH_LOG"
  rm -f "$MARK"
  (cd "$P" && python3 "$APPROVAL" yes "merge pull request 12" --words "merge it" >/dev/null)
  (cd "$P" && PATH="$WORK/bin:$PATH" GH_CASE="$1" PR_BODY="$(sealed "$HEAD_SHA")" \
    PR_HEAD_OID="$HEAD_SHA" PR_BASE_OID="$BASE" python3 "$SCRIPT" --approved 12)
}
merged() { grep -Fq "pr merge 12 --merge --match-head-commit $HEAD_SHA" "$GH_LOG"; }

commit_checks "$WORK/good.yml"
printf 'not saved\n' > "$P/unsaved.txt"
out=$(run billing 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && [ -f "$MARK" ] && merged \
  && printf '%s' "$out" | grep -q 'ran on this computer, not on GitHub' \
  && printf '%s' "$out" | grep -q 'skipped Push only' \
  && git -C "$P" notes --ref=refs/notes/ai-build-kit-approved-merges show "$HEAD_SHA" | grep -q 'did not start it (billing)' \
  && pass "a billing block runs the steps on the exact commit without unsaved files, merges, and records it" \
  || fail "billing fallback returned $code: $out / $(cat "$GH_LOG")"
[ "$(git -C "$P" worktree list | wc -l | tr -d ' ')" = 1 ] \
  && pass "the clean copy is removed afterwards" || fail "a clean copy was left behind"

out=$(FAIL_STEP=1 run billing 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && ! merged && printf '%s' "$out" | grep -q 'Tests failed' \
  && pass "a failing local step holds the merge and names the step" \
  || fail "failing local step returned $code: $out / $(cat "$GH_LOG")"

out=$(run real-failure 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && ! merged && [ ! -f "$MARK" ] \
  && pass "a check that ran and failed holds the merge with no local run" \
  || fail "a real failure returned $code or ran locally: $out"

out=$(run other-blocked 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && ! merged && [ ! -f "$MARK" ] \
  && pass "a blocked check other than project-check holds the merge" \
  || fail "another blocked check returned $code or ran locally: $out"

commit_checks "$WORK/odd.yml"
out=$(run billing 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && ! merged && [ ! -f "$MARK" ] && printf '%s' "$out" | grep -q 'services' \
  && pass "a checks file this computer cannot copy holds the merge as not run" \
  || fail "an unreadable checks file returned $code: $out"

echo "merge-billing.sh: all checks passed"
