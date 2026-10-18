#!/usr/bin/env sh
# behaviour.sh: run the behaviour set on one kit, so two kits can be compared.
#
# The set tests each command by what it should do: eighteen scenarios, three for
# each of the six commands (the expected path, a skipped step, and pushback),
# and the three seeded-fault products with their healthy twins as further cases
# of /implement. The scenarios are numbers 64 to 81 in ../scenarios.md. The
# products are in ../seeded.
#
# Usage:
#   behaviour.sh --list                  the set, with the command and kind of each
#   behaviour.sh expected                the six expected paths and the seeded products
#   behaviour.sh others                  the twelve skipped-step and pushback scenarios
#   behaviour.sh all                     both
#   behaviour.sh --compare <before> <after>   the chance rule over two replay result folders
#
# Settings:
#   KIT_SRC   the kit tree to assemble and test (default: this checkout). Point it at
#             a checkout of the stable branch to run the release people use now.
#   LABEL     names the result folders, so two kits do not share one (default: new)
#   REPEATS   runs per scenario (default 5)
#   REPLAY_RESULTS, SEEDED_RESULTS   override where results go
#
# It prints nothing about cost and spends model calls only when it runs a group.
# Exit: 0 when the runs finished, 1 when a compare found a fall, 2 when a run could
# not run, or there was nothing to compare. A run the harness broke is never a pass.

set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SEEDED=$(CDPATH= cd -- "$HERE/../seeded" && pwd)

EXPECTED="64 67 70 73 76 79"
OTHERS="65 66 68 69 71 72 74 75 77 78 80 81"
PRODUCTS="03 04 08"

list() {
  printf '%s\t%s\t%s\n' "scenario" "command" "kind"
  for pair in \
    "64 setup-ai-build-kit expected" "65 setup-ai-build-kit skipped" "66 setup-ai-build-kit pushback" \
    "67 shape expected" "68 shape skipped" "69 shape pushback" \
    "70 implement expected" "71 implement skipped" "72 implement pushback" \
    "73 setup-hosting expected" "74 setup-hosting skipped" "75 setup-hosting pushback" \
    "76 maintain expected" "77 maintain skipped" "78 maintain pushback" \
    "79 what-now expected" "80 what-now skipped" "81 what-now pushback"; do
    # shellcheck disable=SC2086
    set -- $pair
    printf '%s\t%s\t%s\n' "$1" "$2" "$3"
  done
  for product in $PRODUCTS; do
    printf 'seeded %s\timplement\texpected, with a fault and a healthy twin\n' "$product"
  done
}

case "${1:-}" in
  --list)
    list
    exit 0
    ;;
  --compare)
    [ "$#" -eq 3 ] || { echo "usage: behaviour.sh --compare <before> <after>" >&2; exit 2; }
    exec sh "$HERE/compare.sh" "$2" "$3"
    ;;
  expected) groups="$EXPECTED"; products="$PRODUCTS" ;;
  others) groups="$OTHERS"; products="" ;;
  all) groups="$EXPECTED $OTHERS"; products="$PRODUCTS" ;;
  *)
    echo "usage: behaviour.sh --list | expected | others | all | --compare <before> <after>" >&2
    exit 2
    ;;
esac

LABEL=${LABEL:-new}
REPEATS=${REPEATS:-5}
export REPEATS
STATE=${XDG_STATE_HOME:-$HOME/.local/state}
REPLAY_RESULTS=${REPLAY_RESULTS:-$STATE/abk-replay/results-behaviour-$LABEL}
SEEDED_RESULTS=${SEEDED_RESULTS:-$STATE/abk-seeded/results-behaviour-$LABEL}
export REPLAY_RESULTS SEEDED_RESULTS

worst=0
note_exit() {
  code=$1
  if [ "$code" -eq 2 ]; then worst=2; elif [ "$code" -ne 0 ] && [ "$worst" -eq 0 ]; then worst=$code; fi
}

# shellcheck disable=SC2086
sh "$HERE/run.sh" $groups
note_exit $?

if [ -n "$products" ]; then
  # shellcheck disable=SC2086
  sh "$SEEDED/run.sh" $products
  note_exit $?
fi

echo
echo "Behaviour set, kit $LABEL. Replay results: $REPLAY_RESULTS"
[ -z "$products" ] || echo "Seeded results: $SEEDED_RESULTS"
exit "$worst"
