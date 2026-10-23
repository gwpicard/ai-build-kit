#!/usr/bin/env sh
# recipe-ci-rehearsal.sh: checks the starter's health response and runs its parsed CI commands.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
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
(cd "$WORK/engines" && npm install --no-audit --no-fund --silent eslint@9.36.0 typescript@5.9.2 "@supabase/supabase-js@$sdk") ||
  fail "could not install the engines for the kit-folder boundary check"
node - "$PROJECT" "$WORK/engines" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const { pathToFileURL } = require('node:url');
const [project, engines] = process.argv.slice(2);
const requireEngine = createRequire(path.join(engines, 'package.json'));
const { ESLint } = requireEngine('eslint');
const ts = requireEngine('typescript');
(async () => {
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

ruby -ryaml -rjson -e '
workflow = YAML.load_file(ARGV[0])
permissions = workflow.fetch("permissions")
raise "the pull-request token cannot read pull requests" unless permissions == {"contents"=>"read", "pull-requests"=>"read"}
steps = workflow.fetch("jobs").fetch("project-check").fetch("steps")
detect = steps.find { |step| step["name"] == "Detect the selected recipe" }
test = steps.find { |step| step["name"] == "Install and test" }
raise "recipe detection step is missing" unless detect && detect["run"].include?("Recipe:")
raise "recipe setup does not run only on a recipe" unless steps.any? { |step| step["uses"].to_s.start_with?("supabase/setup-cli") && step["if"] == "steps.recipe.outputs.selected == '\''true'\''" }
raise "Node setup does not run only on a recipe" unless steps.any? { |step| step["uses"].to_s.start_with?("actions/setup-node") && step["if"] == "steps.recipe.outputs.selected == '\''true'\''" }
raise "recipe test step is missing its recipe guard" unless test && test["if"] == "steps.recipe.outputs.selected == '\''true'\''"
["npm ci", "supabase start", "supabase db reset", "npx vitest run --coverage", "npx next typegen", "npx tsc --noEmit", "supabase gen types typescript --local", "diff", "npm run build", "npx next start", "npx playwright test"].each do |command|
  raise "missing CI command: #{command}" unless test["run"].include?(command)
end
File.write(ARGV[1], test.fetch("run"))
' "$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml" "$WORK/recipe-check.sh" || fail "foundation checks.yml does not parse or lacks recipe steps"
pass "the foundation workflow parses and limits recipe steps to the selected recipe"

mkdir -p "$WORK/bin"
cat > "$WORK/bin/log-command" <<'CMD'
#!/usr/bin/env sh
printf '%s %s\n' "$(basename "$0")" "$*" >> "$CI_COMMAND_LOG"
CMD
for command in npm npx curl; do cp "$WORK/bin/log-command" "$WORK/bin/$command"; chmod +x "$WORK/bin/$command"; done
cat > "$WORK/bin/supabase" <<'CMD'
#!/usr/bin/env sh
printf 'supabase %s\n' "$*" >> "$CI_COMMAND_LOG"
if [ "$1 $2 $3" = "gen types typescript" ]; then cat types/database.ts; fi
CMD
chmod +x "$WORK/bin/supabase"
printf '' > "$WORK/commands.log"
(cd "$PROJECT" && PATH="$WORK/bin:$PATH" CI_COMMAND_LOG="$WORK/commands.log" bash "$WORK/recipe-check.sh") || fail "recipe CI commands did not run in the founded starter"
for command in 'npm ci' 'supabase start' 'supabase db reset' 'npx vitest run --coverage' 'npx next typegen' 'npx tsc --noEmit' 'supabase gen types typescript --local' 'npm run build' 'npx next start' 'npx playwright test'; do
  grep -Fq "$command" "$WORK/commands.log" || fail "recipe CI did not run: $command"
done
pass "recipe CI commands ran in a founded recipe starter, including coverage, types, drift and Playwright"

