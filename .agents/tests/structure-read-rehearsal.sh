#!/usr/bin/env sh
# structure-read-rehearsal.sh: run the shipped loop read against a throwaway
# project whose history holds a visit, an old loop and a new one.
#
# For one build, compared with the commit the piece started from, only the
# loop the piece added is named, at the line where each file imports the
# other. For a visit, every loop no earlier visit offered is named, the old
# one included, since nothing says it ever reached the person. Once one is
# recorded as offered it is left out, and the other comes back; once both
# are, the read prints nothing and exits 0. Each case runs with
# dependency-cruiser and with the script's own import reader, and only the
# record of offers may change in the project.
#
# A project with a `@/` path alias and Python files is read too. With
# dependency-cruiser on hand, as a Next.js project has it, the alias is
# followed through the tsconfig and the Python imports still count.
#
# The engine is used from PATH when present and otherwise installed into a
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

if ! command -v depcruise >/dev/null 2>&1; then
  echo "  depcruise not on PATH, installing it into a throwaway folder"
  mkdir -p "$WORK/engines"
  printf '{"name":"engines","private":true}\n' > "$WORK/engines/package.json"
  # TypeScript comes too, as it does in a Next.js project, since that is what
  # dependency-cruiser reads TypeScript files and a tsconfig with.
  (cd "$WORK/engines" && npm install --no-audit --no-fund --silent dependency-cruiser@18 typescript@5) ||
    fail "could not install dependency-cruiser, so the read could not be rehearsed"
  PATH="$WORK/engines/node_modules/.bin:$PATH"
  REHEARSAL_INSTALLED_DEPCRUISE=1
  export PATH REHEARSAL_INSTALLED_DEPCRUISE
fi

node - "$QUALITY" "$WORK" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync, spawnSync } = require('node:child_process');

const [quality, work] = process.argv.slice(2);

const project = path.join(work, 'project');
fs.mkdirSync(path.join(project, 'src'), { recursive: true });
const git = (args, date) => execFileSync('git', args, {
  cwd: project, encoding: 'utf8',
  env: {
    ...process.env,
    GIT_AUTHOR_NAME: 'Rehearsal', GIT_AUTHOR_EMAIL: 'rehearsal@example.invalid',
    GIT_COMMITTER_NAME: 'Rehearsal', GIT_COMMITTER_EMAIL: 'rehearsal@example.invalid',
    ...(date ? { GIT_AUTHOR_DATE: date, GIT_COMMITTER_DATE: date } : {}),
  },
}).trim();
const put = (name, lines) => fs.writeFileSync(path.join(project, name), lines.join('\n') + '\n');
const tree = () => git(['status', '--porcelain', '--untracked-files=all']);

function loops(args, reader) {
  const result = spawnSync('python3', [quality, 'loops', ...args], { cwd: project, encoding: 'utf8', timeout: 180000 });
  assert.ifError(result.error);
  if (reader) assert.ok(result.stderr.includes(`reader: ${reader}`), `the script did not use ${reader}: ${result.stderr}`);
  const lines = result.stdout.trim().split('\n').filter(Boolean);
  assert.equal(result.status, lines.some(l => l.startsWith('loop\t')) ? 1 : 0,
    `the exit code does not match what was printed:\n${result.stdout}${result.stderr}`);
  return lines;
}

git(['init', '-q', '-b', 'main']);
put('package.json', ['{"name": "shop", "private": true, "type": "module"}']);
put('src/index.js', [
  "import { placeOrder } from './orders.js';",
  "import { pay } from './payments.js';",
  'placeOrder(); pay();',
]);
// A loop that was already there at the last visit.
put('src/payments.js', ["import { refund } from './refunds.js';", 'export const pay = () => refund;']);
put('src/refunds.js', ["import { pay } from './payments.js';", 'export const refund = () => pay;']);
put('src/orders.js', ['export const placeOrder = () => 1;']);
put('src/invoices.js', ['export const invoice = () => 2;']);
git(['add', '-A']);
git(['commit', '-q', '-m', 'Founding'], '2026-06-01T10:00:00');
const founding = git(['rev-parse', 'HEAD']);

put('.ai-build-kit-maintenance', ['last-light-pass: 2026-06-01', 'last-full-pass: 2026-06-01']);
git(['add', '-A']);
git(['commit', '-q', '-m', 'Record the visit'], '2026-06-01T16:00:00');

// After the visit, orders and invoices start to depend on each other.
put('src/orders.js', [
  '// Orders are placed here.',
  '',
  "import { invoice } from './invoices.js';",
  'export const placeOrder = () => invoice();',
]);
put('src/invoices.js', ["import { placeOrder } from './orders.js';", 'export const invoice = () => placeOrder;']);
git(['add', '-A']);
git(['commit', '-q', '-m', 'Invoice every order'], '2026-08-15T10:00:00');

const expected = 'loop\tsrc/invoices.js:1 imports src/orders.js\tsrc/orders.js:3 imports src/invoices.js';
const old = 'loop\tsrc/payments.js:1 imports src/refunds.js\tsrc/refunds.js:1 imports src/payments.js';

for (const reader of [[], ['--reader', 'builtin']]) {
  const label = reader.length ? "the script's own import reader" : 'dependency-cruiser';
  const build = loops(['--base', founding, ...reader], label);
  assert.deepEqual(build, [expected], `with ${label}, a build against its starting commit did not name its loop`);
  console.log(`  ok: with ${label}, a build compared with its starting commit names only the loop it added`);
}

// A visit offers what nobody was offered before, whenever it arrived. The old
// loop was there at the last visit, but nothing records that it was offered,
// so it is still printed: a loop that never reached the person is not hidden.
const offered = line => {
  const result = spawnSync('python3', [quality, 'offered', 'loops'], { cwd: project, encoding: 'utf8', input: line + '\n' });
  assert.equal(result.status, 0, result.stdout + result.stderr);
};
for (const reader of [[], ['--reader', 'builtin']]) {
  const said = loops(['--skip-offered', ...reader]);
  assert.deepEqual(said.sort(), [expected, old].sort(), 'a loop nobody was offered was hidden');
}
console.log('  ok: every loop no visit has offered is printed, including one from before the last visit');

// The visit offers one of the two, as if the cap had room for only one.
const before = tree();
offered(old);
assert.match(fs.readFileSync(path.join(project, '.ai-build-kit-maintenance'), 'utf8'),
  /^offered\|loops\|\d{4}-\d{2}-\d{2}\|src\/payments\.js\|src\/refunds\.js$/m, 'the offer was not recorded');
assert.match(fs.readFileSync(path.join(project, '.ai-build-kit-maintenance'), 'utf8'), /^last-full-pass: 2026-06-01$/m,
  'recording the offer lost the record\'s other lines');
for (const reader of [[], ['--reader', 'builtin']]) {
  assert.deepEqual(loops(['--skip-offered', ...reader]), [expected], 'the loop offered was printed again, or the other was lost');
}
console.log('  ok: the loop offered is not raised again, and the one that did not fit comes back');

offered(expected);
for (const reader of [[], ['--reader', 'builtin']]) {
  assert.deepEqual(loops(['--skip-offered', ...reader]), [], 'with every loop offered, it should print nothing');
}
assert.equal(before, '', 'the reads left something in the project');
assert.equal(tree(), 'M .ai-build-kit-maintenance', 'recording the offers changed something beyond the record');
console.log('  ok: once every loop has been offered, it prints nothing and exits 0, and only the record changed');

const bad = spawnSync('python3', [quality, 'loops', '--base', 'no-such-commit'], { cwd: project, encoding: 'utf8' });
assert.equal(bad.status, 2, 'an earlier state that cannot be read did not exit 2');
assert.match(bad.stdout, /^not-compared\t/m);
console.log('  ok: an earlier state that cannot be read says so and exits 2');

// A path alias, as a Next.js project writes one, and a Python package, read by
// the script's own reader.
const other = path.join(work, 'other');
fs.mkdirSync(path.join(other, 'src'), { recursive: true });
fs.mkdirSync(path.join(other, 'shop'), { recursive: true });
const g = args => execFileSync('git', args, { cwd: other, encoding: 'utf8', env: { ...process.env,
  GIT_AUTHOR_NAME: 'R', GIT_AUTHOR_EMAIL: 'r@example.invalid', GIT_COMMITTER_NAME: 'R', GIT_COMMITTER_EMAIL: 'r@example.invalid' } }).trim();
const w = (name, text) => fs.writeFileSync(path.join(other, name), text);
g(['init', '-q', '-b', 'main']);
w('tsconfig.json', '{\n  // the starter writes comments\n  "compilerOptions": { "paths": { "@/*": ["./src/*"] }, },\n}\n');
w('src/cart.ts', "export const cart = () => 1;\n");
w('src/price.ts', "export const price = () => 2;\n");
w('shop/__init__.py', '');
w('shop/orders.py', 'def place():\n    return 1\n');
w('shop/invoices.py', 'def invoice():\n    return 2\n');
g(['add', '-A']);
g(['commit', '-q', '-m', 'Start']);
const startedAt = g(['rev-parse', 'HEAD']);
w('src/cart.ts', "import { price } from '@/price';\nexport const cart = () => price();\n");
w('src/price.ts', "import { cart } from './cart';\nexport const price = () => cart;\n");
w('shop/orders.py', 'from shop import invoices\n\n\ndef place():\n    return invoices.invoice()\n');
w('shop/invoices.py', 'from .orders import place\n\n\ndef invoice():\n    return place\n');
const both = spawnSync('python3', [quality, 'loops', '--base', startedAt, '--reader', 'builtin'], { cwd: other, encoding: 'utf8' });
assert.equal(both.status, 1, both.stdout + both.stderr);
const aliasLoops = [
  'loop\tshop/invoices.py:1 imports shop/orders.py\tshop/orders.py:1 imports shop/invoices.py',
  'loop\tsrc/cart.ts:1 imports src/price.ts\tsrc/price.ts:1 imports src/cart.ts',
];
assert.deepEqual(both.stdout.trim().split('\n').sort(), aliasLoops);
console.log('  ok: the own reader follows a path alias from a commented tsconfig, and Python imports');

// The same project with a package file, as a Next.js project has, so the
// script reaches for dependency-cruiser. The `@/` alias and the Python files
// are still followed: a loop through either is not missed.
w('package.json', '{"name": "shop", "private": true}\n');
const auto = spawnSync('python3', [quality, 'loops', '--base', startedAt], { cwd: other, encoding: 'utf8' });
assert.equal(auto.status, 1, auto.stdout + auto.stderr);
assert.deepEqual(auto.stdout.trim().split('\n').sort(), aliasLoops,
  `with dependency-cruiser on hand, a loop through the alias or through Python was missed (${auto.stderr.trim()})`);
if (process.env.REHEARSAL_INSTALLED_DEPCRUISE) {
  assert.match(auto.stderr, /reader: dependency-cruiser/, 'dependency-cruiser did not read the alias through the tsconfig');
}
console.log(`  ok: with dependency-cruiser on hand, the alias and the Python imports are still followed (${auto.stderr.trim()})`);

console.log('\nstructure-read-rehearsal.sh: the loop a build added named, offered loops left out');
NODE
