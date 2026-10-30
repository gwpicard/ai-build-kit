#!/usr/bin/env sh
# review-guard.sh: run the second-opinion skill's review-guard.sh around a
# stand-in review and prove it puts back a changed draft and names other changes.
#
# If this breaks, a reviewer that edits the masterplan it was asked to read
# changes the person's unsaved draft at founding, and nobody is told.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
GUARD="$ROOT/.agents/skills/second-opinion/scripts/review-guard.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "ok: $1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

P="$WORK/project"
mkdir -p "$P/.agents/tmp"
cd "$P"
git init -q
git config user.email test@example.invalid
git config user.name Test
printf '%s\n' '.agents/tmp/' > .gitignore
printf 'start\n' > app.txt
git add . && git commit -qm start
printf '# Masterplan\nThe draft, not saved yet.\n' > masterplan.md
cp masterplan.md "$WORK/draft"

guard() { sh "$GUARD" "$@"; }

guard snapshot masterplan.md >/dev/null && rc=0 || rc=$?
[ "$rc" -eq 0 ] && pass "a snapshot of the draft is kept" || fail "snapshot exited $rc"
out=$(guard check) && rc=0 || rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] && pass "a review that changes nothing exits 0 and says nothing" \
  || fail "an untouched review gave exit $rc: $out"

guard snapshot masterplan.md >/dev/null
printf 'The reviewer filled the gaps itself.\n' >> masterplan.md
out=$(guard check) && rc=0 || rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -qx 'restored	masterplan.md' && cmp -s masterplan.md "$WORK/draft"; then
  pass "a review that edits the draft exits 1, and the draft is put back word for word"
else
  fail "an edited draft gave exit $rc and '$out'"
fi

guard snapshot masterplan.md >/dev/null
rm masterplan.md
out=$(guard check) && rc=0 || rc=$?
[ "$rc" -eq 1 ] && cmp -s masterplan.md "$WORK/draft" \
  && pass "a draft the review deleted is put back" || fail "a deleted draft gave exit $rc and '$out'"

guard snapshot masterplan.md >/dev/null
printf 'changed by the review\n' > app.txt
printf 'new\n' > stray.txt
out=$(guard check) && rc=0 || rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q '^changed	 M app.txt$' \
  && printf '%s\n' "$out" | grep -q '^changed	?? stray.txt$' && [ -f stray.txt ]; then
  pass "a change outside the files under review is named and left for the person"
else
  fail "a change outside the draft gave exit $rc and '$out'"
fi
git checkout -q -- app.txt
rm -f stray.txt

# Existing edits outside the branch diff keep the same Git status when a
# reviewer overwrites them. Compare their bytes, including untracked work.
printf 'The person changed this.\n' > app.txt
printf 'The person staged this.\n' > 'staged notes.txt'
git add 'staged notes.txt'
printf 'The person has not saved this.\n' > 'untracked notes.txt'
cp app.txt "$WORK/person-app"
cp 'staged notes.txt' "$WORK/person-staged"
cp 'untracked notes.txt' "$WORK/person-untracked"
guard snapshot masterplan.md >/dev/null
printf 'Reviewer overwrite.\n' > app.txt
printf 'Reviewer overwrite.\n' > 'staged notes.txt'
rm 'untracked notes.txt'
out=$(guard check) && rc=0 || rc=$?
if [ "$rc" -eq 1 ] && cmp -s app.txt "$WORK/person-app" \
  && cmp -s 'staged notes.txt' "$WORK/person-staged" \
  && cmp -s 'untracked notes.txt' "$WORK/person-untracked" \
  && printf '%s\n' "$out" | grep -qx 'restored	app.txt' \
  && printf '%s\n' "$out" | grep -qx 'restored	staged notes.txt' \
  && printf '%s\n' "$out" | grep -qx 'restored	untracked notes.txt'; then
  pass "modified, staged and untracked work outside the review is restored and named"
else
  fail "pre-existing work was lost or unreported: exit $rc: $out"
fi

out=$(guard check 2>&1) && rc=0 || rc=$?
[ "$rc" -eq 2 ] && pass "a check with no snapshot exits 2" || fail "a check with no snapshot gave exit $rc"
guard snapshot >/dev/null 2>&1 && rc=0 || rc=$?
[ "$rc" -eq 2 ] && pass "a snapshot naming no file exits 2" || fail "an empty snapshot gave exit $rc"
guard snapshot ../outside.md >/dev/null 2>&1 && rc=0 || rc=$?
[ "$rc" -eq 2 ] && pass "a file outside the project is refused" || fail "a file outside the project gave exit $rc"

exit "$FAIL"
