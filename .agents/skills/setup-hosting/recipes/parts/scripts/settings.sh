#!/usr/bin/env sh
# settings.sh: read the hosted Supabase project's sign-in settings with the
# public key alone, and compare sign-up with the masterplan's Access: line.
#
# Usage: settings.sh
#
# Supabase answers a project's sign-in settings to anyone holding its public
# key, which the tool already sends to the browser. This reads them with
# `curl -fsS -H "apikey: <public key>" https://<ref>.supabase.co/auth/v1/settings`,
# the key taken from the project's own `.env.local` as check-lib.sh's
# cl_public_key says: the publishable key a project made today shows, or the
# older anon key. It never sends the service role key or a secret key, and
# never prints a key. It prints one plain line for each setting the launch
# review needs. The list of addresses sign-in may send a person back to is
# not in this answer, so the review asks the person to look at it.
#
# Where the masterplan records an access setting, sign-up must match it:
# closed for private, and for open address, invitation only. With sign-up closed,
# whether a new account confirms its email does not matter, since nobody can
# make one.
#
# Exit 0 when the settings were read and match the record, 1 when the answer
# carried no settings or sign-up differs from the record, 2 when it could not
# run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/check-lib.sh"

cl_need curl
key=$(cl_public_key)
[ -n "$key" ] ||
  cl_cannot "The project's public key is not in .env.local, so the sign-in settings could not be read."
ref=$(cl_ref)
[ -n "$ref" ] || cl_cannot "The kit does not know which database project this is, so the sign-in settings could not be read."
record=$(cl_access)

answer=$(curl -fsS -H "apikey: $key" "https://$ref.supabase.co/auth/v1/settings" 2>/dev/null) ||
  cl_cannot "Supabase did not answer the sign-in settings, so they could not be read."
printf '%s' "$answer" | python3 -c '
import json, sys
# Any error the kit did not foresee exits 4, so it reads as could not run,
# never as a difference from the record.
try:
    want = sys.argv[1]
    try:
        data = json.load(sys.stdin)
    except ValueError:
        sys.exit(3)
    if not isinstance(data, dict) or "mailer_autoconfirm" not in data:
        sys.exit(3)
    closed = bool(data.get("disable_signup"))
    lines = []
    if closed:
        lines.append("New accounts cannot be made, so only invited people get in.")
    else:
        lines.append("New accounts can be made.")
        if data["mailer_autoconfirm"]:
            lines.append("New accounts do not have to confirm their email address, so somebody can sign up with an address they do not own.")
        else:
            lines.append("New accounts have to confirm their email address.")
    on = sorted(name for name, enabled in (data.get("external") or {}).items() if enabled is True)
    lines.append("Sign-in methods switched on: %s." % (", ".join(on) if on else "none"))
    lines.append("The addresses sign-in may send a person back to cannot be read with the public key. They are in the Supabase dashboard, under Authentication, then URL Configuration.")
except Exception:
    sys.exit(4)
print("\n".join(lines))
if want == "closed" and not closed:
    sys.exit(1)
if want == "open" and closed:
    sys.exit(2)
' "${record#* }"
case $? in
  0) ;;
  1) cl_fail "Anyone can make an account, though the masterplan records that only invited people get in." ;;
  2) cl_fail "New accounts cannot be made, though the masterplan records that anyone can sign up." ;;
  3) cl_fail "Supabase answered, but not with the sign-in settings." ;;
  *) cl_cannot "Supabase's sign-in settings came back in a form the kit cannot read, so they could not be checked." ;;
esac
cl_pass "The sign-in settings were read with the public key."
