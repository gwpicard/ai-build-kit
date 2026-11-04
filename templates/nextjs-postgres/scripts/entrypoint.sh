#!/bin/sh
set -eu
case "${1:-web}" in
  web) exec node --import ./scripts/startup.mjs server.js ;;
  worker) exec node dist/worker.mjs ;;
  migrate) exec node scripts/migrate.mjs ;;
  *) printf '%s\n' '{"event":"process.unknown_role"}'; exit 1 ;;
esac
