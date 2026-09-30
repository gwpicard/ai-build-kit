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
REFRESH="$ROOT/skills/setup-ai-build-kit/templates/foundation/plan-refresh.sh"

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

# One issue per case the printout has to tell apart. The states come first,
# then the mistakes it has to name, then what it must leave out.
#
# Duplicate bookings carries both `broken` and `building`, because a repair
# somebody has already started is the case where two groups could each claim
# the same piece. Weekly payouts carries `blocked`, the label an older project
# still has before anything moves it, which has to read as parked. Card checkout
# carries no state at all, which counts as an idea. Email reminders and Old
# export are closed, and the endpoint asks only for open issues, so a stand-in
# that returns them anyway proves the printout checks for itself.
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
   "labels": [{"name": "shaping"}, {"name": "needs-clarification"}]},
  {"number": 5, "title": "how should the dashboard look", "html_url": "http://x/5",
   "body": "no idea yet", "assignees": [],
   "labels": [{"name": "shaping"}, {"name": "needs-prototype"}]},
  {"number": 6, "title": "what does the VAT API return", "html_url": "http://x/6",
   "body": "need to check", "assignees": [],
   "labels": [{"name": "shaping"}, {"name": "needs-research"}]},
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
   "labels": [{"name": "finance"}, {"name": "ready"}],
   "issue_dependencies_summary": {"blocked_by": 1, "total": 1}},
  {"number": 12, "title": "Refund button", "html_url": "http://x/12",
   "body": "## Done when\nA refund is sent.", "assignees": [],
   "labels": [{"name": "finance"}, {"name": "ready"}],
   "issue_dependencies_summary": {"blocked_by": 1, "total": 1}},
  {"number": 13, "title": "Invoice download", "html_url": "http://x/13",
   "body": "## Done when\nAn invoice downloads.", "assignees": [],
   "labels": [{"name": "finance"}, {"name": "to check"}],
   "issue_dependencies_summary": {"blocked_by": 1, "total": 1}},
  {"number": 14, "title": "Loyalty points", "html_url": "http://x/14",
   "body": "## Done when\nPoints add up.\n\nParked after three failed attempts.",
   "assignees": [], "labels": [{"name": "finance"}, {"name": "parked"}]},
  {"number": 15, "title": "Gift cards", "html_url": "http://x/15",
   "body": "## Done when\nA card is redeemed.", "assignees": [],
   "labels": [{"name": "finance"}, {"name": "ready"}, {"name": "building"}]},
  {"number": 16, "title": "Stock alerts", "html_url": "http://x/16",
   "body": "check the supplier feed", "assignees": [],
   "labels": [{"name": "needs-research"}]},
  {"number": 17, "title": "tidy the footer", "html_url": "http://x/17",
   "body": "it looks off", "assignees": [],
   "labels": [{"name": "visual"}, {"name": "ready"}]},
  {"number": 18, "title": "Email reminders", "html_url": "http://x/18",
   "body": "Left out: nobody reads email here.", "assignees": [], "state": "closed",
   "labels": [{"name": "parked"}]},
  {"number": 19, "title": "Old export", "html_url": "http://x/19",
   "body": "## Done when\nIt exported.", "assignees": [], "state": "closed",
   "labels": [{"name": "ready"}]},
  {"number": 20, "title": "dark mode maybe", "html_url": "http://x/20",
   "body": "jotted on a phone", "assignees": [], "labels": []},
  {"number": 21, "title": "Share a booking link", "html_url": "http://x/21",
   "body": "a link a guest can send on", "assignees": [], "state": "open",
   "labels": [{"name": "idea"}]}
]
JSON

mkdir -p "$WORK/bin"
cat >"$WORK/bin/gh" <<'SH'
#!/usr/bin/env sh
# GH_DOWN stands in for a machine that cannot reach GitHub: every call fails.
[ -z "${GH_DOWN:-}" ] || exit 1
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
       *"/issues/13/dependencies/blocked_by")
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

# Everything under one heading, rather than the first entry a -A1 would reach.
# Several groups carry more than one piece, and a check that only ever reads the
# first would pass while the second sat in the wrong place.
section() {
  awk -v want="$1" '$0 == want { f = 1; next } /^[^ ]/ { f = 0 } f' "${2:-$OUT}"
}

# Pieces are named rather than numbered here, the same rule the printout's own
# readers follow. It also keeps this file clear of the issue-number check, which
# cannot tell a fixture apart from a real citation and should not have to.
under() {
  section "$1" | grep -q "$2"
}

echo "== The printout reads as a board =="

# The headings in the order they print. Needs attention and Broken come first
# because somebody opening the file wants to know what is wrong before what is
# next. Then the states, in the order a piece moves through them, with ready
# split into the pieces free to start and the ones held up by another. The
# groups of free pieces that can be built together follow the pieces they
# group. Parents last, because a parent has no state of its own.
headings=$(awk 'NR > 3 && /^[^ ]/ && !/^Plan / && !/^Last refreshed/ && !/entr(y|ies) (is|are) still/' "$OUT" | tr '\n' '|')
expected="Needs attention|Broken|Idea|Shaping|To build|Go together|Held up|Building|To check|Parked|Made of parts|"
[ "$headings" = "$expected" ] \
  && pass "the groups print in board order" \
  || fail "the groups print as '$headings', expected '$expected'"

under "Broken" "Duplicate bookings" \
  && pass "the repair is listed under Broken" \
  || fail "Duplicate bookings is not under Broken"

# It carries `building` too. It stays under Broken and says somebody is on it,
# rather than appearing twice or vanishing into Building.
section "Broken" | grep "Duplicate bookings" | grep -q "being fixed" \
  && pass "a repair somebody has started says so" \
  || fail "Duplicate bookings does not say it is being fixed"
[ "$(grep -c "Duplicate bookings" "$OUT")" -eq 1 ] \
  && pass "a repair prints once" \
  || fail "Duplicate bookings prints more than once"

under "Idea" "Card checkout" \
  && pass "an open piece with no state label counts as an idea" \
  || fail "Card checkout carries no state but is not under Idea"
under "Idea" "dark mode maybe" && under "Idea" "Share a booking link" \
  && pass "an unlabelled note and a piece labelled idea are both ideas" \
  || fail "an idea is missing from Idea"

under "Shaping" "make the calendar nicer" && under "Shaping" "how should the dashboard look" \
  && under "Shaping" "what does the VAT API return" \
  && pass "a piece being shaped is under Shaping, beside its reason" \
  || fail "a shaping piece is not under Shaping"

under "Building" "Rename the header" \
  && pass "an ordinary piece under way is under Building" \
  || fail "Rename the header is not under Building"

under "To check" "Invoice download" \
  && pass "a piece whose pull request waits for the person is under To check" \
  || fail "Invoice download is not under To check"

section "To check" | grep "Invoice download" | grep -q "needs Card checkout" \
  && pass "a piece to check that another piece holds up names it" \
  || fail "Invoice download does not name Card checkout as its blocker"

under "Parked" "Loyalty points" \
  && pass "an open parked piece is under Parked" \
  || fail "Loyalty points is not under Parked"

# An older project still carries `blocked` until something moves it. Before
# that it still groups, and the retired label reads as the state that replaced
# it.
under "Parked" "Weekly payouts" \
  && pass "an older project's blocked label prints as parked" \
  || fail "Weekly payouts carries blocked but is not under Parked"

grep -q "A pull request, not a piece" "$OUT" \
  && fail "a pull request was printed as a piece" \
  || pass "pull requests stay out of the list"

echo "== What the printout leaves out =="

# A closed issue is done. The idea deliberately left out keeps `parked` on a
# closed issue, and a closed issue left carrying another state is ignored too.
grep -q "Email reminders" "$OUT" \
  && fail "a closed parked idea was printed" \
  || pass "a closed parked idea is left alone and never printed"
grep -q "Old export" "$OUT" \
  && fail "a closed issue still labelled ready was printed" \
  || pass "a closed issue carrying another state is ignored"

echo "== What needs attention =="

# Two states at once is a mistake to name, never a piece in both columns.
section "Needs attention" | grep "Gift cards" | grep "ready" | grep -q "building" \
  && pass "a piece with two states is named under Needs attention with both labels" \
  || fail "Gift cards does not name its two states under Needs attention"
[ "$(grep -c "Gift cards" "$OUT")" -eq 1 ] \
  && pass "a piece with two states prints once" \
  || fail "Gift cards prints more than once"

section "Needs attention" | grep "Stock alerts" | grep "needs-research" | grep -q "shaping" \
  && pass "a needs- label without shaping is named under Needs attention" \
  || fail "Stock alerts does not name its needs- label without shaping"
[ "$(grep -c "Stock alerts" "$OUT")" -eq 1 ] \
  && pass "a needs- label without shaping prints once" \
  || fail "Stock alerts prints more than once"

# Shape decides. A piece labelled ready with no Done when is still an idea, and
# the label is named as the thing to look at.
under "Idea" "tidy the footer" \
  && pass "a ready piece with no Done when prints under Idea" \
  || fail "tidy the footer is not under Idea"
section "Needs attention" | grep "tidy the footer" | grep -q "Done when" \
  && pass "and it is named under Needs attention" \
  || fail "tidy the footer is not named under Needs attention"
under "To build" "tidy the footer" \
  && fail "a ready piece with no Done when was offered as buildable" \
  || pass "a ready piece with no Done when is not offered as buildable"

for piece in "Card checkout" "Rename the header" "Loyalty points" "Invoice download"; do
  if under "Needs attention" "$piece"; then
    fail "$piece has one state but was named under Needs attention"
  fi
done
pass "a piece with one state is not named under Needs attention"

echo "== What the printout says about a waiting piece =="

# The label says why a piece is waiting. Printing the label name would push a
# GitHub word at somebody who never opens GitHub, so it is written out.
section "Shaping" | grep "make the calendar nicer" | grep -q "needs a few questions" \
  && pass "needs-clarification reads as a few questions" \
  || fail "make the calendar nicer does not say it needs questions"

section "Shaping" | grep "how should the dashboard look" | grep -q "needs a throwaway build to decide" \
  && pass "needs-prototype reads as a throwaway build" \
  || fail "the dashboard does not say it needs a prototype"

section "Shaping" | grep "what does the VAT API return" | grep -q "needs a fact from outside the project" \
  && pass "needs-research reads as a fact from outside" \
  || fail "the VAT question does not say it needs research"

# The reason replaces the generic marker rather than printing beside it.
grep "make the calendar nicer" "$OUT" | grep -q "still a note" \
  && fail "a shaping piece prints both the reason and the generic note marker" \
  || pass "a stated reason replaces the generic note marker"

# A piece written down with no Done when is still a note, because shape decides.
section "Idea" | grep "dark mode maybe" | grep -q "still a note" \
  && pass "an unsized idea says it is still a note" \
  || fail "dark mode maybe does not say it is still a note"
grep "Card checkout" "$OUT" | grep -q "still a note" \
  && fail "Card checkout is a sized piece but was marked a note" \
  || pass "a sized piece is not marked a note"

echo "== What the printout says about a piece ready to build =="

section "To build" | grep "Guest list export" | grep -q "(ready)" \
  && pass "a shaped piece waiting to be built says it is ready" \
  || fail "Guest list export does not say it is ready"

under "To build" "Card checkout" \
  && fail "Card checkout carries no ready label but was offered as buildable" \
  || pass "an unlabelled piece is not offered as buildable"

echo "== What the printout says about a held-up piece =="

# The commands that read this file say what is holding a piece up in a sentence
# a person can follow. A number is not that, and it is one they would have to go
# and look up.
section "Held up" | grep "Deposits" | grep -q "needs Card checkout" \
  && pass "a held-up piece names the piece holding it" \
  || fail "Deposits does not name Card checkout as its blocker"

section "Held up" | grep "Deposits" | grep -q "needs #" \
  && fail "Deposits names its blocker by number instead of by name" \
  || pass "a blocker is named rather than numbered"

# The invariant the whole plan rests on: a piece with an open blocker is never
# offered as buildable, so nothing in To build can be waiting on anything else
# in To build. Refund button counts a blocker, but it has closed, so it is free.
under "Held up" "Refund button" \
  && fail "Refund button's blocker has closed but it is still held" \
  || pass "a closed blocker does not hold a piece back"

section "To build" | grep "Refund button" | grep -q "(ready)" \
  && pass "a piece whose blocker has closed is ready to build" \
  || fail "Refund button is not offered as ready"

under "To build" "Deposits" \
  && fail "a piece with an open blocker was offered as buildable" \
  || pass "a piece with an open blocker stays out of To build"

echo "== A piece made of parts =="

# A parent piece is a container. It gets its own group, shows how many of its
# parts are done, and is never offered as a slice to build directly.
section "Made of parts" | grep "Booking flow" | grep -q "1 of 2 parts done" \
  && pass "the parent is under Made of parts and shows how many parts are done" \
  || fail "Booking flow is not under Made of parts with its part count"

[ "$(grep -c 'Booking flow' "$OUT")" -eq 1 ] \
  && pass "the parent appears once, only as a container" \
  || fail "Booking flow appears somewhere other than its own group"

# A parent carries no Done when of its own, because its parts do. It is not a note.
grep "Booking flow" "$OUT" | grep -q "still a note" \
  && fail "Booking flow is a parent but was marked a note" \
  || pass "a parent without its own Done when is not marked a note"

echo "== An older project, before anything moves its labels =="

# Only the labels an older project had: ready, building, blocked and a needs-
# label with no shaping beside it. It still groups, with blocked read as parked.
cat >"$WORK/older.json" <<'JSON'
[
  {"number": 1, "title": "Card checkout", "html_url": "http://x/1",
   "body": "## Done when\nA card is charged.", "assignees": [],
   "labels": [{"name": "ready"}]},
  {"number": 2, "title": "Rename the header", "html_url": "http://x/2",
   "body": "## Done when\nIt reads Bookings.", "assignees": [],
   "labels": [{"name": "building"}]},
  {"number": 3, "title": "Weekly payouts", "html_url": "http://x/3",
   "body": "## Done when\nSellers are paid.", "assignees": [],
   "labels": [{"name": "blocked"}]},
  {"number": 4, "title": "make the calendar nicer", "html_url": "http://x/4",
   "body": "half a sentence", "assignees": [],
   "labels": [{"name": "needs-clarification"}]},
  {"number": 5, "title": "Deposits", "html_url": "http://x/5",
   "body": "## Done when\nA deposit is held.", "assignees": [],
   "labels": [{"name": "ready"}, {"name": "blocked"}]}
]
JSON
mkdir -p "$WORK/older"
(cd "$WORK/older" && FIXTURE="$WORK/older.json" "$REFRESH" >/dev/null 2>&1) \
  || fail "the printout could not be written for an older project"
OLDER="$WORK/older/plan.local.md"
if [ -f "$OLDER" ]; then
  section "To build" "$OLDER" | grep "Card checkout" | grep -q "(ready)" \
    && section "Building" "$OLDER" | grep -q "Rename the header" \
    && section "Parked" "$OLDER" | grep -q "Weekly payouts" \
    && section "Needs attention" "$OLDER" | grep "make the calendar nicer" | grep -q "shaping" \
    && pass "an older project groups by its old labels, with blocked shown as parked" \
    || fail "an older project's labels are grouped wrongly"
else
  fail "no printout was written for an older project"
fi
# The old labels let `blocked` sit beside `ready`. That is how an older project
# looks rather than two states at once, so it reads as parked and nothing more.
if [ -f "$OLDER" ]; then
  section "Parked" "$OLDER" | grep -q "Deposits" \
    && ! section "Needs attention" "$OLDER" | grep -q "Deposits" \
    && pass "an older project's blocked beside ready prints as parked, not as a mistake" \
    || fail "an older project's blocked beside ready is not read as parked"
fi

echo "== Which ready pieces go together =="

# /queue prints the groups and never works them out, so the printout is where a
# clash has to be caught. Each ready piece names the areas it changes on a
# Touches line. Two pieces that name the same area, in any mix of capitals,
# never share a group, since building them in one run could change the same
# thing twice. A piece whose Touches line is missing goes alone, because
# nothing says what it changes. A piece opened with the GitHub form carries the
# line under a Touches heading of its own, and it counts the same.
#
# Guest list export and Export to spreadsheet both name exports. Booking
# reminders names the guest list under a form heading. Seat map has no Touches
# line and Gift wrap left the form's field empty. Refund receipts clashes with
# every group before Seat map's, so it is the piece that would join Seat map if
# a piece going alone could be joined. Deposits is ready but held up
# by an open piece, so it is in no group to build now. Guest list export and
# Refund button share nothing, so they must end up together, or a printout that
# put every piece alone would pass the rest of this.
cat >"$WORK/groups.json" <<'JSON'
[
  {"number": 1, "title": "Guest list export", "html_url": "http://x/1",
   "body": "## Done when\nThe list downloads.\n\nTouches: guest list, exports\n",
   "assignees": [], "labels": [{"name": "ready"}]},
  {"number": 2, "title": "Refund button", "html_url": "http://x/2",
   "body": "## Done when\nA refund is sent.\n\nTouches: Refunds\n",
   "assignees": [], "labels": [{"name": "ready"}]},
  {"number": 3, "title": "Export to spreadsheet", "html_url": "http://x/3",
   "body": "## Done when\nA sheet downloads.\n\nTouches: Exports, settings\n",
   "assignees": [], "labels": [{"name": "ready"}]},
  {"number": 4, "title": "Seat map", "html_url": "http://x/4",
   "body": "## Done when\nSeats show.", "assignees": [],
   "labels": [{"name": "ready"}]},
  {"number": 5, "title": "Booking reminders", "html_url": "http://x/5",
   "body": "### Done when\n\nA reminder goes out.\n\n### Touches\n\nGuest List\n",
   "assignees": [], "labels": [{"name": "ready"}]},
  {"number": 6, "title": "Deposits", "html_url": "http://x/6",
   "body": "## Done when\nA deposit is held.\n\nTouches: payments\n",
   "assignees": [], "labels": [{"name": "ready"}],
   "issue_dependencies_summary": {"blocked_by": 1, "total": 1}},
  {"number": 7, "title": "Card checkout", "html_url": "http://x/7",
   "body": "## Done when\nA card is charged.\n\nTouches: payments\n",
   "assignees": [], "labels": [{"name": "idea"}]},
  {"number": 8, "title": "Gift wrap", "html_url": "http://x/8",
   "body": "## Done when\nA gift is wrapped.\n\n### Touches\n\n_No response_\n",
   "assignees": [], "labels": [{"name": "ready"}]},
  {"number": 9, "title": "Refund receipts", "html_url": "http://x/9",
   "body": "## Done when\nA receipt is sent.\n\nTouches: refunds, settings\n",
   "assignees": [], "labels": [{"name": "ready"}]}
]
JSON
cat >"$WORK/bin-groups-gh" <<'SH'
#!/usr/bin/env sh
case "$1 $2" in
  "repo view") echo '{"nameWithOwner":"someone/project"}' ;;
  *) case "$2" in
       *"/issues?"*) cat "$FIXTURE" ;;
       *"/issues/6/dependencies/blocked_by")
         echo '[{"number":7,"title":"Card checkout","state":"open"}]' ;;
       *) echo '[]' ;;
     esac ;;
esac
SH
mkdir -p "$WORK/groups/bin"
mv "$WORK/bin-groups-gh" "$WORK/groups/bin/gh"
chmod +x "$WORK/groups/bin/gh"
(cd "$WORK/groups" && PATH="$WORK/groups/bin:$PATH" FIXTURE="$WORK/groups.json" \
  "$REFRESH" >/dev/null 2>&1) \
  || fail "the printout could not be written for the groups fixture"
TOGETHER="$WORK/groups/plan.local.md"

# Each piece line under Go together, prefixed with the group it sits in.
grouped() {
  section "Go together" "$TOGETHER" \
    | awk '/^  Group [0-9]/ { g = $2; next } /^    / { print g "\t" $0 }'
}
group_of() {
  grouped | grep "$1" | cut -f1
}

if [ -f "$TOGETHER" ]; then
  [ -n "$(section "Go together" "$TOGETHER")" ] \
    && pass "the printout prints the groups of ready pieces" \
    || fail "the printout has no Go together groups"

  missing=""
  for piece in "Guest list export" "Refund button" "Export to spreadsheet" \
      "Seat map" "Booking reminders" "Gift wrap" "Refund receipts"; do
    [ "$(grouped | grep -c "$piece")" -eq 1 ] || missing="$missing, $piece"
  done
  [ -z "$missing" ] \
    && pass "every piece free to build sits in exactly one group" \
    || fail "not in exactly one group: ${missing#, }"

  a=$(group_of "Guest list export"); b=$(group_of "Export to spreadsheet")
  [ -n "$a" ] && [ -n "$b" ] && [ "$a" != "$b" ] \
    && pass "two pieces naming the same area, in different capitals, never share a group" \
    || fail "Guest list export and Export to spreadsheet both touch exports but are not in separate groups"

  a=$(group_of "Guest list export"); b=$(group_of "Booking reminders")
  [ -n "$a" ] && [ -n "$b" ] && [ "$a" != "$b" ] \
    && grouped | grep "Booking reminders" | grep -q "touches guest list" \
    && pass "a Touches line under a form heading is read and compared the same way" \
    || fail "Booking reminders' Touches under the form heading was not read, or it shares a group with Guest list export"

  a=$(group_of "Guest list export"); b=$(group_of "Refund button")
  [ -n "$a" ] && [ "$a" = "$b" ] \
    && pass "two pieces that share no area go together" \
    || fail "Guest list export and Refund button share nothing but are not grouped together"

  alone=yes
  for piece in "Seat map" "Gift wrap"; do
    g=$(group_of "$piece")
    [ -n "$g" ] && [ "$(grouped | awk -F '\t' -v g="$g" '$1 == g' | wc -l | tr -d ' ')" -eq 1 ] \
      || { alone=no; fail "$piece has no Touches line but does not go alone"; }
    grouped | grep "$piece" | grep -q "Touches unknown" \
      || { alone=no; fail "$piece does not say its Touches is unknown"; }
  done
  [ "$alone" = no ] \
    || pass "a piece with no Touches line goes alone and says its Touches is unknown"

  # The blocker invariant reaches the groups: a piece with an open blocker is
  # never in a group to build now.
  section "Go together" "$TOGETHER" | grep -q "Deposits" \
    && fail "a piece with an open blocker was put in a group to build now" \
    || pass "a piece with an open blocker is in no group"
  section "Held up" "$TOGETHER" | grep "Deposits" | grep -q "needs Card checkout" \
    && pass "and it still names the piece holding it up" \
    || fail "Deposits does not name Card checkout under Held up"
else
  fail "no printout was written for the groups fixture"
fi

echo "== When GitHub cannot be reached =="

# The printout is the only view of the plan left when GitHub is out of reach, so
# a refresh that fails keeps the last one and says when it was written.
stamp=$(sed -n 's/^Last refreshed: //p' "$OUT")
before=$(cksum < "$OUT")
said=$(GH_DOWN=1 "$REFRESH" 2>&1) && fail "a refresh with GitHub out of reach reported success"
[ "$(cksum < "$OUT")" = "$before" ] \
  && pass "the last printout is left as it was" \
  || fail "a failed refresh changed the printout"
case "$said" in
  *"could not reach GitHub"*"$stamp"*) pass "it says GitHub was out of reach and when the printout was written" ;;
  *) fail "a failed refresh does not say when the printout was written: $said" ;;
esac

mkdir -p "$WORK/fresh"
said=$(cd "$WORK/fresh" && GH_DOWN=1 "$REFRESH" 2>&1) && fail "a refresh with no GitHub and no printout reported success"
case "$said" in
  *"no earlier printout"*) pass "with no earlier printout, it says there is none" ;;
  *) fail "a failed first refresh does not say there is no printout: $said" ;;
esac

if [ "$FAIL" -eq 0 ]; then
  echo
  echo "plan-printout.sh: all checks passed"
else
  echo
  echo "plan-printout.sh: FAILED" >&2
fi
exit "$FAIL"
