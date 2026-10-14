#!/usr/bin/env sh
# add-secret.sh: give Vercel one setting for production, with its value read
# from standard input so it never sits on a command line.
#
# Usage: add-secret.sh <NAME> < file-holding-the-value
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

name=${1:-}
case "$name" in
  ''|*[!A-Za-z0-9_]*) cl_cannot "No setting name was given, so nothing was added." ;;
esac
cl_need vercel
[ ! -t 0 ] || cl_cannot "No value arrived on standard input, so nothing was added."

case "$name" in
  NEXT_PUBLIC_*) vercel env add "$name" production --type config --yes >&2 ;;
  *) vercel env add "$name" production --yes >&2 ;;
esac || cl_fail "Vercel did not take the setting $name."
cl_pass "Vercel holds $name for production."
