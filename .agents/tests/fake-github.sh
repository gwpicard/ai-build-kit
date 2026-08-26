#!/usr/bin/env sh
# fake-github.sh: check the replay harness's stand-in for the GitHub CLI.
#
# The stand-in answers the commands the kit reaches for and refuses the rest to
# a log. Both halves matter. An answer that drifts from the real CLI's shape
# makes a scenario fail for a reason the kit did not cause, and a refusal that
# quietly becomes an answer hides the fact that nobody modelled it.
#
# Everything here runs against a throwaway state file. No network, no account.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
GH="$ROOT/tests/replay/fake-github/gh"

FAIL=0
fail() {
  echo "FAIL: $1" >&2
  FAIL=1
}
pass() {
  echo "ok: $1"
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

FAKE_GH_STATE="$WORK/.gh-fixture.json"
FAKE_GH_LOG="$WORK/gh.log"
export FAKE_GH_STATE FAKE_GH_LOG

# A repository to stand on, so the branch a pull request is opened from is real.
git init -q "$WORK/project"
cd "$WORK/project"
git config user.email rehearsal@example.com
git config user.name Rehearsal
git commit -q --allow-empty -m "first"
git checkout -q -b deposits

echo "== The commands the kit uses =="

"$GH" --version | grep -q "gh version" \
  && pass "--version answers plainly" \
  || fail "--version did not answer"

first=$("$GH" issue create --title "Take a deposit" --body "## Done when
- a deposit is recorded" --label behaviour)
case "$first" in
  https://github.com/*/issues/1) pass "issue create returns the new issue's address" ;;
  *) fail "issue create returned '$first'" ;;
esac

"$GH" issue create --title "Refund a deposit" --body "## Done when
- a refund is recorded" --label behaviour > /dev/null

# A dependency the agent worked out during a run, rather than one seeded by a
# fixture. This is the call that was refused throughout the first measured pass.
"$GH" api --method POST "repos/rehearsal/project/issues/2/dependencies/blocked_by" \
  -f issue_id=1 > /dev/null 2>&1 \
  && pass "a dependency can be recorded during a run" \
  || fail "recording a dependency was refused"

blocked=$("$GH" api "repos/rehearsal/project/issues/2/dependencies/blocked_by")
case "$blocked" in
  *'"number": 1'*) pass "the recorded dependency reads back" ;;
  *) fail "the dependency did not read back: $blocked" ;;
esac

summary=$("$GH" api "repos/rehearsal/project/issues?state=open")
case "$summary" in
  *'"blocked_by": 1'*) pass "the listing says which pieces are held up" ;;
  *) fail "the listing does not report the dependency" ;;
esac

echo "== A piece made of parts =="

"$GH" issue create --title "Booking flow" --body "## So that
- guests can book" --label "how it works" > /dev/null
"$GH" issue create --title "Pick a date range" --body "## Done when
- a range is chosen" --label "how it works" > /dev/null

# Issue 3 is the parent, issue 4 a part of it. The kit sends the issue number,
# mirroring the blocked-by call.
"$GH" api --method POST "repos/rehearsal/project/issues/3/sub_issues" \
  -f sub_issue_id=4 > /dev/null 2>&1 \
  && pass "a part can be recorded during a run" \
  || fail "recording a sub-issue was refused"

parts=$("$GH" api "repos/rehearsal/project/issues/3/sub_issues")
case "$parts" in
  *'"number": 4'*) pass "the recorded part reads back" ;;
  *) fail "the sub-issue did not read back: $parts" ;;
esac

made_of=$("$GH" api "repos/rehearsal/project/issues?state=open")
case "$made_of" in
  *'"total": 1, "completed": 0'*) pass "the listing counts a piece's open parts" ;;
  *) fail "the listing does not count the parts" ;;
esac

# Closing the part moves the parent's tally, which is what tells the printout a
# part is done.
"$GH" issue close 4 > /dev/null 2>&1 || fail "closing the part failed"
done_summary=$("$GH" api "repos/rehearsal/project/issues?state=open")
case "$done_summary" in
  *'"total": 1, "completed": 1'*) pass "closing a part moves the parent's tally" ;;
  *) fail "the parent tally did not move: $done_summary" ;;
esac

"$GH" issue comment 1 --body "Built in pull request #1." > /dev/null \
  && pass "issue comment is accepted" \
  || fail "issue comment was refused"

echo "== Pull requests =="

url=$("$GH" pr create --title "Take a deposit" --body "Closes #1")
case "$url" in
  https://github.com/*/pull/1) pass "pr create returns the new address" ;;
  *) fail "pr create returned '$url'" ;;
esac

# Straight after opening one, which is how the kit reports the link.
looked_up=$("$GH" pr view --json url)
case "$looked_up" in
  *'/pull/1'*) pass "pr view finds the pull request for the current branch" ;;
  *) fail "pr view --json url returned '$looked_up'" ;;
esac

by_number=$("$GH" pr view 1 --json number,title,state,statusCheckRollup)
case "$by_number" in
  *'"conclusion": "SUCCESS"'*) pass "pr view reports the check by number" ;;
  *) fail "pr view by number returned '$by_number'" ;;
esac

by_branch=$("$GH" pr view deposits --json url)
case "$by_branch" in
  *'/pull/1'*) pass "pr view accepts a branch name" ;;
  *) fail "pr view by branch returned '$by_branch'" ;;
esac

checks=$("$GH" pr checks 1)
case "$checks" in
  *pass*) pass "pr checks reports the check green" ;;
  *) fail "pr checks returned '$checks'" ;;
esac

# The issue named by "Closes #1" closes when the pull request is opened.
state_of_one=$("$GH" issue view 1)
case "$state_of_one" in
  *'"state": "closed"'*) pass "the piece closes with its pull request" ;;
  *) fail "the piece did not close" ;;
esac

if "$GH" pr view no-such-branch --json url > /dev/null 2>&1; then
  fail "pr view invented a pull request for a branch that has none"
else
  pass "a branch with no pull request says so, as the real CLI does"
fi

echo "== What it still refuses =="

# A project's own agent has no business searching GitHub, so a refusal here is
# information rather than a gap.
for refused in "search repos bramble" "repo list bramble-team"; do
  if "$GH" $refused > /dev/null 2>&1; then
    fail "'$refused' was answered; it should be refused"
  else
    pass "'$refused' is still refused"
  fi
done

if grep -q "UNSUPPORTED.*search repos" "$FAKE_GH_LOG"; then
  pass "a refusal is written to the log"
else
  fail "the refusal log did not record the refused command"
fi

# Nothing the kit reached for during this rehearsal should have been refused.
if grep -q "UNSUPPORTED" "$FAKE_GH_LOG"; then
  unexpected=$(grep "UNSUPPORTED" "$FAKE_GH_LOG" | grep -vc "search repos\|repo list" || true)
  if [ "$unexpected" -gt 0 ]; then
    fail "$unexpected modelled command was refused; see $FAKE_GH_LOG"
  fi
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "fake-github.sh: all checks passed"
else
  echo "fake-github.sh: FAILED" >&2
fi
exit "$FAIL"
