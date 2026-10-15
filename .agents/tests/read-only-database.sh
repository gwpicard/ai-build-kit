#!/usr/bin/env sh
# read-only-database.sh: rehearse the read-only privilege script.
# If this breaks, a user that can write to an existing database may be called read-only.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/setup-hosting/recipes/parts/scripts/read-only-database.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"
cat > "$WORK/bin/psql" <<'EOF'
#!/usr/bin/env python3
import os, re, sys
if os.environ.get("FAKE_PSQL", "readonly") == "down":
    sys.exit(1)
sql = sys.argv[-1]
# Model a single project's table grant list. Evaluate the privileges named by
# the SQL's has_table_privilege calls as PostgreSQL does for that table.
checked = re.findall(r"has_table_privilege\(current_user,c\.oid,'([A-Z]+)'\)", sql)
grants = {"SELECT"}
if os.environ.get("FAKE_PSQL") == "write":
    grants.add("INSERT")
if os.environ.get("FAKE_PSQL") == "no-select":
    grants.remove("SELECT")
if "SELECT" in checked and "SELECT" not in grants:
    print("unreadable")
elif any(privilege in grants for privilege in checked if privilege != "SELECT"):
    print("write")
else:
    print("read-only")
EOF
chmod +x "$WORK/bin/psql"
export PATH="$WORK/bin:$PATH" DATABASE_URL='postgresql://reader:fake-value@db.invalid/app'
run() {
  expected=$1; shift
  set +e
  output=$(env "$@" "$SCRIPT" 2>&1); actual=$?
  set -e
  [ "$actual" -eq "$expected" ] || { echo "expected exit $expected, got $actual: $output"; exit 1; }
}
run 0 FAKE_PSQL=readonly
run 1 FAKE_PSQL=write
run 1 FAKE_PSQL=no-select
run 2 FAKE_PSQL=down
set +e
output=$(env -u DATABASE_URL "$SCRIPT" 2>&1); actual=$?
set -e
[ "$actual" -eq 2 ] || { echo "missing configuration returned $actual instead of 2"; exit 1; }
echo 'read-only database rehearsal: exit 0, 1 and 2 passed'
