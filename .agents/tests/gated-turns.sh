#!/usr/bin/env sh
# gated-turns.sh: check that a scripted turn waits for the thing it answers.
#
# Every replay line used to fire by its position in the case file. The kit asks
# one question at a time, so an interview a question longer or shorter than the
# script expected put a scripted answer against a question nobody asked. The
# grader refuses to credit the kit for words the person typed, so this never
# produced a false pass. It produced noise, and a rate cannot tell noise from a
# regression, stage 3 of the evaluation epic.
#
# The gate is deliberately allowed to be wrong in one direction only. A
# precondition written too narrowly spends fillers and then fires anyway, which
# is what the harness did before, so it costs tokens and leaves a note in the
# transcript. It can never hold a scripted turn back for good and fail a run
# that would otherwise have passed. That asymmetry is what these checks pin
# down, and the last two are the ones that matter: no false failure, and the
# four cases written before this keep working untouched.
#
# This drives the rule with replies written by hand, so it costs no model call
# and runs on every push.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/replay/turn-gate.sh"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

failures=0
ok() { echo "  ok: $1"; }
bad() { echo "  FAIL: $1"; failures=$((failures + 1)); }

echo "Gated-turn checks:"

reply="$WORK/reply.txt"

# --- the decision itself ---------------------------------------------------

expect() {
  # expect <description> <expected> <pattern> <reply-text> <fillers-used>
  printf '%s' "$4" > "$reply"
  got=$(gate_decision "$3" "$reply" "$5" "$FILLER_CAP")
  if [ "$got" = "$2" ]; then ok "$1"; else bad "$1 (wanted $2, got $got)"; fi
}

expect "a turn with no precondition fires by position, as every old case does" \
  send "" "anything at all" 0
expect "a turn waits while the kit has not said the thing it answers" \
  wait "nobody who understands" "Which of the three should I look at first?" 0
expect "and fires once the kit says it" \
  send "nobody who understands" \
  "If I rebuild this here, nobody who understands the original failure will have looked at it." 0
expect "the match ignores capitals, because a reply starts sentences" \
  send "nobody who understands" \
  "Nobody who understands the original failure has looked at this." 0
expect "a precondition on the opening line is meaningless, so the line is sent" \
  send "nobody who understands" "" 0
expect "a turn that has waited its allowance is sent anyway" \
  force "nobody who understands" "Which of the three should I look at first?" 2
expect "and one filler short of the allowance still waits" \
  wait "nobody who understands" "Which of the three should I look at first?" 1

# A pattern nobody's reply will ever match must not swallow the run. This is
# the false-failure guard: two fillers, then the line goes out regardless.
printf '%s' "The kit said something else entirely." > "$reply"
sent=0
used=0
n=0
while [ "$n" -lt 6 ]; do
  n=$((n + 1))
  case $(gate_decision "this will never appear" "$reply" "$used" "$FILLER_CAP") in
    wait) used=$((used + 1)) ;;
    force|send) sent=1; break ;;
  esac
done
if [ "$sent" -eq 1 ] && [ "$used" -eq "$FILLER_CAP" ]; then
  ok "an unmatchable precondition costs $FILLER_CAP fillers and then gives up"
else
  bad "an unmatchable precondition did not give up (sent=$sent used=$used)"
fi

# --- reading the case file -------------------------------------------------

turns="$WORK/turns"
mkdir -p "$turns"
cat > "$WORK/case.txt" <<'CASE'
# setup: fixture
# A comment that is not a precondition.
First line.
---
Second line.
---
# when: named the risk
Third line.
CASE

split_turns "$WORK/case.txt" "$turns"

[ "$(find "$turns" -name 'turn-*.txt' | wc -l | tr -d ' ')" = "3" ] \
  && ok "three turns are split out of the case" \
  || bad "the case did not split into three turns"

grep -q '^First line\.$' "$turns/turn-01.txt" \
  && ok "an ordinary comment is not mistaken for a turn" \
  || bad "the leading comments leaked into the first turn"

[ -f "$turns/turn-03.when" ] \
  && ok "a precondition is carried beside the turn it guards" \
  || bad "turn 3's precondition was dropped"

[ "$(cat "$turns/turn-03.when")" = "named the risk" ] \
  && ok "and it is the pattern the case wrote" \
  || bad "turn 3's precondition is not what the case wrote"

[ -f "$turns/turn-01.when" ] && bad "turn 1 gained a precondition it never had" \
  || ok "a turn without one gets no precondition file"

grep -q 'when:' "$turns/turn-03.txt" \
  && bad "the precondition line was sent to the kit as part of the turn" \
  || ok "the precondition is not spoken to the kit"

# --- the person merges before a turn ---------------------------------------
# A line saying "I merged your fix" must be true when it is sent, or the kit
# rightly answers that the fix never went live. So a case marks the turn, and
# the harness merges every open pull request on the remote first.

cat > "$WORK/case3.txt" <<'CASE'
First line.
---
# merge: open pull requests
I merged it. Still broken.
CASE
turns3="$WORK/turns3"
mkdir -p "$turns3"
split_turns "$WORK/case3.txt" "$turns3"

[ -f "$turns3/turn-02.merge" ] \
  && ok "a merge line is carried beside the turn it comes before" \
  || bad "turn 2's merge was dropped"
[ -f "$turns3/turn-01.merge" ] && bad "turn 1 gained a merge it never had" \
  || ok "a turn without one merges nothing"
grep -q 'merge:' "$turns3/turn-02.txt" \
  && bad "the merge line was sent to the kit as part of the turn" \
  || ok "the merge line is not spoken to the kit"

# Drive the merge against a real project and remote, through the stand-in.
GH_DIR="$ROOT/.agents/tests/replay/fake-github"
FAKE_GH_STATE="$WORK/.gh-fixture.json"
FAKE_GH_LOG="$WORK/gh.log"
export FAKE_GH_STATE FAKE_GH_LOG
proj="$WORK/proj"
git init -q "$proj"
git -C "$proj" config user.email rehearsal@example.com
git -C "$proj" config user.name Rehearsal
git -C "$proj" commit -q --allow-empty -m first
git -C "$proj" branch -M main
git init -q --bare "$proj.git"
git -C "$proj" remote add origin "$proj.git"
git -C "$proj" push -q origin main
git -C "$proj" checkout -q -b the-fix
echo fixed > "$proj/fix.txt"
git -C "$proj" add fix.txt
git -C "$proj" commit -q -m "The fix"
git -C "$proj" push -q origin the-fix
(cd "$proj" && "$GH_DIR/gh" pr create --title "The fix" --body "Closes #1" >/dev/null)

merged=$(merge_open_pulls "$proj")
[ "$merged" = "#1" ] \
  && ok "the harness merges the open pull request and names it" \
  || bad "merge_open_pulls reported '$merged'"
git -C "$proj" fetch -q origin
git -C "$proj" merge-base --is-ancestor origin/the-fix origin/main \
  && ok "the fix is on the remote's main, where the kit will look" \
  || bad "the remote's main does not carry the merged fix"
[ -z "$(merge_open_pulls "$proj")" ] \
  && ok "with nothing open, nothing is merged" \
  || bad "a second merge found something still open"

grep -q 'merge_open_pulls' "$ROOT/.agents/tests/replay/run.sh" \
  && ok "the harness merges before a marked turn" \
  || bad "run.sh no longer merges before a marked turn"
grep -q 'before this turn the person merged' "$ROOT/.agents/tests/replay/grader-prompt.md" \
  && ok "the grader is told what the merge note means" \
  || bad "the grader is not told what the merge note means"

# --- the filler ------------------------------------------------------------

[ -n "$(case_filler "$WORK/case.txt")" ] \
  && ok "a case with no filler line falls back to the default" \
  || bad "the default filler is empty"

printf '# filler: I do not know.\nOnly line.\n' > "$WORK/case2.txt"
[ "$(case_filler "$WORK/case2.txt")" = "I do not know." ] \
  && ok "a case can write its own filler" \
  || bad "the case's own filler was not read"

# The filler must not grant the kit anything. A run where the harness says
# "go ahead" would manufacture the permission the scenario exists to measure.
case $FILLER_DEFAULT in
  *"go ahead"*|*"your best"*|*"whatever you"*|*"up to you"*|*"I accept"*)
    bad "the default filler grants the kit permission the person never gave" ;;
  *) ok "the default filler answers nothing and grants nothing" ;;
esac

# --- the cases on disk -----------------------------------------------------

for c in 05 08; do
  f="$ROOT/.agents/tests/replay/cases/$c.txt"
  grep -q '^# when: ' "$f" \
    && ok "case $c holds its acceptance until the kit has given the notice" \
    || bad "case $c still accepts a risk on turn count alone"
done

for c in 26 31; do
  f="$ROOT/.agents/tests/replay/cases/$c.txt"
  grep -q '^# when: ' "$f" \
    && bad "case $c gained a precondition it does not need" \
    || ok "case $c is untouched, so an ungated case still runs as before"
done

# --- the harness actually uses it -----------------------------------------
# The rule above is worth nothing if run.sh stopped asking. These catch the
# mechanism being disconnected while its own unit checks keep passing.

runsh="$ROOT/.agents/tests/replay/run.sh"
grep -q 'turn-gate.sh' "$runsh" \
  && ok "the harness loads the gate" \
  || bad "run.sh no longer loads turn-gate.sh"

grep -q 'gate_decision' "$runsh" \
  && ok "and asks it before sending a turn" \
  || bad "run.sh no longer asks the gate anything"

grep -q 'lastreply' "$runsh" \
  && ok "and keeps the kit's last reply for the next precondition to read" \
  || bad "run.sh keeps no reply for a precondition to be read against"

grep -q 'sent unheld' "$runsh" \
  && ok "a turn sent without its precondition says so in the transcript" \
  || bad "a forced turn is not marked in the transcript"

# --- what the grader is told ----------------------------------------------

grader="$ROOT/.agents/tests/replay/grader-prompt.md"
grep -qi 'filler' "$grader" \
  && ok "the grader is told what a filler is" \
  || bad "the grader is not told what a filler is, so it may read one as the person"

echo
if [ "$failures" -eq 0 ]; then
  echo "gated-turns.sh: all checks passed"
else
  echo "gated-turns.sh: $failures check(s) failed"
  exit 1
fi
