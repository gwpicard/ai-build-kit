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

# Staged bytes differ from the working file before the review.
printf 'The person staged this version.\n' > app.txt
git add app.txt
printf 'The person kept a later working version.\n' > app.txt
cp app.txt "$WORK/partial-working"
git show :app.txt > "$WORK/partial-staged"
git ls-files -s > "$WORK/index-before"
git status --porcelain > "$WORK/status-before"
[ "$(git status --porcelain -- app.txt)" = 'MM app.txt' ] || fail "fixture is not partially staged"
guard snapshot masterplan.md >/dev/null
printf 'Reviewer overwrite and stage.\n' > app.txt
git add app.txt
printf 'Reviewer overwrite and stage.\n' > 'staged notes.txt'
git add 'staged notes.txt' 'untracked notes.txt'
out=$(guard check) && rc=0 || rc=$?
git show :app.txt > "$WORK/partial-after"
git ls-files -s > "$WORK/index-after"
git status --porcelain > "$WORK/status-after"
if [ "$rc" -eq 1 ] && cmp -s app.txt "$WORK/partial-working" \
  && cmp -s "$WORK/partial-staged" "$WORK/partial-after" \
  && cmp -s "$WORK/index-before" "$WORK/index-after" \
  && cmp -s "$WORK/status-before" "$WORK/status-after" \
  && printf '%s\n' "$out" | grep -qx 'restored	app.txt'; then
  pass "a partially staged file and other staged entries regain their working bytes, index and status"
else
  fail "staged work was lost or falsely reported as restored: exit $rc: $out"
fi

guard snapshot masterplan.md >/dev/null
git add app.txt
out=$(guard check) && rc=0 || rc=$?
git ls-files -s > "$WORK/index-after"
[ "$rc" -eq 1 ] && cmp -s "$WORK/index-before" "$WORK/index-after" \
  && cmp -s app.txt "$WORK/partial-working" \
  && printf '%s\n' "$out" | grep -qx 'restored	app.txt' \
  && pass "an index-only reviewer change is restored while working bytes stay intact" \
  || fail "an index-only change gave exit $rc: $out"

# A pre-existing deletion must remain absent in both the working tree and index.
rm app.txt
git add app.txt
guard snapshot masterplan.md >/dev/null
printf 'Reviewer recreated and staged this.\n' > app.txt
git add app.txt
out=$(guard check) && rc=0 || rc=$?
[ "$rc" -eq 1 ] && [ ! -e app.txt ] && [ -z "$(git ls-files -s -- app.txt)" ] \
  && printf '%s\n' "$out" | grep -qx 'restored	app.txt' \
  && pass "a staged deletion remains absent after the reviewer recreates and stages it" \
  || fail "a staged deletion gave exit $rc: $out"

# A symlink to a directory is compared by target, without reading its contents.
mkdir target-directory
printf 'Target content.\n' > target-directory/note.txt
ln -s target-directory directory-link
guard snapshot masterplan.md >/dev/null
out=$(guard check) && rc=0 || rc=$?
[ "$rc" -eq 0 ] && [ -z "$out" ] && [ "$(readlink directory-link)" = target-directory ] \
  && pass "an unchanged untracked directory symlink is not reported as a reviewer change" \
  || fail "an unchanged directory symlink gave exit $rc: $out"
guard snapshot masterplan.md >/dev/null
rm directory-link
ln -s missing-directory directory-link
git add directory-link
out=$(guard check) && rc=0 || rc=$?
[ "$rc" -eq 1 ] && [ "$(readlink directory-link)" = target-directory ] \
  && [ -z "$(git ls-files -s -- directory-link)" ] \
  && printf '%s\n' "$out" | grep -qx 'restored	directory-link' \
  && pass "a changed symlink target and its staged entry are restored" \
  || fail "a changed directory symlink gave exit $rc: $out"

guard snapshot target-directory >/dev/null
out=$(guard check) && rc=0 || rc=$?
[ "$rc" -eq 0 ] && [ "$out" = 'skipped	target-directory	directory' ] \
  && pass "an unchanged directory is skipped with a note" \
  || fail "a directory gave exit $rc: $out"

# A gitlink is a submodule even when no checkout is present.
git update-index --add --cacheinfo "160000,$(git rev-parse HEAD),module"
guard snapshot masterplan.md >/dev/null
out=$(guard check) && rc=0 || rc=$?
[ "$rc" -eq 0 ] && [ "$out" = 'skipped	module	submodule' ] \
  && pass "an unchanged submodule is skipped with a note" \
  || fail "a submodule gave exit $rc: $out"

out=$(guard check 2>&1) && rc=0 || rc=$?
[ "$rc" -eq 2 ] && pass "a check with no snapshot exits 2" || fail "a check with no snapshot gave exit $rc"
guard snapshot >/dev/null 2>&1 && rc=0 || rc=$?
[ "$rc" -eq 2 ] && pass "a snapshot naming no file exits 2" || fail "an empty snapshot gave exit $rc"
guard snapshot ../outside.md >/dev/null 2>&1 && rc=0 || rc=$?
[ "$rc" -eq 2 ] && pass "a file outside the project is refused" || fail "a file outside the project gave exit $rc"

exit "$FAIL"
