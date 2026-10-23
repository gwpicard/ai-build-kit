#!/usr/bin/env sh
# interface.sh: check design colours and controls, then scan sign-in with Playwright.

set -eu
if [ ! -f package.json ] || [ ! -f e2e/accessibility.spec.ts ]; then
  echo "could not run: run this check from the copied starter, with its packages and Playwright browser installed." >&2
  exit 2
fi
npm run lint
npm run test:e2e -- e2e/accessibility.spec.ts "$@"
