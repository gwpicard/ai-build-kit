#!/usr/bin/env sh
# tests-prove-change.sh: rehearse the red test, baseline run, Done when map and test freeze.
#
# A small JavaScript project keeps one promised rule in its test and one rule
# without a matching test. The tests must fail on the start commit, pass after
# the change, and name the untested promise. A later silent edit and a Trim:
# edit both fail the project hook, while a Test fix: commit records the reason.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
QUALITY="$ROOT/.agents/skills/quality-checks/scripts/quality.py"
TEMPLATE="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-tests.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PROJECT="$WORK/project"
mkdir -p "$PROJECT"
export GIT_AUTHOR_NAME=Rehearsal GIT_AUTHOR_EMAIL=rehearsal@example.invalid
export GIT_COMMITTER_NAME=Rehearsal GIT_COMMITTER_EMAIL=rehearsal@example.invalid
export QUALITY_TEST_PIECE_FILE="$WORK/piece.md"
git -C "$PROJECT" init -q -b main
git -C "$PROJECT" config user.name Rehearsal
git -C "$PROJECT" config user.email rehearsal@example.invalid
put() { mkdir -p "$(dirname "$PROJECT/$1")"; cat > "$PROJECT/$1"; }
save() { git -C "$PROJECT" add -A; git -C "$PROJECT" commit -qm "$1"; git -C "$PROJECT" rev-parse HEAD; }

# The stand-in accepts the same Vitest flags and writes JUnit and v8-shaped
# coverage. It exercises the report contract without claiming to be Vitest.
put package.json <<'EOF'
{"private":true,"scripts":{"test":"vitest run"},"devDependencies":{"vitest":"3.2.0"}}
EOF
put src/rule.js <<'EOF'
module.exports = value => value > 4;
EOF
put tools/vitest-standin.js <<'EOF'
const fs = require('node:fs');
const path = require('node:path');
const args = process.argv.slice(2);
const output = args.find(x => x.startsWith('--outputFile='))?.split('=')[1];
const cov = args.find(x => x.startsWith('--coverage.reportsDirectory='))?.split('=')[1];
const fixed = fs.readFileSync('src/rule.js', 'utf8').includes('>= 4');
const rows = [['D1 accepts four at the limit', fixed], ['D2 accepts five', true]];
const modulePresent = fs.existsSync('src/new-module.js');
if (fs.existsSync('tests/new-module.test.js')) rows.push(['D3 new module loads', modulePresent]);
if (!modulePresent && fs.existsSync('tests/new-module.test.js')) process.stderr.write("Cannot find module '../src/new-module.js'\n");
if (output) fs.writeFileSync(output, '<testsuites><testsuite>' + rows.map(([n, ok]) => `<testcase name="${n}">${ok ? '' : '<failure message="wrong result"/>'}</testcase>`).join('') + '</testsuite></testsuites>');
if (cov && !process.env.MISSING_COVERAGE) { fs.mkdirSync(cov, {recursive:true}); fs.writeFileSync(path.join(cov,'coverage-final.json'), JSON.stringify({[path.resolve('src/rule.js')]:{s:{0:process.env.ZERO_COVERAGE ? 0 : 1},statementMap:{0:{start:{line:1}}}}})); }
process.exit(process.env.FAIL_AFTER && process.cwd().endsWith('/project') ? 1 : (rows.every(row => row[1]) ? 0 : 1));
EOF
put node_modules/@vitest/coverage-v8/provider.json <<'EOF'
{"stand-in":true}
EOF
put node_modules/.bin/vitest <<'EOF'
#!/bin/sh
exec node "$PWD/tools/vitest-standin.js" "$@"
EOF
chmod +x "$PROJECT/node_modules/.bin/vitest"
BASE=$(save 'Start')
put tests/rule.test.js <<'EOF'
// test_D1_accepts_limit and test_D2_accepts_five
EOF
save 'Test: cover D1 and D2'
put src/rule.js <<'EOF'
module.exports = value => value >= 4;
EOF
PIECE=$(save 'Implement rule')
cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- Values at four are accepted
- Values at five
  are accepted
EOF
run_quality() { (cd "$PROJECT" && python3 "$QUALITY" tests --base "$BASE" --piece 1); }
set +e
OUT=$(run_quality 2>&1); CODE=$?
set -e
[ "$CODE" -eq 1 ] || { echo "$OUT"; echo 'FAIL: D2 passing before the change was not reported'; exit 1; }
printf '%s\n' "$OUT" | grep -q '^fails-before[[:space:]]D1$'
printf '%s\n' "$OUT" | grep -q '^passes-before[[:space:]]D2$'
printf '%s\n' "$OUT" | grep -q '^covered[[:space:]]1$'
echo '  ok: per-D results distinguish D1 failing before from D2 passing before'
set +e; (cd "$PROJECT" && python3 "$QUALITY" tests --base missing-commit --piece 1) >"$WORK/cannot-run.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 2 ] || { cat "$WORK/cannot-run.out"; echo 'FAIL: an unreadable start commit did not return exit 2'; exit 1; }
grep -q '^not-checked[[:space:]]tests' "$WORK/cannot-run.out"
echo '  ok: an unreadable start commit returns not-checked and exit 2'
put tests/new-module.test.js <<'EOF'
test_D3_new_module_loads()
EOF
save 'Test: cover the new module'
put src/new-module.js <<'EOF'
module.exports = () => true;
EOF
save 'Build new module'
cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- Values at four are accepted
- Values at five are accepted
- The new module loads
EOF
set +e; run_quality >"$WORK/new-module.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 1 ] || { cat "$WORK/new-module.out"; echo 'FAIL: the new-module rehearsal missed the separate D2 finding'; exit 1; }
grep -q '^fails-before[[:space:]]D3$' "$WORK/new-module.out" || { cat "$WORK/new-module.out"; echo 'FAIL: D3 was not mapped'; exit 1; }
echo '  ok: Cannot find module on the start copy is a good fail-before result'
git -C "$PROJECT" reset --hard "$PIECE" >/dev/null
cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- Values at four are accepted
- Values at five
  are accepted
EOF
cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- Values at four are accepted
EOF
set +e; ZERO_COVERAGE=1 run_quality >"$WORK/zero-coverage.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 1 ] || { cat "$WORK/zero-coverage.out"; echo 'FAIL: zero executed coverage was accepted'; exit 1; }
unset ZERO_COVERAGE
grep -q '^covered[[:space:]]0$' "$WORK/zero-coverage.out"
set +e; MISSING_COVERAGE=1 run_quality >"$WORK/missing-coverage.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 0 ] || { cat "$WORK/missing-coverage.out"; echo 'FAIL: missing coverage blocked the core read'; exit 1; }
unset MISSING_COVERAGE
grep -q '^not-checked[[:space:]]coverage[[:space:]]@vitest/coverage-v8 report is missing$' "$WORK/missing-coverage.out"
rm -rf "$PROJECT/node_modules/@vitest/coverage-v8"
set +e; run_quality >"$WORK/missing-provider.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 0 ] || { cat "$WORK/missing-provider.out"; echo 'FAIL: missing coverage provider blocked the red/green result'; exit 1; }
grep -q '^not-checked[[:space:]]coverage[[:space:]]@vitest/coverage-v8 provider is not installed$' "$WORK/missing-provider.out"
! grep -q 'report is missing' "$WORK/missing-provider.out"
put node_modules/@vitest/coverage-v8/provider.json <<'EOF'
{"stand-in":true}
EOF
set +e; FAIL_AFTER=1 run_quality >"$WORK/after-failure.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 1 ] || { cat "$WORK/after-failure.out"; echo 'FAIL: after-run failure was accepted'; exit 1; }
unset FAIL_AFTER
echo '  ok: zero coverage, missing reports or providers, and a failed after-run are handled'

put tests/skip.test.js <<'EOF'
describe.skip('D3 skipped block', () => {});
it.only('D4 focused case', () => {});
it.skip('D5 skipped it', () => {});
test.skip('D6 skipped test', () => {});
xit('D7 skipped alias', () => {});
@pytest.mark.skip
def test_D8_skip(): pass
@unittest.skip
def test_D9_skip(): pass
EOF
save 'Test: add skip forms'
cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- Values at four are accepted
- Values at five are accepted
- A skipped D3 behaviour is available
EOF
set +e; run_quality >"$WORK/skips.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 1 ] || { cat "$WORK/skips.out"; echo 'FAIL: focused or skipped tests were accepted'; exit 1; }
grep -q '^skipped[[:space:]]tests/skip.test.js:' "$WORK/skips.out"
grep -q '^untested[[:space:]]D3' "$WORK/skips.out"
echo '  ok: focused and skipped forms are reported, and skipped D3 is untested'
rm "$PROJECT/tests/skip.test.js"
git -C "$PROJECT" add -A; git -C "$PROJECT" commit -qm 'Test fix: remove the deliberate skip fixture'

CURRENT=$(git -C "$PROJECT" rev-parse HEAD)
cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- The page shows the updated heading (try it)
EOF
OUT=$(cd "$PROJECT" && python3 "$QUALITY" tests --base "$CURRENT" --piece 3)
printf '%s\n' "$OUT" | grep -q 'visual-only piece'
cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- Existing results remain the same

## Under the hood
Kind: refactor
EOF
OUT=$(cd "$PROJECT" && python3 "$QUALITY" tests --base "$CURRENT" --piece 4)
printf '%s\n' "$OUT" | grep -q '^tests[[:space:]]passed$'
echo '  ok: visual-only and behaviour-preserving refactor exemptions work'

# Real tools are preferred when installed offline. The stand-in above covers
# the real output shape when they are absent.
if python3 -c 'import subprocess,sys; sys.exit(subprocess.run(["npx","--no-install","vitest","--version"],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=12).returncode)' 2>/dev/null; then echo '  available: real Vitest'; else echo '  not available: real Vitest, stand-in report used'; fi
if python3 -c 'import subprocess,sys; sys.exit(subprocess.run([sys.executable,"-m","pytest","--version"],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=12).returncode)' 2>/dev/null; then echo '  available: real pytest'; else echo '  not available: real pytest, pytest case skipped'; fi

# The hook's Git subject logic: body-only tags do not count, and Test fix needs a reason.
HOOK="$PROJECT/.agents/hooks/check-tests.sh"
mkdir -p "$(dirname "$HOOK")"
cp "$TEMPLATE" "$HOOK"
RED="$BASE..HEAD"
put tests/second.test.js <<'EOF'
test('D1 extra', () => {});
EOF
ADDED=$(save 'Test: add later case')
(cd "$PROJECT" && sh "$HOOK" "$BASE..HEAD")
put tests/second.test.js <<'EOF'
test('D1 changed', () => {});
EOF
save 'Test: change later case'
set +e; (cd "$PROJECT" && sh "$HOOK" "$BASE..HEAD") >/dev/null 2>&1; CODE=$?; set -e
[ "$CODE" -eq 1 ] || { echo 'FAIL: later Test commit changed a frozen line'; exit 1; }
echo '  ok: a later Test commit may add, but may not change, a frozen test line'
git -C "$PROJECT" reset --hard "$ADDED" >/dev/null
put tests/second.test.js <<'EOF'
test('D1 extra', () => {});
test('D2 added with reason', () => {});
EOF
REASONED=$(save 'Test fix: add the missing D2 case')
(cd "$PROJECT" && sh "$HOOK" "$BASE..HEAD")
echo '  ok: a Test fix subject with a reason can change a frozen test'
git -C "$PROJECT" reset --hard "$ADDED" >/dev/null
put tests/second.test.js <<'EOF'
test('D1 extra', () => {});
test('D2 body tag', () => {});
EOF
git -C "$PROJECT" add -A
git -C "$PROJECT" commit -qm 'Ordinary edit' -m 'Trim: body-only tag'
set +e; (cd "$PROJECT" && sh "$HOOK" "$BASE..HEAD") >"$WORK/body-tag.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 1 ] && ! grep -q 'trim commit' "$WORK/body-tag.out" || { cat "$WORK/body-tag.out"; echo 'FAIL: commit body was treated as its subject'; exit 1; }
echo '  ok: a Trim tag in a commit body is not a Trim subject'
git -C "$PROJECT" reset --hard "$ADDED" >/dev/null
put tests/second.test.js <<'EOF'
test('D1 extra', () => {});
test('D2 new', () => {});
EOF
save 'Test fix:'
set +e; (cd "$PROJECT" && sh "$HOOK" "$BASE..HEAD") >/dev/null 2>&1; CODE=$?; set -e
[ "$CODE" -eq 1 ] || { echo 'FAIL: empty Test fix reason was accepted'; exit 1; }
echo '  ok: an empty Test fix reason is rejected'

mkdir -p "$WORK/pytest-project/bin" "$WORK/pytest-project/tests"
PY="$WORK/pytest-project"
cat > "$PY/AGENTS.md" <<'EOF'
Test: bin/pytest
EOF
cat > "$PY/app.py" <<'EOF'
value = 1
EOF
cat > "$PY/tests/test_app.py" <<'EOF'
def test_D1_value(): pass
EOF
cat > "$PY/bin/pytest" <<'EOF'
#!/usr/bin/env python3
import json, os, sys
args=sys.argv[1:]
xml=next(x.split('=',1)[1] for x in args if x.startswith('--junitxml='))
ok=open('app.py').read().strip() == 'value = 1'
open(xml,'w').write('<testsuites><testsuite><testcase name="test_D1_value" classname="D1">'+('' if ok else '<failure/>')+'</testcase></testsuite></testsuites>')
for x in args:
 if x.startswith('--cov-report=json:'):
  path=x.split(':',1)[1]; json.dump({'files':{'app.py':{'executed_lines':[1], 'missing_lines':[]}}},open(path,'w'))
EOF
chmod +x "$PY/bin/pytest"
mkdir -p "$WORK/fake-pytest-cov"
touch "$WORK/fake-pytest-cov/pytest_cov.py" "$WORK/fake-pytest-cov/coverage.py"
export PYTHONPATH="$WORK/fake-pytest-cov${PYTHONPATH:+:$PYTHONPATH}"
git -C "$PY" init -q -b main
git -C "$PY" config user.name Rehearsal; git -C "$PY" config user.email rehearsal@example.invalid
rm "$PY/AGENTS.md" "$PY/tests/test_app.py"
printf 'value = 0\n' > "$PY/app.py"
git -C "$PY" add -A; git -C "$PY" commit -qm Start
PYBASE=$(git -C "$PY" rev-parse HEAD)
printf 'Test: bin/pytest\n' > "$PY/AGENTS.md"
printf 'def test_D1_value(): pass\n' > "$PY/tests/test_app.py"
git -C "$PY" add -A; git -C "$PY" commit -qm 'Test: add D1'
printf 'value = 1\n' > "$PY/app.py"
git -C "$PY" add app.py; git -C "$PY" commit -qm 'Implement value'
cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- The value is one
EOF
OUT=$(cd "$PY" && python3 "$QUALITY" tests --base "$PYBASE" --piece 2)
printf '%s\n' "$OUT" | grep -q '^fails-before[[:space:]]D1$'
printf '%s\n' "$OUT" | grep -q '^covered[[:space:]]1$'
echo '  ok: recorded Python command, JUnit results and coverage.py JSON are read'

echo 'tests-prove-change.sh: Vitest report contract, per-D output and test subject guard checked'
