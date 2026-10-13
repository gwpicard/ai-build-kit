#!/usr/bin/env sh
# structure-read-rehearsal.sh: run the shipped loop comparison against a
# throwaway project whose history holds a visit, an old loop and a new one.
#
# The project's last full visit is dated in its maintenance record, and one loop
# between two files was already there on that date. After it, a second loop is
# added. The script has to read the earlier structure again from the saved
# history and name only the new loop, at the line where each file imports the
# other, with exit code 1. Then the visit is recorded again and the script is
# run once more, which must print nothing and exit 0.
#
# The same comparison runs for one build, against the commit the piece started
# from, which is how /implement uses it. Each case runs twice, once with
# dependency-cruiser and once with the script's own import reader, since a
# project may have either. Every run must leave the project's working tree as
# it found it.
#
# The engine is used from PATH when present and otherwise installed into a
# throwaway folder. A machine that can do neither fails here rather than
# skipping, since a rehearsal that passes by never running proves nothing.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
QUALITY="$ROOT/.agents/skills/implement/scripts/quality.py"

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
  (cd "$WORK/engines" && npm install --no-audit --no-fund --silent dependency-cruiser@18) ||
    fail "could not install dependency-cruiser, so the read could not be rehearsed"
  PATH="$WORK/engines/node_modules/.bin:$PATH"
  export PATH
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

for (const reader of [[], ['--reader', 'builtin']]) {
  const label = reader.length ? "the script's own import reader" : 'dependency-cruiser';
  const before = tree();
  const said = loops(['--since-visit', ...reader], label);
  console.log(said.map(line => `    ${line}`).join('\n'));
  assert.deepEqual(said, [expected], `with ${label}, expected only the new loop`);
  assert.equal(tree(), before, 'the read left something in the project');
  console.log(`  ok: with ${label}, the loop added since the last visit is named at each import line, and the old one is not`);

  const build = loops(['--base', founding, ...reader]);
  assert.deepEqual(build, [expected], `with ${label}, a build against its starting commit did not name its loop`);
  console.log(`  ok: with ${label}, a build compared with its starting commit names the loop it added`);
}

// The next visit is recorded, and nothing changes after it.
put('.ai-build-kit-maintenance', ['last-light-pass: 2026-09-01', 'last-full-pass: 2026-09-01']);
git(['add', '-A']);
git(['commit', '-q', '-m', 'Record the next visit'], '2026-09-01T10:00:00');
for (const reader of [[], ['--reader', 'builtin']]) {
  assert.deepEqual(loops(['--since-visit', ...reader]), [], 'an unchanged project should produce nothing');
}
assert.equal(tree(), '', 'the second read left something in the project');
console.log('  ok: with nothing changed since the last visit, it prints nothing and exits 0');

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
assert.deepEqual(both.stdout.trim().split('\n').sort(), [
  'loop\tshop/invoices.py:1 imports shop/orders.py\tshop/orders.py:1 imports shop/invoices.py',
  'loop\tsrc/cart.ts:1 imports src/price.ts\tsrc/price.ts:1 imports src/cart.ts',
]);
console.log('  ok: the own reader follows a path alias from a commented tsconfig, and Python imports');

console.log('\nstructure-read-rehearsal.sh: the new loop named, an unchanged project silent');
NODE
