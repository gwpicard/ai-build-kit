#!/usr/bin/env sh
# found-save.sh: run the founding save in throwaway projects.
#
# If this breaks, founding reports a checkpoint that was never made, saves
# under somebody else's name copied from an old commit, or leaves the
# masterplan's mark unusable so every later build finds nothing to move on.
# A real founding did the last one by writing its own words on the mark line.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SKILL="$ROOT/.agents/skills/setup-ai-build-kit"
SCRIPT="$SKILL/scripts/found-save.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "ok: $1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
# No save name anywhere but where a case puts one.
export HOME="$WORK/home" GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL || true

new_project() {
  p="$WORK/$1"
  mkdir -p "$p/.agents/hooks/git"
  cp "$SKILL/templates/masterplan.md" "$p/masterplan.md"
  cp "$SKILL/templates/foundation/pre-push" "$p/.agents/hooks/git/pre-push"
  printf 'hello\n' > "$p/index.html"
  echo "$p"
}
run() { (cd "$1" && sh "$SCRIPT"); }

# A folder that is not a Git repository yet, with no identity anywhere.
P=$(new_project blank)
out=$(run "$P") && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(git -C "$P" rev-list --count HEAD)" -eq 2 ] \
  && pass "a fresh folder gets the checkpoint and the records-only mark commit" \
  || fail "the founding save returned $code with $(git -C "$P" rev-list --count HEAD 2>/dev/null) commits: $out"
[ "$(git -C "$P" symbolic-ref --short HEAD)" = main ] \
  && pass "the first branch is main" || fail "the first branch is $(git -C "$P" symbolic-ref --short HEAD)"
[ "$(git -C "$P" log -1 --format=%an)" = "Local project user" ] && [ "$(git -C "$P" config --local user.name)" = "Local project user" ] \
  && printf '%s' "$out" | grep -q '^identity	neutral' \
  && pass "with no identity set, the neutral label is used inside this project and reported" \
  || fail "the neutral identity was not used: $(git -C "$P" log -1 --format=%an), $out"
checkpoint=$(git -C "$P" rev-parse HEAD~1)
grep -qx "Trued against: $checkpoint" "$P/masterplan.md" \
  && [ "$(git -C "$P" show --name-only --format= HEAD)" = "masterplan.md" ] \
  && pass "the mark names the founding checkpoint and is saved in a commit of its own" \
  || fail "the mark is $(grep '^Trued against' "$P/masterplan.md")"
(cd "$P" && sh "$SKILL/scripts/trued-mark.sh" >/dev/null) \
  && pass "trued-mark.sh finds the mark usable" || fail "the mark is not usable"
[ "$(git -C "$P" config --local core.hooksPath)" = .agents/hooks/git ] \
  && pass "the push guard is switched on once the folder is a repository" \
  || fail "core.hooksPath is '$(git -C "$P" config --local core.hooksPath)'"

# Nothing left to save: a second run must fail, not report a checkpoint.
out=$(run "$P") && code=0 || code=$?
[ "$code" -eq 1 ] && [ "$(git -C "$P" rev-list --count HEAD)" -eq 2 ] \
  && pass "with nothing to save it fails rather than report a checkpoint" \
  || fail "a run with nothing to save returned $code: $out"

# An existing repository whose last commit is somebody else's, with no
# identity for whoever is here now.
P=$(new_project inherited)
git -C "$P" init -q -b main
printf 'x\n' > "$P/old.txt"
git -C "$P" add old.txt
git -C "$P" -c user.name="Kit Author" -c user.email=author@example.invalid -c commit.gpgsign=false commit -q -m old
out=$(run "$P") && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(git -C "$P" log -1 --format=%an)" = "Local project user" ] \
  && ! git -C "$P" log --format=%an HEAD~1 -1 | grep -q 'Kit Author' \
  && pass "the last commit's author is never copied" \
  || fail "the founding save took '$(git -C "$P" log -1 --format=%an)', exit $code"

# A person who already set their own name keeps it.
P=$(new_project named)
git -C "$P" init -q -b main
git -C "$P" config user.name "Sam Lee"
git -C "$P" config user.email sam@example.invalid
out=$(run "$P") && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(git -C "$P" log -1 --format=%an)" = "Sam Lee" ] && printf '%s' "$out" | grep -q '^identity	kept' \
  && pass "a save name already set is kept" \
  || fail "a set identity was replaced: $(git -C "$P" log -1 --format=%an)"

# A project folder inside somebody else's repository is never saved into it.
mkdir -p "$WORK/outer"
git -C "$WORK/outer" init -q -b main
P=$(new_project outer/inner)
out=$(run "$P") && code=0 || code=$?
[ "$code" -eq 1 ] && ! git -C "$WORK/outer" rev-parse -q --verify HEAD >/dev/null \
  && pass "a folder inside a larger repository is refused and nothing is committed there" \
  || fail "a nested folder returned $code: $out"

echo "== Secrets and other work stay out of the checkpoint =="
P=$(new_project secrets)
printf 'API_KEY=real-value\n' > "$P/.env"
printf 'API_KEY=real-value\n' > "$P/.env.local"
printf 'API_KEY=\n' > "$P/.env.example"
out=$(run "$P") && code=0 || code=$?
saved=$(git -C "$P" ls-tree -r --name-only HEAD 2>/dev/null || true)
[ "$code" -eq 0 ] && ! printf '%s\n' "$saved" | grep -qx '.env' && ! printf '%s\n' "$saved" | grep -qx '.env.local' \
  && printf '%s\n' "$saved" | grep -qx '.env.example' \
  && pass "the .env files are never saved, and .env.example is" \
  || fail "the founding save returned $code and saved: $(printf '%s ' $saved)"
git -C "$P" check-ignore -q .env && git -C "$P" check-ignore -q .env.local && ! git -C "$P" check-ignore -q .env.example \
  && printf '%s\n' "$saved" | grep -qx '.gitignore' \
  && pass "the .env files are ignored from now on, in a saved .gitignore" \
  || fail "the .env files are not ignored after founding"

P=$(new_project key)
printf -- '-----BEGIN PRIVATE KEY-----\n' > "$P/deploy-key.pem"
out=$(run "$P") && code=0 || code=$?
[ "$code" -eq 1 ] && ! git -C "$P" rev-parse -q --verify HEAD >/dev/null \
  && printf '%s' "$out" | grep -q 'deploy-key.pem' \
  && pass "a file that looks like a secret stops the save, and is named" \
  || fail "a private key file returned $code: $out"

P=$(new_project other-work)
git -C "$P" init -q -b main
printf 'app v1\n' > "$P/app.js"
git -C "$P" add app.js
git -C "$P" -c user.name=Sam -c user.email=sam@example.invalid -c commit.gpgsign=false commit -q -m "Sam's app"
printf 'app v2, half done\n' > "$P/app.js"
out=$(run "$P") && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(git -C "$P" log -1 --format=%s -- app.js)" = "Sam's app" ] \
  && git -C "$P" show --name-only --format= HEAD~1 | grep -qx 'masterplan.md' \
  && [ "$(cat "$P/app.js")" = "app v2, half done" ] && git -C "$P" status --porcelain | grep -q '^ M app.js' \
  && printf '%s' "$out" | grep -q 'app.js' \
  && pass "the person's unsaved change to a file already saved stays out of the checkpoint, and is named" \
  || fail "the person's other work was swept up, exit $code: $out / $(git -C "$P" log --format=%s --name-only -3)"

# A masterplan with two mark lines is not guessed at.
P=$(new_project doubled)
printf 'Trued against: not yet checked\n' >> "$P/masterplan.md"
out=$(run "$P") && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s' "$out" | grep -q '2 Trued against' \
  && pass "two mark lines stop the save before the mark is written" \
  || fail "two mark lines returned $code: $out"

[ "$FAIL" -eq 0 ] || exit 1
echo "found-save.sh: all checks passed"
