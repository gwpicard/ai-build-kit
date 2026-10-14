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
# The trim step goes red on a trim commit that changed a test, and also when it
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

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
FLOOR="$ROOT/.agents/skills/quality-checks/references/check-floor.md"
TEMPLATE="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml"
SENSITIVE="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh"
TRIM_CHECK="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-trim.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PROJECT="$WORK/project"
mkdir -p "$PROJECT/.github/workflows" "$PROJECT/.agents/hooks"

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
cp "$TRIM_CHECK" "$PROJECT/.agents/hooks/check-trim.sh"

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

# --- running the check the way the hosted runner would ----------------------

# Prints the name of the first step that failed, or nothing when all passed.
# The Install step is left to the rehearsal, which already provided the tools.
run_check() {
  awk '
    /^ *- name: / { sub(/^ *- name: /, ""); name = $0; next }
    /^ *run: /    { sub(/^ *run: /, ""); print name "\t" $0 }
  ' "$PROJECT/.github/workflows/checks.yml" > "$WORK/steps"
  tab=$(printf '\t')
  while IFS="$tab" read -r step command; do
    [ "$step" = "Install" ] && continue
    if ! (cd "$PROJECT" && sh -c "$command") > "$WORK/last-output" 2>&1; then
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

# The trim step fails when it cannot read the pull request's commits, since a
# trim it never read is not a trim it checked. It said "passed" once.
mkdir -p "$WORK/no-history"
status=0
(cd "$WORK/no-history" && sh "$TRIM_CHECK") > "$WORK/last-output" 2>&1 || status=$?
[ "$status" != 0 ] || fail "the trim step passed with no history to read"
grep -q 'could not be read' "$WORK/last-output" || fail "the trim step did not say it could not read the commits"
echo "  ok: the trim step goes red, and says why, when it cannot read the commits"

in_project init -q -b main
printf '__pycache__/\n.mypy_cache/\n.ruff_cache/\n' > "$PROJECT/.gitignore"
in_project add -A
in_project commit -q -m "Start"
status=0
(cd "$PROJECT" && sh .agents/hooks/check-trim.sh) > "$WORK/last-output" 2>&1 || status=$?
[ "$status" != 0 ] || fail "the trim step passed with no base branch to compare with"
echo "  ok: the trim step goes red when the history holds no base branch, as a shallow checkout leaves it"
in_project update-ref refs/remotes/origin/main HEAD

started=$(date +%s)
first=$(run_check)
finished=$(date +%s)
[ -z "$first" ] || { cat "$WORK/last-output" >&2; fail "the new project's check was red on day one, at $first"; }
echo "  ok: the founded project's check is green on day one ($((finished - started))s)"

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
save_as_base "The checked code"
first=$(run_check)
[ -z "$first" ] || { cat "$WORK/last-output" >&2; fail "the check was red before the trim, at $first"; }
sed 's/total(2, 3), 6/total(1, 6), 6/' "$PROJECT/test_pricing.py" > "$WORK/test"
mv "$WORK/test" "$PROJECT/test_pricing.py"
in_project commit -q -am "Trim: take out what the piece did not need"
first=$(run_check)
[ "$first" = "Check the trim left the tests alone" ] ||
  fail "expected the trim step to go red on a trim that changed a test, got '${first:-nothing}'"
grep -q 'test_pricing.py' "$WORK/last-output" || fail "the trim step did not name the test"
echo "  ok: the check goes red at the trim step when a trim commit changed a test, naming it"

# --- a project founded before the trim step ----------------------------------
#
# The same project as an older founding left it: no hook, no trim step, and a
# checkout of the last commit only. /maintain's truing runs place-trim-check.py,
# which finds all three, records a no, and on a yes puts back exactly what
# founding writes today.

PLACE="$ROOT/.agents/skills/setup-ai-build-kit/scripts/place-trim-check.py"
founded="$WORK/founded-checks.yml"
cp "$PROJECT/.github/workflows/checks.yml" "$founded"
awk '
  /- name: Check the trim left the tests alone/ { skip = 2 }
  skip > 0 { skip--; next }
  /^ *with:$/ || /^ *fetch-depth: 0$/ { next }
  { print }
' "$founded" > "$PROJECT/.github/workflows/checks.yml"
rm "$PROJECT/.agents/hooks/check-trim.sh"
grep -q 'check-trim\|fetch-depth' "$PROJECT/.github/workflows/checks.yml" && fail "the older check still has the trim step"
in_project checkout -q -b older origin/main
save_as_base "An older founding"

place() { (cd "$PROJECT" && python3 "$PLACE" "$@") > "$WORK/place-output" 2>&1; }
status=0; place || status=$?
[ "$status" = 1 ] || fail "an older project's missing trim step was not found (exit $status)"
for kind in hook step history; do
  grep -q "^$kind	" "$WORK/place-output" || fail "place-trim-check.py did not name the missing $kind"
done
[ -z "$(cd "$PROJECT" && git status --porcelain)" ] || fail "place-trim-check.py changed the project while only looking"
echo "  ok: an older project's check is found to lack the hook, the step and the history, and nothing changes"

status=0; place --decline || status=$?
[ "$status" = 0 ] || fail "recording a no failed"
status=0; place || status=$?
[ "$status" = 0 ] && grep -qx 'declined' "$WORK/place-output" || fail "a no was not kept (exit $status)"
grep -q '^trim-check-declined|' "$PROJECT/.ai-build-kit-maintenance" || fail "the no was not recorded"
rm "$PROJECT/.ai-build-kit-maintenance"
echo "  ok: a no is recorded, and the offer is not made again while the kit's hook is the same"

status=0; place --apply || status=$?
[ "$status" = 0 ] || { cat "$WORK/place-output" >&2; fail "adding the trim step failed"; }
cmp -s "$founded" "$PROJECT/.github/workflows/checks.yml" ||
  { diff "$founded" "$PROJECT/.github/workflows/checks.yml" >&2; fail "the check is not what founding writes today"; }
cmp -s "$TRIM_CHECK" "$PROJECT/.agents/hooks/check-trim.sh" || fail "the hook was not added"
status=0; place || status=$?
[ "$status" = 0 ] && [ ! -s "$WORK/place-output" ] || fail "a second look still found something missing (exit $status)"
echo "  ok: on a yes, the hook, the step and the whole history are added, matching a founding today, and nothing else"

save_as_base "The trim step added"
sed 's/total(2, 3), 6/total(3, 2), 6/' "$PROJECT/test_pricing.py" > "$WORK/test"
mv "$WORK/test" "$PROJECT/test_pricing.py"
in_project commit -q -am "Trim: take out what the piece did not need"
first=$(run_check)
[ "$first" = "Check the trim left the tests alone" ] ||
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

PROJECT="$WORK/ts-project"
mkdir -p "$PROJECT/.github/workflows" "$PROJECT/.agents/hooks" "$PROJECT/src"
cp "$SENSITIVE" "$PROJECT/.agents/hooks/check-sensitive-areas.sh"
cp "$TRIM_CHECK" "$PROJECT/.agents/hooks/check-trim.sh"

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

echo "  installing the project's own check tools"
(cd "$PROJECT" && npm install --no-audit --no-fund --silent) ||
  fail "could not install the TypeScript check tools, so the check could not be rehearsed"

in_project init -q -b main
printf 'node_modules/\n' > "$PROJECT/.gitignore"
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
