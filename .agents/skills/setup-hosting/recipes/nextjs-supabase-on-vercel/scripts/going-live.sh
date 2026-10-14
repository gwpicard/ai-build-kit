#!/usr/bin/env sh
# going-live.sh: check the live address runs main, and that no table is open
# to anyone holding the public key.
#
# Usage: going-live.sh
#   LIVE_ADDRESS      the live address, such as https://<project>.vercel.app
#   DB_PASSWORD_FILE  where the database password is kept, for the table read
#   TABLES_ON_RECORD  tables the masterplan records as public by choice,
#                     separated by commas
#
# The live address's /api/health must answer 200 with "database":"ok", and
# its commit must equal `git rev-parse origin/main`. Behind Vercel's sign-in
# it is read as check-lib.sh's cl_live_health says. The
# health route reports the commit from VERCEL_GIT_COMMIT_SHA. The shared
# `rls.sh` lists public tables with row-level security off; none, or only
# tables on the record, passes.
#
# Exit 0 when both pass, 1 when either fails, 2 when the live address could
# not be read, or answered well while the table read could not run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

[ -n "${LIVE_ADDRESS:-}" ] || cl_cannot "No live address is recorded, so the tool is not live yet."
cl_need curl git

git fetch -q origin main 2>/dev/null || true
main=$(cl_main_commit)
answer=$(mktemp)
trap 'rm -f "$answer"' EXIT
cl_live_health "${LIVE_ADDRESS%/}" "$answer"
case $? in
  0) ;;
  3) cl_cannot "The live address asks for Vercel's sign-in, and reading through it would make a lasting key that gets past that sign-in, which waits for the person's yes." ;;
  *) cl_fail "The live address did not answer its health route with 200." ;;
esac
fields=$(cl_health_fields "$answer")
[ "$(printf '%s\n' "$fields" | sed -n 2p)" = ok ] ||
  cl_fail "The live address answers, but it cannot reach its database."
commit=$(printf '%s\n' "$fields" | sed -n 3p)
[ -n "$main" ] && [ "$commit" = "$main" ] ||
  cl_fail "The live address runs a different commit from the latest on main."

tables=$(sh "$here/../../parts/scripts/rls.sh" --on-record "${TABLES_ON_RECORD:-}")
case $? in
  0) cl_pass "The live address answers with main's latest commit, and no table is open to anyone holding the public key." ;;
  1) cl_fail "The live address answers with main's latest commit. $tables" ;;
  *) cl_cannot "The live address answers with main's latest commit, but the check for tables anyone can read did not run. $tables" ;;
esac
