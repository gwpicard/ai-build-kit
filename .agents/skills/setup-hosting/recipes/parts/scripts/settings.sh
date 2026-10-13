#!/usr/bin/env sh
# settings.sh: read the hosted Supabase project's sign-in settings with the
# public key alone.
#
# Usage: settings.sh
#
# Supabase answers a project's sign-in settings to anyone holding its public
# key, which the tool already sends to the browser. This reads them with
# `curl -fsS -H "apikey: $NEXT_PUBLIC_SUPABASE_ANON_KEY" https://<ref>.supabase.co/auth/v1/settings`,
# the key taken from the project's own `.env.local`. It never sends the
# service role key or a secret key. It prints one plain line for each setting
# the launch review needs. The list of addresses sign-in may send a person
# back to is not in this answer, so the review asks the person to look at it.
#
# Exit 0 when the settings were read, 1 when the answer carried no settings,
# 2 when it could not run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/check-lib.sh"

cl_need curl
NEXT_PUBLIC_SUPABASE_ANON_KEY=$(cl_value .env.local NEXT_PUBLIC_SUPABASE_ANON_KEY)
[ -n "$NEXT_PUBLIC_SUPABASE_ANON_KEY" ] ||
  cl_cannot "The project's public key is not in .env.local, so the sign-in settings could not be read."
ref=$(cl_ref)
[ -n "$ref" ] || cl_cannot "The kit does not know which database project this is, so the sign-in settings could not be read."

answer=$(curl -fsS -H "apikey: $NEXT_PUBLIC_SUPABASE_ANON_KEY" "https://$ref.supabase.co/auth/v1/settings" 2>/dev/null) ||
  cl_cannot "Supabase did not answer the sign-in settings, so they could not be read."
printf '%s' "$answer" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except ValueError:
    sys.exit(1)
if "mailer_autoconfirm" not in data:
    sys.exit(1)
if data["mailer_autoconfirm"]:
    print("New accounts do not have to confirm their email address, so somebody can sign up with an address they do not own.")
else:
    print("New accounts have to confirm their email address.")
print("New accounts cannot be made." if data.get("disable_signup") else "New accounts can be made.")
on = sorted(name for name, enabled in (data.get("external") or {}).items() if enabled is True)
print("Sign-in methods switched on: %s." % (", ".join(on) if on else "none"))
print("The addresses sign-in may send a person back to cannot be read with the public key. They are in the Supabase dashboard, under Authentication, then URL Configuration.")
' || cl_fail "Supabase answered, but not with the sign-in settings."
cl_pass "The sign-in settings were read with the public key."
