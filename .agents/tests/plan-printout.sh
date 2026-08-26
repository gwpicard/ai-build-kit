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
   "sub_issues_summary": {"total": 2, "completed": 1, "percent_completed": 50}}
]
JSON

mkdir -p "$WORK/bin"
cat >"$WORK/bin/gh" <<'SH'
#!/usr/bin/env sh
case "$1 $2" in
  "repo view") echo '{"nameWithOwner":"someone/project"}' ;;
  *) case "$2" in
       *"/issues?"*) cat "$FIXTURE" ;;
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
