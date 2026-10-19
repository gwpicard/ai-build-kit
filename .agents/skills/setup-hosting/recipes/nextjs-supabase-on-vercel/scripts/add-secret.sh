#!/usr/bin/env sh
# add-secret.sh: give Vercel one setting for production, with its value read
# from standard input so it never sits on a command line.
#
# Usage: add-secret.sh [--replace] <NAME> < file-holding-the-value
#
# A name that starts with NEXT_PUBLIC_ reaches the browser by design, and
# Vercel refuses a value that looks like a key unless it is told the type, so
# it goes in with `vercel env add <NAME> production --type config --yes`.
# Every other name is a secret and keeps Vercel's default sensitive type:
# `vercel env add <NAME> production --yes`. The value is never printed and
# never written into the repository.
#
# Exit 0 when Vercel took it, 1 when it refused, 2 when it could not run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

replace=no
if [ "${1:-}" = --replace ]; then replace=yes; shift; fi
[ "$#" -eq 1 ] || cl_cannot "Use add-secret.sh [--replace] NAME with the value on standard input."
name=${1:-}
case "$name" in
  ''|*[!A-Za-z0-9_]*) cl_cannot "No setting name was given, so nothing was added." ;;
esac
cl_need vercel
[ ! -t 0 ] || cl_cannot "No value arrived on standard input, so nothing was added."

tmp=$(mktemp) || cl_cannot "A private temporary file could not be made, so nothing was added."
trap 'rm -f "$tmp"' EXIT HUP INT TERM
umask 077
cat > "$tmp"
value=$(cat "$tmp")
case "$name" in
  *_KEY|*_PASSWORD|*_TOKEN)
    [ -n "$value" ] || cl_cannot "$name is empty, so it cannot be added."
    case "$value" in *[[:space:]]*) cl_cannot "$name contains a space or line break, so it does not look like one value." ;; esac
    ;;
esac
case "$name" in
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY|SUPABASE_PUBLISHABLE_KEY)
    case "$value" in sb_publishable_*|eyJ*) ;; *) cl_cannot "$name does not start with sb_publishable_ or eyJ, so it does not look like a Supabase key." ;; esac ;;
  SUPABASE_SECRET_KEY|SUPABASE_SERVICE_ROLE_KEY)
    case "$value" in sb_secret_*|eyJ*) ;; *) cl_cannot "$name does not start with sb_secret_ or eyJ, so it does not look like a Supabase key." ;; esac ;;
esac

cl_approved
case "$name" in
  NEXT_PUBLIC_*) vercel env add "$name" production --type config --yes < "$tmp" >&2 ;;
  *) vercel env add "$name" production --yes < "$tmp" >&2 ;;
esac || cl_fail "Vercel did not take the setting $name."

if [ "$replace" = yes ]; then
  vercel env rm "$name" production --yes >&2 ||
    cl_fail "Vercel could not remove the previous production setting $name. The new value was added."
fi
cl_pass "Vercel holds $name for production."
