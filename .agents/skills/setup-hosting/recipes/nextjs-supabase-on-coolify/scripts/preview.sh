#!/usr/bin/env sh
# preview.sh: read back what the person or the companion pasted about a pull
# request's preview on Coolify. The kit never contacts the server.
#
# Usage: preview.sh --pasted <file>
#   PREVIEW_COMMIT   the pull request's commit, where known
#   LIVE_REF         the live database project's reference
#   SHARED_PREVIEW   yes where the masterplan records that previews share the
#                    live database, because no second project can exist
#
# The paste holds the preview deployment's status in Coolify and the answer
# from the preview's /api/health, read at its address or on the server. A
# finished deployment, "database":"ok", the pull request's commit, and a
# project other than the live one pass. Where previews share the live
# database by record, the project is not compared, and the line says previews
# use live data.
#
# Exit 0 when the paste shows a healthy preview, 1 when it shows a problem,
# 2 when there is no paste or it holds no health answer.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

[ "${1:-}" = "--pasted" ] && [ -f "${2:-}" ] ||
  cl_cannot "Nothing was pasted back about the preview yet."
pasted=$2
grep -qi 'preview deployments disabled' "$pasted" &&
  cl_fail "Coolify says preview deployments are switched off for this app."
grep -qi 'failed' "$pasted" && cl_fail "The pasted status shows the preview deployment failed."
grep -qi 'finished' "$pasted" || cl_fail "The pasted status does not show a finished preview deployment."
fields=$(cl_health_fields "$pasted")
[ -n "$fields" ] || cl_cannot "The paste holds no answer from the preview's health route."
[ "$(printf '%s\n' "$fields" | sed -n 2p)" = ok ] || cl_fail "The preview answered, but it cannot reach its database."
commit=$(printf '%s\n' "$fields" | sed -n 3p)
if [ -n "${PREVIEW_COMMIT:-}" ] && [ "$commit" != "$PREVIEW_COMMIT" ]; then
  cl_fail "The preview runs a different commit from the pull request's latest."
fi
if [ "${SHARED_PREVIEW:-}" = yes ]; then
  cl_pass "The preview is finished and healthy. As recorded, previews use the live database."
fi
live=${LIVE_REF:-$(cl_ref)}
project=$(printf '%s\n' "$fields" | sed -n 4p)
[ -z "$live" ] || [ "$project" != "$live" ] ||
  cl_fail "The preview uses the live database, so trying a change there changes live data."
cl_pass "The preview is finished, healthy, runs the pull request's commit, and uses its own database."
