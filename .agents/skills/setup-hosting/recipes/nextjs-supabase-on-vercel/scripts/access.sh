#!/usr/bin/env sh
# access.sh: check that who can reach the live tool matches the masterplan's
# Access: line. It changes nothing.
#
# Usage: access.sh
#   LIVE_ADDRESS   the live address
#
# Three reads:
#   sign-up    the shared signup.sh: closed for private, and for public by
#              invitation only; open for public
#   setting    `vercel project protection --format json`: Vercel's sign-in
#              in front of every address, deploymentType "all", for private;
#              anything else for public. The answer also holds the project's
#              bypass keys, so it is read inside the script and never printed.
#   live       a request signed in to nothing, to <live address>/api/health:
#              refused or sent to Vercel's sign-in for private, answered 200
#              for public
#
# Exit 0 when all three match the record, 1 when one does not, 2 when none
# differs but one could not be read, or no setting is recorded.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

record=$(cl_access)
[ -n "$record" ] || cl_cannot "The masterplan records no access setting, so there is nothing to compare the live tool with."
[ -n "${LIVE_ADDRESS:-}" ] || cl_cannot "No live address is recorded, so there is no live tool to check yet."
cl_need vercel curl
setting=${record% *}
signup=${record#* }
address=${LIVE_ADDRESS%/}
case "$address" in https://*|http://*) ;; *) address="https://$address" ;; esac

gaps=
unread=
signup_line=$(sh "$here/../../parts/scripts/signup.sh" "$signup")
case $? in
  0) ;;
  1) gaps="$gaps $signup_line" ;;
  *) unread="$unread $signup_line" ;;
esac

type=$(vercel project protection --format json 2>/dev/null | python3 -c '
import json, sys
try:
    sso = json.load(sys.stdin).get("ssoProtection")
except ValueError:
    sys.exit(1)
print((sso or {}).get("deploymentType") or "none")') || type=
gate=$(cl_gate "$address")

if [ "$setting" = private ]; then
  case "$type" in
    all) ;;
    '') unread="$unread Vercel's protection setting could not be read." ;;
    *) gaps="$gaps Vercel's sign-in does not cover the live address." ;;
  esac
  case "$gate" in
    gated) ;;
    open) gaps="$gaps The live address answers anyone who is not signed in." ;;
    *) unread="$unread The live address gave no answer the kit can read." ;;
  esac
else
  [ "$type" != all ] || gaps="$gaps Vercel's sign-in still covers the live address, though the record says public."
  [ -n "$type" ] || unread="$unread Vercel's protection setting could not be read."
  case "$gate" in
    open) ;;
    gated) gaps="$gaps The live address asks for Vercel's sign-in, though the record says public." ;;
    *) unread="$unread The live address gave no answer the kit can read." ;;
  esac
fi

[ -z "$gaps" ] || cl_fail "The live tool does not match the record of $setting.$gaps"
[ -z "$unread" ] || cl_cannot "Access could not be checked in full.$unread"
if [ "$setting" = private ]; then
  cl_pass "Private, as recorded: the live address and its previews ask for Vercel's sign-in, and $(printf '%s' "$signup_line" | sed 's/^S/s/')"
fi
cl_pass "Public, as recorded: the live address answers anyone. $signup_line"
