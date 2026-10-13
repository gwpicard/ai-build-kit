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
# The same runs for a Python piece.
#
# The engines are used from PATH when present and otherwise installed into a
# throwaway folder. A machine that can do neither fails here rather than
# skipping, since a rehearsal that passes by never running proves nothing.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
QUALITY="$ROOT/.agents/skills/section-builder/scripts/quality.py"

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

function strength(dir, base) {
  const before = listing(dir);
  const result = spawnSync('python3', [quality, 'strength', '--base', base], { cwd: dir, encoding: 'utf8', timeout: 900000 });
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
  '.gitignore': 'node_modules/\nreports/\n.stryker-tmp/\n',
  'package.json': JSON.stringify({ name: 'shop', private: true, scripts: { test: 'node --test' } }, null, 2) + '\n',
  'src/old.cjs': 'module.exports = n => n + 1;\n',
  'test/old.test.cjs': "const test = require('node:test');\nconst assert = require('node:assert/strict');\nconst old = require('../src/old.cjs');\ntest('old', () => assert.equal(old(1), 2));\n",
});
const jsBase = js.save();
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
});
py.save();
const pyWeak = strength(py.dir, pyBase);
assert.equal(pyWeak.status, 1, `weak Python tests should give exit code 1:\n${pyWeak.out}`);
assert.ok(pyWeak.missed.some(r => r[1] === 'shop/delivery.py:2' && />\s*50/.test(r[2])), 'the Python boundary miss is not named at its line');
assert.ok(!pyWeak.rows.some(r => (r[1] || '').startsWith('shop/old.py')), 'Python code from before the piece was broken');
console.log('  ok: on a Python piece, the boundary miss is named at its line, and old code is left alone');

const bad = spawnSync('python3', [quality, 'strength', '--base', 'no-such-commit'], { cwd: js.dir, encoding: 'utf8' });
assert.equal(bad.status, 2, 'a base that is not a commit did not exit 2');
console.log('  ok: a base that is not a commit exits 2');

console.log('\ntest-strength-rehearsal.sh: misses counted at their place, project untouched');
NODE
