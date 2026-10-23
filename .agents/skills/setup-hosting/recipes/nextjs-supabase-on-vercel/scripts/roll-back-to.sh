#!/usr/bin/env sh
# roll-back-to.sh: put an earlier production build back on the live address,
# once, and read health to see it there. Run it only after the person's yes
# that names the rollback.
#
# Usage: roll-back-to.sh <earlier deployment> <its commit>
#   LIVE_ADDRESS   the live address
#
# `vercel rollback <earlier deployment> --yes` points the production address
# back at that build in seconds, with no new build. Its whole output is read.
# Then the live address's /api/health, read as check-lib.sh's cl_live_health
# says, must answer 200 with a reachable database and the earlier commit. A
# rollback does not undo a database
# migration, which is why a migration only adds.
#
# After a rollback, Vercel stops moving new pushes to production until a newer
# build is promoted with promote.sh. The last line says so, every time, so the
# kit says it in the same reply and records the hold.
#
# Exit 0 when the live address serves the earlier commit, 1 when the rollback
# failed or the address still serves another commit, 2 when it could not run.
# It never runs the rollback a second time.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

deployment=${1:-}
want=${2:-}
[ -n "$deployment" ] && [ -n "$want" ] ||
  cl_cannot "No earlier build and commit were named, so nothing was rolled back."
[ -n "${LIVE_ADDRESS:-}" ] || cl_cannot "No live address is recorded, so nothing was rolled back."
cl_need vercel curl
cl_approved

vercel rollback "$deployment" --yes >&2 ||
  cl_fail "Vercel did not roll back. The live address still serves the version it served before."

answer=$(mktemp)
trap 'rm -f "$answer"' EXIT
cl_live_health "${LIVE_ADDRESS%/}" "$answer"
case $? in
  0) ;;
  3) cl_cannot "Vercel reported the rollback, but the live address asks for Vercel's sign-in, so the kit could not read which build it serves. Vercel holds the live copy on it: new merges will not go live until a newer build is promoted." ;;
  *) cl_fail "Vercel reported the rollback, but the live address did not answer its health route." ;;
esac
commit=$(cl_health_fields "$answer" | sed -n 3p)
case "$commit" in
  "$want"*) ;;
  *) cl_fail "Vercel reported the rollback, but the live address still serves a different commit." ;;
esac
cl_pass "The live address now serves the earlier version. Vercel holds the live copy on it: new merges will not go live until a newer build is promoted."
