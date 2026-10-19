#!/usr/bin/env sh
# run.sh: run the kit on small products that each carry one seeded fault, and
# count what it caught.
#
# Usage:
#   ./run.sh --list              the products and what they are
#   ./run.sh --report            the counts from the results already saved
#   ./run.sh                     every product, fault and healthy twin
#   ./run.sh 03 04               only these products (a number or a folder name)
#   REPEATS=1 ./run.sh 03        one run each, for a quick look
#   VARIANTS=fault ./run.sh      only the product with the fault
#
# Settings, the same names the replay harness uses:
#   KIT_SRC   the kit tree to assemble and test (default: this checkout)
#   REPEATS   runs per product and variant (default 3)
#   JOBS      runs at the same time (default 4)
#   MODEL     the model for Claude Code (default opus)
#   REPLAY_PROVIDER, REPLAY_EFFORT, REPLAY_WORK   as in ../replay/README.md
#   SEEDED_RESULTS   where results go (default ~/.local/state/abk-seeded/results)
#
# This reuses the replay harness: its turn gate, its provider switch, its fake
# GitHub command and its fake host tools. It starts the kit's /implement on one
# ready piece in a throwaway project, says yes to the merge, and then scores the
# disk. See README.md for what is measured and why the fault keys sit apart.
#
# Exit: 0 when the runs finished and have counts (whatever they found), 2 when
# it could not run, or when there are no results to count.

set -eu

SEEDED_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPLAY_DIR=$(CDPATH= cd -- "$SEEDED_DIR/../replay" && pwd)
. "$REPLAY_DIR/lib.sh"
. "$REPLAY_DIR/turn-gate.sh"

cannot() {
  echo "COULD NOT RUN: $1" >&2
  exit 2
}

# --- the products -----------------------------------------------------------
all_products() {
  for dir in "$SEEDED_DIR"/products/*/; do
    name=$(basename "$dir")
    case "$name" in _*) continue ;; esac
    printf '%s\n' "$name"
  done
}

if [ "${1:-}" = "--list" ]; then
  for name in $(all_products); do
    title=$(sed -n '1s/^Title: *//p' "$SEEDED_DIR/products/$name/piece.md")
    printf '%s\t%s\n' "$name" "$title"
  done
  exit 0
fi

RESULTS=${SEEDED_RESULTS:-${XDG_STATE_HOME:-$HOME/.local/state}/abk-seeded/results}

# The roll-up's own exit code is this script's. No results to count is could
# not run, never a quiet success.
if [ "${1:-}" = "--report" ]; then
  python3 "$SEEDED_DIR/rollup.py" "$RESULTS"
  exit $?
fi

wanted=""
if [ "$#" -gt 0 ]; then
  for want in "$@"; do
    found=""
    for name in $(all_products); do
      case "$name" in
        "$want" | "$want"-* | 0"$want"-*) found=$name ;;
      esac
    done
    [ -n "$found" ] || cannot "no product matches '$want'; try --list"
    wanted="$wanted $found"
  done
else
  wanted=$(all_products)
fi

REPEATS=${REPEATS:-3}
VARIANTS=${VARIANTS:-"fault twin"}
JOBS=${JOBS:-4}
REPLAY_PROVIDER=${REPLAY_PROVIDER:-claude}
case "$REPLAY_PROVIDER" in
  claude)
    MODEL=${MODEL:-opus}
    GRADER_MODEL=${GRADER_MODEL:-$MODEL}
    ;;
  codex)
    MODEL=${MODEL:-}
    GRADER_MODEL=${GRADER_MODEL:-$MODEL}
    ;;
esac
VERSION=${VERSION:-v0.0.0-seeded}
KIT_SRC=${KIT_SRC:-$ROOT}
[ -d "$KIT_SRC" ] || cannot "KIT_SRC is not a folder: $KIT_SRC"
KIT_SRC=$(CDPATH= cd -- "$KIT_SRC" && pwd)
[ -x "$KIT_SRC/.agents/tools/build-release.sh" ] || cannot "the release builder is missing from KIT_SRC=$KIT_SRC"

for tool in python3 git tar node; do
  command -v "$tool" >/dev/null 2>&1 || cannot "$tool is needed to run and score the products"
done
node -e 'const [a, b] = process.versions.node.split(".").map(Number); process.exit(a > 22 || (a === 22 && b >= 6) ? 0 : 1)' \
  || cannot "node 22.6 or newer is needed to run the reproductions"

WORK=${REPLAY_WORK:-${TMPDIR:-/tmp}/abk-seeded-$$}
GH_DIR="$REPLAY_DIR/fake-github"
HOST_DIR="$REPLAY_DIR/fake-host"

if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD=timeout
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_CMD=gtimeout
else
  TIMEOUT_CMD=
  note "no timeout or gtimeout found, so turns run without a time cap"
fi

. "$REPLAY_DIR/provider.sh"
provider_check

mkdir -p "$WORK" "$RESULTS"
provider_prepare
echo "Replay provider: $REPLAY_PROVIDER"

# The kit under test, assembled once and copied for every run.
KIT="$WORK/kit"
echo "Assembling $VERSION into $KIT"
"$KIT_SRC/.agents/tools/build-release.sh" "$VERSION" "$KIT" >/dev/null || cannot "the kit would not assemble"

# The cheap faults of the harness are found before any model is called, and a
# run the harness breaks is could not run, as in the replay harness.
GH_DIR="$GH_DIR" HOST_DIR="$HOST_DIR" WORK="$WORK" RESULTS="$RESULTS" \
  REPLAY_PROVIDER="$REPLAY_PROVIDER" sh "$REPLAY_DIR/preflight.sh" "$KIT" \
  || cannot "the preflight found what stops a run"

new_uuid() {
  if [ -r /proc/sys/kernel/random/uuid ]; then
    cat /proc/sys/kernel/random/uuid
  else
    python3 -c 'import uuid; print(uuid.uuid4())'
  fi
}

# A hash of the product's files, so a result says which pinned state it ran on.
product_hash() {
  python3 - "$1" <<'PY'
import hashlib, os, sys
digest = hashlib.sha256()
for folder, _, names in sorted(os.walk(sys.argv[1])):
    for name in sorted(names):
        path = os.path.join(folder, name)
        digest.update(os.path.relpath(path, sys.argv[1]).encode())
        digest.update(open(path, "rb").read())
print(digest.hexdigest()[:12])
PY
}

pr_merged() {
  python3 - "$1" <<'PY'
import json, sys
try:
    pulls = json.load(open(sys.argv[1])).get("pull_requests", [])
except Exception:
    sys.exit(1)
sys.exit(0 if any(p.get("state") == "MERGED" for p in pulls) else 1)
PY
}

# --- one run ----------------------------------------------------------------
# harness_set writes why the harness stopped, or "ok". A run that ends on
# anything but "ok" is scored could not run, never as a pass.
run_once() {
  pname=$1
  variant=$2
  repeat=$3
  tag="$pname-$variant-r$repeat"
  project="$WORK/$tag"
  product="$SEEDED_DIR/products/$pname"
  harness="$project.harness"
  transcript="$WORK/$tag.transcript"
  ghlog="$WORK/$tag-gh.log"

  mkdir -p "$project"
  : > "$transcript"
  : > "$ghlog"
  printf '%s\n' "the run stopped before it finished" > "$harness"
  cp -R "$KIT/." "$project/"

  sh "$SEEDED_DIR/seed-project.sh" "$project" "$product" "$variant" >/dev/null || {
    printf '%s\n' "the starting state could not be written" > "$harness"
    return 0
  }
  sh "$REPLAY_DIR/prepare/install-project-helper.sh" "$project" "$KIT" || {
    printf '%s\n' "the project helper could not be installed" > "$harness"
    return 0
  }
  answer_merge_box "$project" || {
    printf '%s\n' "the merge box could not be stood in for" > "$harness"
    return 0
  }

  git -C "$project" init -q
  git init -q --bare -b main "$project.git"
  git -C "$project" remote add origin "$project.git"
  git -C "$project" config user.name "Seeded rehearsal"
  git -C "$project" config user.email "rehearsal@example.invalid"
  git -C "$project" config commit.gpgsign false
  git -C "$project" add -A
  git -C "$project" commit -q -m "Project before the scenario"
  sh "$REPLAY_DIR/prepare/code-online.after-commit.sh" "$project" || {
    printf '%s\n' "the project could not be put online" > "$harness"
    return 0
  }
  git -C "$project" rev-parse HEAD > "$project.start"

  ghstate="$project.gh.json"
  cp "$project/.gh-fixture.json" "$ghstate"
  ghrepo=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("repo") or "")' "$ghstate")
  git -C "$project" remote set-url origin "https://github.com/$ghrepo.git"
  git -C "$project" config url."$project.git".insteadOf "https://github.com/$ghrepo.git"
  log_pushes "$project.git" "$ghlog"

  # The conversation: the title of the ready piece goes into the first line.
  title=$(sed -n '1s/^Title: *//p' "$(if [ "$variant" = twin ] && [ -f "$product/twin/piece.md" ]; then echo "$product/twin/piece.md"; else echo "$product/piece.md"; fi)")
  casefile="$WORK/$tag.case"
  awk -v title="$title" '{ sub(/\{\{TITLE\}\}/, title); print }' "$SEEDED_DIR/conversation.txt" > "$casefile"

  provider_new_session
  turns="$WORK/$tag-turns"
  mkdir -p "$turns"
  split_turns "$casefile" "$turns"
  total=$(find "$turns" -name 'turn-*.txt' | wc -l | tr -d ' ')
  filler=$(case_filler "$casefile")
  lastreply="$WORK/$tag-lastreply.txt"
  : > "$lastreply"
  index=0
  turn=0
  fillers=0
  ended=""

  while [ "$index" -lt "$total" ]; do
    next=$((index + 1))
    turnfile=$(printf '%s/turn-%02d.txt' "$turns" "$next")
    [ -f "$turnfile" ] || break
    whenfile="${turnfile%.txt}.when"
    pattern=""
    [ -f "$whenfile" ] && pattern=$(cat "$whenfile")

    case $(gate_decision "$pattern" "$lastreply" "$fillers" "$FILLER_CAP") in
      wait)
        message=$filler
        fillers=$((fillers + 1))
        label=" (filler: turn $next waits for the kit to say something matching /$pattern/)"
        ;;
      force)
        message=$(cat "$turnfile")
        index=$next
        fillers=0
        label=" (sent unheld: nothing the kit said matched /$pattern/ within $FILLER_CAP fillers)"
        ;;
      *)
        message=$(cat "$turnfile")
        index=$next
        fillers=0
        label=""
        ;;
    esac

    turn=$((turn + 1))
    printf '\n### user turn %s%s\n%s\n' "$turn" "$label" "$message" >> "$transcript"

    raw="$WORK/$tag-t$turn.json"
    FAKE_GH_STATE="$ghstate"
    FAKE_GH_LOG="$ghlog"
    export FAKE_GH_STATE FAKE_GH_LOG
    kind=scripted
    if [ "$message" = "$filler" ]; then
      kind=filler
    elif [ -f "${turnfile%.txt}.grants" ]; then
      kind=grants
    fi
    printf 'TURN\t%s\t%s\n' "$turn" "$kind" >> "$FAKE_GH_LOG"
    FAKE_HOST_STATE="$project.host.json"
    FAKE_HOST_LOG="$WORK/$tag-host.log"
    export FAKE_HOST_STATE FAKE_HOST_LOG
    printf 'TURN\t%s\t%s\n' "$turn" "$kind" >> "$FAKE_HOST_LOG"
    REPLAY_TURN=$turn
    export REPLAY_TURN
    GH_CONFIG_DIR="$project/.gh-empty-config"
    mkdir -p "$GH_CONFIG_DIR"
    GH_TOKEN=
    GITHUB_TOKEN=
    GH_ENTERPRISE_TOKEN=
    GITHUB_ENTERPRISE_TOKEN=
    GIT_TERMINAL_PROMPT=0
    export GH_CONFIG_DIR GH_TOKEN GITHUB_TOKEN GH_ENTERPRISE_TOKEN \
      GITHUB_ENTERPRISE_TOKEN GIT_TERMINAL_PROMPT
    provider_isolate_host "$project"

    if ! provider_turn "$project" "$message" "$raw" "$lastreply"; then
      printf '\n### run ended at turn %s\n' "$turn" >> "$transcript"
      ended=$turn
      break
    fi
    printf '\n### kit reply %s\n' "$turn" >> "$transcript"
    cat "$lastreply" >> "$transcript"
    printf '\n' >> "$transcript"

    # Nothing more is due once the pull request is merged. A third turn after a
    # clean merge would only invite the kit to say more.
    if pr_merged "$ghstate"; then
      break
    fi
  done

  printf '%s\n' "${PROVIDER_SESSION:-}" > "$WORK/$tag.session"

  if [ -n "$ended" ]; then
    printf '%s\n' "a turn failed at turn $ended" > "$harness"
    return 0
  fi
  replies=$(grep -c '^### kit reply' "$transcript" || true)
  if [ "$replies" -lt 1 ]; then
    printf '%s\n' "the kit never replied" > "$harness"
    return 0
  fi
  # A run whose GitHub commands reached the real command measured the harness,
  # not the kit. The replay README explains the two sentences looked for.
  if sign=$({ printf '%s\n' "$transcript"
              provider_session_records "$WORK/$tag"; } | real_gh_answered); then
    printf '%s\n' "the real GitHub command answered ($sign)" > "$harness"
    return 0
  fi
  printf 'ok\n' > "$harness"
}

# one_pass <product> <variant> <repeat>: run, then score from disk.
one_pass() {
  pname=$1
  variant=$2
  repeat=$3
  tag="$pname-$variant-r$repeat"
  run_once "$pname" "$variant" "$repeat"
  cp "$WORK/$tag.transcript" "$RESULTS/$tag.transcript" 2>/dev/null || true
  python3 "$SEEDED_DIR/score.py" run \
    --project "$WORK/$tag" \
    --key "$SEEDED_DIR/keys/$pname" \
    --variant "$variant" \
    --product "$pname" \
    --repeat "$repeat" \
    --transcript "$WORK/$tag.transcript" \
    --ghlog "$WORK/$tag-gh.log" \
    --product-hash "$(product_hash "$SEEDED_DIR/products/$pname")" \
    --out "$RESULTS/$tag.json" >/dev/null \
    || python3 - "$RESULTS/$tag.json" "$pname" "$variant" "$repeat" <<'PY'
import json, sys
out, product, variant, repeat = sys.argv[1:5]
json.dump({"product": product, "variant": variant, "repeat": int(repeat),
           "outcome": "could_not_run", "harness": "the scorer failed"}, open(out, "w"))
PY
  echo "  finished $tag: $(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["outcome"])' "$RESULTS/$tag.json")"
}

running=0
for pname in $wanted; do
  [ -d "$SEEDED_DIR/keys/$pname" ] || cannot "product $pname has no fault key"
  for variant in $VARIANTS; do
    # Earlier results for this product and variant are cleared before it runs
    # again, so the counts always describe one measurement.
    rm -f "$RESULTS/$pname-$variant-r"*
    repeat=1
    while [ "$repeat" -le "$REPEATS" ]; do
      echo "Starting $pname ($variant), run $repeat of $REPEATS"
      one_pass "$pname" "$variant" "$repeat" &
      running=$((running + 1))
      if [ "$running" -ge "$JOBS" ]; then
        wait
        running=0
      fi
      repeat=$((repeat + 1))
    done
  done
done
wait

echo
echo "Results and transcripts are in $RESULTS"
echo "Working copies are in $WORK"
SEEDED_RESULTS=$RESULTS exec sh "$SEEDED_DIR/run.sh" --report
