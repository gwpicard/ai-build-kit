#!/usr/bin/env sh
# going-live.sh: check the live copy on Coolify runs main and is checked by
# Coolify, from what was pasted back.
#
# Usage: going-live.sh --pasted <file>
#   DB_PASSWORD_FILE  where the database password is kept, for the table read
#   TABLES_ON_RECORD  tables the masterplan records as public by choice
#
# The paste holds the deployment's status, the app's health check settings,
# the container's health status, and the answer from <live address>/api/health.
# A finished newest deployment, the first one the paste names, the check's own
# path, port and host settings at /api/health, 3000 and 127.0.0.1, a healthy
# container, "database":"ok" and a commit equal
# to `git rev-parse origin/main` pass. The row rules check reads the live
# database at launch.
#
# Exit 0 when all of that holds, 1 when a part fails, or 2 when there is no
# paste or a part of it cannot be read. A paste that cannot be read ends with
# the recipe's fixed question.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

[ "${1:-}" = "--pasted" ] && [ -f "${2:-}" ] ||
  cl_cannot "Nothing was pasted back about the live deployment yet."
pasted=$2
ask=$(cl_ask "$here/../recipe.md" "Going live")
case $(cl_newest_status "$pasted") in
  finished) ;;
  failed) cl_fail "The pasted status shows the newest deployment failed." ;;
  '') cl_cannot "The paste names no deployment status the kit can read. $ask" ;;
  *) cl_fail "The pasted status does not show a finished deployment." ;;
esac
grep -qi 'unhealthy' "$pasted" && cl_fail "Coolify reports the container as unhealthy."
grep -qi 'healthy' "$pasted" || cl_fail "The paste does not show Coolify's health check passing."
# Each health check setting is read from its own label: path, port, host.
settings=$(python3 - "$pasted" <<'PY'
import re, sys
text = open(sys.argv[1], errors="replace").read()
found = [re.search(pattern, text, re.I) for pattern in
         (r"\bpath\b\W*?(/[^\s,]*)", r"\bport\b\D*?(\d+)", r"\bhost\b[^\w.]*([\w.-]+)")]
print(" ".join(m.group(1) if m else "?" for m in found))
PY
)
case "$settings" in
  *\?*) cl_cannot "The paste does not show the health check's path, port and host. $ask" ;;
  "/api/health 3000 127.0.0.1") ;;
  *) cl_fail "Coolify's health check is not set to /api/health on port 3000 and host 127.0.0.1." ;;
esac
fields=$(cl_health_fields "$pasted")
[ -n "$fields" ] || cl_cannot "The paste holds no answer from the live address's health route. $ask"
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
