#!/usr/bin/env sh
# promote.sh: move a chosen production build live by hand, once, and read
# health to see it there. Run it only after the person's yes that names it.
#
# Usage: promote.sh <deployment> <its commit>
#   LIVE_ADDRESS   the live address
#
# `vercel promote <deployment> --yes` moves the live address to that build
# and ends the hold a rollback leaves, so later merges go live by themselves
# again. Then the live address's /api/health, read as check-lib.sh's
# cl_live_health says, must answer 200 with "database":"ok" and that build's
# commit.
#
# Exit 0 when the live address serves that commit, 1 when it does not, 2 when
# it could not run. It never runs the promote a second time.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

deployment=${1:-}
want=${2:-}
[ -n "$deployment" ] && [ -n "$want" ] ||
  cl_cannot "No build and commit were named, so nothing was promoted."
[ -n "${LIVE_ADDRESS:-}" ] || cl_cannot "No live address is recorded, so nothing was promoted."
cl_need vercel curl
cl_approved

vercel promote "$deployment" --yes >&2 ||
  cl_fail "Vercel did not promote the build. The live address still serves the version it served before."

answer=$(mktemp)
trap 'rm -f "$answer"' EXIT
cl_live_health "${LIVE_ADDRESS%/}" "$answer"
case $? in
  0) ;;
  3) cl_cannot "Vercel reported the promote, but the live address asks for Vercel's sign-in, so the kit could not read which build it serves." ;;
  *) cl_fail "Vercel reported the promote, but the live address did not answer its health route." ;;
esac
commit=$(cl_health_fields "$answer" | sed -n 3p)
case "$commit" in
  "$want"*) ;;
  *) cl_fail "Vercel reported the promote, but the live address serves a different commit." ;;
esac
cl_pass "The live address serves the promoted build, and new merges go live by themselves again."
