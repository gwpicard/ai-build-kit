#!/usr/bin/env sh
# could-not-run.sh: guard incomplete rehearsals, their reasons and the stricter GitHub result.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -R "$WORK"' EXIT INT TERM
fail() { cat "$WORK/out" >&2; echo "FAIL: $1" >&2; exit 1; }
run() {
  status=0
  "$@" > "$WORK/out" 2>&1 || status=$?
}

# Exercise the real coverage reader with a pytest stand-in. Other Python calls
# use the normal interpreter, so every later contract and hook case still runs.
PYTHON_REAL=$(command -v python3)
export PYTHON_REAL
cat > "$WORK/python-selected" <<'STUB'
#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
if args[:2] != ['-m', 'pytest']:
    os.execv(os.environ['PYTHON_REAL'], [os.environ['PYTHON_REAL'], *args])
mode = os.environ.get('COVERAGE_CASE', 'absent')
if '--help' in args:
    print('pytest' if mode == 'absent' else '--cov --cov-report=TYPE json xml html')
    sys.exit(0)
report = next(arg.split('=', 1)[1] for arg in args if arg.startswith('--junitxml='))
ok = 'return 2' in pathlib.Path('app.py').read_text()
pathlib.Path(report).write_text('<testsuites><testsuite><testcase name="test_D1_value">' +
                              ('' if ok else '<failure/>') + '</testcase></testsuite></testsuites>')
if mode == 'present':
    for arg in args:
        if arg.startswith('--cov-report=json:'):
            pathlib.Path(arg.split(':', 1)[1]).write_text(json.dumps({
                'files': {'app.py': {'executed_lines': [1, 2], 'missing_lines': []}}}))
sys.exit(0 if ok else 1)
STUB
chmod +x "$WORK/python-selected"
for mode in absent present missing-report; do
  run env COVERAGE_CASE="$mode" PYTHON_BIN="$WORK/python-selected" \
    PYTEST_BIN=/nonexistent PYTEST_NOCOV_BIN= VITEST_BIN=/nonexistent \
    "$ROOT/.agents/tests/tests-prove-change.sh"
  case "$mode" in
    absent)
      [ "$status" -eq 2 ] || fail "pytest without pytest-cov did not return 2"
      grep -q '^could-not-run: real pytest coverage: pytest-cov' "$WORK/out" || fail "missing pytest-cov reason"
      grep -q '^tests-prove-change.sh: Vitest report contract' "$WORK/out" || fail "cases after missing coverage did not finish"
      ;;
    present) [ "$status" -eq 0 ] || fail "available pytest-cov did not pass" ;;
    missing-report) [ "$status" -eq 1 ] || fail "available pytest-cov with missing coverage did not fail" ;;
  esac
done

# No starter, package or database command may run when Docker is unavailable.
mkdir -p "$WORK/bin"
cat > "$WORK/bin/docker" <<'STUB'
#!/bin/sh
[ "$*" = info ] || exit 99
printf 'info\n' >> "$DOCKER_CALLS"
exit 1
STUB
cat > "$WORK/bin/sh" <<'STUB'
#!/bin/sh
printf 'unexpected starter command\n' >> "$DOCKER_CALLS"
exit 99
STUB
chmod +x "$WORK/bin/docker" "$WORK/bin/sh"
run env PATH="$WORK/bin:$PATH" DOCKER_CALLS="$WORK/docker-calls" \
  /bin/sh "$ROOT/.agents/tests/recipe-ci-rehearsal.sh"
[ "$status" -eq 2 ] || fail "unavailable Docker did not return 2"
grep -q '^could-not-run: .*Docker' "$WORK/out" || fail "missing Docker reason"
[ "$(cat "$WORK/docker-calls")" = info ] || fail "database preparation ran without Docker"

# The runner already supports a small fixture by copying it into a test tree.
TESTS="$WORK/tree/.agents/tests"
mkdir -p "$TESTS"
cp "$ROOT/.agents/tests/run-all.sh" "$TESTS/run-all.sh"
printf '#!/bin/sh\nexit 0\n' > "$TESTS/a-pass.sh"
printf '#!/bin/sh\necho "could-not-run: tool missing"\nexit 2\n' > "$TESTS/b-unavailable.sh"
chmod +x "$TESTS/"*.sh
for github in false true; do
  : > "$WORK/summary"
  run env GITHUB_ACTIONS="$github" GITHUB_STEP_SUMMARY="$WORK/summary" "$TESTS/run-all.sh"
  if [ "$github" = true ]; then
    [ "$status" -eq 1 ] || fail "GitHub accepted an incomplete rehearsal"
  else
    [ "$status" -eq 0 ] || fail "local incomplete rehearsal failed the suite"
  fi
  grep -q '1 of 2 rehearsals passed' "$WORK/out" || fail "incomplete rehearsal counted as passed"
  grep -q '0 failed; 1 could not run' "$WORK/out" || fail "incomplete rehearsal counted as failed"
  grep -q 'b-unavailable: tool missing' "$WORK/out" || fail "console summary lost the reason"
  grep -q 'b-unavailable: tool missing' "$WORK/summary" || fail "GitHub summary lost the reason"
  ! grep -q 'Every rehearsal passed' "$WORK/out" || fail "incomplete suite claimed every rehearsal passed"
done
printf '#!/bin/sh\necho "could-not-run: optional tool missing"\nexit 1\n' > "$TESTS/c-failure.sh"
chmod +x "$TESTS/c-failure.sh"
run env GITHUB_ACTIONS=false "$TESTS/run-all.sh"
[ "$status" -eq 1 ] || fail "local failures no longer fail the suite"
grep -q '1 failed; 1 could not run' "$WORK/out" || fail "failure did not take precedence over a reason line"
grep -q 'c-failure' "$WORK/out" || fail "failure disappeared from the summary"
printf '#!/bin/sh\nexit 2\n' > "$TESTS/d-unexplained.sh"
chmod +x "$TESTS/d-unexplained.sh"
run env GITHUB_ACTIONS=false "$TESTS/run-all.sh"
[ "$status" -eq 1 ] || fail "an unexplained exit 2 passed locally"
grep -q '2 failed; 1 could not run' "$WORK/out" || fail "an unexplained exit 2 was treated as incomplete"
echo 'could-not-run.sh: missing coverage, unavailable Docker and both suite policies checked'
