#!/usr/bin/env sh
# rollback.sh: check that an earlier production build is listed, so a rollback
# is possible. It never runs one.
#
# Usage: rollback.sh
#
# It reads Vercel's list of production deployments with
# `vercel ls --environment production --format json` and the build the live
# address points at with `vercel inspect <live address> --format json`. An
# earlier Ready production build, other than the live one, is what a rollback
# would bring back. On the Hobby plan only the build just before is eligible.
# A rollback is never tried to prove it works, since that would change the
# live tool, so a pass is "possible, not tried".
#
# Exit 0 when an earlier build is listed, 1 when none is, 2 when the list
# could not be read.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

[ -n "${LIVE_ADDRESS:-}" ] || cl_cannot "No live address is recorded, so there is nothing to roll back yet."
cl_need vercel

list=$(mktemp)
live=$(mktemp)
trap 'rm -f "$list" "$live"' EXIT
vercel ls --environment production --format json >"$list" 2>/dev/null ||
  cl_cannot "Vercel's list of deployments could not be read, so the kit cannot tell whether a rollback is possible."
address=${LIVE_ADDRESS%/}
address=${address#https://}
vercel inspect "${address#http://}" --format json >"$live" 2>/dev/null ||
  cl_cannot "Vercel could not say which build is live, so the kit cannot tell whether a rollback is possible."

# Each listed build has id, state, target and createdAt, in milliseconds.
earlier=$(python3 - "$list" "$live" <<'PY'
import datetime, json, sys
deps = json.load(open(sys.argv[1])).get("deployments", [])
live = json.load(open(sys.argv[2]))
live_id = live.get("id") or live.get("uid")
when = {d.get("id"): d.get("createdAt") or 0 for d in deps}
live_at = when.get(live_id) or live.get("createdAt") or float("inf")
ready = [d for d in deps if d.get("state") == "READY" and d.get("target") == "production"
         and d.get("id") != live_id and (d.get("createdAt") or 0) < live_at]
if ready:
    newest = max(ready, key=lambda d: d.get("createdAt") or 0)
    stamp = datetime.datetime.fromtimestamp((newest.get("createdAt") or 0) / 1000, datetime.timezone.utc)
    print(stamp.strftime("%Y-%m-%d"))
PY
)
[ -n "$earlier" ] ||
  cl_fail "No earlier production build is listed, so there is nothing to roll back to yet."
cl_pass "An earlier production build is listed, from $earlier, so a rollback could bring it back."
