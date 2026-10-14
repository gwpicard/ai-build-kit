#!/usr/bin/env sh
# restore.sh: prove a copy of the hosted Supabase database can be put back, by
# putting one back on this computer. The live database is only read.
#
# Usage: restore.sh
#
# It dumps the live project three times with `supabase db dump --linked`:
# roles, structure, and data. It stops the project's own local database with
# `supabase stop`, since the restore uses the same ports. In a throwaway
# folder outside the project it runs `supabase init`, copies the linked
# project's `supabase/.temp/*-version` files across, so the local services
# run the live project's versions, and runs `supabase start` with the full
# stack. It loads the three files as `supabase_admin` in one transaction, then
# compares each table's rows in `data.sql` with `select count(*)` locally.
# `supabase stop --no-backup` then removes the local copy. The minutes from
# the first dump to the last count are the restore time.
#
# Putting a backup back onto the live project starts from the Supabase
# dashboard, and nobody can reach the project while it runs. This never does.
#
# Exit 0 when every table's count matches and at least one table holds rows,
# 1 when a count differs or nothing loaded, 2 when it could not run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/check-lib.sh"

cl_need supabase docker psql
docker info >/dev/null 2>&1 ||
  cl_cannot "Docker's engine is not running on this computer, so the restore could not be tried."
[ -d supabase/.temp ] ||
  cl_cannot "The project is not linked to its database on this computer, so the restore could not be tried."
cl_password

project=$(pwd -P)
started=$(date +%s)
work=$(mktemp -d)
local_db=postgresql://supabase_admin:postgres@127.0.0.1:54322/postgres
finish() {
  if [ -d "$work/copy/supabase" ]; then
    (cd "$work/copy" && supabase stop --no-backup >/dev/null 2>&1) || true
  fi
  rm -rf "$work"
}
trap finish EXIT

supabase db dump --linked --role-only -f "$work/roles.sql" >&2 &&
  supabase db dump --linked -f "$work/schema.sql" >&2 &&
  supabase db dump --linked --data-only --use-copy -x storage.buckets_vectors -x storage.vector_indexes -f "$work/data.sql" >&2 ||
  cl_cannot "The live database could not be dumped, so the restore could not be tried."

supabase stop >&2 || true
mkdir -p "$work/copy"
(cd "$work/copy" && supabase init >&2) ||
  cl_cannot "A throwaway local database could not be set up, so the restore could not be tried."
mkdir -p "$work/copy/supabase/.temp"
for version in "$project"/supabase/.temp/*-version; do
  [ -f "$version" ] && cp "$version" "$work/copy/supabase/.temp/"
done
(cd "$work/copy" && supabase start >&2) ||
  cl_cannot "The throwaway local database would not start, so the restore could not be tried."

psql --single-transaction --variable ON_ERROR_STOP=1 --file "$work/roles.sql" --file "$work/schema.sql" --command 'SET session_replication_role = replica' --file "$work/data.sql" --dbname "$local_db" >&2 ||
  cl_fail "The backup did not load into a fresh database, so it could not be put back as it is."

counts=$(python3 - "$work/data.sql" <<'PY'
import re, sys
table, rows = None, 0
for line in open(sys.argv[1], errors="replace"):
    found = re.match(r'COPY\s+("?[\w]+"?\."?[\w]+"?)', line)
    if found and table is None:
        table, rows = found.group(1), 0
    elif table is not None and line.rstrip("\n") == "\\.":
        print("%s %d" % (table, rows))
        table = None
    elif table is not None:
        rows += 1
PY
)
[ -n "$counts" ] || cl_fail "The backup holds no table data, so a restore would load nothing."
held=no
while read -r table want; do
  got=$(psql --tuples-only --command "select count(*) from $table" --dbname "$local_db" 2>/dev/null | tr -d ' \n')
  [ "$got" = "$want" ] || cl_fail "After the restore, $table held $got rows where the backup holds $want."
  [ "$want" -gt 0 ] && held=yes
done <<EOF
$counts
EOF
[ "$held" = yes ] || cl_fail "Every table in the backup is empty, so the restore proves nothing."
minutes=$(( ($(date +%s) - started + 59) / 60 ))
[ "$minutes" -gt 1 ] && took="about $minutes minutes" || took="under a minute"
cl_pass "A copy of the database was put back on this computer and every table's rows matched, in $took."
