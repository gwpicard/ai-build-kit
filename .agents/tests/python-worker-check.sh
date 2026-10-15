#!/usr/bin/env sh
# python-worker-check.sh: rehearse the Python worker check against Postgres with pgmq when available.
# If this breaks, a missing queue or unhealthy worker may be treated as ready.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/setup-hosting/recipes/parts/scripts/python-worker-check.sh"
WORK=$(mktemp -d)
DATA="$WORK/data"
SOCKET="$WORK/socket"
cleanup() {
  if [ -d "$DATA" ] && command -v pg_ctl >/dev/null 2>&1; then
    pg_ctl -D "$DATA" -m immediate -w stop >/dev/null 2>&1 || true
  fi
  rm -rf "$WORK"
}
trap cleanup EXIT
mkdir -p "$SOCKET" "$WORK/bin"
fail() { echo "FAIL: $1" >&2; exit 1; }
run() {
  expected=$1; shift
  set +e
  output=$(env "$@" "$SCRIPT" 2>&1); actual=$?
  set -e
  [ "$actual" -eq "$expected" ] || fail "expected exit $expected, got $actual: $output"
}

REAL_PGMQ=no
if command -v initdb >/dev/null 2>&1 && command -v pg_ctl >/dev/null 2>&1 && \
   command -v postgres >/dev/null 2>&1 && command -v psql >/dev/null 2>&1; then
  if initdb -D "$DATA" -U postgres --auth=trust --no-locale -E UTF8 >"$WORK/initdb.log" 2>&1; then
    PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')
    if pg_ctl -D "$DATA" -l "$WORK/postgres.log" -o "-h 127.0.0.1 -p $PORT -F -c shared_memory_type=mmap -c dynamic_shared_memory_type=mmap" -w start >"$WORK/start.out" 2>&1; then
      ADMIN="postgresql://postgres@127.0.0.1:$PORT/postgres"
      if psql "$ADMIN" -v ON_ERROR_STOP=1 -c 'CREATE EXTENSION pgmq; SELECT pgmq.create('\''document_jobs'\'');' >/dev/null 2>&1; then
        REAL_PGMQ=yes
      else
        pg_ctl -D "$DATA" -m immediate -w stop >/dev/null
      fi
    else
      echo "python worker rehearsal: local Postgres cannot start in this environment"
      rm -rf "$DATA"
    fi
  else
    echo "python worker rehearsal: local Postgres cannot initialise in this environment"
  fi
fi

if [ "$REAL_PGMQ" = yes ]; then
  # Supabase pgmq.create creates pgmq.q_<name>; PostgreSQL to_regclass returns
  # the relation name or NULL. psql -A -t emits the boolean as t or f.
  echo "python worker rehearsal: using a real throwaway Postgres with pgmq"
  cat > "$WORK/bin/curl" <<'EOF'
#!/usr/bin/env sh
case "${FAKE_HEALTH:-200}" in
  200) printf '200' ;;
  bad) printf '503' ;;
  down) exit 1 ;;
esac
EOF
  chmod +x "$WORK/bin/curl"
  export PATH="$WORK/bin:$PATH"
  run 0 "DATABASE_URL=$ADMIN" WORKER_HEALTH_URL='http://worker.invalid/health' FAKE_HEALTH=200
  psql "$ADMIN" -v ON_ERROR_STOP=1 -c 'CREATE DATABASE empty_queue;' >/dev/null
  EMPTY_QUEUE="postgresql://postgres@127.0.0.1:$PORT/empty_queue"
  psql "$EMPTY_QUEUE" -v ON_ERROR_STOP=1 -c 'CREATE EXTENSION pgmq;' >/dev/null
  run 1 "DATABASE_URL=$EMPTY_QUEUE" WORKER_HEALTH_URL='http://worker.invalid/health' FAKE_HEALTH=200
  run 1 "DATABASE_URL=$ADMIN" WORKER_HEALTH_URL='http://worker.invalid/health' FAKE_HEALTH=bad
  pg_ctl -D "$DATA" -m immediate -w stop >/dev/null
  run 2 "DATABASE_URL=$ADMIN" WORKER_HEALTH_URL='http://worker.invalid/health' FAKE_HEALTH=200
else
  # No local pgmq-capable Postgres is available. PostgreSQL documents
  # to_regclass(text) as relation-or-NULL; psql -A -t prints a scalar boolean
  # as t/f. See https://www.postgresql.org/docs/current/functions-info.html
  # and https://www.postgresql.org/docs/current/app-psql.html. Supabase pgmq
  # documents create(name) as creating q_<name>: see
  # https://supabase.com/docs/guides/queues. The stand-in uses a queue table.
  cat > "$WORK/bin/psql" <<'EOF'
#!/usr/bin/env python3
import os, sqlite3, sys
if os.environ.get("FAKE_QUEUE", "present") == "down":
    sys.exit(1)
catalog = sqlite3.connect(":memory:")
catalog.execute("create table relations (name text primary key)")
if os.environ.get("FAKE_QUEUE", "present") == "present":
    catalog.execute("insert into relations values (?)", ("pgmq.q_document_jobs",))
catalog.create_function(
    "to_regclass", 1,
    lambda name: name if catalog.execute("select 1 from relations where name = ?", (name,)).fetchone() else None,
)
print("t" if catalog.execute(sys.argv[-1]).fetchone()[0] else "f")
EOF
  cat > "$WORK/bin/curl" <<'EOF'
#!/usr/bin/env sh
case "${FAKE_HEALTH:-200}" in
  200) printf '200' ;;
  bad) printf '503' ;;
  down) exit 1 ;;
esac
EOF
  chmod +x "$WORK/bin/psql" "$WORK/bin/curl"
  export PATH="$WORK/bin:$PATH" DATABASE_URL='postgresql://reader:fake-value@db.invalid/app' WORKER_HEALTH_URL='http://worker.invalid/health'
  echo "python worker rehearsal: no local Postgres with pgmq is available; using a queue-table stand-in"
  run 0 FAKE_QUEUE=present FAKE_HEALTH=200
  run 1 FAKE_QUEUE=absent FAKE_HEALTH=200
  run 1 FAKE_QUEUE=present FAKE_HEALTH=bad
  run 2 FAKE_QUEUE=down FAKE_HEALTH=200
  run 2 FAKE_QUEUE=present FAKE_HEALTH=down
fi

set +e
output=$(env -u DATABASE_URL "$SCRIPT" 2>&1); actual=$?
set -e
[ "$actual" -eq 2 ] || fail "missing configuration returned $actual instead of 2"
echo 'python worker check rehearsal: exit 0, 1 and 2 passed'
