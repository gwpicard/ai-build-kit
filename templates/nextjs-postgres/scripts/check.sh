#!/usr/bin/env sh
# Run the starter checks in a disposable database and remove its Docker resources.
set -eu
cd "$(dirname -- "$0")/.."
if [ "${ABK_DATABASE_READY:-}" != 1 ]; then
  exec sh scripts/docker-run.sh -- node scripts/test-database.mjs sh scripts/check.sh
fi
npm run check:sign-in-review
npm run typecheck
npm run lint
npm test
npm run test:files
npm run build
npm run test:e2e
