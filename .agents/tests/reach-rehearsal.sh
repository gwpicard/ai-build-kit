#!/usr/bin/env sh
# reach-rehearsal.sh: checks reach output and related-test selection on a small
# Next.js and Supabase project, including each documented exit result.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
QUALITY="$ROOT/.agents/skills/quality-checks/scripts/quality.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
PROJECT="$WORK/project"
mkdir -p "$PROJECT/app/items" "$PROJECT/app/teams" "$PROJECT/app/admin" \
  "$PROJECT/lib" "$PROJECT/ui" "$PROJECT/supabase/migrations" "$PROJECT/test" "$WORK/bin"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }

cat > "$PROJECT/package.json" <<'JSON'
{"name":"reach-fixture","private":true}
JSON
cat > "$PROJECT/lib/format.ts" <<'TS'
export function formatItem(value: string): string { return value.trim(); }
export const table = (client: any) => client.from("items").select();
TS
cat > "$PROJECT/ui/item.ts" <<'TS'
import { formatItem } from "../lib/format";
import { query } from "./items-query";
export const item = formatItem(" item ");
TS
cat > "$PROJECT/app/items/page.tsx" <<'TS'
import { item } from "../../ui/item";
export default function Page() { return <p>{item}</p>; }
TS
cat > "$PROJECT/app/teams/page.tsx" <<'TS'
import { item } from "../../ui/item";
export default function Page() { return <p>{item}</p>; }
TS
cat > "$PROJECT/app/admin/page.tsx" <<'TS'
import { item } from "../../ui/item";
export default function Page() { return <p>{item}</p>; }
TS
cat > "$PROJECT/supabase/migrations/001_items.sql" <<'SQL'
create table public.items (id integer primary key);
SQL
cat > "$PROJECT/ui/items-query.ts" <<'TS'
export const query = (client: any) => client.from("items").select();
TS
cat > "$PROJECT/ui/items-types.ts" <<'TS'
export type ItemRow = Tables<"items">;
SQL
cat > "$PROJECT/ui/items-more.ts" <<'TS'
export const queryMore = (client: any) => client.from("items").select();
TS
cat > "$PROJECT/test/format.test.ts" <<'TS'
import { formatItem } from "../lib/format";
if (formatItem(" item ") !== "item") throw new Error("bad format");
TS

# Vitest related finds test files whose static import graph reaches one of the
# requested files. This follows that selection behaviour without installing it.
cat > "$WORK/bin/vitest" <<'PY'
#!/usr/bin/env python3
import os, re, sys
from pathlib import Path

if sys.argv[1:2] != ["related"] or "--run" not in sys.argv:
    raise SystemExit(2)
root = Path.cwd()
targets = {Path(x).as_posix() for x in sys.argv[2:] if x != "--run"}
imports = re.compile(r"(?:from\s*|import\s*\()\s*['\"]([^'\"]+)['\"]")
tests = list(root.rglob("*.test.*")) + list(root.rglob("*.spec.*"))
def resolves(source, spec):
    if not spec.startswith("."):
        return None
    base = (source.parent / spec).resolve().relative_to(root).as_posix()
    for candidate in [base, *(base + ext for ext in (".ts", ".tsx", ".js", ".jsx"))]:
        if candidate in targets:
            return candidate
    return None
selected = []
for test in tests:
    text = test.read_text()
    if any(resolves(test, spec) in targets for spec in imports.findall(text)
           if resolves(test, spec)):
        selected.append(test)
if not selected:
    print("No test files found related to the specified files.")
    raise SystemExit(0)
for test in selected:
    print(test.relative_to(root))
raise SystemExit(int(os.environ.get("FAKE_VITEST_STATUS", "0")))
PY
chmod +x "$WORK/bin/vitest"

(cd "$PROJECT" && git init -q -b main && git config user.name Rehearsal \
  && git config user.email rehearsal@example.invalid && git add . && git commit -qm Start)

sed 's/value.trim()/value.trim().slice(0)/' "$PROJECT/lib/format.ts" > "$WORK/format.ts"
mv "$WORK/format.ts" "$PROJECT/lib/format.ts"
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" python3 "$QUALITY" reach --base HEAD --run 2>&1) ||
  fail "reach should pass: $out"
printf '%s\n' "$out" | grep -q '^changed[[:space:]]lib/format.ts' || fail "changed function missing: $out"
printf '%s\n' "$out" | grep -q '^reaches[[:space:]]ui/item.ts' || fail "dependent file missing: $out"
printf '%s\n' "$out" | grep -q '^route[[:space:]]/items' || fail "route missing: $out"
printf '%s\n' "$out" | grep -q '^wide[[:space:]]routes[[:space:]]count 3' || fail "wide route limit missing: $out"
printf '%s\n' "$out" | grep -q '^table[[:space:]]items' || fail "table missing: $out"
printf '%s\n' "$out" | grep -q 'test/format.test.ts' || fail "covering test did not run: $out"
pass "reach lists the changed function, its dependents, route, table and covering test"

status=0
(cd "$PROJECT" && PATH="$WORK/bin:$PATH" FAKE_VITEST_STATUS=1 python3 "$QUALITY" reach --paths lib/format.ts --run) > "$WORK/fail.out" 2>&1 || status=$?
[ "$status" -eq 1 ] || fail "a failing related test returned $status"
pass "a failing covering test returns 1"

cat > "$WORK/bin/gh" <<'PY'
#!/usr/bin/env python3
import json
print(json.dumps({"body": "## Under the hood\nReaches: lib/format.ts (routes /items), table items\n"}))
PY
chmod +x "$WORK/bin/gh"
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" python3 "$QUALITY" reach --base HEAD --piece 13 2>&1) ||
  fail "reach should report undeclared wide routes: $out"
printf '%s\n' "$out" | grep -q '^undeclared[[:space:]]route /admin' ||
  fail "the undeclared route was not named: $out"
pass "wide routes missing from the piece's Reaches line are marked undeclared"

EMPTY="$WORK/empty"
mkdir -p "$EMPTY"
(cd "$EMPTY" && git init -q -b main)
status=0
(cd "$EMPTY" && python3 "$QUALITY" reach --paths absent.ts) > "$WORK/nograph.out" 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "a missing graph returned $status"
status=0
(cd "$PROJECT" && PATH="/usr/bin:/bin" /usr/bin/python3 "$QUALITY" reach --paths lib/format.ts --run) > "$WORK/norunner.out" 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "a missing test runner returned $status"
status=0
(cd "$WORK" && python3 "$QUALITY" reach --paths absent.ts) > "$WORK/nogit.out" 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "a folder without Git returned $status"
pass "missing graph, runner context and Git return 2"

echo "reach-rehearsal.sh: all checks passed"
