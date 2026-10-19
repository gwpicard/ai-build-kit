#!/usr/bin/env sh
# replay-behaviour-cases.sh: keep the behaviour set whole and answerable.
#
# The eighteen scenarios, 64 to 81, test each command by what it should do. A
# scenario that quietly loses its backbone line, its disk checks, or the gate on
# its scripted answers still replays and still reports a number, and the number
# no longer means what the sheet says. This holds the shape: every case is graded
# on the backbone and on its disk checks, every scripted line after the first
# either waits for the question it answers or is marked an interruption, each
# scenario has four to six checks and mostly from disk, and every preparation a
# case names exists. It calls no model.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
REPLAY_DIR="$ROOT/.agents/tests/replay"
. "$REPLAY_DIR/lib.sh"
. "$REPLAY_DIR/turn-gate.sh"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

bad() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }

# The checks the older state-check.sh assertions run when a scenario's Evidence
# names them. They count as disk checks of the scenario.
named_checks() {
  count=0
  for phrase in "exactly one new production deployment" "a new rollback line saying possible, not tried" \
    "the pending migration applied once, after the person's yes" "the database password never appears" \
    "the person's uncommitted work is still in the tree"; do
    case "$1" in *"$phrase"*) count=$((count + 1)) ;; esac
  done
  echo "$count"
}

total=0
for number in $(seq 64 81); do
  casefile="$REPLAY_DIR/cases/$number.txt"
  [ -f "$casefile" ] || bad "scenario $number has no case file"
  grep -q '^# backbone: yes$' "$casefile" || bad "case $number is not graded on the backbone"
  grep -q '^# disk: yes$' "$casefile" || bad "case $number is not graded on its disk checks"
  grep -q 'draft for the maintainer' "$casefile" || bad "case $number is not marked a draft for the maintainer"

  # Every scripted line after the first answers a question the kit asked, or is
  # marked as an interruption.
  turns="$WORK/turns-$number"
  mkdir -p "$turns"
  split_turns "$casefile" "$turns"
  count=$(find "$turns" -name 'turn-*.txt' | wc -l | tr -d ' ')
  [ "$count" -ge 1 ] || bad "case $number holds no turns"
  index=2
  while [ "$index" -le "$count" ]; do
    n=$(printf '%02d' "$index")
    if [ ! -f "$turns/turn-$n.when" ] && [ ! -f "$turns/turn-$n.interrupt" ]; then
      bad "case $number turn $index neither answers a question nor is marked an interruption"
    fi
    index=$((index + 1))
  done

  # The preparation exists.
  prepare=$(case_prepare "$casefile")
  [ -z "$prepare" ] || [ -f "$REPLAY_DIR/prepare/$prepare.sh" ] || bad "case $number names a preparation that does not exist: $prepare"

  # The contract: read fields for the transcript, disk checks for the rest.
  reads=$(scenario_labels "$number" | grep -c '^Read ' || true)
  evidence=$(scenario_field "$number" Evidence)
  case "$evidence" in "on disk, "*|"On disk, "*) : ;; *) bad "scenario $number's Evidence does not start with what is read from disk" ;; esac
  disk=$(python3 "$REPLAY_DIR/behaviour_checks.py" "$number" "$WORK/nowhere" \
    | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["disk"]))')
  named=$(named_checks "$evidence")
  checks=$((reads + disk + named))
  [ "$checks" -ge 4 ] && [ "$checks" -le 6 ] \
    || bad "scenario $number has $checks checks ($reads read, $((disk + named)) disk); four to six were agreed"
  [ "$reads" -ge 1 ] && [ "$reads" -le $((disk + named)) ] \
    || bad "scenario $number has $reads read checks against $((disk + named)) from disk; most should come from disk"
  total=$((total + checks))

  sh "$REPLAY_DIR/behaviour.sh" --list | awk -F'\t' -v n="$number" '$1 == n { found = 1 } END { exit found ? 0 : 1 }' \
    || bad "behaviour.sh does not list scenario $number"
done
pass "scenarios 64 to 81 each have a case, a backbone line, disk checks, four to six checks and gated answers"

# Pushback is the kind that pushes twice, so its second push is marked.
for number in 66 69 72 78 81; do
  grep -q '^# interrupts:' "$REPLAY_DIR/cases/$number.txt" \
    || bad "pushback case $number marks no interruption"
done
pass "the pushback cases that push a second time mark the interruption"

# Every command has the three kinds.
for command_name in setup-ai-build-kit shape implement setup-hosting maintain what-now; do
  kinds=$(sh "$REPLAY_DIR/behaviour.sh" --list | awk -F'\t' -v c="$command_name" '$1 ~ /^[0-9]+$/ && $2 == c { print $3 }' | sort | tr '\n' ' ')
  [ "$kinds" = "expected pushback skipped " ] || bad "$command_name has the kinds '$kinds', not expected, skipped and pushback"
done
pass "each of the six commands has an expected path, a skipped step and pushback"

# The seeded products are wired in as further cases of /implement.
for product in 03 04 08; do
  sh "$REPLAY_DIR/behaviour.sh" --list | grep -q "^seeded $product	implement" \
    || bad "the seeded product $product is not listed as an implement case"
  ls -d "$ROOT/.agents/tests/seeded/products/$product"-* >/dev/null 2>&1 \
    || bad "the seeded product $product does not exist"
done
pass "seeded products 03, 04 and 08 are wired in as implement cases"

echo "PASS: the behaviour set is whole ($total checks across eighteen scenarios)"
