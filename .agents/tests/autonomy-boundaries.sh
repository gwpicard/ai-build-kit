#!/usr/bin/env sh
# autonomy-boundaries.sh: attempt limits and parallel reach clashes stop a queue.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
QUALITY="$ROOT/.agents/skills/quality-checks/scripts/quality.py"
ATTEMPT="$ROOT/.agents/skills/implement/scripts/attempt.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }

mkdir -p "$WORK/project" "$WORK/bin"
cat > "$WORK/bin/gh" <<'GH'
#!/usr/bin/env sh
[ "$*" = "issue edit 42 --add-label blocked" ] || exit 2
printf '%s\n' "$*" >> "$GH_LOG"
GH
chmod +x "$WORK/bin/gh"
export GH_LOG="$WORK/gh.log"
git -C "$WORK/project" init -q -b main
git -C "$WORK/project" config user.name Rehearsal
git -C "$WORK/project" config user.email rehearsal@example.invalid
printf 'base\n' > "$WORK/project/file.txt"
printf 'Runs on its own: queue, parallel 2, loop (decided 2026-10-15, "build several pieces")\n' \
  > "$WORK/project/masterplan.md"
git -C "$WORK/project" add file.txt masterplan.md
git -C "$WORK/project" commit -qm base
setting_line=$(cat "$WORK/project/masterplan.md")
printf 'Runs on its own: off\n' > "$WORK/project/masterplan.md"
git -C "$WORK/project" add masterplan.md
git -C "$WORK/project" commit -qm 'disable loop'
out=$(cd "$WORK/project" && sh "$ATTEMPT" 99 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'loop is off on main' \
  && pass "the short loop stays off by default" || fail "off loop returned $code: $out"
printf '%s\n' "$setting_line" > "$WORK/project/masterplan.md"
git -C "$WORK/project" add masterplan.md
git -C "$WORK/project" commit -qm 'enable loop for rehearsal'
for count in 1 2 3; do
  out=$(cd "$WORK/project" && PATH="$WORK/bin:$PATH" sh "$ATTEMPT" 42) || fail "attempt $count failed: $out"
done
out=$(cd "$WORK/project" && PATH="$WORK/bin:$PATH" sh "$ATTEMPT" 42 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'three attempts' \
  && grep -q 'issue edit 42 --add-label blocked' "$GH_LOG" \
  && pass "attempt four stops" || fail "attempt four returned $code: $out"
git -C "$WORK/project" worktree add -q --detach "$WORK/project-linked" HEAD
out=$(cd "$WORK/project-linked" && PATH="$WORK/bin:$PATH" sh "$ATTEMPT" 42 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'three attempts' \
  && pass "attempt count is shared across worktrees" || fail "linked worktree attempt returned $code: $out"
out=$(cd "$WORK/project" && PATH="$WORK/bin:$PATH" sh "$ATTEMPT" 43) || fail "attempt 43 did not start: $out"
git -C "$WORK/project" commit --allow-empty -qm 'Test fix: adjust assertion'
out=$(cd "$WORK/project" && PATH="$WORK/bin:$PATH" sh "$ATTEMPT" 43 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'Test fix commit ends the loop' \
  && pass "a Test fix commit ends the loop" || fail "Test fix returned $code: $out"

cat > "$WORK/bin/gh" <<'GH'
#!/usr/bin/env sh
if [ "$1" = repo ] && [ "$2" = view ]; then
  printf '%s\n' '{"nameWithOwner":"owner/project"}'
  exit 0
fi
if [ "$1" = api ]; then
  cat "$ISSUE_LIST"
  exit 0
fi
case "$3" in
  101) body='Reaches: src/a.ts' ;;
  102) body='Reaches: src/a.ts' ;;
  201) body='Reaches: src/a.ts' ;;
  202) body='Reaches: src/b.ts' ;;
  301) body='Reaches: db/migrations/001.sql' ;;
  302) body='Reaches: db/migrations/002.sql' ;;
  303) body='Reaches: src/c.ts' ;;
  *) exit 2 ;;
esac
BODY="$body" python3 -c 'import json,os; print(json.dumps({"body": os.environ["BODY"]}))'
GH
chmod +x "$WORK/bin/gh"
mkdir -p "$WORK/project/src" "$WORK/project/db/migrations"
printf 'client.from("customers")\n' > "$WORK/project/src/a.ts"
printf 'client.from("customers")\n' > "$WORK/project/src/b.ts"
printf 'create table alpha (id int);\n' > "$WORK/project/db/migrations/001.sql"
printf 'create table beta (id int);\n' > "$WORK/project/db/migrations/002.sql"
run_overlap() { (cd "$WORK/project" && PATH="$WORK/bin:$PATH" python3 "$QUALITY" overlap --pieces "$@"); }
out=$(run_overlap 101 102 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'shared file' \
  && pass "a shared file stops parallel work" || fail "shared file returned $code: $out"
out=$(run_overlap 201 202 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'shared table customers' \
  && pass "a shared table stops parallel work" || fail "shared table returned $code: $out"
out=$(run_overlap 301 302 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'migration work' \
  && pass "two migrations stop parallel work" || fail "migrations returned $code: $out"
printf 'client.from("suppliers")\n' > "$WORK/project/src/b.ts"
out=$(run_overlap 101 202 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s' "$out" | grep -q 'clear' \
  && pass "separate pieces can run together" || fail "separate pieces returned $code: $out"
out=$(run_overlap 101 202 303 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q 'allows 2 parallel pieces' \
  && pass "parallel two is the default cap" || fail "default parallel cap returned $code: $out"

mkdir -p "$WORK/project/.agents/tools"
cp "$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/plan-refresh.sh" \
  "$WORK/project/.agents/tools/plan-refresh.sh"
cat > "$WORK/issues.json" <<'JSON'
[
  {"number":7,"title":"Later ready","body":"## Done when\n- Works","labels":[{"name":"ready"}],"assignees":[]},
  {"number":3,"title":"First ready","body":"## Done when\n- Works","labels":[{"name":"ready"}],"assignees":[]},
  {"number":2,"title":"Not ready","body":"## Done when\n- Works","labels":[],"assignees":[]},
  {"number":4,"title":"Assigned","body":"## Done when\n- Works","labels":[{"name":"ready"}],"assignees":[{"login":"someone"}]}
]
JSON
out=$(cd "$WORK/project" && ISSUE_LIST="$WORK/issues.json" PATH="$WORK/bin:$PATH" \
  sh .agents/tools/plan-refresh.sh --next 2>&1) && code=0 || code=$?
expected=$(printf '3\tFirst ready')
[ "$code" -eq 0 ] && [ "$out" = "$expected" ] \
  && pass "--next picks the lowest-numbered ready, unblocked, unassigned piece" \
  || fail "--next returned $code: $out"

echo "autonomy-boundaries.sh: all checks passed"
