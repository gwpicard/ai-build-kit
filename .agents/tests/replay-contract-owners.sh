#!/usr/bin/env sh
# replay-contract-owners.sh: keep replay-only mutation owners present and named.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
AUDIT="$ROOT/.agents/tests/mutation-audit.md"
SCENARIOS="$ROOT/.agents/tests/scenarios.md"
MUTATE="$ROOT/.agents/tests/mutate.sh"

check_owner() {
  mutation=$1
  case_number=$2
  audit_claim=$3
  case_claim=$4
  scenario_claim=$5
  case_file=$(printf '%s/.agents/tests/replay/cases/%02d.txt' "$ROOT" "$case_number")

  [ -f "$case_file" ] \
    || { echo "FAIL: replay owner case $case_number is missing" >&2; exit 1; }
  grep -Fq "| \`$mutation\` | $case_number |" "$AUDIT" \
    || { echo "FAIL: $mutation is not named as owned by case $case_number in the audit" >&2; exit 1; }
  grep -Fq "$audit_claim" "$AUDIT" \
    || { echo "FAIL: audit no longer states what case $case_number covers" >&2; exit 1; }
  grep -Fq "$case_claim" "$case_file" \
    || { echo "FAIL: case $case_number no longer describes the owned behaviour" >&2; exit 1; }
  grep -Fq "## $case_number." "$SCENARIOS" \
    || { echo "FAIL: scenario contract for case $case_number is missing" >&2; exit 1; }
  grep -Fq "$scenario_claim" "$SCENARIOS" \
    || { echo "FAIL: scenario $case_number no longer measures the owned behaviour" >&2; exit 1; }
  grep -Fq "$mutation) replay_owner=$case_number" "$MUTATE" \
    || { echo "FAIL: mutate.sh no longer reports $mutation as owned by case $case_number" >&2; exit 1; }
}

check_owner build-nothing-mark 45 \
  'A build moves the masterplan mark' \
  'normal save must leave its prose alone and move the mark' \
  'saved mark moves to the commit with the test'
check_owner founding-starter-refusal 58 \
  'Founding waits before writing replacement starter files' \
  'harness refused the Next.js starter command' \
  'writing starter files before the yes'
check_owner prelaunch-migration-route 59 \
  'A pre-launch migration goes through' \
  'Before any database change, tell me the one route' \
  'names `/setup-hosting` as the only route'

echo "PASS: replay-only mutation promises still have named cases and contracts"
