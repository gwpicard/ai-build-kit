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
. "$here/../../../scripts/check-lib.sh"

[ -n "${LIVE_ADDRESS:-}" ] || cl_cannot "No live address is recorded, so there is nothing to roll back yet."
cl_need vercel

list=$(mktemp)
live=$(mktemp)
trap 'rm -f "$list" "$live"' EXIT
vercel ls --environment production --format json >"$list" 2>/dev/null ||
  cl_cannot "Vercel's list of deployments could not be read, so the kit cannot tell whether a rollback is possible."
vercel inspect "${LIVE_ADDRESS#https://}" --format json >"$live" 2>/dev/null ||
  cl_cannot "Vercel could not say which build is live, so the kit cannot tell whether a rollback is possible."

earlier=$(python3 - "$list" "$live" <<'PY'
import json, sys
deps = json.load(open(sys.argv[1])).get("deployments", [])
live = json.load(open(sys.argv[2]))
live_id = live.get("id") or live.get("uid")
for dep in deps:
    ident = dep.get("uid") or dep.get("id")
    state = dep.get("readyState") or dep.get("state")
    if ident != live_id and state == "READY" and dep.get("target") == "production":
        print(str(dep.get("created", ""))[:10])
        break
PY
)
[ -n "$earlier" ] ||
  cl_fail "No earlier production build is listed, so there is nothing to roll back to yet."
cl_pass "An earlier production build is listed, from $earlier, so a rollback could bring it back."
