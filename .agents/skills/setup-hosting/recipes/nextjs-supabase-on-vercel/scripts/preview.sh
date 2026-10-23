#!/usr/bin/env sh
# preview.sh: check a branch's Vercel preview is built, and read its health
# where the person has agreed.
#
# Usage: preview.sh
#   PREVIEW_ADDRESS   the preview deployment's address
#   PREVIEW_COMMIT    the branch's commit, where known
#   PREVIEW_HEALTH    yes once the person has agreed to the read below
#   LIVE_REF          the live database project's reference, where the
#                     folder is linked to the preview one
#
# It waits, with `vercel inspect <preview address> --wait`, until Vercel
# reports the deployment Ready. Vercel protects a generated address with a sign-in, so the health
# route is read with `vercel curl /api/health --deployment <preview address>
# --yes`, which gets past it. That command is marked beta, and the first time
# it runs it creates a protection bypass token on the project, which changes
# who can reach previews. So it runs only with PREVIEW_HEALTH=yes, after the
# person's yes. The health answer must show a reachable database, the branch's
# commit, and a project that is not the live one.
#
# The person still opens the preview and tries the change; this only reads
# what a machine can.
#
# Exit 0 when the preview is Ready and, where read, healthy, 1 when it is not,
# 2 when it could not be checked, such as Vercel not reached or not signed in.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

[ -n "${PREVIEW_ADDRESS:-}" ] || cl_cannot "No preview address was given, so there is no preview to check yet."
cl_need vercel

state=$(vercel inspect "$PREVIEW_ADDRESS" --wait --timeout 5m 2>&1)
if printf '%s\n' "$state" | grep -q 'Ready'; then :
elif printf '%s\n' "$state" | grep -Eq 'status.*(Error|Canceled)'; then
  cl_fail "The preview did not reach Ready on Vercel."
else
  cl_cannot "Vercel did not say how the preview stands, so it could not be checked. This computer may not be signed in to Vercel."
fi

[ "${PREVIEW_HEALTH:-}" = yes ] ||
  cl_pass "The preview is built and Ready. The person opens it signed in to Vercel to try the change."

answer=$(mktemp)
trap 'rm -f "$answer"' EXIT
vercel curl /api/health --deployment "$PREVIEW_ADDRESS" --yes >"$answer" 2>/dev/null ||
  cl_cannot "The preview's health could not be read through Vercel, so the person opens it in their own browser."
fields=$(cl_health_fields "$answer")
database=$(printf '%s\n' "$fields" | sed -n 2p)
commit=$(printf '%s\n' "$fields" | sed -n 3p)
project=$(printf '%s\n' "$fields" | sed -n 4p)
[ "$database" = ok ] || cl_fail "The preview answered, but it cannot reach its database."
if [ -n "${PREVIEW_COMMIT:-}" ] && [ "$commit" != "$PREVIEW_COMMIT" ]; then
  cl_fail "The preview runs a different commit from the branch's latest."
fi
live=${LIVE_REF:-$(cl_ref)}
[ -z "$live" ] || [ "$project" != "$live" ] ||
  cl_fail "The preview uses the live database, so trying a change there changes live data."
cl_pass "The preview is Ready, reaches its own database, and runs the branch's commit."
