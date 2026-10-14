#!/usr/bin/env sh
# Run the starter's complete local check and report one plain result line.
set -eu
cd "$(dirname -- "$0")/.."
failed=0
npm run typecheck || failed=1
npm run lint || failed=1
npm test || failed=1
npm run build || failed=1
if [ "$failed" -eq 0 ]; then
  echo "Project check passed: types, lint, tests and build are green."
  exit 0
fi
echo "Project check failed: read the command output above."
exit 1
