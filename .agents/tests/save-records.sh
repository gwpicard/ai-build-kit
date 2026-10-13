#!/usr/bin/env sh
# save-records.sh: run section-builder's save-records.sh in a throwaway
# project.
#
# If this breaks, a records commit sweeps up the person's own unsaved work, or
# leaves it out of the commit by throwing it away. Either loses work the
# person never agreed to give up, and the commit looks normal.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/section-builder/scripts/save-records.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "ok: $1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
P="$WORK/project"
mkdir -p "$P/app"
git -C "$P" init -q
git -C "$P" config user.name Rehearsal
git -C "$P" config user.email rehearsal@example.invalid
git -C "$P" config commit.gpgsign false
printf 'old\n' > "$P/CHANGELOG.md"
printf 'plan\n' > "$P/masterplan.md"
printf 'code\n' > "$P/app/page.js"
git -C "$P" add -A
git -C "$P" commit -q -m first

run() { (cd "$P" && sh "$SCRIPT" "$@"); }

# The person's own work: an edit, a new file, and something staged.
printf 'code, half changed\n' > "$P/app/page.js"
printf 'notes\n' > "$P/app/notes.txt"
printf 'new line\n' >> "$P/CHANGELOG.md"

out=$(run "Record the launch" CHANGELOG.md) && code=0 || code=$?
committed=$(git -C "$P" show --name-only --format= HEAD)
[ "$code" -eq 0 ] && [ "$committed" = "CHANGELOG.md" ] \
  && pass "only the named record is in the new commit" \
  || fail "the commit held '$committed', exit $code: $out"
[ "$(cat "$P/app/page.js")" = "code, half changed" ] && [ -f "$P/app/notes.txt" ] \
  && git -C "$P" status --porcelain | grep -q '^ M app/page.js' \
  && pass "the person's unsaved edit and new file are left exactly as they were" \
  || fail "the person's work was moved or lost"

before=$(git -C "$P" rev-parse HEAD)
git -C "$P" add app/page.js
printf 'second\n' >> "$P/masterplan.md"
out=$(run "Record the truing" masterplan.md) && code=0 || code=$?
[ "$code" -eq 1 ] && [ "$(git -C "$P" rev-parse HEAD)" = "$before" ] && printf '%s' "$out" | grep -q 'app/page.js' \
  && pass "something else already staged stops the save and is named" \
  || fail "a save went ahead over another staged file, exit $code: $out"
git -C "$P" diff --cached --name-only | grep -qx 'app/page.js' \
  && pass "the refused save leaves the staged file staged" \
  || fail "the refused save changed what was staged"
git -C "$P" restore --staged app/page.js

out=$(run "Record nothing" CHANGELOG.md) && code=0 || code=$?
[ "$code" -eq 1 ] && [ "$(git -C "$P" rev-parse HEAD)" = "$before" ] \
  && pass "a named record with no change makes no commit" \
  || fail "an empty save returned $code"

out=$(run "Escape" ../outside.md) && code=0 || code=$?
[ "$code" -eq 1 ] && pass "a path outside the project is refused" || fail "a path outside the project returned $code"

out=$(cd "$P/app" && sh "$SCRIPT" "Wrong place" ../masterplan.md 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "running it away from the project root is refused" || fail "running from a subfolder returned $code"

mkdir -p "$P/docs"
for sweep in . ./ docs/.. app/.. ':/' ':(top)' ':(top)app' '*' '*.md' app 'app/*' .git/config; do
  printf 'more\n' >> "$P/masterplan.md"
  before=$(git -C "$P" rev-parse HEAD)
  out=$(run "Sweep" "$sweep") && code=0 || code=$?
  if [ "$code" -eq 1 ] && [ "$(git -C "$P" rev-parse HEAD)" = "$before" ] \
     && [ -z "$(git -C "$P" diff --cached --name-only)" ]; then
    pass "the path '$sweep' is refused, and nothing is staged or saved"
  else
    fail "the path '$sweep' returned $code and saved $(git -C "$P" show --name-only --format= HEAD | tr '\n' ' '): $out"
    git -C "$P" reset -q --soft "$before"
    git -C "$P" reset -q
  fi
done
git -C "$P" status --porcelain | grep -q '^ M app/page.js' \
  && pass "after every refused path the person's edit is still unsaved" \
  || fail "the person's edit was swept up"

out=$(run "Two records" masterplan.md CHANGELOG.md) && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(git -C "$P" show --name-only --format= HEAD)" = "masterplan.md" ] \
  && pass "several named paths commit together, and an unchanged one is fine" \
  || fail "two records returned $code: $out"

[ "$FAIL" -eq 0 ] || exit 1
echo "save-records.sh: all checks passed"
