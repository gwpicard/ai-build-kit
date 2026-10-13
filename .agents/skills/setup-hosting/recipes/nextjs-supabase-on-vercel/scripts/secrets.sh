#!/usr/bin/env sh
# secrets.sh: check every name the tool needs is set on Vercel, no secret is
# public, and nothing secret can be committed.
#
# Usage: secrets.sh
#
# `vercel env ls production` must list every name in `.env.example`. It lists
# names only; this never asks Vercel for a value. No name that starts with
# NEXT_PUBLIC_ may contain SERVICE_ROLE or SECRET, since a public name reaches
# the browser. `git check-ignore supabase/.temp` must name the folder,
# `git check-ignore .vercel .env.local` must name both, and
# `git check-ignore --no-index .env.example` must name nothing and exit 1, so
# `.env.example` can be committed.
#
# Exit 0 when all hold, 1 when one does not, 2 when Vercel could not be read.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../../scripts/check-lib.sh"

cl_need vercel git
[ -f .env.example ] || cl_fail "The project has no .env.example, so nobody can tell which names the tool needs."

for name in $(cl_names .env.example); do
  case "$name" in
    NEXT_PUBLIC_*SERVICE_ROLE*|NEXT_PUBLIC_*SECRET*)
      cl_fail "$name starts with NEXT_PUBLIC_, so a secret would reach every browser." ;;
  esac
done

listed=$(vercel env ls production 2>/dev/null) ||
  cl_cannot "Vercel's list of settings could not be read, so the kit cannot tell whether the tool has every name it needs."
missing=
for name in $(cl_names .env.example); do
  printf '%s\n' "$listed" | grep -Eq "^[[:space:]]*$name([[:space:]]|\$)" || missing="$missing $name"
done
[ -z "$missing" ] || cl_fail "Vercel is missing settings the tool needs:$missing."

git check-ignore supabase/.temp >/dev/null 2>&1 ||
  cl_fail "Git does not ignore supabase/.temp, so the database address could be committed."
[ "$(git check-ignore .vercel .env.local 2>/dev/null | wc -l | tr -d ' ')" = 2 ] ||
  cl_fail "Git does not ignore both .vercel and .env.local, so a token could be committed."
git check-ignore --no-index .env.example >/dev/null 2>&1
[ $? -eq 1 ] || cl_fail "Git ignores .env.example, so the list of names the tool needs would be left out of commits."
cl_pass "Vercel holds every name in .env.example, no public name carries a secret, and no value can be committed."
