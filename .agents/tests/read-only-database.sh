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
#!/usr/bin/env sh
sql=$(printf '%s\n' "$*" | tail -n 1)
case "${FAKE_PSQL:-readonly}" in
  readonly)
    for privilege in INSERT UPDATE DELETE TRUNCATE TRIGGER REFERENCES; do
      case "$sql" in *"'$privilege'"*) ;; *) printf 'write\n'; exit 0 ;; esac
    done
    printf 'read-only\n' ;;
  write) printf 'write\n' ;;
  down) exit 1 ;;
  *) printf 'surprise\n' ;;
esac
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
run 2 FAKE_PSQL=down
set +e
output=$(env -u DATABASE_URL "$SCRIPT" 2>&1); actual=$?
set -e
[ "$actual" -eq 2 ] && echo "$output" | grep -q 'could not run' || { echo 'missing configuration did not return 2'; exit 1; }
echo 'read-only database rehearsal: exit 0, 1 and 2 passed'
