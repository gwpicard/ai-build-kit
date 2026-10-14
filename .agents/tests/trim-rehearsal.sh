#!/usr/bin/env sh
# trim-rehearsal.sh: run the shipped trim script and commit guard against a
# throwaway project, play the agent's part on what the script prints, and read
# back what happened.
#
# The project starts from a saved commit, then a piece is built on top of it
# carrying one of everything the trim is meant to handle: a wrapper with one
# user and a test behind it, an export nothing calls, a dependency nothing
# imports, a wrapper with one user and no test, a dependency used once, a
# copied block, and a new function past the limit. Beside those sit things the
# script must leave alone: an unused export from before the piece, an old
# function past the limit that the piece changed without making worse, and a
# wrapper with two users. One decoy is there to be got wrong: a file reached
# only through a path built at run time, which the engine calls unused and a
# search for its name cannot find. Removing it breaks a test, so the agent has
# to undo the removal rather than touch the test.
#
# The script decides what is found, by exit code and fixed lines. The agent's
# part here only removes and folds what the script marks, and the commit goes
# through trim-commit.sh, which refuses a test change. The project check's
# check-trim.sh is then run against a trim commit that changed a test, made by
# hand past the guard, and must fail. The rule for which paths are tests lives
# once, in check-trim.sh, and covers each stack's test layout and set-up files.
#
# A wrapper is folded only when a test runs its user. A test of a file in
# another folder with the same name as that user does not count. With one
# engine missing, the script still prints what the others found, names the
# part it could not check, and answers 2. An unused local name is the linter's.
#
# The engines are used from PATH when present and otherwise installed into a
# throwaway folder. A machine that can do neither fails here rather than
# skipping, since a rehearsal that passes by never running proves nothing.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPTS="$ROOT/.agents/skills/quality-checks/scripts"
CHECK="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-trim.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

command -v node >/dev/null 2>&1 || fail "node is needed to run this rehearsal"
command -v python3 >/dev/null 2>&1 || fail "python3 is needed to run this rehearsal"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if ! command -v knip >/dev/null 2>&1 || ! command -v jscpd >/dev/null 2>&1; then
  echo "  knip or jscpd not on PATH, installing both into a throwaway folder"
  mkdir -p "$WORK/engines"
  printf '{"name":"engines","private":true}\n' > "$WORK/engines/package.json"
  (cd "$WORK/engines" && npm install --no-audit --no-fund --silent knip@6 jscpd@5) ||
    fail "could not install knip and jscpd, so the trim could not be rehearsed"
  PATH="$WORK/engines/node_modules/.bin:$PATH"
  export PATH
fi

if ! command -v lizard >/dev/null 2>&1 || ! command -v vulture >/dev/null 2>&1; then
  echo "  lizard or vulture not on PATH, installing both into a throwaway folder"
  python3 -m venv "$WORK/py" && "$WORK/py/bin/pip" install -q 'lizard>=1.24,<2' vulture ||
    fail "could not install lizard and vulture, so the trim could not be rehearsed"
  PATH="$WORK/py/bin:$PATH"
  export PATH
fi

node - "$SCRIPTS" "$CHECK" "$WORK" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');

const [scripts, checkTrim, work] = process.argv.slice(2);
const quality = path.join(scripts, 'quality.py');
const trimCommit = path.join(scripts, 'trim-commit.sh');

function sh(dir, cmd, args, allowFail = false) {
  const result = spawnSync(cmd, args, { cwd: dir, encoding: 'utf8', timeout: 300000,
    env: { ...process.env, GIT_AUTHOR_NAME: 'Rehearsal', GIT_AUTHOR_EMAIL: 'rehearsal@example.invalid',
      GIT_COMMITTER_NAME: 'Rehearsal', GIT_COMMITTER_EMAIL: 'rehearsal@example.invalid' } });
  assert.ifError(result.error);
  if (!allowFail && result.status !== 0) {
    throw new Error(`${cmd} ${args.join(' ')} failed:\n${result.stdout}${result.stderr}`);
  }
  return result;
}
const git = (dir, ...args) => sh(dir, 'git', ['-c', 'commit.gpgsign=false', ...args]).stdout.trim();

function write(dir, files) {
  for (const [name, text] of Object.entries(files)) {
    const full = path.join(dir, name);
    if (text === null) { fs.rmSync(full, { force: true }); continue; }
    fs.mkdirSync(path.dirname(full), { recursive: true });
    fs.writeFileSync(full, text);
  }
}

function projectFiles(dir) {
  const out = [];
  (function walk(d) {
    for (const entry of fs.readdirSync(d, { withFileTypes: true })) {
      if (entry.name === 'node_modules' || entry.name === '.git') continue;
      const full = path.join(d, entry.name);
      if (entry.isDirectory()) walk(full);
      else out.push(path.relative(dir, full));
    }
  })(dir);
  return out.sort();
}

const hashOf = (dir, files) => crypto.createHash('sha256')
  .update(files.map(f => f + '\0' + (fs.existsSync(path.join(dir, f)) ? fs.readFileSync(path.join(dir, f), 'utf8') : '')).join('\0')).digest('hex');
const testsPass = dir => sh(dir, 'node', ['--test'], true).status === 0;
const read = (dir, file) => fs.readFileSync(path.join(dir, file), 'utf8');
const exists = (dir, file) => fs.existsSync(path.join(dir, file));
const pkg = extra => JSON.stringify({
  name: 'shop', private: true, type: 'module', main: 'src/index.js',
  scripts: { test: 'node --test' }, ...extra,
}, null, 2) + '\n';

// The script's answer: exit code and its tab-separated lines.
function findings(dir, base) {
  const result = sh(dir, 'python3', [quality, 'trim', '--base', base], true);
  assert.ok([0, 1].includes(result.status), `the trim script could not run:\n${result.stdout}${result.stderr}`);
  const rows = result.stdout.trim().split('\n').filter(Boolean).map(line => {
    const [action, kind, place, name, detail] = line.split('\t');
    const [file, at] = place.split(/:(?=\d+$)/);
    return { action, kind, file, line: Number(at), name, detail };
  });
  assert.equal(result.status, rows.some(r => ['remove', 'fold', 'report'].includes(r.action)) ? 1 : 0,
    `the exit code does not match what the script printed:\n${result.stdout}${result.stderr}`);
  return rows;
}

// A function past the limit of 15: one path per test, plus the one through the end.
const branchy = (name, returns) => [
  `export function ${name}(value) {`,
  ...Array.from({ length: 16 }, (_, i) => `  if (value === ${i}) return '${returns}${i}';`),
  `  return '${returns}';`,
  '}',
].join('\n') + '\n';

const block = name => [
  `export function ${name}(items) {`,
  '  let sum = 0;',
  '  for (const item of items) {',
  '    if (item.quantity > 0 && item.price > 0) {',
  '      sum += item.quantity * item.price;',
  '    } else {',
  "      console.warn('skipping an empty line', item.name);",
  '    }',
  '  }',
  '  return Math.round(sum * 100) / 100;',
  '}',
].join('\n') + '\n';

const test = (file, name, body) => ({
  [file]: `import { test } from 'node:test';\nimport assert from 'node:assert/strict';\n${body}\ntest('${name}', ${name === 'refund' ? 'async ' : ''}() => {\n  ${
    { total: "assert.equal(total([{ quantity: 2, price: 1.5 }]), 3);",
      grade: "assert.equal(grade(3), 'grade3');",
      label: "assert.equal(totalLabel([{ quantity: 2, price: 1.5 }]), '3.00');",
      refund: "assert.equal(await dispatch('refund', 'order'), 'refunded');",
      risk: "assert.equal(risk(2), 'risk2');",
      tax: 'assert.equal(tax(10), 2);' }[name]}\n});\n`,
});

const start = {
  '.gitignore': 'node_modules/\n',
  'package.json': pkg({}),
  'src/index.js': "import { total } from './pricing.js';\nimport { grade } from './grade.js';\nconsole.log(total([]), grade(1));\n",
  'src/pricing.js': block('total') + '\nexport function legacyRound(value) {\n  return Math.round(value);\n}\n',
  'src/grade.js': branchy('grade', 'grade'),
  ...test('test/pricing.test.js', 'total', "import { total } from '../src/pricing.js';"),
  ...test('test/grade.test.js', 'grade', "import { grade } from '../src/grade.js';"),
  // A file in another folder with the same name as the untested wrapper's
  // user, src/cli.js, and a test that runs it. A test that runs this file
  // does not run src/cli.js, so it must not count as a test of that wrapper.
  'tools/cli.js': "export function banner() {\n  return 'shop';\n}\n",
  'test/tools.test.js': "import { test } from 'node:test';\nimport assert from 'node:assert/strict';\nimport { banner } from '../tools/cli.js';\ntest('banner', () => assert.equal(banner(), 'shop'));\n",
};

const piece = {
  'package.json': pkg({ dependencies: { 'left-pad': '1.3.0', 'tiny-words': '1.0.0' } }),
  'node_modules/tiny-words/package.json': '{"name":"tiny-words","version":"1.0.0","type":"module","main":"index.js"}\n',
  'node_modules/tiny-words/index.js': 'export function toWords(n) {\n  return String(n);\n}\n',
  'src/index.js': [
    "import { total, totalLabel } from './pricing.js';",
    "import { grade } from './grade.js';",
    "import { reportTotal } from './report.js';",
    "import { amountInWords } from './words.js';",
    "import { printTotal } from './cli.js';",
    "import { dispatch } from './dispatch.js';",
    "import { risk } from './risk.js';",
    "console.log(total([]), totalLabel([]), grade(1), reportTotal([]), amountInWords(2), risk(1));",
    'printTotal([]);',
    "console.log(await dispatch('refund', 'order'));",
    '',
  ].join('\n'),
  'src/format.js': 'export function formatMoney(value) {\n  return value.toFixed(2);\n}\n',
  'src/pricing.js': "import { formatMoney } from './format.js';\n\n" + block('total') +
    '\nexport function legacyRound(value) {\n  return Math.round(value);\n}\n' +
    '\nexport function totalLabel(items) {\n  return formatMoney(total(items));\n}\n' +
    '\nexport function legacyTotal(items) {\n  return items.length;\n}\n',
  'src/grade.js': branchy('grade', 'grade').replace("return 'grade';", "return 'ungraded';"),
  'src/report.js': block('reportTotal').replace(/\bsum\b/g, 'running').replace(/\bitem\b/g, 'line'),
  'src/words.js': "import { toWords } from 'tiny-words';\n\nexport function amountInWords(n) {\n  const words = toWords(n);\n  return words.toUpperCase();\n}\n",
  'src/cli.js': "import { total } from './pricing.js';\n\nexport function pad(label) {\n  return label.padStart(12);\n}\n\nexport function printTotal(items) {\n  const text = String(total(items));\n  console.log(pad(text));\n}\n",
  'src/dispatch.js': 'export async function dispatch(action, thing) {\n  const handler = await import(`./handlers/${action}-${thing}.js`);\n  return handler.run();\n}\n',
  'src/handlers/refund-order.js': "export function run() {\n  return 'refunded';\n}\n",
  'src/risk.js': branchy('risk', 'risk'),
  ...test('test/label.test.js', 'label', "import { totalLabel } from '../src/pricing.js';"),
  ...test('test/dispatch.test.js', 'refund', "import { dispatch } from '../src/dispatch.js';"),
  ...test('test/risk.test.js', 'risk', "import { risk } from '../src/risk.js';"),
};

// --- the agent's part: remove and fold what the script marks, nothing else ----

function functionAt(text, startLine) {
  const lines = text.split('\n');
  let end = startLine - 1;
  while (end < lines.length && lines[end] !== '}') end++;
  return { from: startLine, to: end + 1, body: lines.slice(startLine, end).map(l => l.trim()) };
}

function removeFunction(dir, file, line) {
  const text = read(dir, file);
  const fn = functionAt(text, line);
  const lines = text.split('\n');
  lines.splice(fn.from - 1, fn.to - fn.from + 1 + (lines[fn.to] === '' ? 1 : 0));
  const rest = lines.join('\n').replace(/\n+$/, '\n');
  if (!/\bfunction\b/.test(rest)) fs.rmSync(path.join(dir, file));
  else fs.writeFileSync(path.join(dir, file), rest);
}

function argumentAt(text, from) {
  let depth = 0;
  for (let i = from; i < text.length; i++) {
    if (text[i] === '(') depth++;
    if (text[i] === ')') { if (depth === 0) return text.slice(from, i); depth--; }
  }
  throw new Error('unbalanced call');
}

function apply(dir, row) {
  if (row.action === 'remove' && row.kind === 'unused-export') return removeFunction(dir, row.file, row.line);
  if (row.action === 'remove' && row.kind === 'unused-file') return fs.rmSync(path.join(dir, row.file));
  if (row.action === 'remove' && row.kind === 'unused-dependency') {
    const json = JSON.parse(read(dir, 'package.json'));
    delete json.dependencies[row.name];
    return fs.writeFileSync(path.join(dir, 'package.json'), JSON.stringify(json, null, 2) + '\n');
  }
  if (row.action === 'fold' && row.kind === 'one-user') {
    const wrapper = read(dir, row.file).split('\n')[row.line - 1].match(/function (\w+)\((\w+)\)/);
    const expr = functionAt(read(dir, row.file), row.line).body[0].replace(/^return /, '').replace(/;$/, '');
    const userFile = row.detail.split(':')[0];
    let text = read(dir, userFile);
    const call = text.indexOf(`${row.name}(`);
    const arg = argumentAt(text, call + row.name.length + 1);
    text = text.slice(0, call) + expr.replace(new RegExp(`\\b${wrapper[2]}\\b`, 'g'), `(${arg})`) +
      text.slice(call + row.name.length + arg.length + 2);
    text = text.split('\n').filter(l => !new RegExp(`^import \\{ ${row.name} \\} from`).test(l)).join('\n').replace(/^\n+/, '');
    fs.writeFileSync(path.join(dir, userFile), text);
    return removeFunction(dir, row.file, row.line);
  }
  throw new Error(`the trim may not make a ${row.action} ${row.kind} edit`);
}

function trim(dir, base) {
  git(dir, 'add', '-A');
  git(dir, 'commit', '-q', '-m', 'Build the piece');
  const built = git(dir, 'rev-parse', 'HEAD');

  const rows = findings(dir, base);
  if (rows.length) console.log(rows.map(r => `    ${r.action} ${r.kind} ${r.file}:${r.line} ${r.name} ${r.detail}`).join('\n'));
  const applied = [];
  const wrongCalls = [];
  for (const row of rows.filter(r => r.action === 'remove' || r.action === 'fold')) {
    const touched = [row.file, row.detail && row.detail.includes(':') ? row.detail.split(':')[0] : null, 'package.json'].filter(Boolean);
    const saved = Object.fromEntries(touched.map(f => [f, exists(dir, f) ? read(dir, f) : null]));
    apply(dir, row);
    if (testsPass(dir)) applied.push(row);
    else { write(dir, saved); wrongCalls.push(row); }
  }

  // The script once more over the result. Nothing it finds is applied.
  const treeBefore = hashOf(dir, projectFiles(dir));
  const again = findings(dir, base);
  assert.equal(hashOf(dir, projectFiles(dir)), treeBefore, 'the second run changed the code');
  const known = new Set(rows.map(r => `${r.kind}:${r.name}`));
  const newlyFound = again.filter(r => r.action !== 'not-checked' && !known.has(`${r.kind}:${r.name}`));

  assert.ok(testsPass(dir), 'the tests failed after the trim');
  const saved = sh(dir, 'sh', [trimCommit], true);
  assert.equal(saved.status, 0, `trim-commit refused a clean trim:\n${saved.stderr}`);
  const head = git(dir, 'rev-parse', 'HEAD');
  return { built, trimmed: head === built ? null : head, rows, applied, wrongCalls, newlyFound };
}

function freshProject(name) {
  const dir = path.join(work, name);
  fs.mkdirSync(dir, { recursive: true });
  git(dir, 'init', '-q', '-b', 'main');
  write(dir, start);
  git(dir, 'add', '-A');
  git(dir, 'commit', '-q', '-m', 'Start');
  return { dir, base: git(dir, 'rev-parse', 'HEAD') };
}

// --- the piece with something to take out --------------------------------------

const { dir, base } = freshProject('project');
write(dir, piece);
const testFiles = projectFiles(dir).filter(f => f.startsWith('test/'));
const testsBefore = hashOf(dir, testFiles);
assert.ok(testsPass(dir), 'the piece as built should pass its tests');

const result = trim(dir, base);

const by = (action, kind) => result.rows.filter(r => r.action === action && r.kind === kind).map(r => r.name).sort();
assert.deepEqual(by('remove', 'unused-export'), ['legacyTotal'], 'the unused export the piece added was not marked for removal');
assert.deepEqual(by('remove', 'unused-dependency'), ['left-pad'], 'the unused dependency was not marked for removal');
assert.deepEqual(by('remove', 'unused-file'), ['refund-order'], 'the decoy file was not marked, so its wrong call was never tested');
assert.deepEqual(by('fold', 'one-user'), ['formatMoney'], 'the tested one-user wrapper was not marked to fold');
assert.deepEqual(by('report', 'untested-one-user'), ['pad'], 'the untested wrapper was not only reported');
assert.deepEqual(by('report', 'one-use-dependency'), ['tiny-words'], 'the one-use dependency was not reported');
assert.deepEqual(result.rows.filter(r => r.kind === 'copy').map(r => r.file), ['src/report.js'], 'the copy was not reported at its new place');
assert.deepEqual(by('report', 'over-limit'), ['risk'], 'only the new function past the limit should be reported');
console.log('  ok: the script marks each kind once, and the old export, the old function and the two-user wrapper are left alone');
assert.ok(result.rows.every(r => !/\b(knip|jscpd|lizard|vulture|ccn)\b/i.test(r.detail || '')), 'an engine name or a score is in a finding');
console.log('  ok: no finding carries a score');

assert.deepEqual(result.applied.map(r => r.name).sort(), ['formatMoney', 'left-pad', 'legacyTotal']);
assert.ok(!exists(dir, 'src/format.js') && read(dir, 'src/pricing.js').includes('(total(items)).toFixed(2)'),
  'the tested one-user wrapper was not folded into its user');
assert.ok(read(dir, 'src/pricing.js').includes('legacyRound'), 'an unused export from before the piece was touched');
assert.ok(read(dir, 'src/cli.js').includes('export function pad'), 'the untested wrapper was folded');
console.log('  ok: the marked removals and the fold are made, and nothing only reported is changed');
assert.deepEqual(result.wrongCalls.map(r => r.name), ['refund-order'], 'the file reached at run time was not the wrong call');
assert.ok(exists(dir, 'src/handlers/refund-order.js'), 'the wrong call was not undone');
assert.equal(hashOf(dir, testFiles), testsBefore, 'a test was changed');
console.log('  ok: a removal that breaks a test is undone, and no test changed');
assert.deepEqual(result.newlyFound, [], 'the second run found something new');
console.log('  ok: the second run over the result finds nothing new');

assert.ok(result.trimmed, 'the trim was not saved');
assert.equal(git(dir, 'rev-parse', 'HEAD~1'), result.built, 'the trim is not the commit after the piece');
assert.match(git(dir, 'log', '-1', '--format=%s'), /^Trim: /, 'the trim commit does not carry its tag');
assert.equal(sh(dir, 'sh', [checkTrim, `${base}..HEAD`], true).status, 0, 'the project check refused a trim that left the tests alone');
git(dir, 'revert', '--no-edit', 'HEAD');
assert.equal(git(dir, 'diff', result.built, 'HEAD', '--stat'), '', 'undoing the trim did not bring back the piece as built');
console.log('  ok: the trim sits in its own tagged commit, the project check passes it, and undoing it brings back the piece');

// --- a trim that changed a test ------------------------------------------------

write(dir, { 'test/risk.test.js': read(dir, 'test/risk.test.js').replace("risk(2), 'risk2'", "risk(3), 'risk3'"),
  'src/risk.js': read(dir, 'src/risk.js') + '\n' });
const headBefore = git(dir, 'rev-parse', 'HEAD');
const refused = sh(dir, 'sh', [trimCommit], true);
assert.equal(refused.status, 1, 'trim-commit saved a trim that changed a test');
assert.match(refused.stderr, /test\/risk\.test\.js/, 'trim-commit did not name the test it refused');
assert.equal(git(dir, 'rev-parse', 'HEAD'), headBefore, 'trim-commit made a commit while refusing');
console.log('  ok: trim-commit refuses a trim that changed a test, names it, and commits nothing');

git(dir, 'add', '-A');
git(dir, 'commit', '-q', '-m', 'Trim: made by hand past the guard');
const caught = sh(dir, 'sh', [checkTrim, `${base}..HEAD`], true);
assert.equal(caught.status, 1, 'the project check passed a trim commit that changed a test');
assert.match(caught.stderr, /test\/risk\.test\.js/, 'the project check did not name the test');
git(dir, 'commit', '-q', '--amend', '-m', 'Change the risk test on purpose');
assert.equal(sh(dir, 'sh', [checkTrim, `${base}..HEAD`], true).status, 0, 'the project check refused a test change that is not a trim');
console.log('  ok: the project check fails a trim commit that changed a test, and leaves other commits alone');

// --- the three name a test path the same way ------------------------------------

const tests = ['test/a.js', 'src/a.test.ts', 'src/__tests__/b.js', 'tests/test_app.py', 'app/thing_test.py',
  'conftest.py', 'test/fixtures/data.json', 'fixtures/orders.csv', 'pkg/x_test.go',
  // The test layouts other stacks use, and the files that set the tests up.
  'shop/tests.py', 'spec/models/user_spec.rb', 'src/app.e2e-spec.ts', 'src/__mocks__/api.js',
  'jest.config.js', 'vitest.config.ts', 'playwright.config.ts', 'pytest.ini', 'src/setupTests.ts',
  'cypress/e2e/login.cy.js'];
const notTests = ['src/app.js', 'src/contest.js', 'latest/notes.md', 'src/testing.py', 'attest.py',
  'src/ab-test.js', 'src/spec.ts', 'src/inspect.js'];
const paths = [...tests, ...notTests];
const pyAnswer = sh(work, 'python3', ['-B', '-c', `import importlib.util,sys
spec = importlib.util.spec_from_file_location('q', ${JSON.stringify(quality)})
q = importlib.util.module_from_spec(spec); spec.loader.exec_module(q)
print('\\n'.join(p for p in sys.argv[1:] if q.is_test(p)))`, ...paths]).stdout.trim();
assert.equal(pyAnswer, tests.join('\n'), `quality.py named the wrong paths as tests: ${pyAnswer}`);
const rule = read(path.dirname(checkTrim), path.basename(checkTrim)).match(/^TEST_PATH='([^']+)'$/m)[1];
const shAnswer = paths.filter(p => spawnSync('grep', ['-qE', rule], { input: p + '\n' }).status === 0).join('\n');
assert.equal(shAnswer, pyAnswer, 'check-trim.sh and quality.py disagree about which paths are tests');
for (const file of [quality, trimCommit]) {
  assert.ok(!read(path.dirname(file), path.basename(file)).includes('__tests__'),
    `${path.basename(file)} carries its own copy of the test-path rule`);
}
console.log('  ok: the test-path rule lives once, in check-trim.sh, and covers each stack\'s test layout');

// trim-commit.sh refuses a trim that changed a test set-up file, by the same rule.
write(dir, { 'jest.config.js': 'export default {};\n' });
const config = sh(dir, 'sh', [trimCommit], true);
assert.equal(config.status, 1, 'trim-commit saved a trim that changed a test set-up file');
assert.match(config.stderr, /jest\.config\.js/);
fs.rmSync(path.join(dir, 'jest.config.js'));
console.log('  ok: trim-commit reads that rule, and refuses a trim that changed a test set-up file');

// --- the piece with nothing to take out ----------------------------------------

const clean = freshProject('clean');
write(clean.dir, {
  'src/tax.js': 'export function tax(amount) {\n  const rate = 0.2;\n  return Math.round(amount * rate * 100) / 100;\n}\n',
  'src/index.js': "import { total } from './pricing.js';\nimport { grade } from './grade.js';\nimport { tax } from './tax.js';\nconsole.log(total([]), grade(1), tax(10));\n",
  ...test('test/tax.test.js', 'tax', "import { tax } from '../src/tax.js';"),
});
const quiet = trim(clean.dir, clean.base);
assert.deepEqual(quiet.rows, [], `a clean change should produce nothing, got: ${JSON.stringify(quiet.rows)}`);
assert.equal(quiet.trimmed, null, 'a clean change made a trim commit');
console.log('  ok: a clean change prints nothing, exits 0, and makes no commit');

const missing = sh(clean.dir, 'python3', [quality, 'trim', '--base', 'no-such-commit'], true);
assert.equal(missing.status, 2, 'a commit that does not exist did not exit 2');
console.log('  ok: a base that is not a commit exits 2');

const gitDir = path.dirname(sh(work, 'sh', ['-c', 'command -v git']).stdout.trim());
const bare = spawnSync(sh(work, 'sh', ['-c', 'command -v python3']).stdout.trim(), [quality, 'trim', '--base', 'HEAD~1'],
  { cwd: dir, encoding: 'utf8', env: { PATH: gitDir, HOME: process.env.HOME } });
assert.equal(bare.status, 2, `with no engine at all the script did not exit 2:\n${bare.stdout}${bare.stderr}`);
assert.match(bare.stdout, /^not-checked\tcopies\t/m, 'the copy check that could not run was not named');
console.log('  ok: with no engine at all, it names each check it could not run and exits 2');

// Some engines but not all: the parts that ran still print their findings, the
// part that did not is named, and the answer is 2, never a clean 0 or 1.
const some = path.join(work, 'some-engines');
fs.mkdirSync(some);
for (const tool of ['git', 'node', 'python3', 'knip', 'jscpd']) {
  fs.symlinkSync(sh(work, 'sh', ['-c', `command -v ${tool}`]).stdout.trim(), path.join(some, tool));
}
const partial = spawnSync(path.join(some, 'python3'), [quality, 'trim', '--base', base],
  { cwd: dir, encoding: 'utf8', env: { PATH: some, HOME: process.env.HOME } });
assert.equal(partial.status, 2, `with lizard missing the script did not exit 2:\n${partial.stdout}${partial.stderr}`);
assert.match(partial.stdout, /^not-checked\tfunctions\tlizard is not installed$/m, 'the part with no engine was not named');
assert.match(partial.stdout, /^report\tcopy\tsrc\/report\.js:/m, 'the findings from the engines that ran were not printed');
console.log('  ok: with one engine missing, it prints what the others found, names the part not checked, and exits 2');

// --- a Python piece -------------------------------------------------------------

const py = path.join(work, 'python');
fs.mkdirSync(py, { recursive: true });
git(py, 'init', '-q', '-b', 'main');
write(py, {
  'shop/__init__.py': '',
  'shop/app.py': 'def total(prices):\n    return sum(prices)\n\n\nif __name__ == "__main__":\n    print(total([1, 2]))\n',
  'tests/test_app.py': 'from shop.app import total, label\n\n\ndef test_total():\n    assert total([1, 2]) == 3\n\n\ndef test_label():\n    assert label([1, 2]) == "3"\n',
});
git(py, 'add', '-A');
git(py, 'commit', '-q', '-m', 'Start');
const pyBase = git(py, 'rev-parse', 'HEAD');
write(py, {
  'shop/app.py': 'def total(prices):\n    return sum(prices)\n\n\ndef as_text(value):\n    return str(round(value))\n\n\n' +
    'def label(prices):\n    amount = total(prices)\n    draft = amount\n    return as_text(amount)\n\n\ndef old_label(prices):\n    amount = total(prices)\n    return amount\n\n\n' +
    'if __name__ == "__main__":\n    print(total([1, 2]))\n',
});
git(py, 'add', '-A');
git(py, 'commit', '-q', '-m', 'Build the piece');
const pyRows = findings(py, pyBase);
console.log(pyRows.map(r => `    ${r.action} ${r.kind} ${r.file}:${r.line} ${r.name} ${r.detail}`).join('\n'));
assert.deepEqual(pyRows.filter(r => r.action === 'remove').map(r => r.name), ['old_label'], 'the unused Python function was not marked');
assert.deepEqual(pyRows.filter(r => r.action === 'fold').map(r => r.name), ['as_text'], 'the one-user Python wrapper was not marked to fold');
assert.ok(!pyRows.some(r => ['total', 'label'].includes(r.name)), 'a function in use was marked');
console.log('  ok: on a Python piece, the unused function and the one-user wrapper are marked, and nothing in use');
assert.ok(!pyRows.some(r => r.name === 'draft'), 'an unused local name was marked; it is the linter\'s to report');
console.log('  ok: an unused local name is left to the linter');

console.log('\ntrim-rehearsal.sh: findings, edits, the commit guard and silence all held');
NODE
