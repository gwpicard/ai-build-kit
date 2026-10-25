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
# A reference other than the live one, LIVE_REF or the folder's link, is
# another project, such as a preview's. Its password comes from the file
# PREVIEW_DB_PASSWORD_FILE names, never the live one's, and the folder's link
# is put back as it was on exit.
#
# A migration only adds, so the version live now keeps working once it is
# applied. Applying one changes the live database, so the kit runs --apply on
# the live project only after approval naming it, except during a first
# launch, which the person asked for.
#
# Without --apply: exit 0 when nothing is waiting, 1 when a migration is
# waiting, 2 when the database could not be read, or its answer named no
# migration the script could read.
# With --apply: exit 0 when it applied what was waiting, or nothing was, 1
# when the push failed, 2 when it could not run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/check-lib.sh"

apply=no
[ "${1:-}" = "--apply" ] && { apply=yes; shift; }
linked=$(cl_ref)
live=${LIVE_REF:-$linked}
ref=${1:-$linked}
[ -n "$ref" ] || cl_cannot "The kit does not know which database project this is, so the migrations could not be read."

cl_need supabase
out=$(mktemp)
saved=$(mktemp -d)
trap 'rm -f "$out"; rm -rf "$saved"' EXIT
if [ -n "$live" ] && [ "$ref" != "$live" ]; then
  [ -n "${PREVIEW_DB_PASSWORD_FILE:-}" ] ||
    cl_cannot "No password location is recorded for the database project $ref, and the live one's is never used for it, so the migrations could not be read."
  SUPABASE_DB_PASSWORD=
  DB_PASSWORD_FILE=$PREVIEW_DB_PASSWORD_FILE
  # Put the folder's link back as it was, whatever happens next.
  [ -d supabase/.temp ] && cp -R supabase/.temp "$saved/temp"
  trap 'rm -rf supabase/.temp; [ ! -d "$saved/temp" ] || cp -R "$saved/temp" supabase/.temp; rm -f "$out"; rm -rf "$saved"' EXIT
fi
cl_password
case "$SUPABASE_DB_PASSWORD" in
  ''|*[[:space:]]*|supabase|supabase\ *|vercel|vercel\ *|curl|curl\ *|npm|npm\ *|npx|npx\ *|git|git\ *|psql|psql\ *|node|node\ *|bash|bash\ *|sh|sh\ *|echo|echo\ *|printf|printf\ *|export|export\ *|cat|cat\ *|rm|rm\ *|pwd|pwd\ *|ls|ls\ *)
    cl_cannot "the password file does not look like a password" ;;
esac

supabase link --project-ref "$ref" >"$out" 2>&1 ||
  { cat "$out" >&2; cl_cannot "The folder could not be linked to the database project, so the migrations could not be read."; }

supabase db push --dry-run >"$out" 2>&1 ||
  { cat "$out" >&2; cl_cannot "The database could not be reached, so the kit cannot tell whether a migration is waiting."; }
cat "$out" >&2
# The names after "Would push", read without the colour codes a terminal adds.
esc=$(printf '\033')
waiting=$(sed "s/$esc\[[0-9;]*m//g" "$out" | awk '/[Ww]ould push/ { on = 1; next } on' |
  grep -Eo '[0-9]+_[^[:space:]]*\.sql' | paste -sd' ' -)
if [ -z "$waiting" ] && { grep -qi 'would push' "$out" || ! grep -qi 'up to date' "$out"; }; then
  cl_cannot "Supabase's answer named no migration the kit could read, so it cannot tell whether one is waiting."
fi

if [ "$apply" = no ]; then
  [ -z "$waiting" ] && cl_pass "The database has every migration main holds."
  cl_fail "The database lacks these migrations main holds: $waiting."
fi

[ -n "$waiting" ] || cl_pass "The database already had every migration main holds, so nothing was applied."
cl_approved
supabase db push >"$out" 2>&1 ||
  { cat "$out" >&2; cl_fail "The migrations could not be applied: $waiting. The database is as it was before."; }
cat "$out" >&2
cl_pass "Applied these migrations to the database, once: $waiting."
