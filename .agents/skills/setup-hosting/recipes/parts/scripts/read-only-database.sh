#!/usr/bin/env sh
# read-only-database.sh: confirm the configured Postgres user cannot write.
set -eu

cannot() { echo "could not run: $1"; exit 2; }
fail() { echo "$1"; exit 1; }
pass() { echo "$1"; exit 0; }

if [ -z "${DATABASE_URL:-}" ]; then
  if [ -z "${DATABASE_URL_FILE:-}" ] || [ ! -r "$DATABASE_URL_FILE" ]; then
    cannot "the database connection setting is not available on this server."
  fi
  DATABASE_URL=$(cat -- "$DATABASE_URL_FILE") || cannot "the database connection setting could not be read."
fi
[ -n "$DATABASE_URL" ] || cannot "the database connection setting is empty."
command -v psql >/dev/null 2>&1 || cannot "psql is not installed."

# has_table_privilege and pg_class follow PostgreSQL's documented privilege and
# relation catalogue semantics: https://www.postgresql.org/docs/current/functions-info.html
# and https://www.postgresql.org/docs/current/catalog-pg-class.html.
query="select case when not exists (select 1 from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid = c.relnamespace where c.relkind in ('r','p','v','m','f') and n.nspname not in ('pg_catalog','information_schema') and has_table_privilege(current_user,c.oid,'SELECT')) then 'unreadable' when exists (select 1 from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid = c.relnamespace where c.relkind in ('r','p','v','m','f') and n.nspname not in ('pg_catalog','information_schema') and (has_table_privilege(current_user,c.oid,'INSERT') or has_table_privilege(current_user,c.oid,'UPDATE') or has_table_privilege(current_user,c.oid,'DELETE') or has_table_privilege(current_user,c.oid,'TRUNCATE') or has_table_privilege(current_user,c.oid,'TRIGGER') or has_table_privilege(current_user,c.oid,'REFERENCES'))) then 'write' else 'read-only' end"
result=$(psql -X -A -t -v ON_ERROR_STOP=1 "$DATABASE_URL" -c "$query" 2>/dev/null) || cannot "the configured database user or its privileges could not be read."
case "$result" in
  read-only) pass "The configured database user can read tables and has no table write privileges." ;;
  unreadable) fail "The configured database user cannot read the project's tables." ;;
  write) fail "The configured database user can change table data." ;;
  *) cannot "the database returned an unreadable privilege result." ;;
esac
