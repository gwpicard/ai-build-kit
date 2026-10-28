#!/usr/bin/env sh
# tests-prove-change.sh: rehearse the red test, baseline run, Done when map and test freeze.
#
# A small JavaScript project keeps one promised rule in its test and one rule
# without a matching test. The tests must fail on the start commit, pass after
# the change, and name the untested promise. A later silent edit and a Trim:
# edit both fail the project hook, while a Test fix: commit records the reason.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/could-not-run.sh"
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

# Use real Vitest when installed. The fallback report stand-in mirrors Vitest's
# JUnit shape, including module errors that appear only in XML.
put package.json <<'EOF'
{"private":true,"scripts":{"test":"vitest run"},"devDependencies":{"vitest":"3.2.0"}}
EOF
put .gitignore <<'EOF'
node_modules/
EOF
put masterplan.md <<'EOF'
Risk areas:
  Data:
    paths: src
EOF
put src/rule.js <<'EOF'
module.exports = value => value > 4;
EOF
put tests/legacy.test.js <<'EOF'
import { it } from 'vitest';
it.skip('old skipped case remains untouched', () => {});
EOF
put tools/vitest-standin.js <<'EOF'
const fs = require('node:fs');
const path = require('node:path');
const args = process.argv.slice(2);
const output = args.find(x => x.startsWith('--outputFile='))?.split('=')[1];
const cov = args.find(x => x.startsWith('--coverage.reportsDirectory='))?.split('=')[1];
const fixed = fs.readFileSync('src/rule.js', 'utf8').includes('>= 4');
const rows = process.env.REFRACTOR ? [] : [['D1 accepts four at the limit', fixed && !process.env.FAIL_D1_AFTER], ['D2 accepts five', true]];
const modulePresent = fs.existsSync('src/new-module.js');
if (fs.existsSync('tests/new-module.test.js')) rows.push(['D3 new module loads', modulePresent]);
if (output) fs.writeFileSync(output, '<testsuites><testsuite>' + rows.map(([n, ok]) => `<testcase name="${n}">${ok ? '' : `<failure message="${n.startsWith('D3') ? 'Failed to load: Cannot find module' : 'wrong result'}">${n.startsWith('D3') ? 'Cannot find module ../src/new-module.js' : 'wrong result'}</failure>`}</testcase>`).join('') + '</testsuite></testsuites>');
if (cov && !process.env.MISSING_COVERAGE) { fs.mkdirSync(cov, {recursive:true}); fs.writeFileSync(path.join(cov,'coverage-final.json'), JSON.stringify({[path.resolve('src/rule.js')]:{s:{0:process.env.ZERO_COVERAGE ? 0 : 1},statementMap:{0:{start:{line:1}}}}})); }
process.exit(process.env.FAIL_AFTER && process.cwd().endsWith('/project') ? 1 : (rows.every(row => row[1]) ? 0 : 1));
EOF
mkdir -p "$WORK/bin"
cat > "$WORK/bin/vitest" <<'EOF'
#!/bin/sh
exec node "$PWD/tools/vitest-standin.js" "$@"
EOF
chmod +x "$WORK/bin/vitest"
VITEST_BIN=${VITEST_BIN:-$(command -v vitest || true)}
PYTHON_BIN=${PYTHON_BIN:-$(command -v python3 || true)}
PYTEST_BIN=${PYTEST_BIN:-$(command -v pytest || true)}
PYTEST_COMMAND=
PYTEST_READY=0
if [ -n "$PYTHON_BIN" ] && (ulimit -c 0; "$PYTHON_BIN" -m pytest --help >/dev/null 2>&1); then
  PYTEST_COMMAND="$PYTHON_BIN -m pytest"
  PYTEST_READY=1
elif [ -n "$PYTEST_BIN" ] && (ulimit -c 0; sh -c "$PYTEST_BIN --help" >/dev/null 2>&1); then
  PYTEST_COMMAND="$PYTEST_BIN"
  PYTEST_READY=1
fi
PYTEST_NOCOV_BIN=${PYTEST_NOCOV_BIN:-}
if [ -n "$VITEST_BIN" ] && [ -x "$VITEST_BIN" ]; then
  VITEST_REAL=$(realpath "$VITEST_BIN")
  VITEST_PACKAGE=$(dirname "$VITEST_REAL")
  echo '  available: real Vitest'
else
  echo '  not available: real Vitest; using a report stand-in for contract cases'
fi
mkdir -p "$PROJECT/node_modules/@vitest/coverage-v8"
printf '%s\n' '{"name":"@vitest/coverage-v8","version":"0.0.0"}' > "$PROJECT/node_modules/@vitest/coverage-v8/package.json"
PATH="$WORK/bin:$PATH"
export PATH
BASE=$(save 'Start')
put tests/rule.test.js <<'EOF'
import { test, expect } from 'vitest';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
test('D1 accepts four at the limit', () => expect(require('../src/rule.js')(4)).toBe(true));
test('D2 accepts five', () => expect(require('../src/rule.js')(5)).toBe(true));
EOF
save 'Test: cover D1 and D2'
put src/rule.js <<'EOF'
module.exports = value => value >= 4;
EOF
put "src/my tests/space.js" <<'EOF'
module.exports = 'space';
EOF
PIECE=$(save 'Implement rule')
cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
### Done when
1. Values at four are accepted
2. Values at five
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
printf '%s\n' "$OUT" | grep -q '^uncovered[[:space:]]src/my tests/space.js:'
! printf '%s\n' "$OUT" | grep -q '^skipped[[:space:]]tests/legacy.test.js'
printf '%s\n' "$OUT" | grep -q '^not-checked[[:space:]]strength[[:space:]]StrykerJS is not installed$'
echo '  ok: per-D results distinguish D1 failing before from D2 passing before'
echo '  ok: paths with spaces are parsed and an old skip in an untouched test is ignored'
set +e; (cd "$PROJECT" && python3 "$QUALITY" tests --base missing-commit --piece 1) >"$WORK/cannot-run.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 2 ] || { cat "$WORK/cannot-run.out"; echo 'FAIL: an unreadable start commit did not return exit 2'; exit 1; }
grep -q '^not-checked[[:space:]]tests' "$WORK/cannot-run.out"
echo '  ok: an unreadable start commit returns not-checked and exit 2'
cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
### Done when
EOF
set +e; run_quality >"$WORK/no-done.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 1 ] || { cat "$WORK/no-done.out"; echo 'FAIL: empty Done when passed'; exit 1; }
grep -q '^not-checked[[:space:]]tests[[:space:]]no Done when lines found$' "$WORK/no-done.out"
echo '  ok: a behaviour piece with no Done when lines fails explicitly'
python3 - "$QUALITY" <<'PY'
import importlib.util, sys
sys.dont_write_bytecode = True
import os, tempfile
spec = importlib.util.spec_from_file_location("quality", sys.argv[1])
quality = importlib.util.module_from_spec(spec)
spec.loader.exec_module(quality)
plan = "Risk areas:\n  one: first area\n    paths: src/one/\n  two: second area\n    paths: src/two/\n"
assert quality.mapped_paths(plan) == ["src/one/", "src/two/"]
with tempfile.TemporaryDirectory() as root:
    os.makedirs(os.path.join(root, "tests"))
    with open(os.path.join(root, "tests", "screen.spec.ts"), "w") as spec_file:
        spec_file.write("test('D9 screen renders', () => {});\n")
    assert quality.playwright_specs(root, ["tests/screen.spec.ts"]) == {9: ["tests/screen.spec.ts"]}
    with open(os.path.join(root, "AGENTS.md"), "w") as agents:
        agents.write("## Stack, and how to run and check it\nTests: bin/pytest\n")
    os.makedirs(os.path.join(root, ".github", "workflows"))
    with open(os.path.join(root, ".github", "workflows", "checks.yml"), "w") as workflow:
        workflow.write("jobs:\n  check:\n    steps:\n      - run: npm test\n")
    assert quality.test_command(root) == ["bin/pytest"]
with tempfile.TemporaryDirectory() as root:
    with open(os.path.join(root, "AGENTS.md"), "w") as agents:
        agents.write("## Stack, and how to run and check it\n")
    os.makedirs(os.path.join(root, ".github", "workflows"))
    with open(os.path.join(root, ".github", "workflows", "checks.yml"), "w") as workflow:
        workflow.write("jobs:\n  project-check:\n    steps:\n      - name: Recipe tests\n        if: steps.recipe.outputs.selected == 'true'\n        run: |\n          npx vitest run --coverage\n      - name: Python tests\n        run: pytest -q\n")
    assert quality.test_command(root) == ["pytest", "-q"]
    binary = os.path.join(root, "bin")
    os.makedirs(binary)
    pytest = os.path.join(binary, "pytest")
    python = os.path.join(binary, "python3")
    open(pytest, "w").close()
    open(python, "w").close()
    os.chmod(python, 0o755)
    assert quality.pytest_module_command([pytest, "-q"]) == [python, "-m", "pytest", "-q"]
PY
echo '  ok: the strength trigger reads both mapped areas and finds default-folder Playwright cases'
echo '  ok: an absolute pytest launcher uses its sibling Python module runner'
put tests/new-module.test.js <<'EOF'
import { test, expect } from 'vitest';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const newModule = require('../src/new-module.js');
test('D3 new module loads', () => expect(newModule()).toBe(true));
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
set +e; FAIL_D1_AFTER=1 run_quality >"$WORK/d1-after-failure.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 1 ] || { cat "$WORK/d1-after-failure.out"; echo 'FAIL: D1 failing both before and after was accepted'; exit 1; }
grep -q '^fails-after[[:space:]]D1$' "$WORK/d1-after-failure.out"
echo '  ok: zero coverage, missing reports or providers, and a D failure after the build are handled'

if [ -n "$VITEST_BIN" ] && [ -x "$VITEST_BIN" ]; then
  REAL="$WORK/real-vitest"
  mkdir -p "$REAL/src"
  git -C "$REAL" init -q -b main
  git -C "$REAL" config user.name Rehearsal; git -C "$REAL" config user.email rehearsal@example.invalid
  printf '%s\n' '{"private":true,"scripts":{"test":"vitest run"},"devDependencies":{"vitest":"3.2.7"}}' > "$REAL/package.json"
  printf 'node_modules/\n' > "$REAL/.gitignore"
  VITEST_NM=$(dirname "$VITEST_PACKAGE")
  ln -s "$VITEST_NM" "$REAL/node_modules"
  printf 'export const total = () => 1;\n' > "$REAL/src/total.js"
  printf 'export const oldValue = () => 1;\n' > "$REAL/src/old.js"
  git -C "$REAL" add -A; git -C "$REAL" commit -qm Start
  REALBASE=$(git -C "$REAL" rev-parse HEAD)
  cat > "$REAL/src/total.test.js" <<'EOF'
import { test, expect } from 'vitest';
import { total } from './total.js';
test('D1 returns the updated total', () => expect(total()).toBe(2));
EOF
  git -C "$REAL" add -A; git -C "$REAL" commit -qm 'Test: add D1'
  printf 'export const total = () => 2;\n' > "$REAL/src/total.js"
  git -C "$REAL" add -A; git -C "$REAL" commit -qm 'Build the total'
  cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- The total is updated
EOF
  set +e; REAL_OUT=$(cd "$REAL" && python3 "$QUALITY" tests --base "$REALBASE" --piece 399 2>&1); CODE=$?; set -e
  [ "$CODE" -eq 0 ] || { printf '%s\n' "$REAL_OUT"; echo 'FAIL: real Vitest did not prove the change'; exit 1; }
  printf '%s\n' "$REAL_OUT" | grep -q '^fails-before[[:space:]]D1$'
  printf '%s\n' "$REAL_OUT" | grep -q '^covered[[:space:]]1$'
  echo '  ok: real Vitest 3.2.7 runs on the linked project dependencies and proves D1'
  cat > "$REAL/src/missing.test.js" <<'EOF'
import { test, expect } from 'vitest';
import { missing } from './missing.js';
test('D2 loads the new module', () => expect(missing()).toBe(true));
EOF
  cat > "$REAL/src/old.test.js" <<'EOF'
import { test, expect } from 'vitest';
import { oldValue } from './old.js';
test('D3 keeps the old value', () => expect(oldValue()).toBe(1));
EOF
  git -C "$REAL" add -A; git -C "$REAL" commit -qm 'Test: add D2 module load'
  printf 'export const missing = () => true;\n' > "$REAL/src/missing.js"
  git -C "$REAL" add -A; git -C "$REAL" commit -qm 'Build the missing module'
  cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- The total is updated
- The new module loads
- The old total remains
EOF
  set +e; REAL_OUT=$(cd "$REAL" && python3 "$QUALITY" tests --base "$REALBASE" --piece 399 2>&1); CODE=$?; set -e
  [ "$CODE" -eq 1 ] || { printf '%s\n' "$REAL_OUT"; echo 'FAIL: the already-passing D3 or missing-module D2 was misclassified'; exit 1; }
  printf '%s\n' "$REAL_OUT" | grep -q '^fails-before[[:space:]]D2$'
  printf '%s\n' "$REAL_OUT" | grep -q '^passes-before[[:space:]]D3$'
  echo '  ok: a JUnit module failure maps only to D2 in its file; D3 in another file remains passes-before'
fi

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
OUT=$(cd "$PROJECT" && REFRACTOR=1 python3 "$QUALITY" tests --base "$CURRENT" --piece 4)
printf '%s\n' "$OUT" | grep -q '^tests[[:space:]]passed$'
echo '  ok: visual-only and behaviour-preserving refactor exemptions work'

if [ "$PYTEST_READY" -eq 1 ]; then echo '  available: real pytest'; else echo '  not available: real pytest runner could not start'; fi

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
put tests/second.test.js <<'EOF'
test('D1 renamed with a reason', () => {});
test('D2 added after rename', () => {});
EOF
save 'Test fix: rename the frozen case'
put tests/second.test.js <<'EOF'
test('D1 renamed with a reason', () => {});
test('D2 added after rename', () => {});
test('D3 later addition', () => {});
EOF
save 'Test: add a line after the rename'
(cd "$PROJECT" && sh "$HOOK" "$BASE..HEAD")
echo '  ok: a later Test addition is compared with its parent after a Test fix rename'
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
git -C "$PROJECT" reset --hard "$ADDED" >/dev/null
put tests/sign.test.js <<'EOF'
-1;
EOF
save 'Test: add a minus-leading line'
put tests/sign.test.js <<'EOF'
1;
EOF
save 'Test: remove a minus-leading line'
set +e; (cd "$PROJECT" && sh "$HOOK" "$BASE..HEAD") >"$WORK/minus-line.out" 2>&1; CODE=$?; set -e
[ "$CODE" -eq 1 ] || { cat "$WORK/minus-line.out"; echo 'FAIL: a deleted line starting with a minus was missed'; exit 1; }
grep -q 'sign.test.js' "$WORK/minus-line.out"
echo '  ok: the freeze catches a deleted test line whose text starts with a minus'

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
if '--help' in args:
 print('--cov and --cov-report=TYPE supports term, xml, and html reports' if os.environ.get('OLD_COV') else '--cov and --cov-report=TYPE supports term, xml, json, and html reports')
 sys.exit(0)
xml=next(x.split('=',1)[1] for x in args if x.startswith('--junitxml='))
ok=open('app.py').read().strip() == 'value = 1'
open(xml,'w').write('<testsuites><testsuite><testcase name="test_D1_value" classname="D1">'+('' if ok else '<failure/>')+'</testcase></testsuite></testsuites>')
for x in args:
 if x.startswith('--cov-report=json:'):
  path=x.split(':',1)[1]; json.dump({'files':{'app.py':{'executed_lines':[1], 'missing_lines':[]}}},open(path,'w'))
EOF
chmod +x "$PY/bin/pytest"
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

set +e; REALPY_OUT=$(cd "$PY" && OLD_COV=1 python3 "$QUALITY" tests --base "$PYBASE" --piece 2 2>&1); CODE=$?; set -e
[ "$CODE" -eq 0 ] || { printf '%s\n' "$REALPY_OUT"; echo 'FAIL: pytest-cov without JSON blocked the test read'; exit 1; }
[ "$(printf '%s\n' "$REALPY_OUT" | grep -c '^not-checked[[:space:]]coverage')" -eq 1 ]
printf '%s\n' "$REALPY_OUT" | grep -q '^not-checked[[:space:]]coverage[[:space:]]installed pytest-cov does not support JSON output$'
printf '%s\n' "$REALPY_OUT" | grep -q '^fails-before[[:space:]]D1$'
echo '  ok: pytest-cov without JSON prints one coverage line and keeps the read at exit 0'

if [ "$PYTEST_READY" -eq 1 ]; then
  REALPY="$WORK/real-pytest"
  mkdir -p "$REALPY/tests"
  git -C "$REALPY" init -q -b main
  git -C "$REALPY" config user.name Rehearsal; git -C "$REALPY" config user.email rehearsal@example.invalid
  printf 'def value():\n    return 1\n' > "$REALPY/app.py"
  printf '[tool.pytest.ini_options]\n' > "$REALPY/pyproject.toml"
  mkdir -p "$REALPY/.github/workflows"
  printf 'jobs:\n  project-check:\n    steps:\n      - run: %s -q\n' "$PYTEST_COMMAND" > "$REALPY/.github/workflows/checks.yml"
  git -C "$REALPY" add -A; git -C "$REALPY" commit -qm Start
  REALPYBASE=$(git -C "$REALPY" rev-parse HEAD)
  cat > "$REALPY/tests/test_app.py" <<'EOF'
from app import value

def test_D1_value():
    assert value() == 2
EOF
  git -C "$REALPY" add -A; git -C "$REALPY" commit -qm 'Test: add D1'
  printf 'def value():\n    return 2\n' > "$REALPY/app.py"
  git -C "$REALPY" add -A; git -C "$REALPY" commit -qm 'Build value'
  cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- The value is two
EOF
  set +e; REALPY_OUT=$(cd "$REALPY" && "$PYTHON_BIN" "$QUALITY" tests --base "$REALPYBASE" --piece 400 2>&1); CODE=$?; set -e
  [ "$CODE" -eq 0 ] || { printf '%s\n' "$REALPY_OUT"; echo 'FAIL: real pytest with pytest-cov did not prove the change'; exit 1; }
  printf '%s\n' "$REALPY_OUT" | grep -q '^fails-before[[:space:]]D1$'
  # An older pytest-cov has no JSON report; then coverage is one not-checked line.
  if printf '%s\n' "$REALPY_OUT" | grep -q '^not-checked[[:space:]]coverage[[:space:]]installed pytest-cov does not support JSON output$'; then
    if printf '%s\n' "$REALPY_OUT" | grep -q '^covered'; then echo 'FAIL: coverage was claimed without a JSON report'; exit 1; fi
    echo '  ok: real pytest with an older pytest-cov proves D1 and says coverage was not checked'
  elif printf '%s\n' "$REALPY_OUT" | grep -q '^not-checked[[:space:]]coverage[[:space:]]pytest-cov (coverage.py provider) is not installed$'; then
    if printf '%s\n' "$REALPY_OUT" | grep -q '^covered'; then echo 'FAIL: coverage was claimed without pytest-cov'; exit 1; fi
    could_not_run "real pytest coverage: pytest-cov (coverage.py provider) is not installed"
  else
    printf '%s\n' "$REALPY_OUT" | grep -q '^covered[[:space:]]1$' || { printf '%s\n' "$REALPY_OUT"; echo 'FAIL: real pytest-cov coverage was not read'; exit 1; }
    [ ! -e "$REALPY/.coverage" ] || { echo 'FAIL: pytest-cov wrote .coverage into the project'; exit 1; }
    echo '  ok: real pytest with pytest-cov proves D1 and keeps .coverage temporary'
  fi
fi

if [ -n "$PYTEST_NOCOV_BIN" ] && (ulimit -c 0; sh -c "$PYTEST_NOCOV_BIN --help" >/dev/null 2>&1); then
  REALPY="$WORK/pytest-without-cov"
  mkdir -p "$REALPY/tests"
  git -C "$REALPY" init -q -b main
  git -C "$REALPY" config user.name Rehearsal; git -C "$REALPY" config user.email rehearsal@example.invalid
  printf 'def value():\n    return 1\n' > "$REALPY/app.py"
  printf '[tool.pytest.ini_options]\n' > "$REALPY/pyproject.toml"
  mkdir -p "$REALPY/.github/workflows"
  printf 'jobs:\n  project-check:\n    steps:\n      - run: %s -q\n' "$PYTEST_NOCOV_BIN" > "$REALPY/.github/workflows/checks.yml"
  git -C "$REALPY" add -A; git -C "$REALPY" commit -qm Start
  REALPYBASE=$(git -C "$REALPY" rev-parse HEAD)
  cat > "$REALPY/tests/test_app.py" <<'EOF'
from app import value

def test_D1_value():
    assert value() == 2
EOF
  git -C "$REALPY" add -A; git -C "$REALPY" commit -qm 'Test: add D1'
  printf 'def value():\n    return 2\n' > "$REALPY/app.py"
  git -C "$REALPY" add -A; git -C "$REALPY" commit -qm 'Build value'
  cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- The value is two
EOF
  set +e; REALPY_OUT=$(cd "$REALPY" && python3 "$QUALITY" tests --base "$REALPYBASE" --piece 401 2>&1); CODE=$?; set -e
  [ "$CODE" -eq 0 ] || { printf '%s\n' "$REALPY_OUT"; echo 'FAIL: pytest without pytest-cov blocked test results'; exit 1; }
  printf '%s\n' "$REALPY_OUT" | grep -q '^not-checked[[:space:]]coverage[[:space:]]pytest-cov (coverage.py provider) is not installed$'
  printf '%s\n' "$REALPY_OUT" | grep -q '^fails-before[[:space:]]D1$'
  echo '  ok: real pytest without pytest-cov keeps coverage not-checked and proves D1'
fi

# A recorded Python command with no per-test report must not be inferred as
# pytest or labelled untested by D number.
CUSTOM="$WORK/custom-python"
mkdir -p "$CUSTOM/tests"
git -C "$CUSTOM" init -q -b main
git -C "$CUSTOM" config user.name Rehearsal; git -C "$CUSTOM" config user.email rehearsal@example.invalid
printf 'def value(): return 1\n' > "$CUSTOM/app.py"
printf 'print("ok")\n' > "$CUSTOM/run_tests.py"
git -C "$CUSTOM" add -A; git -C "$CUSTOM" commit -qm Start
CUSTOMBASE=$(git -C "$CUSTOM" rev-parse HEAD)
printf 'Test command: python3 run_tests.py\n' > "$CUSTOM/AGENTS.md"
printf 'def test_D1_value(): pass\n' > "$CUSTOM/tests/test_app.py"
git -C "$CUSTOM" add -A; git -C "$CUSTOM" commit -qm 'Test: add D1'
printf 'def value(): return 2\n' > "$CUSTOM/app.py"
git -C "$CUSTOM" add app.py; git -C "$CUSTOM" commit -qm 'Implement value'
OUT=$(cd "$CUSTOM" && python3 "$QUALITY" tests --base "$CUSTOMBASE" --piece 3 2>&1) && CODE=0 || CODE=$?
[ "$CODE" -eq 2 ] || { printf '%s\n' "$OUT"; echo 'FAIL: a command without per-test results did not return 2'; exit 1; }
printf '%s\n' "$OUT" | grep -q '^not-checked[[:space:]]tests[[:space:]]recorded test command has no per-test report$'
! printf '%s\n' "$OUT" | grep -q '^untested[[:space:]]D1'
echo '  ok: a recorded plain Python runner is not called pytest and does not claim untested D lines'

# A recorded Playwright command with numbered specs takes the D-specific path.
PW="$WORK/playwright"
mkdir -p "$PW/tests" "$PW/node_modules/.bin" "$PW/.github/workflows"
git -C "$PW" init -q -b main
git -C "$PW" config user.name Rehearsal; git -C "$PW" config user.email rehearsal@example.invalid
printf '%s\n' '{"private":true}' > "$PW/package.json"
printf '%s\n' "export default { testDir: './tests' };" > "$PW/playwright.config.ts"
git -C "$PW" add -A; git -C "$PW" commit -qm Start
PWBASE=$(git -C "$PW" rev-parse HEAD)
printf '%s\n' "import { test } from '@playwright/test';" "test('D1 accepts the rule', async () => {});" > "$PW/tests/rule.spec.ts"
git -C "$PW" add -A; git -C "$PW" commit -qm 'Test: add D1 browser case'
printf '%s\n' 'module.exports = true;' > "$PW/src-rule.js"
git -C "$PW" add -A; git -C "$PW" commit -qm 'Build rule'
printf '%s\n' 'jobs:' '  test:' '    steps:' '      - run: npx playwright test' > "$PW/.github/workflows/checks.yml"
cat > "$PW/node_modules/.bin/playwright" <<'EOF'
#!/bin/sh
case "$PWD" in */before) exit 1 ;; *) exit 0 ;; esac
EOF
chmod +x "$PW/node_modules/.bin/playwright"
cat > "$QUALITY_TEST_PIECE_FILE" <<'EOF'
## Done when
- The rule is accepted
EOF
set +e; OUT=$(cd "$PW" && PATH="$PW/node_modules/.bin:$PATH" python3 "$QUALITY" tests --base "$PWBASE" --piece 1 2>&1); CODE=$?; set -e
[ "$CODE" -eq 0 ] || { printf '%s\n' "$OUT"; echo 'FAIL: numbered Playwright test did not use its D-specific path'; exit 1; }
printf '%s\n' "$OUT" | grep -q '^fails-before[[:space:]]D1$'
printf '%s\n' "$OUT" | grep -q '^playwright[[:space:]]D1[[:space:]]passed$'
echo '  ok: numbered Playwright specs run their D-specific before/after check'

echo 'tests-prove-change.sh: Vitest report contract, per-D output and test subject guard checked'

finish_rehearsal
