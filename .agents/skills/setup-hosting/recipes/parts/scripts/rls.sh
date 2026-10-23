#!/usr/bin/env sh
# rls.sh: list the public tables anyone holding the public key could read.
#
# Usage: rls.sh [--local] [--on-record <table>,<table>]
#
# It asks the live database, through the session pooler address with the
# password added, for the public tables with row-level security off. Such a
# table can be read by anyone holding the public key, which the tool sends to
# every browser. A table the masterplan already records as public by choice is
# named with --on-record and does not fail the check. Where the person's
# Supabase access token is set, the security advisor is read as well, as an
# optional second opinion that decides nothing.
#
# Exit 0 when no table is listed, or each one is on the record, 1 when a table
# is open and not on the record, 2 when the database could not be read.
# With --local, read only the disposable local database. SUPABASE_LOCAL_DB_URL
# can name its address inside a container. No linked password or advisor is read.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/check-lib.sh"

recorded=
local_db=no
if [ "${1:-}" = "--local" ]; then local_db=yes; shift; fi
if [ "${1:-}" = "--on-record" ]; then recorded=${2:-}; fi

cl_need psql
if [ "$local_db" = yes ]; then
  SUPABASE_DB_URL=${SUPABASE_LOCAL_DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}
else
  cl_db_url
fi

tables=$(psql --dbname "$SUPABASE_DB_URL" --tuples-only --command "select tablename from pg_tables where schemaname = 'public' and not rowsecurity;" 2>/dev/null) ||
  cl_cannot "The live database could not be reached, so the kit could not list tables anyone can read."

# The Supabase security advisor is an optional second read, since its endpoint
# is marked experimental. Its answer goes to stderr and decides nothing.
if [ "$local_db" = no ] && [ -n "${SUPABASE_ACCESS_TOKEN:-}" ] && command -v curl >/dev/null 2>&1; then
  ref=$(cl_ref)
  [ -z "$ref" ] || curl -fsS -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" \
    "https://api.supabase.com/v1/projects/$ref/advisors/security" >&2 2>/dev/null || true
fi

open=
for table in $tables; do
  case ",$recorded," in *",$table,"*) continue ;; esac
  open="$open $table"
done
open=${open# }
[ -z "$open" ] && cl_pass "No public table can be read with the public key alone, beyond what is on the record."
cl_fail "Anyone holding the public key can read these tables: $open."
