#!/usr/bin/env sh
# recipe-ci-rehearsal.sh: checks the starter's health response and runs its parsed CI commands.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -R "$WORK"' EXIT INT TERM
PROJECT="$WORK/project"
mkdir -p "$PROJECT"
fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }

sh "$ROOT/.agents/skills/setup-ai-build-kit/scripts/use-starter.sh" recipes/nextjs-supabase-on-vercel "$PROJECT" >/dev/null
sh "$ROOT/.agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh" "$PROJECT" >/dev/null
sed -i.bak 's/^Recipe: none$/Recipe: nextjs-supabase-on-vercel/' "$PROJECT/AGENTS.md" 2>/dev/null || \
  sed -i 's/^Recipe: none$/Recipe: nextjs-supabase-on-vercel/' "$PROJECT/AGENTS.md"
[ -f "$PROJECT/.agents/hooks/check-review.sh" ] || fail "founding did not install check-review.sh"
[ -f "$PROJECT/.agents/hooks/review_boxes.py" ] || fail "founding did not install the shared review reader"

# Use real check engines for the installed-source boundary. The empty Next
# presets isolate the starter's own exclusions from framework defaults.
mkdir -p "$WORK/engines"
printf '{"private":true}\n' > "$WORK/engines/package.json"
sdk=$(node -p 'require(process.argv[1]).dependencies["@supabase/supabase-js"]' "$PROJECT/package.json")
(cd "$WORK/engines" && npm install --no-audit --no-fund --silent eslint@9.36.0 typescript@5.9.2 eslint-plugin-better-tailwindcss@4.10.0 tailwindcss@4.3.3 "@supabase/supabase-js@$sdk") ||
  fail "could not install the engines for the kit-folder boundary check"
node --input-type=module - "$PROJECT" "$WORK/engines" <<'NODE'
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
const [project, engines] = process.argv.slice(2);
const requireEngine = createRequire(path.join(engines, 'package.json'));
const { ESLint } = requireEngine('eslint');
const ts = requireEngine('typescript');
(async () => {
  process.chdir(project);
  fs.mkdirSync(path.join(project, 'node_modules'), { recursive: true });
  fs.symlinkSync(path.join(engines, 'node_modules/eslint-plugin-better-tailwindcss'), path.join(project, 'node_modules/eslint-plugin-better-tailwindcss'));
  fs.symlinkSync(path.join(engines, 'node_modules/tailwindcss'), path.join(project, 'node_modules/tailwindcss'));
  const preset = path.join(project, 'node_modules/eslint-config-next');
  fs.mkdirSync(preset, { recursive: true });
  fs.writeFileSync(path.join(preset, 'package.json'), JSON.stringify({
    type: 'module', exports: { './core-web-vitals': './empty.js', './typescript': './empty.js' },
  }));
  fs.writeFileSync(path.join(preset, 'empty.js'), 'export default [];');
  for (const folder of ['.agents/skills/sample', '.claude/skills/sample', 'src']) {
    fs.mkdirSync(path.join(project, folder), { recursive: true });
    fs.writeFileSync(path.join(project, folder, 'lint-boundary.js'), 'missingName();');
    fs.writeFileSync(path.join(project, folder, 'type-boundary.ts'), 'const value: string = 42;');
  }
  const { default: config } = await import(pathToFileURL(path.join(project, 'eslint.config.mjs')));
  const eslint = new ESLint({ cwd: project, overrideConfigFile: true,
    overrideConfig: [...config, { files: ['**/*.js'], rules: { 'no-undef': 'error' } }],
  });
  const results = await eslint.lintFiles(['.']);
  assert.ok(results.some(result => result.filePath.endsWith('/src/lint-boundary.js') && result.errorCount > 0),
    'ESLint stopped checking application source');
  assert.ok(!results.some(result => /\/\.(agents|claude)\//.test(result.filePath)),
    'ESLint read installed kit source');
  const loaded = ts.readConfigFile(path.join(project, 'tsconfig.json'), ts.sys.readFile);
  assert.ok(!loaded.error, 'TypeScript configuration could not be read');
  const parsed = ts.parseJsonConfigFileContent(loaded.config, ts.sys, project);
  assert.ok(parsed.fileNames.some(file => file.endsWith('/src/type-boundary.ts')),
    'TypeScript stopped checking application source');
  assert.ok(!parsed.fileNames.some(file => /\/\.(agents|claude)\//.test(file)),
    'TypeScript read installed kit source');
})().catch(error => { console.error(error); process.exitCode = 1; });
NODE
pass "real ESLint and TypeScript exclude installed kit source while checking application source"

node --input-type=module - "$PROJECT" "$WORK/engines" "$ROOT" <<'NODE'
import assert from 'node:assert/strict';
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { createRequire } from 'node:module';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
const [project, engines, root] = process.argv.slice(2);
const requireEngine = createRequire(path.join(engines, 'package.json'));
const ts = requireEngine('typescript');
const source = fs.readFileSync(path.join(project, 'src/app/api/health/route.ts'), 'utf8');
const compiled = path.join(engines, 'health-route.mjs');
fs.writeFileSync(compiled, ts.transpileModule(source, {
  compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 },
}).outputText);
let unavailable = false;
let requests = 0;
const database = http.createServer((request, response) => {
  assert.ok(request.url.startsWith('/rest/v1/roles?'), 'health did not query the database');
  requests++;
  response.writeHead(unavailable ? 500 : 200, { 'content-type': 'application/json' });
  response.end(unavailable ? JSON.stringify({ message: 'database unavailable' }) : '[]');
});
await new Promise(resolve => database.listen(0, '127.0.0.1', resolve));
try {
  process.env.NEXT_PUBLIC_SUPABASE_URL = `http://127.0.0.1:${database.address().port}`;
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_contract_test';
  process.env.SOURCE_COMMIT = 'health-contract';
  delete process.env.VERCEL_GIT_COMMIT_SHA;
  const { GET } = await import(pathToFileURL(compiled));
  const healthy = await GET();
  assert.equal(healthy.status, 200);
  const body = await healthy.json();
  assert.equal(body.status, 'ok');
  assert.equal(body.commit, 'health-contract');
  assert.equal(requests, 1);
  const answer = path.join(engines, 'health-answer.json');
  fs.writeFileSync(answer, JSON.stringify(body));
  const parsed = spawnSync('sh', ['-c', '. "$1"; cl_health_fields "$2"', 'health-contract',
    path.join(root, '.agents/skills/setup-hosting/recipes/parts/scripts/check-lib.sh'), answer], { encoding: 'utf8' });
  assert.equal(parsed.status, 0, parsed.stderr);
  assert.equal(parsed.stdout.trim().split('\n')[1], 'ok', 'recipe checks reject the actual starter health response');
  unavailable = true;
  const failed = await GET();
  assert.equal(failed.status, 503);
  assert.equal((await failed.json()).database, 'unavailable');
  delete process.env.NEXT_PUBLIC_SUPABASE_URL;
  assert.equal((await GET()).status, 503);
} finally {
  await new Promise(resolve => database.close(resolve));
}
NODE
pass "the actual starter health response passes recipe parsing, and database failures return 503"

# The starter workflow owns every project-check command. The foundation keeps
# the review and secret checks, and refuses a recipe with no project workflow.
ruby -ryaml -e '
steps = YAML.load_file(ARGV[0]).fetch("jobs").fetch("project-check").fetch("steps")
raise "the foundation still runs its own recipe commands" if steps.any? { |step| step.fetch("run", "").match?(/npm ci|supabase start|playwright test/) }
raise "the foundation does not require the recipe workflow" unless steps.any? { |step| step["run"] == "test -f .github/workflows/check.yml" }
' "$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml"

PROJECT="$WORK/workflow-project"
mkdir "$PROJECT"
sh "$ROOT/.agents/skills/setup-ai-build-kit/scripts/use-starter.sh" recipes/nextjs-supabase-on-vercel "$PROJECT" >/dev/null
sh "$ROOT/.agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh" "$PROJECT" >/dev/null
# A unique name keeps this disposable database away from an existing project.
python3 - "$PROJECT/supabase/config.toml" "recipe-ci-$$" <<'PYTHON'
from pathlib import Path
import sys
p = Path(sys.argv[1])
p.write_text(p.read_text().replace('project_id = "nextjs-supabase"', 'project_id = "' + sys.argv[2] + '"'))
instructions = p.parents[1] / "AGENTS.md"
instructions.write_text(instructions.read_text().replace("Recipe: none", "Recipe: nextjs-supabase-on-vercel"))
PYTHON
WORKFLOW="$PROJECT/.github/workflows/check.yml"
RUNNER="$ROOT/.agents/tests/lib/recipe-workflow.rb"
# Run the database fault cases before the full run, whose final step stops it.
# Both the successful checks and the failures execute the workflow commands.
run_steps() { ruby "$RUNNER" "$WORKFLOW" "$PROJECT" "$1"; }
cleanup() {
  (cd "$PROJECT" && supabase stop --no-backup > "$WORK/stop.log" 2>&1) || true
  rm -R "$WORK"
}
trap cleanup EXIT INT TERM
run_steps versions,database,connection,database-types,row-rules || fail "the clean database checks failed"
cp "$PROJECT/types/database.ts" "$WORK/clean-types.ts"
python3 - "$PROJECT/types/database.ts" <<'PYTHON'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text()
assert "role: string" in text
p.write_text(text.replace("role: string", "role: number", 1))
PYTHON
if run_steps database-types > "$WORK/types-fault.log" 2>&1; then
  fail "planted stale database types passed"
fi
grep -q 'Time: Check database types against migrations | fail' "$WORK/types-fault.log" || { cat "$WORK/types-fault.log"; fail "another step failed instead of the database types check"; }
grep -qF 'role: number' "$WORK/types-fault.log" && grep -qF 'role: string' "$WORK/types-fault.log" || { cat "$WORK/types-fault.log"; fail "the types check did not report the planted type difference"; }
pass "planted stale types/database.ts: Check database types against migrations caught it"
cp "$WORK/clean-types.ts" "$PROJECT/types/database.ts"
run_steps database-types || fail "restored database types did not pass"
printf 'create table public.unprotected_notes (id bigint primary key);\n' > "$PROJECT/supabase/migrations/20261023000000_unprotected_notes.sql"
run_steps database || fail "the planted migration did not apply"
# Keep the new table's types current, so row rules are the only planted fault.
(cd "$PROJECT" && supabase gen types typescript --local --schema public > types/database.ts) || fail "could not generate types for the planted table"
if run_steps connection,database-types,row-rules > "$WORK/row-fault.log" 2>&1; then
  fail "planted table without row-level security passed"
fi
grep -q 'Time: Check every table has row rules | fail' "$WORK/row-fault.log" || { cat "$WORK/row-fault.log"; fail "another step failed instead of the row rules check"; }
grep -q unprotected_notes "$WORK/row-fault.log" || fail "row rules did not name the planted table"
pass "planted migration without row-level security on unprotected_notes: Check every table has row rules caught it"
rm "$PROJECT/supabase/migrations/20261023000000_unprotected_notes.sql"
cp "$WORK/clean-types.ts" "$PROJECT/types/database.ts"
# The workflow rebuilds the clean database from migrations before measuring.
run_steps stop || fail "the fault-case database did not stop"
ruby "$RUNNER" "$WORKFLOW" "$PROJECT" all "${RECIPE_CI_TIMINGS:-$WORK/timings.json}" || fail "the starter workflow failed on this computer"
pass "recipe-ci-rehearsal.sh: the workflow shell steps passed in a founded starter; both database faults failed at their checks; GitHub actions remain untried"
