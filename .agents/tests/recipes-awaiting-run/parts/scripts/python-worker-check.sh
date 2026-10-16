#!/usr/bin/env sh
# python-worker-check.sh: check pgmq queue presence and the worker health route.
set -eu
cannot() { echo "could not run: $1"; exit 2; }
fail() { echo "$1"; exit 1; }
pass() { echo "$1"; exit 0; }

[ -n "${DATABASE_URL:-}" ] || cannot "DATABASE_URL is not set on this server."
[ -n "${WORKER_HEALTH_URL:-}" ] || cannot "WORKER_HEALTH_URL is not set on this server."
command -v psql >/dev/null 2>&1 || cannot "psql is not installed."
command -v curl >/dev/null 2>&1 || cannot "curl is not installed."

# Supabase Queues documents pgmq.create(name) as creating pgmq.q_<name>;
# pgmq.read(queue_name, vt, qty) returns msg_id, read_ct, enqueued_at,
# vt, message, headers. See https://supabase.com/docs/guides/queues and
# https://github.com/tembo-io/pgmq. Check the queue table without consuming a job.
# PostgreSQL documents to_regclass(text) as resolving a relation or returning
# NULL when none exists: https://www.postgresql.org/docs/current/functions-info.html.
queue=$(psql -X -A -t -v ON_ERROR_STOP=1 "$DATABASE_URL" -c "select to_regclass('pgmq.q_document_jobs') is not null" 2>/dev/null) || cannot "the Supabase queue could not be checked."
[ "$queue" = t ] || fail "The document_jobs queue does not exist."
status=$(curl -sS -o /dev/null -w '%{http_code}' "$WORKER_HEALTH_URL" 2>/dev/null) || cannot "the worker health route could not be reached."
[ "$status" = 200 ] || fail "The worker health route returned an unexpected status."
pass "The document_jobs queue exists and the worker health route answers."
