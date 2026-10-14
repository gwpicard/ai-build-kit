#!/usr/bin/env sh
# reach-rehearsal.sh: checks reach output and related-test selection on a small
# Next.js and Supabase project, including each documented exit result.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
QUALITY="$ROOT/.agents/skills/quality-checks/scripts/quality.py"
PYTHON=$(command -v python3) || { echo "python3 is required" >&2; exit 2; }
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
PROJECT="$WORK/project"
mkdir -p "$PROJECT/app/items" "$PROJECT/app/teams" "$PROJECT/app/admin" \
  "$PROJECT/app/(admin)/settings" "$PROJECT/app/users/[id]" "$PROJECT/app/@modal" \
  "$PROJECT/lib/widgets" "$PROJECT/ui" "$PROJECT/supabase/migrations" "$PROJECT/test" "$PROJECT/e2e" "$WORK/bin"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok: $1"; }

cat > "$PROJECT/package.json" <<'JSON'
{"name":"reach-fixture","private":true}
JSON
cat > "$PROJECT/tsconfig.json" <<'JSON'
{"compilerOptions":{"baseUrl":".","paths":{"@/*":["./*"]}}}
JSON
cat > "$PROJECT/lib/format.ts" <<'TS'
export function formatItem(value: string): string { return value.trim(); }
export const table = (client: any) => client.from("items").select();
TS
cat > "$PROJECT/ui/item.ts" <<'TS'
import { formatItem } from "@/lib/format";
import { query } from "./items-query";
export const item = formatItem(" item ");
TS
cat > "$PROJECT/app/items/page.tsx" <<'TS'
import { item } from "@/ui/item";
import { widget } from "@/lib/widgets";
export default function Page() { return <p>{item}{widget}</p>; }
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
create function public.refresh_items() returns void language sql as $$ select; $$;
SQL
cat > "$PROJECT/supabase/migrations/002_dormant.sql" <<'SQL'
create table public.dormant (id integer primary key);
SQL
cat > "$PROJECT/ui/items-query.ts" <<'TS'
export const query = (client: any) => client.from("items").select();
TS
cat > "$PROJECT/ui/items-types.ts" <<'TS'
export type ItemRow = Tables<"items">;
TS
cat > "$PROJECT/ui/items-more.ts" <<'TS'
export const queryMore = (client: any) => client.from("items").select();
TS
cat > "$PROJECT/ui/items-fourth.ts" <<'TS'
export const queryFourth = (client: any) => client.from("items").select();
TS
cat > "$PROJECT/test/format.test.ts" <<'TS'
import { formatItem } from "@/lib/format";
if (formatItem(" item ") !== "item") throw new Error("bad format");
TS
cat > "$PROJECT/lib/widgets/index.ts" <<'TS'
export const widget = "widget";
TS
cat > "$PROJECT/app/(admin)/settings/page.tsx" <<'TS'
import { item } from "@/ui/item";
export default function Page() { return <p>{item}</p>; }
TS
cat > "$PROJECT/app/users/[id]/page.tsx" <<'TS'
import { item } from "@/ui/item";
export default function Page() { return <p>{item}</p>; }
TS
cat > "$PROJECT/app/items/loading.tsx" <<'TS'
import { item } from "@/ui/item";
export default function Loading() { return <p>{item}</p>; }
TS
cat > "$PROJECT/app/users/[id]/error.tsx" <<'TS'
import { item } from "@/ui/item";
export default function ErrorView() { return <p>{item}</p>; }
TS
cat > "$PROJECT/app/@modal/page.tsx" <<'TS'
import { item } from "@/ui/item";
export default function Page() { return <p>{item}</p>; }
TS
cat > "$PROJECT/app/layout.tsx" <<'TS'
import { item } from "@/ui/item";
export default function Layout({ children }: any) { return <main>{item}{children}</main>; }
TS
cat > "$PROJECT/ui/items-rpc.ts" <<'TS'
export const refresh = (supabase: any) => supabase.rpc("refresh_items");
TS
cat > "$PROJECT/lib/removed.ts" <<'TS'
export const removed = 1;
TS
cat > "$PROJECT/ui/removed-user.ts" <<'TS'
import { removed } from "../lib/removed";
export const stillUsesRemoved = removed;
TS
mkdir -p "$PROJECT/other"
cat > "$PROJECT/lib/gone.ts" <<'TS'
export const gone = 1;
TS
cat > "$PROJECT/other/gone.ts" <<'TS'
export const otherGone = 1;
TS
cat > "$PROJECT/ui/gone-user.ts" <<'TS'
import { gone } from "../lib/gone";
export const stillUsesGone = gone;
TS
cat > "$PROJECT/ui/other-gone-user.ts" <<'TS'
import { otherGone } from "../other/gone";
export const stillUsesOtherGone = otherGone;
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
    if spec.startswith("@/"):
        base = Path(spec[2:]).as_posix()
        return next((candidate for candidate in [base, *(base + ext for ext in (".ts", ".tsx", ".js", ".jsx")),
                                   *(base + "/index" + ext for ext in (".ts", ".tsx", ".js", ".jsx"))]
                     if candidate in targets), None)
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
if os.environ.get("FAKE_VITEST_MARKER"):
    Path(os.environ["FAKE_VITEST_MARKER"]).write_text("ran\n")
status = int(os.environ.get("FAKE_VITEST_STATUS", "0"))
if status and os.environ.get("FAKE_VITEST_SUMMARY", "1") == "1":
    print("Tests 1 failed")
raise SystemExit(status)
PY
chmod +x "$WORK/bin/vitest"
cat > "$WORK/bin/playwright" <<'SH'
#!/usr/bin/env sh
[ "$1" = test ] || exit 2
shift
printf '%s\n' "$*" > "$PLAYWRIGHT_MARKER"
SH
chmod +x "$WORK/bin/playwright"
cat > "$PROJECT/app/items.spec.ts" <<'TS'
// reached screen spec
TS
cat > "$PROJECT/e2e/not-reached.spec.ts" <<'TS'
// unrelated screen spec
TS

(cd "$PROJECT" && git init -q -b main && git config user.name Rehearsal \
  && git config user.email rehearsal@example.invalid && git add . && git commit -qm Start)

sed 's/value.trim()/value.trim().slice(0)/' "$PROJECT/lib/format.ts" > "$WORK/format.ts"
mv "$WORK/format.ts" "$PROJECT/lib/format.ts"
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" FAKE_VITEST_MARKER="$WORK/vitest-ran" PLAYWRIGHT_MARKER="$WORK/playwright-first" "$PYTHON" "$QUALITY" reach --base HEAD --run 2>&1) ||
  fail "reach should pass: $out"
printf '%s\n' "$out" | grep -q '^changed[[:space:]]lib/format.ts' || fail "changed function missing: $out"
printf '%s\n' "$out" | grep -q '^reaches[[:space:]]ui/item.ts' || fail "dependent file missing: $out"
printf '%s\n' "$out" | grep -q '^route[[:space:]]/items' || fail "route missing: $out"
printf '%s\n' "$out" | grep -q '^route[[:space:]]/settings' || fail "route group leaked into its address or route missing: $out"
printf '%s\n' "$out" | grep -q '^route[[:space:]]/users/\[id\]' || fail "dynamic route missing: $out"
printf '%s\n' "$out" | grep -q '^route[[:space:]]all$' || fail "root layout did not affect all routes: $out"
if printf '%s\n' "$out" | grep -q '^route[[:space:]]/@modal'; then fail "parallel route became an address segment: $out"; fi
printf '%s\n' "$out" | grep -q '^wide[[:space:]]routes[[:space:]]count ' || fail "wide route limit missing: $out"
printf '%s\n' "$out" | grep -q '^wide[[:space:]]table items[[:space:]]files 5' || fail "Tables<> or wide table detection missing: $out"
if printf '%s\n' "$out" | grep -q '^table[[:space:]]dormant'; then fail "an unchanged migration entered the changed table list: $out"; fi
[ -f "$WORK/vitest-ran" ] || fail "fake Vitest did not run: $out"
pass "reach lists the changed function, its dependents, route, table and covering test"

out=$(cd "$PROJECT" && "$PYTHON" "$QUALITY" reach --paths ./lib/widgets/index.ts 2>&1) || fail "index reach failed: $out"
printf '%s\n' "$out" | grep -q '^changed[[:space:]]lib/widgets/index.ts' || fail "./ path was not normalised: $out"
printf '%s\n' "$out" | grep -q '^reaches[[:space:]]app/items/page.tsx' || fail "index or @/ alias import was not resolved: $out"
pass "@/ aliases, index resolution and ./ path normalisation work"

out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" "$PYTHON" "$QUALITY" reach --paths ui/items-rpc.ts 2>&1) || fail "RPC reach failed: $out"
printf '%s\n' "$out" | grep -q '^rpc[[:space:]]refresh_items' || fail "RPC function was not detected: $out"
pass "Supabase RPC function calls are included in the database reach list"

cat > "$PROJECT/ui/not-db.ts" <<'TS'
export const bytes = Buffer.from("items");
export const values = Array.from("items");
TS
out=$(cd "$PROJECT" && "$PYTHON" "$QUALITY" reach --paths ui/not-db.ts 2>&1) || fail "non-database from calls failed: $out"
if printf '%s\n' "$out" | grep -q '^table'; then fail "Buffer.from or Array.from was counted as a database table: $out"; fi
pass "Buffer.from and Array.from do not count as database tables"

cat > "$PROJECT/supabase/migrations/003_alter.sql" <<'SQL'
alter table public.customers add column name text;
SQL
out=$(cd "$PROJECT" && "$PYTHON" "$QUALITY" reach --paths supabase/migrations/003_alter.sql 2>&1) || fail "changed alter migration failed: $out"
printf '%s\n' "$out" | grep -q '^table[[:space:]]customers' || fail "alter table was not detected in the changed migration: $out"
pass "changed migrations detect both create table and alter table"

for n in $(seq 1 10); do
  cat > "$PROJECT/ui/shared-user-$n.ts" <<TS
import { shared } from "../lib/shared";
export const user$n = shared;
TS
done
printf '%s\n' 'export const shared = 1;' > "$PROJECT/lib/shared.ts"
out=$(cd "$PROJECT" && "$PYTHON" "$QUALITY" reach --paths lib/shared.ts 2>&1) || fail "shared reach failed: $out"
printf '%s\n' "$out" | grep -q '^wide[[:space:]]lib/shared.ts[[:space:]]dependents 10$' || fail "dependents were not counted through reverse imports: $out"
pass "wide dependents counts files that import the changed file"

sed '/export const removed/d' "$PROJECT/lib/removed.ts" > "$WORK/removed.ts"
mv "$WORK/removed.ts" "$PROJECT/lib/removed.ts"
out=$(cd "$PROJECT" && "$PYTHON" "$QUALITY" reach --base HEAD 2>&1) || fail "removed export read failed: $out"
printf '%s\n' "$out" | grep -q '^wide[[:space:]]lib/removed.ts[[:space:]]removed export still imported in 1 files' || fail "removed imported export was missed: $out"
pass "a removed named export still imported is reported as wide"

rm "$PROJECT/lib/gone.ts"
out=$(cd "$PROJECT" && "$PYTHON" "$QUALITY" reach --base HEAD 2>&1) || fail "deleted file read failed: $out"
printf '%s\n' "$out" | grep -q '^wide[[:space:]]lib/gone.ts[[:space:]]deleted export imported in 1 files' || fail "deleted path matching used only a basename: $out"
pass "deleted files are matched to resolved import paths, not matching basenames"

out=$(cd "$PROJECT" && "$PYTHON" "$QUALITY" reach --paths ./src/new.ts 2>&1) || fail "new source path should pass: $out"
printf '%s\n' "$out" | grep -q '^new[[:space:]]src/new.ts$' || fail "new source was not listed: $out"
pass "new source paths are normalised and listed without a false could-not-run result"

PYPROJECT="$WORK/python-project"
PYBIN="$WORK/python-bin"
mkdir -p "$PYPROJECT/app" "$PYBIN"
cat > "$PYPROJECT/app/bramble.py" <<'PY'
def bramble():
    return "ok"
PY
cat > "$PYPROJECT/app/test_bramble.py" <<'PY'
from bramble import bramble
assert bramble() == "ok"
PY
cat > "$PYBIN/pytest" <<'SH'
#!/bin/sh
printf '%s\n' "$*" > "$PYTEST_MARKER"
echo '1 passed'
SH
chmod +x "$PYBIN/pytest"
ln -s "$(command -v git)" "$PYBIN/git"
(cd "$PYPROJECT" && git init -q -b main && git add . && git -c user.name=Rehearsal -c user.email=rehearsal@example.invalid commit -qm Start)
out=$(cd "$PYPROJECT" && PATH="$PYBIN" PYTEST_MARKER="$WORK/pytest-ran" "$PYTHON" "$QUALITY" reach --paths app/bramble.py --run 2>&1) || fail "Python pytest fallback failed: $out"
printf '%s\n' "$out" | grep -q '^not-checked[[:space:]]tests[[:space:]]Vitest is not installed$' || fail "missing Vitest was not named: $out"
grep -q 'app/test_bramble.py' "$WORK/pytest-ran" || fail "pytest did not receive the covering test: $out"
pass "Python imports resolve beside the importer and pytest can cover reach without Vitest"

DELETED="$WORK/deletion-only"
mkdir -p "$DELETED/lib" "$DELETED/other" "$DELETED/ui" "$DELETED/test"
printf '%s\n' 'export const gone = 1;' > "$DELETED/lib/gone.ts"
printf '%s\n' 'export const otherGone = 1;' > "$DELETED/other/gone.ts"
cat > "$DELETED/ui/gone-user.ts" <<'TS'
import { gone } from "../lib/gone";
export const useGone = gone;
TS
cat > "$DELETED/ui/other-gone-user.ts" <<'TS'
import { otherGone } from "../other/gone";
export const useOtherGone = otherGone;
TS
cat > "$DELETED/test/gone.test.ts" <<'TS'
import { useGone } from "../ui/gone-user";
if (useGone !== 1) throw new Error("bad gone");
TS
(cd "$DELETED" && git init -q -b main && git add . && git -c user.name=Rehearsal -c user.email=rehearsal@example.invalid commit -qm Start)
rm "$DELETED/lib/gone.ts"
out=$(cd "$DELETED" && PATH="$WORK/bin:$PATH" FAKE_VITEST_MARKER="$WORK/deleted-vitest" PLAYWRIGHT_MARKER="$WORK/deleted-playwright" "$PYTHON" "$QUALITY" reach --base HEAD --run 2>&1) || fail "deletion-only reach failed: $out"
printf '%s\n' "$out" | grep -q '^tests[[:space:]]test/gone.test.ts$' || fail "deleted file's former importer did not seed its covering test: $out"
grep -q '^ran$' "$WORK/deleted-vitest" || fail "Vitest did not leave its run marker: $out"
printf '%s\n' "$out" | grep -q '^test-output[[:space:]]test/gone.test.ts$' || fail "Vitest did not select the deleted file's former covering test: $out"
pass "a change that only deletes a file seeds its former importers and their tests"

status=0
(cd "$PROJECT" && PATH="$WORK/bin:$PATH" FAKE_VITEST_STATUS=1 "$PYTHON" "$QUALITY" reach --paths lib/format.ts --run) > "$WORK/fail.out" 2>&1 || status=$?
[ "$status" -eq 1 ] || fail "a failing related test returned $status"
pass "a failing covering test returns 1"

status=0
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" FAKE_VITEST_STATUS=1 FAKE_VITEST_SUMMARY=0 PLAYWRIGHT_MARKER="$WORK/startup-playwright" "$PYTHON" "$QUALITY" reach --paths lib/format.ts --run 2>&1) || status=$?
[ "$status" -eq 2 ] && printf '%s\n' "$out" | grep -q '^not-checked[[:space:]]tests[[:space:]]Vitest did not produce a test result summary$' || fail "Vitest startup failure was treated as a test failure: $status $out"
pass "Vitest exit 1 without a test summary is reported as could not run"

cat > "$WORK/bin/gh" <<'PY'
#!/usr/bin/env python3
import json
import os, sys
if os.environ.get("GH_FAIL"):
    raise SystemExit(1)
line = os.environ.get("GH_REACHES", "- **Reaches:** lib/format.ts (routes /items), table items")
done = os.environ.get("GH_DONE", "The items page shows the item list.")
body = "## Done when\n- " + done + "\n\n## Under the hood\n" + line + "\n\nMore notes.\n"
if "--jq" in __import__("sys").argv:
    print(body)
else:
    print(json.dumps({"body": body}))
PY
chmod +x "$WORK/bin/gh"
status=0
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" "$PYTHON" "$QUALITY" reach --paths app/layout.tsx --piece 13 2>&1) || status=$?
[ "$status" -eq 1 ] && printf '%s\n' "$out" | grep -q '^wide[[:space:]]routes[[:space:]]count 1$' \
  && printf '%s\n' "$out" | grep -q '^undeclared[[:space:]]route all' || fail "root layout reach was not treated as wide: $status $out"
pass "route all is wide and must be declared even when it is the only route line"
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" GH_REACHES='Reaches: lib/format.ts / /admin /items /settings /teams /users/[id] all items' PLAYWRIGHT_MARKER="$WORK/playwright-ran" "$PYTHON" "$QUALITY" reach --paths lib/format.ts --piece 13 --run 2>&1) || fail "Playwright reach failed: $out"
grep -q 'app/items.spec.ts' "$WORK/playwright-ran" || fail "matching Playwright route spec did not run: $out"
if grep -q 'not-reached.spec.ts' "$WORK/playwright-ran"; then fail "unrelated Playwright spec ran: $out"; fi
pass "--run includes only installed Playwright specs whose names match a reached route"
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" GH_DONE='The list refreshes.' GH_REACHES='Reaches: lib/format.ts / /admin /items /settings /teams /users/[id] all items' PLAYWRIGHT_MARKER="$WORK/no-screen-playwright" "$PYTHON" "$QUALITY" reach --paths lib/format.ts --piece 13 --run 2>&1) || fail "non-screen Playwright skip failed: $out"
[ ! -f "$WORK/no-screen-playwright" ] || fail "Playwright ran without a screen named in Done when: $out"
pass "Playwright does not run when Done when names no screen"
status=0
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" "$PYTHON" "$QUALITY" reach --base HEAD --piece 13 2>&1) || status=$?
[ "$status" -eq 1 ] || fail "undeclared wide routes should stop the build with exit 1, got $status: $out"
printf '%s\n' "$out" | grep -q '^undeclared[[:space:]]route /admin' ||
  fail "the undeclared route was not named: $out"
pass "wide routes missing from the piece's Reaches line are marked undeclared"

status=0
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" GH_REACHES='Reaches:' "$PYTHON" "$QUALITY" reach --paths lib/format.ts --piece 13 2>&1) || status=$?
[ "$status" -eq 1 ] && printf '%s\n' "$out" | grep -q '^undeclared' || fail "an empty Reaches line was accepted: $status $out"
pass "quality.py requires Reaches text on the same line"

status=0
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" GH_REACHES='Reaches: lib/format.ts, route /a, table item' "$PYTHON" "$QUALITY" reach --base HEAD --piece 13 2>&1) || status=$?
[ "$status" -eq 1 ] && printf '%s\n' "$out" | grep -q '^undeclared[[:space:]]route /admin' \
  && printf '%s\n' "$out" | grep -q '^undeclared[[:space:]]table items' || fail "undeclared tokens matched by substring: $status $out"
pass "routes and table names in Reaches are matched as whole tokens"

status=0
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" GH_REACHES='Reaches: lib/format.ts, routes / /admin /items /settings /teams /users/[id] all, table items' "$PYTHON" "$QUALITY" reach --paths lib/format.ts --piece 13 2>&1) || status=$?
[ "$status" -eq 0 ] || fail "declared route all and exact routes did not pass: $status $out"
pass "the route all declaration is recognised"

status=0
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" GH_FAIL=1 "$PYTHON" "$QUALITY" reach --paths lib/format.ts --piece 13 2>&1) || status=$?
[ "$status" -eq 2 ] && printf '%s\n' "$out" | grep -q '^not-checked[[:space:]]undeclared' || fail "a failed gh read was silent: $status $out"
NO_GH="$WORK/no-gh"
mkdir -p "$NO_GH"
ln -s "$(command -v git)" "$NO_GH/git"
status=0
out=$(cd "$PROJECT" && PATH="$NO_GH" "$PYTHON" "$QUALITY" reach --paths lib/format.ts --piece 13 2>&1) || status=$?
[ "$status" -eq 2 ] && printf '%s\n' "$out" | grep -q '^not-checked[[:space:]]undeclared' || fail "missing gh was silent: $status $out"
pass "missing or failing gh makes the undeclared check not-checked with exit 2"

EMPTY="$WORK/empty"
mkdir -p "$EMPTY"
(cd "$EMPTY" && git init -q -b main)
status=0
(cd "$EMPTY" && "$PYTHON" "$QUALITY" reach --paths notes.txt) > "$WORK/nograph.out" 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "a missing graph returned $status"
status=0
out=$(cd "$EMPTY" && "$PYTHON" "$QUALITY" reach --paths ./src/new.ts 2>&1) || status=$?
[ "$status" -eq 0 ] && printf '%s\n' "$out" | grep -q '^new[[:space:]]src/new.ts$' || fail "a new file in an otherwise empty project returned $status: $out"
status=0
(cd "$PROJECT" && PATH="/usr/bin:/bin" "$PYTHON" "$QUALITY" reach --paths lib/format.ts --run) > "$WORK/norunner.out" 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "a missing test runner returned $status"
status=0
(cd "$WORK" && "$PYTHON" "$QUALITY" reach --paths absent.ts) > "$WORK/nogit.out" 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "a folder without Git returned $status"
pass "missing graph, runner context and Git return 2"

echo "reach-rehearsal.sh: all checks passed"
