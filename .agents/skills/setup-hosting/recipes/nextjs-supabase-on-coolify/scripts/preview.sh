#!/usr/bin/env sh
# preview.sh: read back what the person or the companion pasted about a pull
# request's preview on Coolify. The kit never contacts the server.
#
# Usage: preview.sh --pasted <file>
#   PREVIEW_COMMIT   the pull request's commit, where known
#   LIVE_REF         the live database project's reference
#
# The paste holds the preview deployment's status in Coolify and the answer
# from the preview's /api/health, read at its address or on the server. A
# finished newest deployment, the first one the paste names, "database":"ok", the pull request's commit, and a
# project other than the live one pass. Previews stay off when no second
# database project is available.
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
ask=$(cl_ask "$here/../recipe.md" Preview)
case $(cl_newest_status "$pasted") in
  finished) ;;
  failed) cl_fail "The pasted status shows the newest preview deployment failed." ;;
  '') cl_cannot "The paste names no deployment status the kit can read. $ask" ;;
  *) cl_fail "The pasted status does not show a finished preview deployment." ;;
esac
fields=$(cl_health_fields "$pasted")
[ -n "$fields" ] || cl_cannot "The paste holds no answer from the preview's health route. $ask"
[ "$(printf '%s\n' "$fields" | sed -n 2p)" = ok ] || cl_fail "The preview answered, but it cannot reach its database."
commit=$(printf '%s\n' "$fields" | sed -n 3p)
if [ -n "${PREVIEW_COMMIT:-}" ] && [ "$commit" != "$PREVIEW_COMMIT" ]; then
  cl_fail "The preview runs a different commit from the pull request's latest."
fi
live=${LIVE_REF:-$(cl_ref)}
project=$(printf '%s\n' "$fields" | sed -n 4p)
[ -z "$live" ] || [ "$project" != "$live" ] ||
  cl_fail "The preview uses the live database, so trying a change there changes live data."
cl_pass "The preview is finished, healthy, runs the pull request's commit, and uses its own database."
