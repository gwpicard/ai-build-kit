#!/usr/bin/env sh
# run-all.sh: runs every rehearsal in this folder, one after another, and reports each by
# name.
# A check with cases it could not run prints could-not-run: <reason> and exits 2.
# Use lib/could-not-run.sh to record this and finish after the remaining cases.
# Exit 2 without a reason is a failure. Any failure still exits 1. Locally,
# incomplete checks are reported separately; on GitHub (GITHUB_ACTIONS=true)
# they also make the suite fail.
#
# A hosted job for each rehearsal names a failure on the checks list by itself,
# but a job is billed a whole minute however long it takes, and most of these
# finish in under ten seconds. Twenty five jobs cost twenty five minutes to do
# about three minutes of work. Running them here costs one job and still names
# every failure.
#
# A failing rehearsal does not stop the others. One failure must never hide
# another, so the run continues to the end and lists everything that broke.
# rehearsal-runner.sh is what proves that, since no validator can read it off
# this file the way it could read fail-fast: false off the workflow.
#
# mutate.sh audits the suite rather than passing or failing, so it is not a
# rehearsal and is not run here.
#
# Both exclusions match the leading name rather than the whole one, because a
# copy is not called run-all. A sync daemon watching this folder writes copies
# as "<name> 2.sh" and "<name> copy.sh", and a copy of this file that is not
# excluded gets run as though it were a rehearsal. It then runs the whole suite
# again and reaches its own copy again, so the run never finishes and never
# reports. A hosted job does not fail when that happens, it hangs, and it is
# billed for every minute until something cuts it off.

set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$ROOT" || exit 1

failed=""
failed_count=0
total=0
not_run_count=0
WORK=$(mktemp -d)
trap 'rm -R "$WORK"' EXIT INT TERM
: > "$WORK/not-run"

for script in .agents/tests/*.sh; do
  name=$(basename "$script" .sh)
  case "$name" in
    mutate | 'mutate '* | run-all | 'run-all '*) continue ;;
  esac

  total=$((total + 1))
  printf '\n=== %s ===\n' "$name"
  {
    status=0
    "$script" || status=$?
    printf '%s\n' "$status" > "$WORK/status"
  } 2>&1 | tee "$WORK/output"
  status=$(cat "$WORK/status")
  reasons=$(sed -n 's/^could-not-run: \(..*\)$/\1/p' "$WORK/output")
  if [ "$status" -eq 0 ]; then
    printf '  passed: %s\n' "$name"
  elif [ "$status" -eq 2 ] && [ -n "$reasons" ]; then
    printf '%s\n' "$reasons" | while IFS= read -r reason; do
      printf '  - %s: %s\n' "$name" "$reason" >> "$WORK/not-run"
    done
    printf '  could not run: %s\n' "$name"
    not_run_count=$((not_run_count + 1))
  else
    printf '  FAILED: %s\n' "$name"
    failed="$failed $name"
    failed_count=$((failed_count + 1))
  fi
done

passed_count=$((total - failed_count - not_run_count))

printf '\n===================================\n'
printf '%d of %d rehearsals passed\n' "$passed_count" "$total"

printf '%d failed; %d could not run\n' "$failed_count" "$not_run_count"
if [ "$not_run_count" -gt 0 ]; then
  printf '\nThese rehearsals could not run fully:\n'
  cat "$WORK/not-run"
fi

# GitHub supplies this variable for the rehearsal job in source-checks.yml.
if [ "${GITHUB_ACTIONS:-}" = true ] && [ "$not_run_count" -gt 0 ]; then
  printf '\nOn GitHub, rehearsals that could not run fail the job.\n'
  failed_count=$((failed_count + not_run_count))
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    printf '## Rehearsals\n\n'
    printf '%d of %d passed.\n\n' "$passed_count" "$total"
    printf '%d could not run.\n\n' "$not_run_count"
    if [ "$not_run_count" -gt 0 ]; then
      printf 'Could not run fully:\n'
      cat "$WORK/not-run"
      printf '\n'
    fi
    for name in $failed; do
      printf -- '- failed: `%s`\n' "$name"
    done
  } >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$failed_count" -gt 0 ]; then
  if [ -n "$failed" ]; then
    printf '\nThese rehearsals failed:\n'
    for name in $failed; do
      printf -- '  - %s\n' "$name"
    done
  fi
  printf '\nRun one on its own to read its output: .agents/tests/<name>.sh\n'
  exit 1
fi

if [ "$not_run_count" -eq 0 ]; then printf 'Every rehearsal passed.\n'; fi
