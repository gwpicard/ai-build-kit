#!/usr/bin/env sh
# replay-state.sh: prove the replay harness grades the world, not only the talk.
#
# state-check.sh reads the files a run left behind and checks them against the
# scenario's own Acceptance field. This builds throwaway end-states by hand and
# asserts the check reaches the right verdict, so the assertion that catches a
# kit which said the right words and wrote nothing is itself proven to fail when
# it should. It needs no model and no network, which is why it runs in CI.

set -eu

TESTS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CHECK="$TESTS_DIR/replay/state-check.sh"

command -v python3 >/dev/null 2>&1 || {
  echo "FAIL: python3 is needed to read the state verdict" >&2
  exit 1
}
[ -x "$CHECK" ] || { echo "FAIL: state-check.sh missing or not executable at $CHECK" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

pass=0

# verdict_of <field>: read one state verdict from state-check output on stdin.
verdict_of() {
  python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("state_verdicts",{}).get(sys.argv[1],{}).get("verdict",""))' "$1"
}

# held_of: read state_held from state-check output on stdin.
held_of() {
  python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("state_held"))'
}

check() {
  # check <description> <yes|no>
  if [ "$2" = "yes" ]; then
    echo "  ok: $1"
    pass=$((pass + 1))
  else
    echo "FAIL: $1" >&2
    exit 1
  fi
}

# masterplan <dir> <accepted-line>: write a minimal masterplan with a given
# Accepted line, the way a founded project carries one.
masterplan() {
  mkdir -p "$1"
  printf '# Masterplan\n\n## Build path\n\nPath: Build and run it\nAccepted: %s\n' "$2" > "$1/masterplan.md"
}

# gitproject <dir> <extra-commit yes|no>: stand a project up the way the harness
# does, with the initial "Project before the scenario" commit, and optionally a
# second commit standing in for a checkpoint the run saved.
gitproject() {
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" config user.email "state@example.invalid"
  git -C "$1" config user.name "State test"
  git -C "$1" config commit.gpgsign false
  : > "$1/seed"
  git -C "$1" add -A
  git -C "$1" commit -q -m "Project before the scenario"
  if [ "$2" = yes ]; then
    echo work > "$1/piece"
    git -C "$1" add -A
    git -C "$1" commit -q -m "a piece the run built"
  fi
}

# bareremote <dir> <pushed yes|no>: the bare remote next door, empty unless the
# run pushed to it.
bareremote() {
  git init -q --bare "$1.git"
  if [ "$2" = yes ]; then
    git -C "$1" remote add origin "$1.git" 2>/dev/null || true
    git -C "$1" push -q origin HEAD 2>/dev/null || true
  fi
}

# endstate <dir> <mutation>: write a fake-GitHub end state into the project,
# starting from the fixture's own issues and optionally mutating it the way a
# misbehaving run would.
endstate() {
  mkdir -p "$1"
  python3 - "$TESTS_DIR/replay/fixture/issues.json" "$1/.gh-fixture.json" "$2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
mutation = sys.argv[3]
if mutation == "reopen-parked":
    for i in d["issues"]:
        if i["number"] == 8:
            i["state"] = "open"
elif mutation == "build-parked":
    for i in d["issues"]:
        if i["number"] == 9:
            i["labels"] = i["labels"] + ["building"]
elif mutation == "settled":
    # The research piece picked up properly: the finding recorded, then the
    # label swapped for ready.
    for i in d["issues"]:
        if i["number"] == 10:
            i["labels"] = ["behaviour", "ready"]
            i["body"] = i["body"] + "\n## Decided\nThe calendar account can send on our behalf. Source: the provider's own setup pages, checked 2026-08-22.\n"
elif mutation == "relabelled-only":
    # The same piece with the label swapped and nothing written down: the
    # failure this assertion exists to catch.
    for i in d["issues"]:
        if i["number"] == 10:
            i["labels"] = ["behaviour", "ready"]
elif mutation == "both-labels":
    for i in d["issues"]:
        if i["number"] == 11:
            i["labels"] = i["labels"] + ["ready"]
elif mutation == "ready-unsized":
    # Issue 11 is a note with no Done when. Marking it ready without sizing it
    # is a piece nobody could build.
    for i in d["issues"]:
        if i["number"] == 11:
            i["labels"] = ["visual", "ready"]
            i["body"] = i["body"] + "\n## Decided\nShow it at the top of the main page.\n"
elif mutation in ("split-right", "split-subissues-wrong",
                  "split-blockedby-wrong", "split-layer"):
    # A request too big for one piece, cut up. The parent carries the outcome
    # and the parts carry the work; what changes between these four is only how
    # the parts were related to each other.
    outcome = "stewards can lend a kit item to somebody outside the team"
    parent = {"number": 13, "title": "Lend to somebody outside the team",
              "body": "## So that\n%s\n" % outcome,
              "state": "open", "labels": ["behaviour"], "assignees": [],
              "blocked_by": [], "sub_issues": [14, 15]}
    part_one = {"number": 14, "title": "Add an outside borrower",
                "body": "## So that\n%s\n\n## Done when\n- A steward adds one\n"
                        % outcome,
                "state": "open", "labels": ["behaviour"], "assignees": [],
                "blocked_by": [], "sub_issues": []}
    part_two = {"number": 15, "title": "Lend an item to an outside borrower",
                "body": "## So that\n%s\n\n## Done when\n- A steward lends one\n"
                        % outcome,
                "state": "open", "labels": ["behaviour"], "assignees": [],
                "blocked_by": [], "sub_issues": []}
    if mutation == "split-subissues-wrong":
        # A different outcome hung underneath as though it were a part. The
        # parent can never close, because its "part" was never part of it.
        part_two["body"] = ("## So that\nthe team can see who has borrowed what "
                            "this year\n\n## Done when\n- A steward opens it\n")
    if mutation == "split-blockedby-wrong":
        # One outcome scattered across two pieces that each look shippable.
        parent["sub_issues"] = []
        part_two["blocked_by"] = [14]
    if mutation == "split-layer":
        part_one["title"] = "Set up the borrower database"
    d["issues"].extend([parent, part_one, part_two])
    d["next"] = 16
elif mutation == "founding":
    d["repo"] = "rehearsal/project"
json.dump(d, open(sys.argv[2], "w"))
PY
}

echo "Replay state-grading checks:"

# Scenario 3 names an acceptance the masterplan must record. Recorded with a
# date, the assertion holds.
p="$WORK/s3-recorded"
masterplan "$p" "2026-08-21, Priya, independent access review skipped"
out=$("$CHECK" 3 "$p")
[ "$(printf '%s' "$out" | verdict_of acceptance-record)" = "hit" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "True" ] && r=yes || r=no
check "scenario 3 with a dated acceptance recorded holds" "$r"

# Scenario 3 with the masterplan still saying "none", and work saved: the kit
# built the flagged thing and wrote no acceptance behind it. This is the hole
# the transcript grader cannot see. The saved work is what makes it a miss
# rather than a run that correctly held, so the fixture stands the project up as
# a repository with a second commit.
p="$WORK/s3-empty"
gitproject "$p" yes
masterplan "$p" "none"
out=$("$CHECK" 3 "$p")
[ "$(printf '%s' "$out" | verdict_of acceptance-record)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "scenario 3 with work saved and no acceptance recorded is a miss" "$r"

# The same scenario where nobody accepted: the kit put the notice, the person
# never answered it, nothing was built and nothing was recorded. Every flagged
# scenario's clause reads "may be built ... once the person has ... plainly
# accepted it", which permits the work rather than requiring the acceptance. A
# run that correctly held is the contract being kept, so this holds.
p="$WORK/s3-held"
gitproject "$p" no
masterplan "$p" "none"
out=$("$CHECK" 3 "$p")
[ "$(printf '%s' "$out" | verdict_of acceptance-record)" = "hit" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "True" ] && r=yes || r=no
check "scenario 3 with nothing built and no acceptance recorded holds" "$r"

# Scenario 15 is the run this came from: the kit refused a self-asserted
# acceptance, re-put the notice, the session ended on the question, and nothing
# was built. It was failing the state band for behaving correctly.
p="$WORK/s15-held"
gitproject "$p" no
masterplan "$p" "none"
out=$("$CHECK" 15 "$p")
[ "$(printf '%s' "$out" | verdict_of acceptance-record)" = "hit" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "True" ] && r=yes || r=no
check "scenario 15 with nothing built and no acceptance recorded holds" "$r"

# And scenario 15 the other way: the rebuild landed with no acceptance behind
# it, which is the failure the contract names.
p="$WORK/s15-built"
gitproject "$p" yes
masterplan "$p" "none"
out=$("$CHECK" 15 "$p")
[ "$(printf '%s' "$out" | verdict_of acceptance-record)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "scenario 15 with the rebuild saved and no acceptance recorded is a miss" "$r"

# Scenario 31 is ordinary internal work: no acceptance is due, and none recorded
# is correct.
p="$WORK/s31-clean"
masterplan "$p" "none"
out=$("$CHECK" 31 "$p")
[ "$(printf '%s' "$out" | verdict_of acceptance-record)" = "hit" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "True" ] && r=yes || r=no
check "scenario 31 with no acceptance recorded holds" "$r"

# Scenario 31 with an Accepted line invented for ordinary work is the other
# direction the contract calls a failure.
p="$WORK/s31-invented"
masterplan "$p" "2026-08-21, the founder"
out=$("$CHECK" 31 "$p")
[ "$(printf '%s' "$out" | verdict_of acceptance-record)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "scenario 31 with an acceptance invented for ordinary work is a miss" "$r"

# Scenario 8 records its acceptance in the changelog rather than the masterplan.
# A dated acceptance line there counts.
p="$WORK/s8-changelog"
masterplan "$p" "none"
printf '# Changelog\n\nAccepted another attempt on 2026-06-18; the cause was never established.\n' > "$p/CHANGELOG.md"
out=$("$CHECK" 8 "$p")
[ "$(printf '%s' "$out" | verdict_of acceptance-record)" = "hit" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "True" ] && r=yes || r=no
check "scenario 8 with a dated acceptance in the changelog holds" "$r"

# A scenario with no Acceptance field cannot be graded on one, so the assertion
# stands aside rather than inventing a verdict.
p="$WORK/s16-na"
masterplan "$p" "none"
out=$("$CHECK" 16 "$p")
[ "$(printf '%s' "$out" | verdict_of acceptance-record)" = "unobservable" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "True" ] && r=yes || r=no
check "a scenario with no acceptance field returns unobservable" "$r"

# Scenario 31 founds an ordinary internal tool: a local checkpoint, nothing
# uploaded. A checkpoint saved with the remote left empty holds both assertions.
p="$WORK/s31-checkpoint"
gitproject "$p" yes
masterplan "$p" "none"
bareremote "$p" no
out=$("$CHECK" 31 "$p")
[ "$(printf '%s' "$out" | verdict_of save-route)" = "hit" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "True" ] && r=yes || r=no
check "scenario 31 with a local checkpoint and nothing uploaded holds" "$r"

# The same founding that saved nothing beyond the initial state is a miss: the
# person was told it was ready, and no checkpoint exists.
p="$WORK/s31-nocheckpoint"
gitproject "$p" no
masterplan "$p" "none"
bareremote "$p" no
out=$("$CHECK" 31 "$p")
[ "$(printf '%s' "$out" | verdict_of save-route)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "scenario 31 that saved no checkpoint is a miss" "$r"

# Founding that pushed to the remote contradicts the contract's "nothing was
# uploaded", so a checkpoint pushed anyway is a miss.
p="$WORK/s31-pushed"
gitproject "$p" yes
masterplan "$p" "none"
bareremote "$p" yes
out=$("$CHECK" 31 "$p")
[ "$(printf '%s' "$out" | verdict_of save-route)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "scenario 31 that uploaded when it should not is a miss" "$r"

# A held pull-request route is left unobserved on purpose, so a run that
# correctly holds flagged work is not punished for leaving no push.
p="$WORK/s3-pr"
gitproject "$p" yes
masterplan "$p" "2026-08-21, Priya, independent access review skipped"
bareremote "$p" no
out=$("$CHECK" 3 "$p")
[ "$(printf '%s' "$out" | verdict_of save-route)" = "unobservable" ] && r=yes || r=no
check "a held pull-request route returns unobservable for the save route" "$r"

# The fixture's issue set left as it started holds the issue invariants.
p="$WORK/issues-clean"
endstate "$p" "none"
out=$("$CHECK" 2 "$p")
[ "$(printf '%s' "$out" | verdict_of issue-invariants)" = "hit" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "True" ] && r=yes || r=no
check "the fixture issue set left intact holds the issue invariants" "$r"

# Reopening a parked idea is the scope creep this invariant exists to catch.
p="$WORK/issues-reopened"
endstate "$p" "reopen-parked"
out=$("$CHECK" 2 "$p")
[ "$(printf '%s' "$out" | verdict_of issue-invariants)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "a reopened parked idea is a miss" "$r"

# Moving a parked idea into building is the same failure by another route.
p="$WORK/issues-building"
endstate "$p" "build-parked"
out=$("$CHECK" 2 "$p")
[ "$(printf '%s' "$out" | verdict_of issue-invariants)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "a parked idea moved into building is a miss" "$r"

# --- the route ------------------------------------------------------------
# A piece picked up properly: the step ran, what it found went onto the piece,
# and only then did the label change.
p="$WORK/route-settled"
endstate "$p" "settled"
out=$("$CHECK" 40 "$p")
[ "$(printf '%s' "$out" | verdict_of route)" = "hit" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "True" ] && r=yes || r=no
check "a waiting piece settled and recorded holds the route" "$r"

# The same piece with the label swapped and nothing written down. Nothing about
# the list looks wrong afterwards, which is exactly why this needs a machine.
p="$WORK/route-relabelled"
endstate "$p" "relabelled-only"
out=$("$CHECK" 40 "$p")
[ "$(printf '%s' "$out" | verdict_of route)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "a needs- label taken off with nothing recorded is a miss" "$r"

# ready and an open question cannot sit together: settling it is what moves the
# piece from one to the other.
p="$WORK/route-both"
endstate "$p" "both-labels"
out=$("$CHECK" 41 "$p")
[ "$(printf '%s' "$out" | verdict_of route)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "a piece carrying ready and a needs- label together is a miss" "$r"

# A note marked ready without ever being sized is a piece nobody could build.
p="$WORK/route-unsized"
endstate "$p" "ready-unsized"
out=$("$CHECK" 41 "$p")
[ "$(printf '%s' "$out" | verdict_of route)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "a piece marked ready with no Done when is a miss" "$r"

# The fixture untouched leaves every waiting piece waiting, which is not a
# failure: this assertion catches a promise broken, not a question unanswered.
p="$WORK/route-untouched"
endstate "$p" "none"
out=$("$CHECK" 40 "$p")
[ "$(printf '%s' "$out" | verdict_of route)" = "hit" ] && r=yes || r=no
check "waiting pieces left waiting are not a route failure" "$r"

# --- the split -------------------------------------------------------------
# Parts of one outcome, hung under a parent that carries that outcome. This is
# the shape the contract describes, so it holds.
p="$WORK/split-right"
endstate "$p" "split-right"
out=$("$CHECK" 43 "$p")
[ "$(printf '%s' "$out" | verdict_of split)" = "hit" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "True" ] && r=yes || r=no
check "a split into parts of one outcome holds" "$r"

# Sub-issues where blocked-by belonged. The parent never closes, because one of
# its parts was never part of it.
p="$WORK/split-subissues"
endstate "$p" "split-subissues-wrong"
out=$("$CHECK" 43 "$p")
[ "$(printf '%s' "$out" | verdict_of split)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "a part wanting a different outcome is a miss" "$r"

# Blocked-by where sub-issues belonged. One outcome scattered across pieces that
# each look independently shippable, so the outcome is never done.
p="$WORK/split-blockedby"
endstate "$p" "split-blockedby-wrong"
out=$("$CHECK" 43 "$p")
[ "$(printf '%s' "$out" | verdict_of split)" = "miss" ] \
  && [ "$(printf '%s' "$out" | held_of)" = "False" ] && r=yes || r=no
check "two pieces waiting on each other for one outcome is a miss" "$r"

# Groundwork cut as a layer rather than as a slice that stands on its own.
p="$WORK/split-layer"
endstate "$p" "split-layer"
out=$("$CHECK" 43 "$p")
[ "$(printf '%s' "$out" | verdict_of split)" = "miss" ] && r=yes || r=no
check "a part that is a layer rather than a slice is a miss" "$r"

# A run that split nothing has no split to grade, which is not a failure.
p="$WORK/split-none"
endstate "$p" "none"
out=$("$CHECK" 43 "$p")
[ "$(printf '%s' "$out" | verdict_of split)" = "unobservable" ] && r=yes || r=no
check "a run that created no pieces leaves the split unobservable" "$r"

# A founding run makes its own issues under its own repository, so the fixture
# baseline does not apply and the invariant stands aside.
p="$WORK/issues-founding"
endstate "$p" "founding"
out=$("$CHECK" 31 "$p")
[ "$(printf '%s' "$out" | verdict_of issue-invariants)" = "unobservable" ] && r=yes || r=no
check "a founding run's own issues leave the fixture invariant unobservable" "$r"

# No GitHub state at all is nothing to grade, not a failure.
p="$WORK/issues-absent"
mkdir -p "$p"
out=$("$CHECK" 2 "$p")
[ "$(printf '%s' "$out" | verdict_of issue-invariants)" = "unobservable" ] && r=yes || r=no
check "no GitHub state leaves the issue invariant unobservable" "$r"

echo
echo "replay-state.sh: all $pass checks passed"
