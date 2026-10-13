#!/usr/bin/env sh
# going-live.sh: check the live copy on Coolify runs main and is checked by
# Coolify, from what was pasted back, and that no table is open to anyone
# holding the public key, which the kit reads itself.
#
# Usage: going-live.sh --pasted <file>
#   DB_PASSWORD_FILE  where the database password is kept, for the table read
#   TABLES_ON_RECORD  tables the masterplan records as public by choice
#
# The paste holds the deployment's status, the app's health check settings,
# the container's health status, and the answer from <live address>/api/health.
# A finished deployment, the check switched on for /api/health on port 3000
# and host 127.0.0.1, a healthy container, "database":"ok" and a commit equal
# to `git rev-parse origin/main` pass. The shared rls.sh lists the public
# tables with row-level security off.
#
# Exit 0 when all of that holds, 1 when a part fails, 2 when there is no paste,
# or the paste passes while the table read could not run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../../scripts/check-lib.sh"

[ "${1:-}" = "--pasted" ] && [ -f "${2:-}" ] ||
  cl_cannot "Nothing was pasted back about the live deployment yet."
pasted=$2
grep -qi 'failed' "$pasted" && cl_fail "The pasted status shows the deployment failed."
grep -qi 'finished' "$pasted" || cl_fail "The pasted status does not show a finished deployment."
grep -qi 'unhealthy' "$pasted" && cl_fail "Coolify reports the container as unhealthy."
grep -qi 'healthy' "$pasted" || cl_fail "The paste does not show Coolify's health check passing."
for setting in /api/health 3000 127.0.0.1; do
  grep -qF "$setting" "$pasted" ||
    cl_fail "Coolify's health check is not set to /api/health on port 3000 and host 127.0.0.1."
done
fields=$(cl_health_fields "$pasted")
[ -n "$fields" ] || cl_cannot "The paste holds no answer from the live address's health route."
[ "$(printf '%s\n' "$fields" | sed -n 2p)" = ok ] || cl_fail "The live copy answers, but it cannot reach its database."
git fetch -q origin main 2>/dev/null || true
main=$(cl_main_commit)
[ -n "$main" ] && [ "$(printf '%s\n' "$fields" | sed -n 3p)" = "$main" ] ||
  cl_fail "The live copy runs a different commit from the latest on main."

tables=$(sh "$here/../../parts/scripts/rls.sh" --on-record "${TABLES_ON_RECORD:-}")
case $? in
  0) cl_pass "The live copy runs main's latest commit, Coolify checks its health, and no table is open to anyone holding the public key." ;;
  1) cl_fail "The live copy runs main's latest commit, and Coolify checks its health. $tables" ;;
  *) cl_cannot "The live copy runs main's latest commit, and Coolify checks its health, but the check for tables anyone can read did not run. $tables" ;;
esac
