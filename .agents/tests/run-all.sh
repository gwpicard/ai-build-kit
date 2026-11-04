#!/usr/bin/env sh
# run-all.sh: run every rehearsal, retaining failures and incomplete results.
# Two workers share only tests with isolated fixtures. All other tests run alone.
# REHEARSAL_JOBS=1 gives a serial run for diagnosis and comparison.
# Exit 2 needs a could-not-run reason; on GitHub incomplete tests fail the job.
# Copies of this runner and mutate are excluded to prevent recursive runs.

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

# Keep discovery here: adding a test always adds it to the suite.
for script in .agents/tests/*.sh; do
  name=$(basename "$script" .sh)
  case "$name" in
    mutate | 'mutate '* | run-all | 'run-all '*) continue ;;
  esac
  printf '%s\n' "$script"
done > "$WORK/scripts"

python3 - "$WORK" "${REHEARSAL_JOBS:-2}" <<'PYTHON' || exit 1
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import os
import signal
import subprocess
import sys
import threading
import time

work = Path(sys.argv[1])
if sys.argv[2] not in ('1', '2'):
    sys.exit('REHEARSAL_JOBS must be 1 or 2')
workers = int(sys.argv[2])
scripts = work.joinpath('scripts').read_text().splitlines()
# These tests write to disposable projects and use local service stand-ins.
# Only recipe-ci starts a database or installs a browser in this group.
# Browser interface tests and unclassified tests run alone after this group.
parallel = (
    'recipe-ci-rehearsal', 'replay-case-states', 'check-floor-rehearsal',
    'piece-labels', 'replay-state', 'test-strength-rehearsal', 'found-issues',
    'could-not-run', 'upload-piece', 'upgrade-rehearsal',
    'recipe-nextjs-supabase-on-vercel', 'mark-ready', 'trim-rehearsal',
    'secrets-gates', 'check-tooling', 'replay-preflight',
    'recipe-nextjs-supabase-on-coolify', 'first-upload',
)
lock = threading.Lock()
children = set()

def stop(signum, frame):
    # Each child owns its process group. Never signal another running programme.
    for child in tuple(children):
        try:
            os.killpg(child.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    raise SystemExit(128 + signum)

signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)

def run(script):
    name = Path(script).stem
    before = time.monotonic()
    with lock:
        print(f'Starting: {name}', flush=True)
    with work.joinpath(name + '.output').open('w') as output:
        try:
            child = subprocess.Popen([script], stdout=output, stderr=subprocess.STDOUT,
                                     start_new_session=True)
            children.add(child)
            status = child.wait()
            children.discard(child)
        except OSError as error:
            output.write(f'Could not start rehearsal: {error}\n')
            status = 1
    elapsed = time.monotonic() - before
    work.joinpath(name + '.status').write_text(str(status))
    work.joinpath(name + '.seconds').write_text(f'{elapsed:.3f}')
    with lock:
        print(f'\n=== {name} ===', flush=True)
        print(work.joinpath(name + '.output').read_text(errors='replace'), end='', flush=True)
        print(f'Time: {name} | {elapsed:.3f} s | exit {status}', flush=True)

if workers == 1:
    for script in scripts:
        run(script)
else:
    selected = sorted((s for s in scripts if Path(s).stem in parallel),
                      key=lambda s: parallel.index(Path(s).stem))
    with ThreadPoolExecutor(max_workers=workers) as pool:
        list(pool.map(run, selected))
    for script in scripts:
        if Path(script).stem not in parallel:
            run(script)
PYTHON

while IFS= read -r script; do
  name=$(basename "$script" .sh)
  total=$((total + 1))
  status=$(cat "$WORK/$name.status")
  reasons=$(sed -n 's/^could-not-run: \(..*\)$/\1/p' "$WORK/$name.output")
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
done < "$WORK/scripts"

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

# Timings are measured inside each worker, so parallel output cannot distort them.
python3 - "$WORK" <<'PYTHON'
from pathlib import Path
import os
import sys
work = Path(sys.argv[1])
rows = sorted(((float(p.read_text()), p.stem) for p in work.glob('*.seconds')), reverse=True)
report = '\n| Rehearsal | Seconds |\n|---|---:|\n'
report += ''.join(f'| {name} | {seconds:.3f} |\n' for seconds, name in rows)
print(report)
if os.environ.get('GITHUB_STEP_SUMMARY'):
    with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as summary:
        summary.write(report)
PYTHON

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
