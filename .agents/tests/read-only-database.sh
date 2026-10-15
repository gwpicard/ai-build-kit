#!/usr/bin/env sh
# read-only-database.sh: rehearse the read-only privilege script against a real throwaway Postgres when available.
# If this breaks, a user that can write to an existing database may be called read-only.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/setup-hosting/recipes/parts/scripts/read-only-database.sh"
WORK=$(mktemp -d)
DATA="$WORK/data"
cleanup() {
  if [ -d "$DATA" ] && command -v pg_ctl >/dev/null 2>&1; then
    pg_ctl -D "$DATA" -m immediate -w stop >/dev/null 2>&1 || true
  fi
  rm -rf "$WORK"
}
trap cleanup EXIT
mkdir -p "$WORK/bin"
fail() { echo "FAIL: $1" >&2; exit 1; }
run() {
  expected=$1; shift
  set +e
  output=$(env "$@" "$SCRIPT" 2>&1); actual=$?
  set -e
  [ "$actual" -eq "$expected" ] || fail "expected exit $expected, got $actual: $output"
}

REAL_POSTGRES=no
if command -v initdb >/dev/null 2>&1 && command -v pg_ctl >/dev/null 2>&1 && \
   command -v postgres >/dev/null 2>&1 && command -v psql >/dev/null 2>&1; then
  if initdb -D "$DATA" -U postgres --auth=trust --no-locale -E UTF8 >"$WORK/initdb.log" 2>&1; then
    PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')
    if pg_ctl -D "$DATA" -l "$WORK/postgres.log" -o "-h 127.0.0.1 -p $PORT -F -c shared_memory_type=mmap -c dynamic_shared_memory_type=mmap" -w start >"$WORK/start.out" 2>&1; then
      REAL_POSTGRES=yes
    else
      echo "read-only rehearsal: local Postgres cannot start in this environment; using a privilege-table stand-in"
      rm -rf "$DATA"
    fi
  else
    echo "read-only rehearsal: local Postgres cannot initialise in this environment; using a privilege-table stand-in"
  fi
fi

if [ "$REAL_POSTGRES" = yes ]; then
  ADMIN="postgresql://postgres@127.0.0.1:$PORT/postgres"
  psql "$ADMIN" -v ON_ERROR_STOP=1 -c 'CREATE TABLE public.documents (id integer); CREATE ROLE reader LOGIN PASSWORD '\''fake-value'\''; CREATE ROLE writer LOGIN PASSWORD '\''fake-value'\''; CREATE ROLE no_reader LOGIN PASSWORD '\''fake-value'\''; GRANT CONNECT ON DATABASE postgres TO reader, writer, no_reader; GRANT USAGE ON SCHEMA public TO reader, writer, no_reader; GRANT SELECT ON public.documents TO reader; GRANT SELECT, INSERT ON public.documents TO writer;' >/dev/null
  echo "read-only rehearsal: using a real throwaway local Postgres"
  run 0 "DATABASE_URL=postgresql://reader:fake-value@127.0.0.1:$PORT/postgres"
  run 1 "DATABASE_URL=postgresql://writer:fake-value@127.0.0.1:$PORT/postgres"
  run 1 "DATABASE_URL=postgresql://no_reader:fake-value@127.0.0.1:$PORT/postgres"
  pg_ctl -D "$DATA" -m immediate -w stop >/dev/null
  run 2 "DATABASE_URL=postgresql://reader:fake-value@127.0.0.1:$PORT/postgres"
else
  # PostgreSQL documents has_table_privilege as a boolean privilege check and
  # psql -A -t as unaligned, tuple-only output. See
  # https://www.postgresql.org/docs/current/functions-info.html and
  # https://www.postgresql.org/docs/current/app-psql.html. The stand-in uses a
  # privilege table and returns the query's scalar labels.
  cat > "$WORK/bin/psql" <<'EOF'
#!/usr/bin/env python3
import os, sys
if os.environ.get("FAKE_PSQL", "reader") == "down":
    sys.exit(1)
sql = sys.argv[-1]
tokens = []
i = 0
while i < len(sql):
    if sql[i] == "'":
        i += 1
        value = ""
        while i < len(sql) and sql[i] != "'":
            if sql[i:i + 2] == "''":
                value += "'"
                i += 2
            else:
                value += sql[i]
                i += 1
        i += 1
        tokens.append(("literal", value.upper()))
    elif sql[i].isalnum() or sql[i] == "_":
        start = i
        while i < len(sql) and (sql[i].isalnum() or sql[i] == "_"):
            i += 1
        tokens.append(("word", sql[start:i].lower()))
    else:
        tokens.append(("punct", sql[i]))
        i += 1
checked = set()
known_privileges = {"SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "TRIGGER", "REFERENCES"}
for index, token in enumerate(tokens):
    if token == ("word", "has_table_privilege"):
        for kind, value in tokens[index + 1:]:
            if kind == "punct" and value == ")":
                break
            if kind == "literal" and value in known_privileges:
                checked.add(value)
# This small catalogue models the role's grants. Apply the requested privilege
# checks to it as PostgreSQL does; do not infer the result from the SQL string.
privileges = {
    "reader": {"SELECT"},
    "writer": {"SELECT", "INSERT"},
    "no_reader": set(),
}
user = os.environ.get("FAKE_USER", "reader")
grants = privileges[user]
print("unreadable" if "SELECT" in checked and "SELECT" not in grants else
      "write" if (checked - {"SELECT"}) & grants else "read-only")
EOF
  chmod +x "$WORK/bin/psql"
  export PATH="$WORK/bin:$PATH"
  echo "read-only rehearsal: no usable local Postgres server is available; using a privilege-table stand-in"
  run 0 FAKE_USER=reader DATABASE_URL='postgresql://reader:fake-value@db.invalid/app'
  run 1 FAKE_USER=writer DATABASE_URL='postgresql://writer:fake-value@db.invalid/app'
  run 1 FAKE_USER=no_reader DATABASE_URL='postgresql://no_reader:fake-value@db.invalid/app'
  run 2 FAKE_PSQL=down DATABASE_URL='postgresql://reader:fake-value@db.invalid/app'
fi

set +e
output=$(env -u DATABASE_URL "$SCRIPT" 2>&1); actual=$?
set -e
[ "$actual" -eq 2 ] || fail "missing configuration returned $actual instead of 2"
echo 'read-only database rehearsal: exit 0, 1 and 2 passed'
