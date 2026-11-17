#!/usr/bin/env sh
# handover-contract.sh: prove the released schema validates a copied project and rejects planted handover drift.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -R "$WORK"' EXIT
sh "$ROOT/.agents/tools/build-release.sh" v0.0.0-handover "$WORK/release" > "$WORK/release.log"
cmp "$ROOT/hosting/handover.schema.json" "$WORK/release/hosting/handover.schema.json"
PROJECT="$WORK/project"
mkdir "$PROJECT"
for path in src scripts db hosting masterplan.md Dockerfile .env.example; do
  cp -R "$ROOT/templates/nextjs-postgres/$path" "$PROJECT/$path"
done
cp "$WORK/release/hosting/handover.schema.json" "$PROJECT/hosting/handover.schema.json"
cp "$WORK/release/.agents/skills/merge/scripts/host-record.cjs" "$PROJECT/hosting/"
cp "$WORK/release/.agents/skills/merge/contracts/ai-host-kit/host-record.schema.json" "$PROJECT/hosting/"
mkdir "$PROJECT/tests"
cp "$ROOT/templates/nextjs-postgres/tests/handover.test.mjs" "$PROJECT/tests/"
cp "$ROOT/templates/nextjs-postgres/tests/host-record.test.mjs" "$PROJECT/tests/"
mkdir -p "$PROJECT/tests/fixtures/host-record"
cp "$ROOT/.agents/tests/fixtures/host-record/"*.json "$PROJECT/tests/fixtures/host-record/"
node --input-type=module - "$ROOT" "$PROJECT" <<'JS'
import { readFileSync, writeFileSync } from 'node:fs';
const [root, project] = process.argv.slice(2);
const deps = JSON.parse(readFileSync(`${root}/templates/nextjs-postgres/package.json`)).devDependencies;
writeFileSync(`${project}/package.json`, JSON.stringify({ private: true, type: 'module', dependencies: { ajv: deps.ajv, typescript: deps.typescript } }));
JS
cd "$PROJECT"
npm install --ignore-scripts --no-audit --no-fund > "$WORK/install.log" 2>&1 || { cat "$WORK/install.log"; exit 1; }
MERGE_SCRIPT="$ROOT/.agents/skills/merge/scripts/merge.py" node --test tests/handover.test.mjs tests/host-record.test.mjs
