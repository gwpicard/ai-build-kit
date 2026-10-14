#!/usr/bin/env sh
# signup.sh: read whether anyone can make an account on the hosted Supabase
# project, with the public key alone, and compare it with the record.
#
# Usage: signup.sh [closed|open]
#
# With no argument, the wanted state comes from the masterplan's Access:
# line: closed for private, or for public by invitation only, and open for
# public. Two reads, and neither changes anything:
#
#   GET  https://<ref>.supabase.co/auth/v1/settings, whose disable_signup is
#        true when sign-up is closed
#   POST https://<ref>.supabase.co/auth/v1/signup with an empty request,
#        which Supabase refuses with error code signup_disabled when sign-up
#        is closed. It checks that before it reads the request, and an empty
#        request makes no account either way.
#
# The key is the public one, from the project's own .env.local, as
# check-lib.sh's cl_public_key says: publishable or anon. It is never printed.
#
# Exit 0 when sign-up is as wanted, 1 when it is not, 2 when it could not be
# read.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/check-lib.sh"

want=${1:-}
if [ -z "$want" ]; then
  want=$(cl_access)
  want=${want#* }
fi
case "$want" in
  closed|open) ;;
  *) cl_cannot "The masterplan records no access setting, so the kit cannot say whether sign-up should be open." ;;
esac
cl_need curl
key=$(cl_public_key)
[ -n "$key" ] || cl_cannot "The project's public key is not in .env.local, so sign-up could not be read."
ref=$(cl_ref)
[ -n "$ref" ] || cl_cannot "The kit does not know which database project this is, so sign-up could not be read."

settings=$(curl -fsS -H "apikey: $key" "https://$ref.supabase.co/auth/v1/settings" 2>/dev/null) ||
  cl_cannot "Supabase did not answer its sign-in settings, so sign-up could not be read."
answer=$(mktemp)
trap 'rm -f "$answer"' EXIT
code=$(curl -sS -o "$answer" -w '%{http_code}' -X POST -H "apikey: $key" \
  -H "Content-Type: application/json" -d '{}' "https://$ref.supabase.co/auth/v1/signup" 2>/dev/null) ||
  cl_cannot "Supabase did not answer a sign-up attempt, so sign-up could not be read."

state=$(printf '%s' "$settings" | python3 -c '
import json, sys
code, path = sys.argv[1], sys.argv[2]
try:
    closed = json.load(sys.stdin)["disable_signup"]
except (ValueError, KeyError, TypeError):
    print("unknown"); sys.exit()
try:
    body = json.load(open(path))
except ValueError:
    body = {}
refused = code == "422" and body.get("error_code") == "signup_disabled"
if closed is True and refused:
    print("closed")
elif closed is False and not refused:
    print("open")
else:
    print("unknown")
' "$code" "$answer")

case "$state:$want" in
  closed:closed) cl_pass "Sign-up is closed: Supabase refused a new account, so only invited people get in." ;;
  open:open) cl_pass "Sign-up is open, as recorded: anyone can make an account." ;;
  open:closed) cl_fail "Sign-up is open: anyone can make an account, though the record says only invited people get in." ;;
  closed:open) cl_fail "Sign-up is closed, though the record says anyone can make an account." ;;
  *) cl_cannot "Supabase's settings and its answer to a sign-up attempt disagree, so the kit cannot say whether sign-up is open." ;;
esac
