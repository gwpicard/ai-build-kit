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
git -C "$PROJECT" init -q -b main
git -C "$PROJECT" config user.name Rehearsal
git -C "$PROJECT" config user.email rehearsal@example.invalid

put() { mkdir -p "$(dirname "$PROJECT/$1")"; cat > "$PROJECT/$1"; }
save() { git -C "$PROJECT" add -A; git -C "$PROJECT" commit -qm "$1"; git -C "$PROJECT" rev-parse HEAD; }

put package.json <<'EOF'
{"private":true,"scripts":{"test":"node --test"}}
EOF
put src/rule.js <<'EOF'
module.exports = value => value > 4;
EOF
BASE=$(save 'Start')
put tests/rule.test.js <<'EOF'
const test = require('node:test');
const assert = require('node:assert/strict');
const rule = require('../src/rule.js');
// vi.mock('../src/rule.js')
test.skip('later example', () => {});
test('D1 accepts four at the limit', () => assert.equal(rule(4), true));
EOF
put tests/done-when.txt <<'EOF'
## Done when
- Values at four are accepted
- Values below four are rejected
EOF
save 'Test: cover D1'
put src/rule.js <<'EOF'
module.exports = value => value >= 4;
EOF
PIECE=$(save 'Implement rule')
mkdir -p "$PROJECT/coverage"
printf '{"%s/src/rule.js":{"s":{"0":0},"statementMap":{"0":{"start":{"line":1}}}}}\n' "$PROJECT" > "$PROJECT/coverage/coverage-final.json"

node - "$QUALITY" "$TEMPLATE" "$PROJECT" "$BASE" "$PIECE" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const [quality, template, project, base, piece] = process.argv.slice(2);
function run(args) {
  return spawnSync('python3', [quality, ...args], { cwd: project, encoding: 'utf8' });
}
let result = run(['tests', '--base', base, '--piece', '1']);
assert.equal(result.status, 1, `the changed code passes on the old code or missed D2:\n${result.stdout}${result.stderr}`);
assert.match(result.stdout, /^passes-before\tfailed$/m);
assert.match(result.stdout, /^untested\tD2\t/m);
assert.match(result.stdout, /^uncovered\t/m);
assert.match(result.stdout, /^stands-in\t/m);
assert.match(result.stdout, /^skipped\t/m);
assert.match(result.stdout, /^removed\t/m);
console.log('  ok: baseline test fails, D2 is named, and changed lines without coverage are listed');
fs.writeFileSync(path.join(project, 'tests/done-when.txt'), '## Done when\n- Values at four are accepted\n');
fs.writeFileSync(path.join(project, 'coverage/coverage-final.json'), JSON.stringify({
  [path.join(project, 'src/rule.js')]: { s: { 0: 1 }, statementMap: { 0: { start: { line: 1 } } } },
}));
result = run(['tests', '--base', base, '--piece', '1']);
assert.equal(result.status, 0, `a passing red test was rejected:\n${result.stdout}${result.stderr}`);
assert.match(result.stdout, /^tests\tpassed$/m);
console.log('  ok: the red test passes after the change and covers changed code');

const hook = path.join(project, '.agents/hooks/check-tests.sh');
fs.mkdirSync(path.dirname(hook), { recursive: true });
fs.copyFileSync(template, hook);
function check(range) { return spawnSync('sh', [hook, range], { cwd: project, encoding: 'utf8' }); }
const red = `${base}..HEAD`;
const testFile = path.join(project, 'tests/rule.test.js');
const original = fs.readFileSync(testFile, 'utf8');
fs.appendFileSync(testFile, '\n// weakened silently\n');
spawnSync('git', ['add', 'tests/rule.test.js'], { cwd: project });
spawnSync('git', ['commit', '-qm', 'Silent test edit'], { cwd: project });
result = check(red);
assert.equal(result.status, 1, `silent edit was allowed:\n${result.stdout}${result.stderr}`);
console.log('  ok: a silent edit to a red-commit test fails');
spawnSync('git', ['reset', '--hard', piece], { cwd: project });
fs.writeFileSync(testFile, original + "\ntest('D2 rejects four when fixed', () => assert.equal(rule(3), false));\n");
spawnSync('git', ['add', 'tests/rule.test.js'], { cwd: project });
spawnSync('git', ['commit', '-qm', 'Test fix: add the lower boundary after the test runner exposed it'], { cwd: project });
result = check(red);
assert.equal(result.status, 0, `a reasoned Test fix was rejected:\n${result.stdout}${result.stderr}`);
console.log('  ok: a reasoned Test fix commit can change a frozen test');
spawnSync('git', ['reset', '--hard', piece], { cwd: project });
fs.appendFileSync(testFile, "\ntest('trim edit', () => assert.ok(true));\n");
spawnSync('git', ['add', 'tests/rule.test.js'], { cwd: project });
spawnSync('git', ['commit', '-qm', 'Trim: tidy the code'], { cwd: project });
result = check(red);
assert.equal(result.status, 1, `a trim edit to a test was allowed:\n${result.stdout}${result.stderr}`);
console.log('  ok: a Trim commit cannot change a test');
result = check('missing-base..missing-head');
assert.equal(result.status, 2, 'an unreadable range did not return exit 2');
console.log('  ok: an unreadable range returns exit 2');

// A weak test that already passes on the start code is not evidence for the
// change, even when the full test command passes after it.
spawnSync('git', ['reset', '--hard', base], { cwd: project });
fs.mkdirSync(path.dirname(testFile), { recursive: true });
fs.writeFileSync(testFile, [
  "const test = require('node:test');",
  "const assert = require('node:assert/strict');",
  "const rule = require('../src/rule.js');",
  "test('D1 rejects three', () => assert.equal(rule(3), false));",
  '',
].join('\n'));
fs.writeFileSync(path.join(project, 'tests/done-when.txt'), '## Done when\n- Values at four are accepted\n');
spawnSync('git', ['add', '-A'], { cwd: project });
spawnSync('git', ['commit', '-qm', 'Test: add a weak check'], { cwd: project });
fs.writeFileSync(path.join(project, 'src/rule.js'), 'module.exports = value => value > 5;\n');
spawnSync('git', ['add', 'src/rule.js'], { cwd: project });
spawnSync('git', ['commit', '-qm', 'Implement rule'], { cwd: project });
fs.mkdirSync(path.join(project, 'coverage'), { recursive: true });
fs.writeFileSync(path.join(project, 'coverage/coverage-final.json'), JSON.stringify({
  [path.join(project, 'src/rule.js')]: { s: { 0: 1 }, statementMap: { 0: { start: { line: 1 } } } },
}));
result = run(['tests', '--base', base, '--piece', '1']);
assert.equal(result.status, 1, `a test that passes before the change was accepted:\n${result.stdout}${result.stderr}`);
assert.match(result.stdout, /^passes-before\tpassed$/m);
console.log('  ok: a test that passes before the change is caught');

console.log('tests-prove-change.sh: exit codes, baseline, test map and frozen tests were checked');
NODE
