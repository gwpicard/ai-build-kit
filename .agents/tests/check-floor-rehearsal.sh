#!/usr/bin/env sh
# check-floor-rehearsal.sh: found a throwaway project, wire its check the way
# check-floor.md says, and watch the check go red on a type error and green
# once the error is fixed.
#
# The commands come out of the shipped reference's table rather than being
# written here, so a table that named a command that does not work fails this
# rehearsal. The check starts from the shipped workflow template, and each
# step's command is run locally in order, which is what the hosted check does.
#
# The broken function has no test. That is the point of the floor: the tests
# pass, and the type check is what turns the tick red.
#
# The test check goes red on a trim commit that changed a test, and also when it
# cannot read the commits at all. A project founded before that step gets it
# from place-trim-check.py, on a yes, exactly as founding writes it today.
#
# Python is the language rehearsed because its two tools install as small
# packages. They are used from PATH when present and otherwise installed into a
# throwaway environment. A machine that can do neither fails here rather than
# skipping, since a rehearsal that passes by never running proves nothing.

set -eu

# The throwaway project's check reads its base branch from GITHUB_BASE_REF. On
# the hosted run that names this repository's own base, which the throwaway
# project does not have, so clear it.
unset GITHUB_BASE_REF
unset PR_BASE_SHA

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
FLOOR="$ROOT/.agents/skills/quality-checks/references/check-floor.md"
TEMPLATE="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml"
SENSITIVE="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh"
SCAN="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/scan-secrets.sh"
SCAN_PY="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/scan-secrets.py"
GUARD_PY="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/guard-secrets.py"
REDACT_PY="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/redact-secrets.py"
CODEX_PY="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/codex-github-check.py"
TEST_CHECK="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-tests.sh"
REVIEW_CHECK="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-review.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

bootstrap_review_reader() {
  mkdir -p "$1/.agents/skills"
  ln -s "$ROOT/.agents/skills/setup-ai-build-kit" "$1/.agents/skills/setup-ai-build-kit"
  sh "$ROOT/.agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh" "$1" >/dev/null
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/npm-cache"
npm_config_cache="$WORK/npm-cache"
export npm_config_cache
PROJECT="$WORK/project"
mkdir -p "$PROJECT/.github/workflows" "$PROJECT/.agents/hooks" "$PROJECT/.agents/tools"

# --- the commands, read from the shipped table ------------------------------

row=$(grep '^| Python |' "$FLOOR") || fail "check-floor.md has no Python row"
type_check=$(printf '%s\n' "$row" | awk -F'|' '{print $3}' | sed -n 's/.*`\([^`]*\)`.*/\1/p')
lint=$(printf '%s\n' "$row" | awk -F'|' '{print $4}' | sed -n 's/.*`\([^`]*\)`.*/\1/p')
[ -n "$type_check" ] || fail "the Python row names no type check command"
[ -n "$lint" ] || fail "the Python row names no lint command"
echo "  type check: $type_check"
echo "  lint: $lint"

# --- the tools --------------------------------------------------------------

if ! command -v mypy >/dev/null 2>&1 || ! command -v ruff >/dev/null 2>&1; then
  echo "  mypy or ruff not on PATH, installing both into a throwaway environment"
  python3 -m venv "$WORK/venv" ||
    fail "could not make a Python environment, so the check could not be rehearsed"
  "$WORK/venv/bin/pip" install --quiet mypy ruff ||
    fail "could not install mypy and ruff, so the check could not be rehearsed"
  PATH="$WORK/venv/bin:$PATH"
  export PATH
fi

# --- founding: the project and its wired check ------------------------------

cp "$SENSITIVE" "$PROJECT/.agents/hooks/check-sensitive-areas.sh"
cp "$SCAN" "$PROJECT/.agents/hooks/scan-secrets.sh"
cp "$SCAN_PY" "$PROJECT/.agents/hooks/scan-secrets.py"
cp "$GUARD_PY" "$PROJECT/.agents/hooks/guard-secrets.py"
cp "$REDACT_PY" "$PROJECT/.agents/hooks/redact-secrets.py"
cp "$CODEX_PY" "$PROJECT/.agents/tools/codex-github-check.py"
cp "$TEST_CHECK" "$PROJECT/.agents/hooks/check-tests.sh"
bootstrap_review_reader "$PROJECT"
cp "$REVIEW_CHECK" "$PROJECT/.agents/hooks/check-review.sh"


# The edit founding makes: the placeholder step goes, and install, type check,
# lint and test go in its place, each as its own named step.
awk -v tc="$type_check" -v li="$lint" '
  /- name: Install and test/ { skipping = 1 }
  skipping { next }
  { print }
  END {
    print "      - name: Install"
    print "        run: python3 -m pip install mypy ruff"
    print "      - name: Type check"
    print "        run: " tc
    print "      - name: Lint"
    print "        run: " li
    print "      - name: Test"
    print "        run: python3 -m unittest"
  }
' "$TEMPLATE" > "$PROJECT/.github/workflows/checks.yml"

grep -q 'placeholder' "$PROJECT/.github/workflows/checks.yml" &&
  fail "the placeholder step survived the edit"

cat > "$PROJECT/pricing.py" <<'PY'
def total(price: int, count: int) -> int:
    return price * count
PY

cat > "$PROJECT/test_pricing.py" <<'PY'
import unittest

from pricing import total


class TotalTest(unittest.TestCase):
    def test_total(self) -> None:
        self.assertEqual(total(2, 3), 6)


if __name__ == "__main__":
    unittest.main()
PY
cat > "$PROJECT/masterplan.md" <<'MD'
Path: Build with care

Sensitive areas:
  Data:
    paths: pricing.py
    Accepted: yes, 2026-10-14
MD

# --- running the check the way the hosted runner would ----------------------

# Prints the name of the first step that failed, or nothing when all passed.
# The Install step is left to the rehearsal, which already provided the tools.
mkdir -p "$WORK/bin"
cat > "$WORK/bin/gh" <<'SH'
#!/usr/bin/env sh
case "$*" in
  "pr view 9 --json body --jq .body") printf '%s\n' '## Worth stopping for' '- None' '## Worth knowing' '- None' 'Review record: reviewed=quality review; tried=0; open=0' ;;
  *) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
SH
chmod +x "$WORK/bin/gh"
run_check() {
  event_name=${1:-pull_request}
  awk '
    /^ *- id: / { name = ""; condition = ""; block = 0; next }
    /^ *- uses: / { name = ""; condition = ""; block = 0; next }
    /^ *- name: / { sub(/^ *- name: /, ""); name = $0; condition = ""; next }
    /^ *if: / { sub(/^ *if: /, ""); condition = $0; next }
    /^ *run: \|[-+]?$/ { run_indent = match($0, /[^ ]/); command = ""; block = 1; next }
    block && /^[ ]+/ {
      indent = match($0, /[^ ]/)
      if (indent > run_indent) { sub(/^[ ]+/, ""); command = command $0 "\n"; next }
      printf "%s\034%s\034%s\n", name, condition, command; block = 0
    }
    /^ *run: /    { sub(/^ *run: /, ""); printf "%s\034%s\034%s\n", name, condition, $0 }
    END { if (block) printf "%s\034%s\034%s\n", name, condition, command }
  ' "$PROJECT/.github/workflows/checks.yml" > "$WORK/steps"
  separator=$(printf '\034')
  while IFS="$separator" read -r step condition command; do
    [ "$step" = "Install" ] && continue
    if [ "$condition" = "github.event_name == 'pull_request'" ] && [ "$event_name" != pull_request ]; then
      continue
    fi
    base_sha=$(git -C "$PROJECT" rev-parse refs/remotes/origin/main)
    head_sha=$(git -C "$PROJECT" rev-parse HEAD)
    pr_base=$base_sha
    [ "$event_name" = pull_request ] || pr_base=
    if ! (cd "$PROJECT" && PATH="$WORK/bin:$PATH" PR_NUMBER=9 GITHUB_EVENT_NAME="$event_name" PR_BASE_SHA="$pr_base" BASE_SHA="$base_sha" \
        HEAD_SHA="$head_sha" PUSH_BEFORE="$base_sha" PUSH_AFTER="$head_sha" sh -c "$command") > "$WORK/last-output" 2>&1; then
      cat "$WORK/last-output" >&2
      git -C "$PROJECT" show "$pr_base:masterplan.md" >&2 || true
      printf '%s\n' "$step"
      return 0
    fi
  done < "$WORK/steps"
}

in_project() {
  (cd "$PROJECT" && git -c user.name=Rehearsal -c user.email=rehearsal@example.invalid \
    -c commit.gpgsign=false "$@") > /dev/null
}

# The hosted check runs in a clone with the whole history, where the pull
# request's base is origin/main. A local origin/main stands in for it.
save_as_base() {
  in_project add -A
  in_project commit -q -m "$1"
  in_project update-ref refs/remotes/origin/main HEAD
}

# The test check fails when it cannot read the pull request's commits, since a
# trim it never read is not a trim it checked. It said "passed" once.
mkdir -p "$WORK/no-history"
status=0
(cd "$WORK/no-history" && sh "$TEST_CHECK") > "$WORK/last-output" 2>&1 || status=$?
[ "$status" != 0 ] || fail "the test check passed with no history to read"
grep -q 'could not be read' "$WORK/last-output" || fail "the test check did not say it could not read the commits"
echo "  ok: the test check goes red, and says why, when it cannot read the commits"

in_project init -q -b main
printf '__pycache__/\n.mypy_cache/\n.ruff_cache/\n' > "$PROJECT/.gitignore"
in_project add -A -f -- masterplan.md
in_project add -A
in_project commit -q -m "Start"
status=0
(cd "$PROJECT" && sh .agents/hooks/check-tests.sh) > "$WORK/last-output" 2>&1 || status=$?
[ "$status" != 0 ] || fail "the test check passed with no base branch to compare with"
echo "  ok: the test check goes red when the history holds no base branch, as a shallow checkout leaves it"
in_project update-ref refs/remotes/origin/main HEAD

started=$(date +%s)
first=$(run_check)
finished=$(date +%s)
[ -z "$first" ] || { cat "$WORK/last-output" >&2; fail "the new project's check was red on day one, at $first"; }
echo "  ok: the founded project's check is green on day one ($((finished - started))s)"
first=$(run_check push)
[ -z "$first" ] || { cat "$WORK/last-output" >&2; fail "the push event with an empty pull request base went red at $first"; }
echo "  ok: a push event stays green with an empty pull request base"

# A type error in code no test reaches.
cat >> "$PROJECT/pricing.py" <<'PY'


def describe(count: int) -> str:
    return count
PY

(cd "$PROJECT" && python3 -m unittest) > "$WORK/tests-only" 2>&1 ||
  fail "the tests should still pass with the type error in place"
echo "  ok: the tests alone still pass with the type error in place"

first=$(run_check)
[ "$first" = "Type check" ] || fail "expected the Type check step to go red, got '${first:-nothing}'"
grep -q 'pricing.py' "$WORK/last-output" || fail "the type check did not name the file"
echo "  ok: the check goes red at Type check, naming pricing.py"

# The fix.
sed 's/    return count/    return str(count)/' "$PROJECT/pricing.py" > "$WORK/fixed"
mv "$WORK/fixed" "$PROJECT/pricing.py"
first=$(run_check)
[ -z "$first" ] || { cat "$WORK/last-output" >&2; fail "the check stayed red after the fix, at $first"; }
echo "  ok: the check goes green once the type error is fixed"

# An unused import is the linter's to catch, with the type check still green.
printf 'import os\n%s\n' "$(cat "$PROJECT/pricing.py")" > "$WORK/linted"
mv "$WORK/linted" "$PROJECT/pricing.py"
first=$(run_check)
[ "$first" = "Lint" ] || fail "expected the Lint step to go red, got '${first:-nothing}'"
echo "  ok: the check goes red at Lint on an unused import"

# A trim commit that changed a test turns the tick red at its own step. The
# pull request's base is stood in for by a local origin/main.
sed '1d' "$PROJECT/pricing.py" > "$WORK/unlinted"
mv "$WORK/unlinted" "$PROJECT/pricing.py"
for kit_dir in .agents .claude .codex .cursor .gemini; do
  mkdir -p "$PROJECT/$kit_dir"
  printf 'import os\n' > "$PROJECT/$kit_dir/lint_probe.py"
done
first=$(run_check)
[ -z "$first" ] || { cat "$WORK/last-output" >&2; fail "the project's lint step checked a kit folder, at $first"; }
echo "  ok: the project's lint step leaves the kit's folders alone"
rm -f "$PROJECT"/.agents/lint_probe.py "$PROJECT"/.claude/lint_probe.py \
  "$PROJECT"/.codex/lint_probe.py "$PROJECT"/.cursor/lint_probe.py \
  "$PROJECT"/.gemini/lint_probe.py
save_as_base "The checked code"
first=$(run_check)
[ -z "$first" ] || { cat "$WORK/last-output" >&2; fail "the check was red before the trim, at $first"; }
sed 's/total(2, 3), 6/total(1, 6), 6/' "$PROJECT/test_pricing.py" > "$WORK/test"
mv "$WORK/test" "$PROJECT/test_pricing.py"
in_project commit -q -am "Trim: take out what the piece did not need"
first=$(run_check)
[ "$first" = "Check tests were not changed silently" ] ||
  fail "expected the test check to go red on a trim that changed a test, got '${first:-nothing}'"
grep -q 'test_pricing.py' "$WORK/last-output" || fail "the test check did not name the test"
echo "  ok: the check goes red at the test check when a trim commit changed a test, naming it"

# --- a project founded before the test check ----------------------------------
#
# The same project as an older founding left it: no hook, no test check, and a
# checkout of the last commit only. /maintain's truing runs place-trim-check.py,
# which finds all three, records a no, and on a yes puts back exactly what
# founding writes today.

PLACE="$ROOT/.agents/skills/setup-ai-build-kit/scripts/place-trim-check.py"
founded="$WORK/founded-checks.yml"
cp "$PROJECT/.github/workflows/checks.yml" "$founded"
awk '
  /- name: Check tests were not changed silently/ { skip = 2 }
  skip > 0 { skip--; next }
  /^ *with:$/ || /^ *fetch-depth: 0$/ { next }
  { print }
' "$founded" > "$PROJECT/.github/workflows/checks.yml"
rm "$PROJECT/.agents/hooks/check-tests.sh"
grep -q 'check-tests\|fetch-depth' "$PROJECT/.github/workflows/checks.yml" && fail "the older check still has the test check"
in_project checkout -q -b older origin/main
save_as_base "An older founding"

place() { (cd "$PROJECT" && python3 "$PLACE" "$@") > "$WORK/place-output" 2>&1; }
status=0; place || status=$?
[ "$status" = 1 ] || fail "an older project's missing test check was not found (exit $status)"
for kind in hook step history; do
  grep -q "^$kind	" "$WORK/place-output" || fail "place-trim-check.py did not name the missing $kind"
done
[ -z "$(cd "$PROJECT" && git status --porcelain)" ] || fail "place-trim-check.py changed the project while only looking"
echo "  ok: an older project's check is found to lack the hook, the step and the history, and nothing changes"

status=0; place --decline || status=$?
[ "$status" = 0 ] || fail "recording a no failed"
status=0; place || status=$?
[ "$status" = 0 ] && grep -qx 'declined' "$WORK/place-output" || fail "a no was not kept (exit $status)"
grep -q '^tests-check-declined|' "$PROJECT/.ai-build-kit-maintenance" || fail "the no was not recorded"
rm "$PROJECT/.ai-build-kit-maintenance"
echo "  ok: a no is recorded, and the offer is not made again while the kit's hook is the same"

status=0; place --apply || status=$?
[ "$status" = 0 ] || { cat "$WORK/place-output" >&2; fail "adding the test check failed"; }
cmp -s "$TEST_CHECK" "$PROJECT/.agents/hooks/check-tests.sh" || fail "the hook was not added"
grep -q 'fetch-depth: 0' "$PROJECT/.github/workflows/checks.yml" || fail "the workflow still does not fetch full history"
grep -q 'sh .agents/hooks/check-tests.sh' "$PROJECT/.github/workflows/checks.yml" || fail "the test-check step was not added"
grep -q 'Detect the selected recipe' "$PROJECT/.github/workflows/checks.yml" || fail "the recipe check was lost"
grep -q 'sh .agents/hooks/check-review.sh' "$PROJECT/.github/workflows/checks.yml" || fail "the review check was lost"
status=0; place || status=$?
[ "$status" = 0 ] && [ ! -s "$WORK/place-output" ] || fail "a second look still found something missing (exit $status)"
echo "  ok: on a yes, the hook, the step and full history are added, with the rest of the workflow kept"

save_as_base "The test check added"
sed 's/total(2, 3), 6/total(3, 2), 6/' "$PROJECT/test_pricing.py" > "$WORK/test"
mv "$WORK/test" "$PROJECT/test_pricing.py"
in_project commit -q -am "Trim: take out what the piece did not need"
first=$(run_check)
[ "$first" = "Check tests were not changed silently" ] ||
  fail "after the step was added, a trim that changed a test did not turn the check red, got '${first:-nothing}'"
echo "  ok: once added, the older project's check goes red on a trim that changed a test"

# --- the same again for TypeScript -------------------------------------------
#
# The web app recipes build with Next.js in TypeScript, so the TypeScript row is
# rehearsed the same way. This founds a small TypeScript project from the same
# template and takes its commands from the table. It does not run the Next.js
# starter: that would download the whole framework, and a project the starter
# made would use the starter's own lint settings, which the reference says to
# keep as they stand. The table's row is what founding writes when there are
# none, so that is the half worth watching go red.
#
# The tools install into the throwaway project, as a founded project's own
# dependencies. The tests run through tsx, which strips the types without
# checking them, so as with Python the tests pass and the type check is what
# turns the tick red.

echo
echo "TypeScript:"
command -v npm >/dev/null 2>&1 || fail "npm is needed to rehearse the TypeScript row"

row=$(grep '^| TypeScript |' "$FLOOR") || fail "check-floor.md has no TypeScript row"
type_check=$(printf '%s\n' "$row" | awk -F'|' '{print $3}' | sed -n 's/^[^`]*`\([^`]*\)`.*/\1/p')
lint=$(printf '%s\n' "$row" | awk -F'|' '{print $4}' | sed -n 's/^[^`]*`\([^`]*\)`.*/\1/p')
[ -n "$type_check" ] || fail "the TypeScript row names no type check command"
[ -n "$lint" ] || fail "the TypeScript row names no lint command"
printf '%s\n' "$row" | grep -q "ESLint's own recommended rules and typescript-eslint's recommended rules" ||
  fail "the TypeScript row no longer says which lint rules it starts from"
echo "  type check: $type_check"
echo "  lint: $lint"

# Rehearse the command's decision with npx as a stand-in. A plain TypeScript
# project must reach tsc without calling Next, while a Next project runs both.
NO_NEXT="$WORK/no-next"
mkdir -p "$NO_NEXT/bin" "$NO_NEXT/project"
cat > "$NO_NEXT/project/package.json" <<'JSON'
{"devDependencies":{"typescript":"5"}}
JSON
cat > "$NO_NEXT/bin/npx" <<'SH'
#!/usr/bin/env sh
printf '%s\n' "$*" >> "$NPX_LOG"
SH
chmod +x "$NO_NEXT/bin/npx"
(
  cd "$NO_NEXT/project"
  NPX_LOG="$NO_NEXT/calls" PATH="$NO_NEXT/bin:$PATH" sh -c "$type_check"
) ||
  fail "the plain TypeScript type check did not pass"
grep -q '^tsc --noEmit$' "$NO_NEXT/calls" || fail "tsc did not run for plain TypeScript"
if grep -q 'next typegen' "$NO_NEXT/calls"; then fail "Next typegen ran without Next in package.json"; fi
cat > "$NO_NEXT/project/package.json" <<'JSON'
{"devDependencies":{"typescript":"5","next":"15"}}
JSON
: > "$NO_NEXT/calls"
(
  cd "$NO_NEXT/project"
  NPX_LOG="$NO_NEXT/calls" PATH="$NO_NEXT/bin:$PATH" sh -c "$type_check"
) ||
  fail "the Next type check did not pass"
grep -q '^next typegen$' "$NO_NEXT/calls" && grep -q '^tsc --noEmit$' "$NO_NEXT/calls" ||
  fail "Next project did not run route generation and tsc"
echo "  ok: the TypeScript command runs Next typegen only when Next is a dependency"

# Keep an actual Next app beside the command-shape check. Install it when the
# network is available, and name the limit only when npm cannot reach it.
NEXT="$WORK/next-project"
mkdir -p "$NEXT/app"
cat > "$NEXT/package.json" <<'JSON'
{"private":true,"scripts":{"typecheck":"next typegen && tsc --noEmit"},"dependencies":{"next":"15.5.0","react":"19.1.0","react-dom":"19.1.0"},"devDependencies":{"@types/node":"22.15.30","@types/react":"19.1.6","typescript":"5.8.3"}}
JSON
cat > "$NEXT/tsconfig.json" <<'JSON'
{"compilerOptions":{"target":"ES2017","lib":["dom","dom.iterable","esnext"],"allowJs":true,"skipLibCheck":true,"strict":true,"noEmit":true,"esModuleInterop":true,"module":"esnext","moduleResolution":"bundler","resolveJsonModule":true,"isolatedModules":true,"jsx":"preserve","incremental":true,"plugins":[{"name":"next"}],"paths":{"@/*":["./*"]}},"include":["next-env.d.ts",".next/types/**/*.ts","**/*.ts","**/*.tsx"],"exclude":["node_modules"]}
JSON
cat > "$NEXT/app/page.tsx" <<'TS'
export default function Page() { return <main>Next type generation ran.</main>; }
TS
if (cd "$NEXT" && npm install --no-audit --no-fund --silent); then
  (cd "$NEXT" && npx --no-install next typegen && npx --no-install tsc --noEmit) ||
    fail "the actual Next.js project's typegen and TypeScript check did not pass"
  echo "  ok: next typegen and tsc ran on an actual Next.js project"
else
  if npm ping --silent --fetch-retries=0 --fetch-timeout=10000 >/dev/null 2>&1; then
    fail "npm could reach the network, but the actual Next.js packages did not install"
  fi
  echo "  could not run: npm could not reach its package registry"
  exit 2
fi

PROJECT="$WORK/ts-project"
mkdir -p "$PROJECT/.github/workflows" "$PROJECT/.agents/hooks" "$PROJECT/src"
cp "$SENSITIVE" "$PROJECT/.agents/hooks/check-sensitive-areas.sh"
cp "$SCAN" "$PROJECT/.agents/hooks/scan-secrets.sh"
cp "$SCAN_PY" "$PROJECT/.agents/hooks/scan-secrets.py"
cp "$TEST_CHECK" "$PROJECT/.agents/hooks/check-tests.sh"
bootstrap_review_reader "$PROJECT"
cp "$REVIEW_CHECK" "$PROJECT/.agents/hooks/check-review.sh"

awk -v tc="$type_check" -v li="$lint" '
  /- name: Install and test/ { skipping = 1 }
  skipping { next }
  { print }
  END {
    print "      - name: Install"
    print "        run: npm install"
    print "      - name: Type check"
    print "        run: " tc
    print "      - name: Lint"
    print "        run: " li
    print "      - name: Test"
    print "        run: npx tsx --test src/pricing.test.ts"
  }
' "$TEMPLATE" > "$PROJECT/.github/workflows/checks.yml"
grep -q 'placeholder' "$PROJECT/.github/workflows/checks.yml" &&
  fail "the placeholder step survived the edit"

cat > "$PROJECT/package.json" <<'JSON'
{
  "name": "rehearsal",
  "private": true,
  "type": "module",
  "devDependencies": {
    "@eslint/js": "^9",
    "@types/node": "^22",
    "eslint": "^9",
    "tsx": "^4",
    "typescript": "^5",
    "typescript-eslint": "^8"
  }
}
JSON

cat > "$PROJECT/tsconfig.json" <<'JSON'
{
  "compilerOptions": {
    "strict": true,
    "noEmit": true,
    "jsx": "preserve",
    "module": "nodenext",
    "target": "es2022",
    "skipLibCheck": true
  },
  "include": ["src"]
}
JSON

# ESLint's own recommended rules and typescript-eslint's, and nothing else.
cat > "$PROJECT/eslint.config.mjs" <<'JS'
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default [js.configs.recommended, ...tseslint.configs.recommended];
JS

cat > "$PROJECT/src/pricing.ts" <<'TS'
export function total(price: number, count: number): number {
  return price * count;
}
TS

cat > "$PROJECT/src/pricing.test.ts" <<'TS'
import { test } from "node:test";
import assert from "node:assert/strict";

import { total } from "./pricing.js";

test("total", () => {
  assert.equal(total(2, 3), 6);
});
TS

# Rehearse the recipe's schema-derived type output before the JavaScript tools
# are installed, so this check still runs in an offline environment.
RECIPE="$ROOT/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/recipe.md"
db_check=$(sed -n 's/^Database types check: `\(.*\)`$/\1/p' "$RECIPE")
[ -n "$db_check" ] || fail "the database types check command could not be read"
DB="$WORK/database"
DB_BIN="$WORK/database-bin"
mkdir -p "$DB/supabase/migrations" "$DB/types" "$DB_BIN"
cat > "$DB_BIN/supabase" <<'PY'
#!/usr/bin/env python3
import os, pathlib, re, sys
if sys.argv[1:] == ["status"]:
    raise SystemExit(1 if os.environ.get("SUPABASE_DOWN") else 0)
if sys.argv[1:] != ["gen", "types", "typescript", "--local"]:
    raise SystemExit(2)
if os.environ.get("SUPABASE_GEN_FAIL"):
    raise SystemExit(1)
tables = sorted({name for file in pathlib.Path("supabase/migrations").glob("*.sql")
                 for name in re.findall(r"create\s+table\s+(?:public\.)?(\w+)", file.read_text(), re.I)})
print("export type LocalDatabase = " + " | ".join(repr(name) for name in tables) + ";")
PY
chmod +x "$DB_BIN/supabase"
printf '%s\n' 'create table public.items (id integer primary key);' > "$DB/supabase/migrations/001_items.sql"
(cd "$DB" && PATH="$DB_BIN:$PATH" supabase gen types typescript --local > types/database.ts)
git -C "$DB" init -q -b main
git -C "$DB" -c user.name=Rehearsal -c user.email=rehearsal@example.invalid add .
git -C "$DB" -c user.name=Rehearsal -c user.email=rehearsal@example.invalid commit -qm Start
(cd "$DB" && PATH="$DB_BIN:$PATH" sh -c "$db_check") ||
  fail "matching generated database types did not pass"
echo "  ok: generated database types pass when they match the schema"
printf '%s\n' 'create table public.rota (id integer primary key);' >> "$DB/supabase/migrations/001_items.sql"
status=0
(cd "$DB" && PATH="$DB_BIN:$PATH" sh -c "$db_check") > "$WORK/database-drift.out" 2>&1 || status=$?
[ "$status" -eq 1 ] || fail "database type drift returned $status"
echo "  ok: generated database types fail when a migration changes the schema"
mv "$DB/types/database.ts" "$DB/types/database.saved"
status=0
(cd "$DB" && PATH="$DB_BIN:$PATH" sh -c "$db_check") > "$WORK/database-missing.out" 2>&1 || status=$?
[ "$status" -eq 2 ] && grep -q 'could not run' "$WORK/database-missing.out" || fail "missing database types did not report could not run"
mv "$DB/types/database.saved" "$DB/types/database.ts"
git -C "$DB" rm --cached -q types/database.ts
status=0
(cd "$DB" && PATH="$DB_BIN:$PATH" sh -c "$db_check") > "$WORK/database-untracked.out" 2>&1 || status=$?
[ "$status" -eq 2 ] && grep -q 'could not run' "$WORK/database-untracked.out" || fail "untracked database types did not report could not run"
echo "  ok: missing or untracked database types report could not run without overwriting the file"
status=0
(cd "$DB" && PATH="$DB_BIN:$PATH" SUPABASE_DOWN=1 sh -c "$db_check") > "$WORK/database-stopped.out" 2>&1 || status=$?
[ "$status" -eq 2 ] && grep -q 'could not run' "$WORK/database-stopped.out" || fail "a stopped local database did not report could not run"
cp "$DB/types/database.ts" "$WORK/database-before-failed-generation"
status=0
(cd "$DB" && PATH="$DB_BIN:$PATH" SUPABASE_GEN_FAIL=1 sh -c "$db_check") > "$WORK/database-generation-failed.out" 2>&1 || status=$?
[ "$status" -eq 2 ] && cmp -s "$WORK/database-before-failed-generation" "$DB/types/database.ts" ||
  fail "failed database type generation changed the tracked types file"
echo "  ok: a stopped database or failed generation reports could not run and keeps the types file intact"

echo "  installing the project's own check tools"
if ! (cd "$PROJECT" && npm install --no-audit --no-fund --silent); then
  echo "  could not run: TypeScript check tools could not be installed"
  echo "check-floor-rehearsal.sh: Python and check-shape cases passed; TypeScript runtime cases could not run"
  exit 2
fi

in_project init -q -b main
printf 'node_modules/\n' > "$PROJECT/.gitignore"
cat > "$PROJECT/masterplan.md" <<'MD'
Path: Build with care

Sensitive areas:
  Data:
    paths: src
    Accepted: yes, 2026-10-14
MD
in_project add -A -f -- masterplan.md
save_as_base "Start"

started=$(date +%s)
first=$(run_check)
finished=$(date +%s)
[ -z "$first" ] || { cat "$WORK/last-output" >&2; fail "the new TypeScript project's check was red on day one, at $first"; }
echo "  ok: the founded TypeScript project's check is green on day one ($((finished - started))s)"

# A type error in code no test reaches. It is exported, so the linter has no
# reason to object and only the type check can see it.
cat >> "$PROJECT/src/pricing.ts" <<'TS'

export function describe(count: number): string {
  return count;
}
TS

(cd "$PROJECT" && npx tsx --test src/pricing.test.ts) > "$WORK/tests-only" 2>&1 ||
  { cat "$WORK/tests-only" >&2; fail "the TypeScript tests should still pass with the type error in place"; }
echo "  ok: the tests alone still pass with the type error in place"

first=$(run_check)
[ "$first" = "Type check" ] || fail "expected the TypeScript Type check step to go red, got '${first:-nothing}'"
grep -q 'pricing.ts' "$WORK/last-output" || fail "the TypeScript type check did not name the file"
echo "  ok: the check goes red at Type check, naming pricing.ts"

sed 's/  return count;/  return String(count);/' "$PROJECT/src/pricing.ts" > "$WORK/fixed"
mv "$WORK/fixed" "$PROJECT/src/pricing.ts"
first=$(run_check)
[ -z "$first" ] || { cat "$WORK/last-output" >&2; fail "the TypeScript check stayed red after the fix, at $first"; }
echo "  ok: the check goes green once the type error is fixed"

printf 'import { readFileSync } from "node:fs";\n%s\n' "$(cat "$PROJECT/src/pricing.ts")" > "$WORK/linted"
mv "$WORK/linted" "$PROJECT/src/pricing.ts"
first=$(run_check)
[ "$first" = "Lint" ] || { cat "$WORK/last-output" >&2; fail "expected the TypeScript Lint step to go red, got '${first:-nothing}'"; }
echo "  ok: the check goes red at Lint on an unused import"

echo
echo "check-floor-rehearsal.sh: red on a type error, green once fixed, in Python and TypeScript"
