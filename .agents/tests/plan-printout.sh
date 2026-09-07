#!/usr/bin/env sh
# plan-printout.sh: check what plan-refresh.sh writes into plan.local.md.
#
# The printout is the only view of the plan a person gets when GitHub cannot be
# reached, so what it groups and what it says about each piece has to be right.
# Greps over the script cannot judge that. This runs it against a fixed set of
# issues and reads the file it produces.
#
# A stand-in for the GitHub CLI supplies the issues. plan-refresh.sh asks gh for
# JSON and does its own filtering, which is what makes that substitution honest.
#
# Everything here runs in a throwaway directory. No network, no account.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
REFRESH="$ROOT/tools/plan-refresh.sh"

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

# One issue per state the printout has to tell apart. #7 carries both `broken`
# and `building`, because a repair somebody has already started is the case
# where two groups could each claim the same piece.
cat >"$WORK/issues.json" <<'JSON'
[
  {"number": 1, "title": "Card checkout", "html_url": "http://x/1",
   "body": "## Done when\nA card is charged.", "assignees": [],
   "labels": [{"name": "finance"}, {"name": "external service"}]},
  {"number": 2, "title": "Rename the header", "html_url": "http://x/2",
   "body": "## Done when\nIt reads Bookings.", "assignees": [{"login": "ana"}],
   "labels": [{"name": "visual"}, {"name": "building"}]},
  {"number": 3, "title": "Weekly payouts", "html_url": "http://x/3",
   "body": "## Done when\nSellers are paid.", "assignees": [],
   "labels": [{"name": "finance"}, {"name": "blocked"}]},
  {"number": 4, "title": "make the calendar nicer", "html_url": "http://x/4",
   "body": "half a sentence", "assignees": [],
   "labels": [{"name": "needs-clarification"}]},
  {"number": 5, "title": "how should the dashboard look", "html_url": "http://x/5",
   "body": "no idea yet", "assignees": [],
   "labels": [{"name": "needs-prototype"}]},
  {"number": 6, "title": "what does the VAT API return", "html_url": "http://x/6",
   "body": "need to check", "assignees": [],
   "labels": [{"name": "needs-research"}]},
  {"number": 7, "title": "Duplicate bookings", "html_url": "http://x/7",
   "body": "## Done when\nOne booking per click.", "assignees": [{"login": "sam"}],
   "labels": [{"name": "how it works"}, {"name": "broken"}, {"name": "building"}]},
  {"number": 8, "title": "A pull request, not a piece", "html_url": "http://x/8",
   "body": "## Done when\nnever", "assignees": [], "labels": [],
   "pull_request": {"url": "http://x/8"}},
  {"number": 9, "title": "Booking flow", "html_url": "http://x/9",
   "body": "## So that\nGuests can book.", "assignees": [],
   "labels": [{"name": "how it works"}],
   "sub_issues_summary": {"total": 2, "completed": 1, "percent_completed": 50}},
  {"number": 10, "title": "Guest list export", "html_url": "http://x/10",
   "body": "## Done when\nThe list downloads.", "assignees": [],
   "labels": [{"name": "how it works"}, {"name": "ready"}]},
  {"number": 11, "title": "Deposits", "html_url": "http://x/11",
   "body": "## Done when\nA deposit is held.", "assignees": [],
   "labels": [{"name": "finance"}],
   "issue_dependencies_summary": {"blocked_by": 1, "total": 1}},
  {"number": 12, "title": "Refund button", "html_url": "http://x/12",
   "body": "## Done when\nA refund is sent.", "assignees": [],
   "labels": [{"name": "finance"}, {"name": "ready"}],
   "issue_dependencies_summary": {"blocked_by": 1, "total": 1}}
]
JSON

mkdir -p "$WORK/bin"
cat >"$WORK/bin/gh" <<'SH'
#!/usr/bin/env sh
case "$1 $2" in
  "repo view") echo '{"nameWithOwner":"someone/project"}' ;;
  *) case "$2" in
       *"/issues?"*) cat "$FIXTURE" ;;
       # Deposits is held up by an open piece, which is the case the printout
       # has to name. Refund button counts a blocker too, but that blocker has
       # closed, so it is free to build. Both go through the same call, and only
       # the state in the answer tells them apart.
       *"/issues/11/dependencies/blocked_by")
         echo '[{"number":1,"title":"Card checkout","state":"open"}]' ;;
       *"/issues/12/dependencies/blocked_by")
         echo '[{"number":2,"title":"Rename the header","state":"closed"}]' ;;
       *dependencies/blocked_by*) echo '[]' ;;
       *) echo '[]' ;;
     esac ;;
esac
SH
chmod +x "$WORK/bin/gh"

FIXTURE="$WORK/issues.json"
export FIXTURE
PATH="$WORK/bin:$PATH"
export PATH

cd "$WORK"
"$REFRESH" >/dev/null 2>&1 || fail "the printout could not be written"
OUT="$WORK/plan.local.md"
[ -f "$OUT" ] || { echo "FAIL: no printout was written" >&2; exit 1; }

echo "== What the printout groups =="

# A repair is what somebody wants to see first, so it heads the file.
head -5 "$OUT" | grep -q "^Broken$" \
  && pass "a repair is the first group in the file" \
  || fail "Broken is not the first group"

grep -q "^Broken$" "$OUT" && grep -A1 "^Broken$" "$OUT" | grep -q "#7" \
  && pass "the repair is listed under Broken" \
  || fail "#7 is not under Broken"

# #7 carries `building` too. It stays under Broken and says somebody is on it,
# rather than appearing twice or vanishing into Building.
grep -A1 "^Broken$" "$OUT" | grep -q "being fixed" \
  && pass "a repair somebody has started says so" \
  || fail "#7 does not say it is being fixed"

grep -A1 "^Building$" "$OUT" | grep -q "#2" \
  && pass "an ordinary piece under way is under Building" \
  || fail "#2 is not under Building"

grep -A1 "^Blocked$" "$OUT" | grep -q "#3" \
  && pass "a blocked piece is under Blocked" \
  || fail "#3 is not under Blocked"

grep -q "#8" "$OUT" \
  && fail "a pull request was printed as a piece" \
  || pass "pull requests stay out of the list"

echo "== What the printout says about a waiting piece =="

# The label says why a piece is waiting. Printing the label name would push a
# GitHub word at somebody who never opens GitHub, so it is written out.
grep "#4" "$OUT" | grep -q "needs a few questions" \
  && pass "needs-clarification reads as a few questions" \
  || fail "#4 does not say it needs questions"

grep "#5" "$OUT" | grep -q "needs a throwaway build to decide" \
  && pass "needs-prototype reads as a throwaway build" \
  || fail "#5 does not say it needs a prototype"

grep "#6" "$OUT" | grep -q "needs a fact from outside the project" \
  && pass "needs-research reads as a fact from outside" \
  || fail "#6 does not say it needs research"

# The reason replaces the generic marker rather than printing beside it.
grep "#4" "$OUT" | grep -q "still a note" \
  && fail "#4 prints both the reason and the generic note marker" \
  || pass "a stated reason replaces the generic note marker"

# A piece nobody labelled is still a note, because shape decides.
grep "#1" "$OUT" | grep -q "still a note" \
  && fail "#1 is a sized piece but was marked a note" \
  || pass "a sized piece is not marked a note"

echo "== What the printout says about a piece ready to build =="

# Everything under one heading, rather than the first entry a -A1 would reach.
# Two groups now carry more than one piece, and a check that only ever reads the
# first would pass while the second sat in the wrong place.
section() {
  awk -v want="$1" '$0 == want { f = 1; next } /^[^ ]/ { f = 0 } f' "$OUT"
}

# Pieces are named rather than numbered here, the same rule the printout's own
# readers follow. It also keeps this file clear of the issue-number check, which
# cannot tell a fixture apart from a real citation and should not have to.
section "To build" | grep "Guest list export" | grep -q "(ready)" \
  && pass "a shaped piece waiting to be built says it is ready" \
  || fail "Guest list export does not say it is ready"

# Shape is what says a piece has been sized. The label follows it and never
# talks over it, so a piece nobody has labelled is not announced as ready.
section "To build" | grep "Card checkout" | grep -q "(ready)" \
  && fail "Card checkout carries no ready label but was printed as ready" \
  || pass "an unlabelled piece is not printed as ready"

echo "== What the printout says about a blocked piece =="

# The commands that read this file say what is holding a piece up in a sentence
# a person can follow. A number is not that, and it is one they would have to go
# and look up.
section "Blocked" | grep "Deposits" | grep -q "needs Card checkout" \
  && pass "a held-up piece names the piece holding it" \
  || fail "Deposits does not name Card checkout as its blocker"

section "Blocked" | grep "Deposits" | grep -q "needs #" \
  && fail "Deposits names its blocker by number instead of by name" \
  || pass "a blocker is named rather than numbered"

# The invariant the whole plan rests on: a piece with an open blocker is never
# offered as buildable, so nothing in To build can be waiting on anything else
# in To build. Refund button counts a blocker, but it has closed, so it is free.
section "Blocked" | grep -q "Refund button" \
  && fail "Refund button's blocker has closed but it is still held" \
  || pass "a closed blocker does not hold a piece back"

section "To build" | grep "Refund button" | grep -q "(ready)" \
  && pass "a piece whose blocker has closed is ready to build" \
  || fail "Refund button is not offered as ready"

section "To build" | grep -q "Deposits" \
  && fail "a piece with an open blocker was offered as buildable" \
  || pass "a piece with an open blocker stays out of To build"

echo "== A piece made of parts =="

# A parent piece is a container. It gets its own group, shows how many of its
# parts are done, and is never offered as a slice to build directly.
grep -q "^Made of parts$" "$OUT" \
  && pass "a parent piece has its own group" \
  || fail "the Made of parts group is missing"

grep -A1 "^Made of parts$" "$OUT" | grep -q "#9" \
  && pass "the parent is listed under Made of parts" \
  || fail "#9 is not under Made of parts"

grep "#9" "$OUT" | grep -q "1 of 2 parts done" \
  && pass "the parent shows how many parts are done" \
  || fail "#9 does not show its part count"

[ "$(grep -c '#9' "$OUT")" -eq 1 ] \
  && pass "the parent appears once, only as a container, not under To build" \
  || fail "#9 appears somewhere other than its own group"

# A parent carries no Done when of its own, because its parts do. It is not a note.
grep "#9" "$OUT" | grep -q "still a note" \
  && fail "#9 is a parent but was marked a note" \
  || pass "a parent without its own Done when is not marked a note"

if [ "$FAIL" -eq 0 ]; then
  echo
  echo "plan-printout.sh: all checks passed"
else
  echo
  echo "plan-printout.sh: FAILED" >&2
fi
exit "$FAIL"
