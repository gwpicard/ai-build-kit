#!/usr/bin/env sh
# python-worker-check.sh: rehearse the Python worker check with documented
# pgmq queue names and HTTP status behaviour. Guards pass, fail and could-not-run.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/setup-hosting/recipes/parts/scripts/python-worker-check.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"
cat > "$WORK/bin/psql" <<'EOF'
#!/usr/bin/env sh
sql=$(printf '%s\n' "$*" | tail -n 1)
case "$sql" in *"pgmq.q_document_jobs"*) ;; *) printf 'f\n'; exit 0 ;; esac
case "${FAKE_QUEUE:-present}" in
  present) printf 't\n' ;;
  absent) printf 'f\n' ;;
  down) exit 1 ;;
esac
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
run() {
  expected=$1; shift
  set +e
  output=$(env "$@" "$SCRIPT" 2>&1); actual=$?
  set -e
  [ "$actual" -eq "$expected" ] || { echo "expected exit $expected, got $actual: $output"; exit 1; }
  case "$expected:$output" in
    2:*'could not run'*) ;;
    2:*) echo 'exit 2 did not say could not run'; exit 1 ;;
  esac
}
run 0 FAKE_QUEUE=present FAKE_HEALTH=200
run 1 FAKE_QUEUE=absent FAKE_HEALTH=200
run 1 FAKE_QUEUE=present FAKE_HEALTH=bad
run 2 FAKE_QUEUE=down FAKE_HEALTH=200
run 2 FAKE_QUEUE=present FAKE_HEALTH=down
set +e
output=$(env -u DATABASE_URL "$SCRIPT" 2>&1); actual=$?
set -e
[ "$actual" -eq 2 ] && echo "$output" | grep -q 'could not run' || { echo 'missing configuration did not return 2'; exit 1; }
echo 'python worker check rehearsal: exit 0, 1 and 2 passed'
