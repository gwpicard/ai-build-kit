#!/usr/bin/env sh
# test-strength-rehearsal.sh: run the shipped check that breaks changed code on
# purpose against weak tests, and read back what it counted.
#
# A piece adds a free-delivery rule with a test that never tries the boundary
# itself. The script runs the mutation engine on the changed lines only, in a
# throwaway copy, and must report the tests catching most breakages and
# missing the one that moves the boundary, at its file and line, with exit
# code 1. Code from before the piece is never broken, the project is left
# exactly as it was, and once a test covers the boundary the script exits 0.
# The tests run in a copy with no real .env, with .env.example, and with the
# project's own folder named reports.
#
# The same runs for a Python piece, a changed method on a class included. A
# change with nothing the engine can break, and tests that fail before
# anything is broken, both answer 2: a run that tried nothing is never a pass.
#
# The engines are used from PATH when present and otherwise installed into a
# throwaway folder. A machine that can do neither fails here rather than
# skipping, since a rehearsal that passes by never running proves nothing.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
QUALITY="$ROOT/.agents/skills/quality-checks/scripts/quality.py"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

command -v node >/dev/null 2>&1 || fail "node is needed to run this rehearsal"
command -v python3 >/dev/null 2>&1 || fail "python3 is needed to run this rehearsal"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if ! command -v stryker >/dev/null 2>&1; then
  echo "  stryker not on PATH, installing it into a throwaway folder"
  mkdir -p "$WORK/engines"
  printf '{"name":"engines","private":true}\n' > "$WORK/engines/package.json"
  (cd "$WORK/engines" && npm install --no-audit --no-fund --silent @stryker-mutator/core@9) ||
    fail "could not install StrykerJS, so the check could not be rehearsed"
  PATH="$WORK/engines/node_modules/.bin:$PATH"
  export PATH
fi

if ! command -v mutmut >/dev/null 2>&1 || ! command -v pytest >/dev/null 2>&1; then
  echo "  mutmut or pytest not on PATH, installing both into a throwaway folder"
  python3 -m venv "$WORK/py" && "$WORK/py/bin/pip" install -q 'mutmut>=3,<4' pytest ||
    fail "could not install mutmut, so the check could not be rehearsed"
  PATH="$WORK/py/bin:$PATH"
  export PATH
fi

node - "$QUALITY" "$WORK" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync, spawnSync } = require('node:child_process');

const [quality, work] = process.argv.slice(2);

function listing(dir) {
  const out = [];
  (function walk(d) {
    for (const entry of fs.readdirSync(d, { withFileTypes: true })) {
      if (entry.name === '.git') continue;
      const full = path.join(d, entry.name);
      if (entry.isDirectory()) walk(full);
      else out.push(path.relative(dir, full) + ':' + fs.readFileSync(full, 'utf8'));
    }
  })(dir);
  return out.sort().join('\n');
}

function repo(name) {
  const dir = path.join(work, name);
  fs.mkdirSync(dir, { recursive: true });
  const git = args => execFileSync('git', args, { cwd: dir, encoding: 'utf8', env: { ...process.env,
    GIT_AUTHOR_NAME: 'R', GIT_AUTHOR_EMAIL: 'r@example.invalid', GIT_COMMITTER_NAME: 'R', GIT_COMMITTER_EMAIL: 'r@example.invalid' } }).trim();
  git(['init', '-q', '-b', 'main']);
  const put = files => {
    for (const [file, text] of Object.entries(files)) {
      fs.mkdirSync(path.dirname(path.join(dir, file)), { recursive: true });
      fs.writeFileSync(path.join(dir, file), text);
    }
  };
  const save = () => { git(['add', '-A']); git(['commit', '-q', '-m', 'Save']); return git(['rev-parse', 'HEAD']); };
  return { dir, put, save };
}

const probe = path.join(work, 'probe.txt');

function strength(dir, base) {
  const before = listing(dir);
  const result = spawnSync('python3', [quality, 'strength', '--base', base], { cwd: dir, encoding: 'utf8', timeout: 900000,
    env: { ...process.env, STRENGTH_PROBE: probe } });
  assert.ifError(result.error);
  console.log(result.stdout.trim().split('\n').map(l => `    ${l}`).join('\n'));
  assert.equal(listing(dir), before, 'the check left something changed in the project');
  const rows = result.stdout.trim().split('\n').filter(Boolean).map(l => l.split('\t'));
  const count = name => Number((rows.find(r => r[0] === name) || [])[1]);
  return { status: result.status, rows, tried: count('tried'), caught: count('caught'),
    missed: rows.filter(r => r[0] === 'missed'), out: result.stdout + result.stderr };
}

// --- a JavaScript piece ------------------------------------------------------------

const js = repo('javascript');
js.put({
  '.gitignore': 'node_modules/\n/reports/\n.stryker-tmp/\n.env\n',
  'package.json': JSON.stringify({ name: 'shop', private: true, scripts: { test: 'node --test' } }, null, 2) + '\n',
  'src/old.cjs': 'module.exports = n => n + 1;\n',
  'test/old.test.cjs': "const test = require('node:test');\nconst assert = require('node:assert/strict');\nconst old = require('../src/old.cjs');\ntest('old', () => assert.equal(old(1), 2));\n",
  // A folder of the project's own that shares its name with engine output.
  // The tests need it, so a copy that left it out could not run them.
  'src/reports/label.cjs': "module.exports = () => 'report';\n",
  // A test that writes down, outside the project, what the copy it ran in
  // held: the real .env must never be there, and .env.example always is.
  'test/probe.test.cjs': [
    "const test = require('node:test');",
    "const assert = require('node:assert/strict');",
    "const fs = require('node:fs');",
    "const path = require('node:path');",
    "test('probe', () => {",
    "  assert.equal(require('../src/reports/label.cjs')(), 'report');",
    "  const root = path.join(__dirname, '..');",
    "  if (process.env.STRENGTH_PROBE) fs.appendFileSync(process.env.STRENGTH_PROBE,",
    "    `env=${fs.existsSync(path.join(root, '.env'))} example=${fs.existsSync(path.join(root, '.env.example'))}\\n`);",
    "});",
    '',
  ].join('\n'),
  '.env.example': 'SHOP_API_KEY=\n',
});
const jsBase = js.save();
// The real keys, which git ignores and the throwaway copy must leave out.
fs.writeFileSync(path.join(js.dir, '.env'), 'SHOP_API_KEY=live-key-for-the-rehearsal\n');
js.put({
  'src/delivery.cjs': 'module.exports = total => total >= 50;\n',
  'test/delivery.test.cjs': "const test = require('node:test');\nconst assert = require('node:assert/strict');\nconst free = require('../src/delivery.cjs');\ntest('free delivery', () => {\n  assert.equal(free(49), false);\n  assert.equal(free(51), true);\n});\n",
});
js.save();

const weak = strength(js.dir, jsBase);
assert.equal(weak.status, 1, `weak tests should give exit code 1:\n${weak.out}`);
assert.ok(weak.tried >= 2 && weak.caught >= 1 && weak.caught === weak.tried - weak.missed.length, 'the counts do not add up');
assert.equal(weak.missed.length, 1, 'the weak test should miss exactly the boundary breakage');
assert.equal(weak.missed[0][1], 'src/delivery.cjs:1', 'the miss is not named at its file and line');
assert.match(weak.missed[0][2], />\s*50/, 'the miss does not say what was changed');
assert.ok(!weak.rows.some(r => (r[1] || '').startsWith('src/old.cjs')), 'code from before the piece was broken on purpose');
console.log('  ok: the weak test misses the boundary breakage, named at its line, and code from before the piece is left alone');
const seen = fs.readFileSync(probe, 'utf8').trim().split('\n');
assert.ok(seen.length >= 1 && seen.every(l => l === 'env=false example=true'),
  `the tests ran with the real .env in the copy, or without .env.example:\n${seen.join('\n')}`);
console.log('  ok: the tests ran in a copy with no real .env, with .env.example, and with the project\'s own reports folder');

js.put({ 'test/delivery.test.cjs': fs.readFileSync(path.join(js.dir, 'test/delivery.test.cjs'), 'utf8')
  .replace('assert.equal(free(51), true);', 'assert.equal(free(51), true);\n  assert.equal(free(50), true);') });
js.save();
const strong = strength(js.dir, jsBase);
assert.equal(strong.status, 0, `tests that cover the boundary should give exit code 0:\n${strong.out}`);
assert.equal(strong.missed.length, 0);
console.log('  ok: once a test covers the boundary, nothing is missed and the exit code is 0');

// --- a Python piece ----------------------------------------------------------------

const py = repo('python');
py.put({
  'pyproject.toml': '[project]\nname = "shop"\nversion = "0.1.0"\n',
  'shop/__init__.py': '',
  'shop/old.py': 'def bump(n):\n    return n + 1\n',
  'tests/test_old.py': 'from shop.old import bump\n\n\ndef test_bump():\n    assert bump(1) == 2\n',
});
const pyBase = py.save();
py.put({
  'shop/delivery.py': 'def free_delivery(total):\n    return total >= 50\n',
  'tests/test_delivery.py': 'from shop.delivery import free_delivery\n\n\ndef test_free():\n    assert free_delivery(49) is False\n    assert free_delivery(51) is True\n',
  // A method on a class, which mutmut names differently from a function.
  'shop/cart.py': 'class Cart:\n    def big_order(self, total):\n        return total >= 100\n',
  'tests/test_cart.py': 'from shop.cart import Cart\n\n\ndef test_big():\n    assert Cart().big_order(99) is False\n    assert Cart().big_order(101) is True\n',
});
const pyPiece = py.save();
const pyWeak = strength(py.dir, pyBase);
assert.equal(pyWeak.status, 1, `weak Python tests should give exit code 1:\n${pyWeak.out}`);
assert.ok(pyWeak.missed.some(r => r[1] === 'shop/delivery.py:2' && />\s*50/.test(r[2])), 'the Python boundary miss is not named at its line');
assert.ok(!pyWeak.rows.some(r => (r[1] || '').startsWith('shop/old.py')), 'Python code from before the piece was broken');
console.log('  ok: on a Python piece, the boundary miss is named at its line, and old code is left alone');
assert.ok(pyWeak.missed.some(r => r[1] === 'shop/cart.py:3' && />\s*100/.test(r[2])),
  'the method the piece changed was never broken, so its boundary miss is not named');
console.log('  ok: a changed method on a class is broken too, and its boundary miss is named at its line');

// A change outside any function breaks nothing, so nothing was checked: exit
// 2, never "tried 0" reported as a pass.
py.put({ 'shop/settings.py': 'LIMIT = 50\n' });
const pyGood = py.save();
const outside = strength(py.dir, pyPiece);
assert.equal(outside.status, 2, `a change with nothing to break should exit 2:\n${outside.out}`);
assert.match(outside.out, /^not-checked\tstrength\t/m);
console.log('  ok: a change with nothing the engine can break exits 2 and says it was not checked');

// Tests that already fail on the unchanged code: nothing was tried, exit 2.
py.put({
  'shop/delivery.py': 'def free_delivery(total):\n    return total >= 60\n',
});
py.save();
const failing = strength(py.dir, pyGood);
assert.equal(failing.status, 2, `tests that fail before anything is broken should exit 2:\n${failing.out}`);
assert.match(failing.out, /^not-checked\tstrength\tthe tests failed before any code was broken/m, 'the failed first run was not named');
assert.ok(!/^tried\t/m.test(failing.out), 'a run that broke nothing still printed a count');
console.log('  ok: tests that fail on the unchanged code exit 2, with no count');

const bad = spawnSync('python3', [quality, 'strength', '--base', 'no-such-commit'], { cwd: js.dir, encoding: 'utf8' });
assert.equal(bad.status, 2, 'a base that is not a commit did not exit 2');
console.log('  ok: a base that is not a commit exits 2');

console.log('\ntest-strength-rehearsal.sh: misses counted at their place, project untouched');
NODE
