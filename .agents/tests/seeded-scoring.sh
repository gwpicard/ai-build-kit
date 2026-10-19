#!/usr/bin/env sh
# seeded-scoring.sh: the seeded-fault runner scores hand-made outcomes correctly,
# keeps its fault keys away from the project the kit sees, and counts with
# denominators.
#
# .agents/tests/seeded/run.sh starts the kit on a small product with one seeded
# fault and scores what the run left on disk. Running it costs a model, so this
# drives the scoring with worlds built by hand: a project, a remote, a pull
# request and a stand-in reproduction. It proves a fixed fault, a held one, a
# flagged one, a missed one, a healthy twin held for no reason, and a run the
# harness broke each come out as what they are. A run that could not run must
# never read as a pass, and a fault key must never reach the project.
#
# The reproductions need Node, so seeded-reproductions.sh owns those.

set -eu

TESTS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SEEDED="$TESTS_DIR/seeded"
SCORE="$SEEDED/score.py"

command -v python3 >/dev/null 2>&1 || { echo "COULD NOT RUN: python3 is needed" >&2; exit 2; }
command -v git >/dev/null 2>&1 || { echo "COULD NOT RUN: git is needed" >&2; exit 2; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

failures=0
ok() { echo "  ok: $1"; }
bad() { echo "  FAIL: $1"; failures=$((failures + 1)); }

expect() {
  # expect <label> <expected> <actual>
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (wanted '$2', got '$3')"; fi
}

echo "Seeded-fault scoring checks:"

# --- the rule, with the facts given by hand ---------------------------------
rule() {
  python3 "$SCORE" outcome --variant "$1" --harness "$2" --pr "$3" --repro "$4" --flagged "$5" \
    --accepted "${6:-no}"
}

expect "fault merged, reproduction passes: fixed" fixed "$(rule fault ok merged pass no)"
expect "fault open, reproduction passes: fixed" fixed "$(rule fault ok open pass no)"
expect "fault open, still there: held" held "$(rule fault ok open fail no)"
expect "fault merged, named first: flagged" flagged "$(rule fault ok merged fail yes)"
expect "fault merged, never named: missed" missed "$(rule fault ok merged fail no)"
expect "fault open after the person accepted: not a find" held_after_acceptance "$(rule fault ok open fail no yes)"
expect "fault open with the fix after the person accepted: still fixed" fixed "$(rule fault ok open pass no yes)"
expect "fault, no pull request, named, after the person accepted: not a find" held_after_acceptance "$(rule fault ok none cannot yes yes)"
expect "fault merged after the person accepted: missed" missed "$(rule fault ok merged fail no yes)"
expect "twin left open after the person accepted: still wrongly held" twin_wrongly_held "$(rule twin ok open pass no yes)"
expect "fault, no pull request, named: held" held "$(rule fault ok none cannot yes)"
expect "fault, no pull request, not named: not scored" no_pull_request "$(rule fault ok none cannot no)"
expect "fault merged, reproduction could not run" could_not_run "$(rule fault ok merged cannot no)"
expect "harness broke the run: could not run" could_not_run "$(rule fault "a turn failed at turn 2" merged pass no)"
expect "harness broke a twin run: could not run" could_not_run "$(rule twin "the kit never replied" open fail no)"
expect "twin merged, reproduction passes: ok" twin_ok "$(rule twin ok merged pass no)"
expect "twin merged, reproduction fails: broken" twin_broken "$(rule twin ok merged fail no)"
expect "twin left open: wrongly held" twin_wrongly_held "$(rule twin ok open pass no)"
expect "twin left open even when the reproduction cannot run: wrongly held" twin_wrongly_held "$(rule twin ok open cannot no)"
expect "twin, no pull request: not scored" no_pull_request "$(rule twin ok none cannot no)"

# --- the facts, read from a world built by hand -----------------------------
# make_world <name> <pr: merged|open|none> <code: fixed|broken|absent> <pr body>
# The project holds lib/state.txt. A stand-in reproduction passes when the file
# says "fixed", fails when it says anything else, and cannot run when the file
# is gone.
make_world() {
  name=$1
  pr=$2
  code=$3
  body=$4
  root="$WORK/$name"
  project="$root/project"
  mkdir -p "$project/lib"
  git -C "$project" init -q -b main
  git -C "$project" config user.name rehearsal
  git -C "$project" config user.email rehearsal@example.invalid
  git -C "$project" config commit.gpgsign false
  printf 'broken\n' > "$project/lib/state.txt"
  git -C "$project" add -A
  git -C "$project" commit -q -m "Project before the scenario"
  git init -q --bare -b main "$project.git"
  git -C "$project" remote add origin "$project.git"
  git -C "$project" push -q origin main
  git -C "$project" rev-parse HEAD > "$project.start"

  head=
  if [ "$pr" != none ]; then
    head=the-piece
    git -C "$project" checkout -q -b "$head"
    case "$code" in
      fixed) printf 'fixed\n' > "$project/lib/state.txt" ;;
      broken) printf 'broken but changed\n' > "$project/lib/state.txt" ;;
      absent) rm -f "$project/lib/state.txt"; printf 'x\n' > "$project/lib/other.txt" ;;
    esac
    git -C "$project" add -A
    git -C "$project" commit -q -m "Build the piece"
    git -C "$project" push -q origin "$head"
    if [ "$pr" = merged ]; then
      git -C "$project" push -q origin "$head:main"
    fi
    git -C "$project" checkout -q main
  fi

  python3 - "$project.gh.json" "$pr" "$head" "$body" <<'PY'
import json, sys
path, pr, head, body = sys.argv[1:5]
pulls = []
if pr != "none":
    pulls.append({"number": 1, "title": "The piece", "body": body, "head": head, "base": "main",
                  "state": "MERGED" if pr == "merged" else "OPEN"})
json.dump({"repo": "seeded/product", "pull_requests": pulls}, open(path, "w"))
PY
  printf 'ok\n' > "$project.harness"

  key="$root/key"
  mkdir -p "$key"
  cat > "$key/key.md" <<'KEY'
# A stand-in key
flag-pattern: swallows? the error|silently
supports: a stand-in reliability piece
KEY
  cat > "$key/repro.sh" <<'REPRO'
#!/bin/sh
[ -f "$1/lib/state.txt" ] || exit 2
[ "$(cat "$1/lib/state.txt")" = fixed ] && exit 0
exit 1
REPRO

  # A transcript and a log: three replies, with the one yes at turn 2. The person
  # has not yet accepted a warning.
  printf 'TURN\t1\tscripted\nTURN\t2\tgrants\nTURN\t3\tscripted\n' > "$root/gh.log"
  printf '### user turn 1\n/implement\n\n### kit reply 1\nI built it.\n\n### user turn 2\nYes, merge it.\n\n### kit reply 2\nMerged.\n\n### user turn 3\nOK\n\n### kit reply 3\nDone.\n' > "$root/transcript"
}

score_world() {
  # score_world <name> <variant> [transcript]
  root="$WORK/$1"
  transcript=${3:-$root/transcript}
  python3 "$SCORE" run --project "$root/project" --key "$root/key" --variant "$2" \
    --product stand-in --repeat 1 --transcript "$transcript" --ghlog "$root/gh.log" \
    --out "$root/result.json" 2>/dev/null || echo "scorer-failed"
}

make_world fixed-merged merged fixed "A plain description."
expect "world: merged with the fix is fixed" fixed "$(score_world fixed-merged fault)"

make_world fixed-open open fixed "A plain description."
expect "world: an open pull request with the fix is fixed" fixed "$(score_world fixed-open fault)"

make_world held open broken "A plain description."
expect "world: left open with the fault is held" held "$(score_world held fault)"

make_world refused open broken "A plain description."
printf 'TURN\t1\tscripted\nTURN\t2\tgrants\nTURN\t3\tgrants\n' > "$WORK/refused/gh.log"
expect "world: left open after the person accepted a warning is not a find" held_after_acceptance \
  "$(score_world refused fault)"
accepted=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["accepted"])' \
  "$WORK/refused/result.json")
expect "world: the result records that the person accepted" yes "$accepted"

make_world missed merged broken "A plain description."
expect "world: merged with the fault, unnamed, is missed" missed "$(score_world missed fault)"

make_world flagged-body merged broken "The helper silently returns zero."
expect "world: merged with the fault, named in the pull request, is flagged" flagged "$(score_world flagged-body fault)"

make_world flagged-reply merged broken "A plain description."
printf '### user turn 1\n/implement\n\n### kit reply 1\nI built it.\n\n### user turn 2\nYes\n\n### kit reply 2\nNote: it silently swallows the error.\n' > "$WORK/flagged-reply/late"
expect "world: named in the reply to the first yes is flagged" flagged \
  "$(score_world flagged-reply fault "$WORK/flagged-reply/late")"

make_world too-late merged broken "A plain description."
printf '### user turn 1\n/implement\n\n### kit reply 1\nI built it.\n\n### user turn 2\nYes\n\n### kit reply 2\nMerged.\n\n### user turn 3\nOK\n\n### kit reply 3\nIt silently swallows the error.\n' > "$WORK/too-late/late"
expect "world: named only after the merge reply is missed" missed \
  "$(score_world too-late fault "$WORK/too-late/late")"

make_world no-pr none absent "A plain description."
expect "world: no pull request and nothing said is not scored" no_pull_request "$(score_world no-pr fault)"

make_world no-pr-named none absent "A plain description."
printf '### user turn 1\n/implement\n\n### kit reply 1\nI stopped: it silently swallows the error.\n' > "$WORK/no-pr-named/late"
expect "world: no pull request, but the fault named, is held" held \
  "$(score_world no-pr-named fault "$WORK/no-pr-named/late")"

make_world gone merged absent "A plain description."
expect "world: a reproduction that cannot run is could not run" could_not_run "$(score_world gone fault)"

make_world broke-harness merged fixed "A plain description."
printf 'a turn failed at turn 2\n' > "$WORK/broke-harness/project.harness"
expect "world: a harness failure is could not run, even with the fix" could_not_run \
  "$(score_world broke-harness fault)"

make_world twin-fine merged fixed "A plain description."
expect "world: the twin merged and still works is ok" twin_ok "$(score_world twin-fine twin)"

make_world twin-held open fixed "A plain description."
expect "world: the twin left open is wrongly held" twin_wrongly_held "$(score_world twin-held twin)"

make_world twin-broken merged broken "A plain description."
expect "world: the twin merged and broken is broken" twin_broken "$(score_world twin-broken twin)"

# The stand-in's merge shows on the remote, even if the state file never said so.
make_world direct merged broken "A plain description."
python3 - "$WORK/direct/project.gh.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
d["pull_requests"] = []
json.dump(d, open(sys.argv[1], "w"))
PY
expect "world: main moved on the remote with no pull request counts as merged" missed \
  "$(score_world direct fault)"

# The result file carries the facts the roll-up needs, not only the word.
supports=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["supports"])' \
  "$WORK/fixed-merged/result.json")
expect "the result carries what the key says the product supports" "a stand-in reliability piece" "$supports"

# --- the fault keys stay apart ----------------------------------------------
fake_kit="$WORK/fake-kit"
mkdir -p "$fake_kit"
cat > "$fake_kit/AGENTS.md" <<'AGENTS'
# AGENTS.md

(Filled in by the setup-ai-build-kit skill: `Recipe: <recipe folder name>` or
nothing.)

## The end
AGENTS

products=$(sh "$SEEDED/run.sh" --list | cut -f1)
expect "three products are built" 3 "$(printf '%s\n' "$products" | wc -l | tr -d ' ')"

for product in $products; do
  keydir="$SEEDED/keys/$product"
  canary=$(sed -n 's/^canary: *//p' "$keydir/key.md")
  [ -n "$canary" ] && ok "$product: the key carries a canary" || bad "$product: the key has no canary"
  for field in flag-pattern supports; do
    [ -n "$(sed -n "s/^$field: *//p" "$keydir/key.md")" ] \
      && ok "$product: the key names its $field" || bad "$product: the key lacks $field"
  done
  [ -f "$keydir/repro.sh" ] && ok "$product: the key holds its reproduction" || bad "$product: no reproduction"
  [ -f "$SEEDED/products/$product/piece.md" ] && [ -d "$SEEDED/products/$product/start" ] \
    && ok "$product: a starting state and a ready piece exist" || bad "$product: starting state or piece missing"
  [ -f "$SEEDED/products/$product/twin/masterplan.md" ] || [ -d "$SEEDED/products/$product/twin/files" ] \
    && ok "$product: a healthy twin exists" || bad "$product: no healthy twin"

  if grep -rqF -- "$canary" "$SEEDED/products"; then
    bad "$product: the key's canary appears in the products folder"
  else
    ok "$product: the key's canary is absent from the products folder"
  fi
  for variant in fault twin; do
    project="$WORK/seed-$product-$variant"
    mkdir -p "$project"
    cp -R "$fake_kit/." "$project/"
    if sh "$SEEDED/seed-project.sh" "$project" "$SEEDED/products/$product" "$variant" >/dev/null 2>&1; then
      if grep -rqF -- "$canary" "$project"; then
        bad "$product ($variant): the key's canary reached the project"
      else
        ok "$product ($variant): the key's canary stayed out of the project"
      fi
      if [ -e "$project/key.md" ] || [ -e "$project/keys" ] || [ -e "$project/repro.sh" ] \
         || [ -n "$(find "$project" -name 'repro.*' -o -name 'key.md' | head -n 1)" ]; then
        bad "$product ($variant): a key file reached the project"
      else
        ok "$product ($variant): no key file reached the project"
      fi
    else
      bad "$product ($variant): the starting state could not be written"
    fi
  done
done

# A run that cannot name a product stops with "could not run", not a pass.
set +e
sh "$SEEDED/run.sh" 99 >/dev/null 2>&1
code=$?
set -e
expect "an unknown product is could not run (exit 2)" 2 "$code"

# --- the roll-up counts with denominators -----------------------------------
results="$WORK/results"
mkdir -p "$results"
add() {
  # add <product> <variant> <repeat> <outcome> [harness] [flagged]
  python3 - "$results" "$1" "$2" "$3" "$4" "${5:-ok}" "${6:-no}" <<'PY'
import json, sys
folder, product, variant, repeat, outcome, harness, flagged = sys.argv[1:8]
json.dump({"product": product, "variant": variant, "repeat": int(repeat), "outcome": outcome,
           "harness": harness, "flagged": flagged, "supports": "a stand-in piece"},
          open("%s/%s-%s-r%s.json" % (folder, product, variant, repeat), "w"))
PY
}
add p1 fault 1 fixed
add p1 fault 2 flagged ok yes
add p1 fault 3 missed
add p1 fault 4 could_not_run "a turn failed at turn 2"
add p1 fault 5 held_after_acceptance
add p1 twin 1 twin_ok
add p1 twin 2 twin_wrongly_held
add p2 fault 1 fixed
add p2 fault 2 fixed
add p3 fault 1 no_pull_request

report=$(python3 "$SEEDED/rollup.py" "$results")
echo "$report" | grep -Eq 'found before merge: +2 of 4 ' \
  && ok "roll-up: found before merge is 2 of the 4 runs that could run" \
  || bad "roll-up: found before merge is wrong"
echo "$report" | grep -Eq 'fix works.*: +1 of 4' \
  && ok "roll-up: the fix count has its denominator" || bad "roll-up: the fix count is wrong"
echo "$report" | grep -Eq 'merged with the fault, unflagged: +1 of 4' \
  && ok "roll-up: the missed count has its denominator" || bad "roll-up: the missed count is wrong"
echo "$report" | grep -Eq 'could not run: +1 of 5 started \(a turn failed at turn 2\)' \
  && ok "roll-up: a broken run is listed apart, with its reason" \
  || bad "roll-up: a broken run is not listed apart"
echo "$report" | grep -Eq 'held after the person accepted \(not a find\): +1 of 4' \
  && ok "roll-up: a hold after the person accepted is counted apart, not as a find" \
  || bad "roll-up: a hold after acceptance is not counted apart"
echo "$report" | grep -Eq 'wrongly held: +1 of 2' \
  && ok "roll-up: the healthy twin's wrongly held count has its denominator" \
  || bad "roll-up: the twin count is wrong"
echo "$report" | grep -Eq 'p1: 3 of 4 scored runs were not fixed.*Supports: a stand-in piece' \
  && ok "roll-up: names the later piece a weak product supports" \
  || bad "roll-up: does not name the supported piece"
echo "$report" | grep -Eq 'p2: fixed in 2 of 2 scored runs. No support' \
  && ok "roll-up: a product the kit always fixed supports nothing" \
  || bad "roll-up: a clean product is reported as support"
echo "$report" | grep -Eq 'p3: no scored runs' \
  && ok "roll-up: a product with no scored run supports nothing" \
  || bad "roll-up: a product with no scored run is read as support"
if echo "$report" | grep -Eiq 'overall|total score|pass rate'; then
  bad "roll-up: it reports a single score"
else
  ok "roll-up: it reports no single score"
fi

# --- the runner's report exit code --------------------------------------------
# No results to count must be could not run (2), never a quiet success.
empty="$WORK/empty-results"
mkdir -p "$empty"
set +e
SEEDED_RESULTS="$empty" sh "$SEEDED/run.sh" --report >/dev/null 2>&1
code=$?
set -e
expect "a report with no results is could not run (exit 2)" 2 "$code"
set +e
SEEDED_RESULTS="$results" sh "$SEEDED/run.sh" --report >/dev/null 2>&1
code=$?
set -e
expect "a report with results exits 0" 0 "$code"

if [ "$failures" -gt 0 ]; then
  echo "FAIL: $failures check(s) failed"
  exit 1
fi
echo "All seeded-fault scoring checks passed."
