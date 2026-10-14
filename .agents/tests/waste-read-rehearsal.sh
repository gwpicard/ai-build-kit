#!/usr/bin/env sh
# waste-read-rehearsal.sh: run the shipped waste read against a throwaway
# project with one known copy, one unused export and one unused dependency,
# and read back that each is printed at a real file and line, that a visit
# leaves out only what an earlier visit recorded as offered, that a finding
# that did not fit comes back, that a missing engine answers 2 with the other
# findings still printed, that a clean project prints nothing, and that the
# read wrote nothing into any of them.
#
# The project carries a decoy, an export the engine calls unused that a
# configuration file names, which the script's second look must drop. A
# Python project is read the same way, for code that cannot run and a
# dependency nothing imports.
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

if ! command -v knip >/dev/null 2>&1 || ! command -v jscpd >/dev/null 2>&1; then
  echo "  knip or jscpd not on PATH, installing both into a throwaway folder"
  mkdir -p "$WORK/engines"
  printf '{"name":"engines","private":true}\n' > "$WORK/engines/package.json"
  (cd "$WORK/engines" && npm install --no-audit --no-fund --silent knip@6 jscpd@5) ||
    fail "could not install knip and jscpd, so the read could not be rehearsed"
  PATH="$WORK/engines/node_modules/.bin:$PATH"
  export PATH
fi

if ! command -v vulture >/dev/null 2>&1 || ! command -v deptry >/dev/null 2>&1; then
  echo "  vulture or deptry not on PATH, installing both into a throwaway folder"
  python3 -m venv "$WORK/py" && "$WORK/py/bin/pip" install -q vulture deptry ||
    fail "could not install vulture and deptry, so the read could not be rehearsed"
  PATH="$WORK/py/bin:$PATH"
  export PATH
fi

node - "$QUALITY" "$WORK" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync, spawnSync } = require('node:child_process');

const [quality, work] = process.argv.slice(2);

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
].join('\n');

function listing(dir) {
  const out = [];
  (function walk(d) {
    for (const entry of fs.readdirSync(d, { withFileTypes: true })) {
      if (entry.name === '.git') continue;
      const full = path.join(d, entry.name);
      if (entry.isDirectory()) walk(full);
      else out.push(path.relative(dir, full) + ':' + fs.statSync(full).size);
    }
  })(dir);
  return out.sort().join('\n');
}

function repo(name) {
  const dir = path.join(work, name);
  fs.mkdirSync(dir, { recursive: true });
  const git = (args, date) => execFileSync('git', args, { cwd: dir, encoding: 'utf8', env: { ...process.env,
    GIT_AUTHOR_NAME: 'R', GIT_AUTHOR_EMAIL: 'r@example.invalid', GIT_COMMITTER_NAME: 'R', GIT_COMMITTER_EMAIL: 'r@example.invalid',
    ...(date ? { GIT_AUTHOR_DATE: date, GIT_COMMITTER_DATE: date } : {}) } }).trim();
  git(['init', '-q', '-b', 'main']);
  const put = files => {
    for (const [file, text] of Object.entries(files)) {
      fs.mkdirSync(path.dirname(path.join(dir, file)), { recursive: true });
      fs.writeFileSync(path.join(dir, file), text);
    }
  };
  const save = (message, date) => { git(['add', '-A']); git(['commit', '-q', '-m', message], date); };
  return { dir, put, save };
}

function waste(dir, args = [], env = undefined) {
  const before = listing(dir);
  const result = spawnSync(env ? env.python : 'python3', [quality, 'waste', ...args],
    { cwd: dir, encoding: 'utf8', timeout: 300000, env: env ? env.vars : process.env });
  assert.ifError(result.error);
  const rows = result.stdout.trim().split('\n').filter(Boolean).map(l => l.split('\t'));
  Object.defineProperty(rows, 'status', { value: result.status, enumerable: false });
  const found = rows.filter(r => !r[0].startsWith('not-'));
  const expected = rows.some(r => r[0] === 'not-checked') ? 2 : found.length ? 1 : 0;
  assert.equal(result.status, expected, `the exit code does not match what was printed:\n${result.stdout}${result.stderr}`);
  assert.equal(listing(dir), before, 'the read wrote something into the project');
  for (const row of found) {
    const [file, line] = row[1].split(/:(?=\d+$)/);
    const lines = fs.readFileSync(path.join(dir, file), 'utf8').split('\n');
    assert.ok(Number(line) >= 1 && Number(line) <= lines.length, `${file} has no line ${line}`);
  }
  if (rows.length) console.log(rows.map(r => `    ${r.join(' ')}`).join('\n'));
  return rows;
}

// --- the wasteful project ------------------------------------------------------

const shop = repo('project');
shop.put({
  '.gitignore': 'node_modules/\n',
  'package.json': JSON.stringify({
    name: 'shop', private: true, type: 'module', main: 'src/index.js',
    dependencies: { 'left-pad': '1.3.0' },
  }, null, 2) + '\n',
  'routes.json': JSON.stringify({ '/refunds': 'handleRefunds' }, null, 2) + '\n',
  'src/index.js': [
    "import { total } from './pricing.js';",
    "import { reportTotal } from './report.js';",
    "import * as handlers from './handlers.js';",
    'console.log(total([]), reportTotal([]), handlers);',
    '',
  ].join('\n'),
  'src/pricing.js': block('total') + '\n\nexport function discount(price) {\n  return price * 0.9;\n}\n',
  'src/report.js': block('reportTotal').replace(/\bsum\b/g, 'running').replace(/\bitem\b/g, 'line') + '\n',
  'src/handlers.js': "export function handleOrders() {\n  return 'orders';\n}\n\nexport function handleRefunds() {\n  return 'refunds';\n}\n",
});
shop.save('Founding', '2026-06-01T10:00:00');

const all = waste(shop.dir);
const kinds = kind => all.filter(r => r[0] === kind);
assert.deepEqual(kinds('copy').map(r => [r[1], r[2]]), [['src/pricing.js:1', 'src/report.js:1']], 'the renamed copy was not named with both places');
console.log('  ok: the renamed copy is named with both files and lines');
assert.ok(kinds('unused-export').some(r => r[1] === 'src/pricing.js:13' && r[2] === 'discount'), 'the unused export was not named at its line');
console.log('  ok: the unused export is named at its line');
const pad = kinds('unused-dependency').find(r => r[2] === 'left-pad');
assert.ok(pad && /^package\.json:\d+$/.test(pad[1]), 'the unused dependency was not named with its line');
console.log('  ok: the unused dependency is named with its line in the package file');
assert.ok(!all.some(r => r[2] === 'handleRefunds'), 'the export a configuration file names was not dropped');
console.log('  ok: an export named in a configuration file is dropped on the second look');
assert.ok(!all.some(r => r.join(' ').match(/\d\s*%|percent/i)), 'a percentage reached the output');

assert.equal(all.status, 1);
assert.ok(!all.some(r => r[0] === 'not-checked'), 'a part was not checked with every engine on hand');

// The visit had room for two of the three, so only those two reached the
// person and are recorded as offered. The third never did.
shop.put({ '.ai-build-kit-maintenance': 'last-light-pass: 2026-06-01\nlast-full-pass: 2026-06-01\n' });
shop.save('Record the visit', '2026-06-01T16:00:00');
const named = all.filter(r => r[0] === 'copy' || r[2] === 'discount').map(r => r.join('\t'));
const recorded = spawnSync('python3', [quality, 'offered', 'waste'], { cwd: shop.dir, encoding: 'utf8', input: named.join('\n') + '\n' });
assert.equal(recorded.status, 0, recorded.stdout + recorded.stderr);
const record = fs.readFileSync(path.join(shop.dir, '.ai-build-kit-maintenance'), 'utf8');
assert.match(record, /^offered\|waste\|\d{4}-\d{2}-\d{2}\|copy\|src\/pricing\.js\|src\/report\.js$/m, 'the copy offered was not recorded');
assert.match(record, /^offered\|waste\|\d{4}-\d{2}-\d{2}\|unused-export\|src\/pricing\.js\|discount$/m, 'the export offered was not recorded');
assert.match(record, /^last-full-pass: 2026-06-01$/m, 'recording the offers lost the record\'s other lines');
shop.save('Record what the visit offered', '2026-06-01T17:00:00');

// Later, one more unused export arrives, and the lines above it move.
shop.put({ 'src/pricing.js': '// Prices.\n\n' + fs.readFileSync(path.join(shop.dir, 'src/pricing.js'), 'utf8') +
  '\nexport function surcharge(price) {\n  return price * 1.1;\n}\n' });
shop.save('Add a surcharge', '2026-08-01T10:00:00');
const fresh = waste(shop.dir, ['--skip-offered']);
assert.deepEqual(fresh.map(r => [r[0], r[2]]).sort(), [['unused-dependency', 'left-pad'], ['unused-export', 'surcharge']],
  'the next visit should leave out only what was offered, and bring back what did not fit');
console.log('  ok: what a visit offered is left out after, even moved, and a finding that did not fit comes back');

// Some engines but not all: what ran is printed, the part with no engine is
// named, and the answer is 2.
const some = path.join(work, 'some-engines');
fs.mkdirSync(some);
for (const tool of ['git', 'node', 'python3', 'knip']) {
  fs.symlinkSync(execFileSync('sh', ['-c', `command -v ${tool}`], { encoding: 'utf8' }).trim(), path.join(some, tool));
}
const partial = waste(shop.dir, [], { python: path.join(some, 'python3'), vars: { PATH: some, HOME: process.env.HOME } });
assert.equal(partial.status, 2, 'with jscpd missing the read did not exit 2');
assert.ok(partial.some(r => r[0] === 'not-checked' && r[1] === 'copies'), 'the copy check that could not run was not named');
assert.ok(partial.some(r => r[0] === 'unused-export' && r[2] === 'surcharge'), 'the findings from the engine that ran were not printed');
assert.ok(partial.some(r => r[0] === 'unused-export' && r[2] === 'discount'),
  'a finding the record names as offered was taken for a use of it, and dropped');
console.log('  ok: with one engine missing, it prints what the others found, names the part not checked, and exits 2');

// --- the clean project ---------------------------------------------------------

const clean = repo('clean');
clean.put({
  'package.json': JSON.stringify({ name: 'shop', private: true, type: 'module', main: 'src/index.js' }, null, 2) + '\n',
  'src/index.js': "import { total } from './pricing.js';\nconsole.log(total([]));\n",
  'src/pricing.js': block('total') + '\n',
});
clean.save('Founding');
assert.deepEqual(waste(clean.dir), [], 'a clean project should print nothing');
console.log('  ok: a clean project prints nothing and exits 0');

// --- a Python project ----------------------------------------------------------

const py = repo('python');
py.put({
  'pyproject.toml': '[project]\nname = "shop"\nversion = "0.1.0"\ndependencies = [\n    "requests>=2",\n]\n',
  'shop/__init__.py': '',
  'shop/app.py': 'def total(prices):\n    return sum(prices)\n    print("never runs")\n\n\nprint(total([1, 2]))\n',
});
py.save('Founding');
const pyRows = waste(py.dir);
assert.ok(pyRows.some(r => r[0] === 'unreachable-code' && r[1] === 'shop/app.py:3'), 'the code after a return was not named');
assert.ok(pyRows.some(r => r[0] === 'unused-dependency' && r[2] === 'requests' && r[1] === 'pyproject.toml:5'),
  'the Python dependency nothing imports was not named at its line');
console.log('  ok: in a Python project, code that cannot run and an unused dependency are named at their lines');

console.log('\nwaste-read-rehearsal.sh: all kinds named, only what was offered left out, clean project silent');
NODE
