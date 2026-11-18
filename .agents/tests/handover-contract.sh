#!/usr/bin/env sh
# handover-contract.sh: prove the released schema validates a copied project and rejects planted handover drift.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -R "$WORK"' EXIT
sh "$ROOT/.agents/tools/build-release.sh" v0.0.0-handover "$WORK/release" > "$WORK/release.log"
cmp "$ROOT/hosting/handover.schema.json" "$WORK/release/hosting/handover.schema.json"
PROJECT="$WORK/project"
mkdir "$PROJECT"
for path in src scripts db hosting tests masterplan.md Dockerfile .env.example; do
  cp -R "$ROOT/templates/nextjs-postgres/$path" "$PROJECT/$path"
done
cp "$WORK/release/hosting/handover.schema.json" "$PROJECT/hosting/handover.schema.json"
cp "$WORK/release/.agents/skills/merge/scripts/host-record.cjs" "$PROJECT/hosting/"
cp "$WORK/release/.agents/skills/merge/scripts/host-record-validator.cjs" "$PROJECT/hosting/"
cp "$WORK/release/.agents/skills/merge/contracts/ai-host-kit/host-record.schema.json" "$PROJECT/hosting/"
node --input-type=module - "$ROOT" "$PROJECT" <<'JS'
import { readFileSync, writeFileSync } from 'node:fs';
const [root, project] = process.argv.slice(2);
const template = JSON.parse(readFileSync(`${root}/templates/nextjs-postgres/package.json`));
const deps = template.devDependencies;
writeFileSync(`${project}/package.json`, JSON.stringify({ private: true, type: 'module', scripts: { 'test:handover': template.scripts['test:handover'] }, dependencies: { ajv: deps.ajv, typescript: deps.typescript, esbuild: deps.esbuild } }));
JS
cd "$PROJECT"
npm install --cache "${npm_config_cache:-$WORK/npm-cache}" --ignore-scripts --no-audit --no-fund > "$WORK/install.log" 2>&1 || { cat "$WORK/install.log"; exit 1; }
node "$ROOT/.agents/tools/build-host-record-validator.cjs" "$PROJECT" --check
npm run test:handover
