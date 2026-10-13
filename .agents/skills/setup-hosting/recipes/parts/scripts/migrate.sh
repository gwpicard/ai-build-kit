#!/usr/bin/env sh
# migrate.sh: read, or apply, the migrations a hosted Supabase database lacks.
#
# Usage: migrate.sh [--apply] [<project ref>]
#
# It links the folder to the project with `supabase link --project-ref`, then
# lists what `supabase db push --dry-run` would change. With --apply it then
# runs `supabase db push`, once. Without a reference it uses the project the
# folder is linked to. The database password comes from the file
# DB_PASSWORD_FILE names, read here and never printed.
#
# A migration only adds, so the version live now keeps working once it is
# applied. Applying one changes the live database, so the kit runs --apply on
# the live project only after a yes that names it, except during a first
# launch, which the person asked for.
#
# Without --apply: exit 0 when nothing is waiting, 1 when a migration is
# waiting, 2 when the database could not be read.
# With --apply: exit 0 when it applied what was waiting, or nothing was, 1
# when the push failed, 2 when it could not run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/check-lib.sh"

apply=no
[ "${1:-}" = "--apply" ] && { apply=yes; shift; }
ref=${1:-}
[ -n "$ref" ] || ref=$(cl_ref)
[ -n "$ref" ] || cl_cannot "The kit does not know which database project this is, so the migrations could not be read."

cl_need supabase
cl_password

out=$(mktemp)
trap 'rm -f "$out"' EXIT

supabase link --project-ref "$ref" >"$out" 2>&1 ||
  { cat "$out" >&2; cl_cannot "The folder could not be linked to the database project, so the migrations could not be read."; }

supabase db push --dry-run >"$out" 2>&1 ||
  { cat "$out" >&2; cl_cannot "The database could not be reached, so the kit cannot tell whether a migration is waiting."; }
cat "$out" >&2
waiting=$(sed -n 's/^[[:space:]]*[•*-][[:space:]]*\([0-9][0-9]*_[^[:space:]]*\.sql\).*/\1/p' "$out" | paste -sd' ' -)

if [ "$apply" = no ]; then
  [ -z "$waiting" ] && cl_pass "The database has every migration main holds."
  cl_fail "The database lacks these migrations main holds: $waiting."
fi

[ -n "$waiting" ] || cl_pass "The database already had every migration main holds, so nothing was applied."
supabase db push >"$out" 2>&1 ||
  { cat "$out" >&2; cl_fail "The migrations could not be applied: $waiting. The database is as it was before."; }
cat "$out" >&2
cl_pass "Applied these migrations to the database, once: $waiting."
