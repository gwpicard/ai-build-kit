#!/usr/bin/env sh
# secrets.sh: read back the list of setting names Coolify holds for the app,
# and check nothing secret can be committed.
#
# Usage: secrets.sh --pasted <file>
#
# The paste is the list of names set in Coolify, with no values. Every name in
# `.env.example` must be on it. No name that starts with NEXT_PUBLIC_ may
# contain SERVICE_ROLE or SECRET. `git check-ignore supabase/.temp` must name
# the folder. A paste that carries a value is not read: nothing from it is
# kept, and the last line asks for the names alone.
#
# Exit 0 when all hold, 1 when one does not, 2 when there is no paste or it
# carries values.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../../scripts/check-lib.sh"

cl_need git
[ "${1:-}" = "--pasted" ] && [ -f "${2:-}" ] ||
  cl_cannot "Nothing was pasted back about the settings Coolify holds yet."
pasted=$2
grep -Eq '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*[^[:space:]]' "$pasted" &&
  cl_cannot "The paste carries values, so nothing from it was kept. Paste the names alone, and change any secret that was shown."
[ -f .env.example ] || cl_fail "The project has no .env.example, so nobody can tell which names the tool needs."

for name in $(cl_names .env.example); do
  case "$name" in
    NEXT_PUBLIC_*SERVICE_ROLE*|NEXT_PUBLIC_*SECRET*)
      cl_fail "$name starts with NEXT_PUBLIC_, so a secret would reach every browser." ;;
  esac
done
missing=
for name in $(cl_names .env.example); do
  grep -Eq "(^|[^A-Za-z0-9_])$name([^A-Za-z0-9_]|\$)" "$pasted" || missing="$missing $name"
done
[ -z "$missing" ] || cl_fail "Coolify is missing settings the tool needs:$missing."
git check-ignore supabase/.temp >/dev/null 2>&1 ||
  cl_fail "Git does not ignore supabase/.temp, so the database address could be committed."
cl_pass "Coolify holds every name in .env.example, no public name carries a secret, and no value can be committed."
