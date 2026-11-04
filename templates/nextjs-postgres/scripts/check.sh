#!/usr/bin/env sh
# Run the starter checks against an already migrated local database.
set -eu
npm run check:sign-in-review
npm run typecheck
npm run lint
npm test
npm run build
npm run test:e2e
