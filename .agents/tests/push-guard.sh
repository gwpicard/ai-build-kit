#!/usr/bin/env sh
# push-guard.sh: push to a real bare remote through the pre-push hook a founded
# project receives, and switch it on with use-push-guard.sh.
#
# The Claude Code settings read the words of a command, so a push to main
# written another way, or run by another coding agent, gets past them. The
# hook reads what the push would change instead. If it breaks, a push lands
# on main without a pull request, or a force push replaces a teammate's work.
# If it is too strict, an ordinary piece branch cannot be pushed at all.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SKILL="$ROOT/.agents/skills/setup-ai-build-kit"
HOOK="$SKILL/templates/foundation/pre-push"
USE="$SKILL/scripts/use-push-guard.sh"

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "ok: $1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
export GIT_CONFIG_NOSYSTEM=1 HOME="$WORK/home"
mkdir -p "$HOME"
git config --global user.name Rehearsal
git config --global user.email rehearsal@example.invalid
git config --global commit.gpgsign false
git config --global init.defaultBranch main

P="$WORK/project"
R="$WORK/remote.git"
git init -q --bare "$R"
git init -q "$P"
mkdir -p "$P/.agents/hooks/git"
cp "$HOOK" "$P/.agents/hooks/git/pre-push"
git -C "$P" remote add origin "$R"
git -C "$P" commit -q --allow-empty -m first
# main reaches the remote before the guard is on, as the first upload's API
# call puts it there.
git -C "$P" push -q origin main

echo "== Switching the guard on =="
sh "$USE" "$P" && code=0 || code=$?
[ "$code" -eq 0 ] && [ "$(git -C "$P" config --local core.hooksPath)" = .agents/hooks/git ] \
  && pass "an unset hooks path is pointed at the project's hooks" \
  || fail "use-push-guard returned $code and set '$(git -C "$P" config --local core.hooksPath)'"
sh "$USE" "$P" && pass "running it again changes nothing" || fail "a second run failed"

pushes() { git -C "$P" push "$@" >/dev/null 2>&1; }
remote_main() { git -C "$R" rev-parse main; }

echo "== Pushes the guard stops =="
git -C "$P" checkout -q -b sign-out
git -C "$P" commit -q --allow-empty -m "Sign an item out"
before=$(remote_main)
for spelling in "origin main" "origin HEAD:main" "origin sign-out:main" "origin HEAD:refs/heads/main" \
                "-q origin main" "--force origin HEAD:main" "origin +HEAD:main" "origin --delete main" "origin :main"; do
  git -C "$P" checkout -q main 2>/dev/null
  git -C "$P" merge -q --ff-only sign-out
  # shellcheck disable=SC2086
  if pushes $spelling; then
    fail "git push $spelling went through"
  else
    pass "git push $spelling is stopped"
  fi
  git -C "$P" checkout -q sign-out
done
git -C "$P" checkout -q main
if git -C "$P" -c push.default=current push origin >/dev/null 2>&1; then
  fail "a bare git push while main is checked out went through"
else
  pass "a bare git push while main is checked out is stopped, though it never names main"
fi
git -C "$P" checkout -q sign-out
[ "$(remote_main)" = "$before" ] && pass "main on the remote never moved" || fail "main on the remote moved"

pushes -u origin sign-out && pass "a piece branch pushes" || fail "a piece branch was stopped"
git -C "$P" commit -q --allow-empty -m "Sign it back in"
pushes origin sign-out && pass "a piece branch that only moves forward pushes again" || fail "a fast-forward push was stopped"

git -C "$P" reset -q --soft HEAD~1
git -C "$P" commit -q --allow-empty -m "Sign it back in, rewritten"
for spelling in "--force origin sign-out" "--force-with-lease origin sign-out" "origin +sign-out" "-uf origin sign-out"; do
  # shellcheck disable=SC2086
  if pushes $spelling; then
    fail "git push $spelling replaced work on the remote"
  else
    pass "git push $spelling is stopped"
  fi
done

# Work somebody else pushed, which this copy has never fetched.
other="$WORK/other"
git clone -q "$R" "$other"
git -C "$other" checkout -q sign-out
git -C "$other" commit -q --allow-empty -m "A teammate's change"
git -C "$other" push -q origin sign-out
if pushes --force origin sign-out; then
  fail "a force push over work this copy never saw went through"
else
  pass "a force push over work this copy never saw is stopped"
fi

pushes origin --delete sign-out && pass "deleting a piece branch is allowed" || fail "deleting a piece branch was stopped"
git -C "$P" tag v1
pushes origin v1 && pass "a tag pushes" || fail "a tag was stopped"
git -C "$P" checkout -q -b main-fix
pushes origin main-fix && pass "a branch whose name starts with main pushes" || fail "main-fix was stopped"

echo "== The hook is what stops them =="
git -C "$P" config --local --unset core.hooksPath
git -C "$P" checkout -q main
if pushes origin main; then
  pass "with the guard off the same push goes through, so the guard is load-bearing"
else
  fail "a push to main was stopped with the guard off, so the check proves nothing"
fi

echo "== When the guard stays off =="
Q="$WORK/husky"
git init -q "$Q"
mkdir -p "$Q/.agents/hooks/git"
cp "$HOOK" "$Q/.agents/hooks/git/pre-push"
git -C "$Q" config core.hooksPath .husky
out=$(sh "$USE" "$Q" 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && [ "$(git -C "$Q" config core.hooksPath)" = .husky ] && printf '%s' "$out" | grep -q '.husky' \
  && pass "a project whose Git already runs its own hooks keeps them, and is told the guard is off" \
  || fail "an existing hooks path was replaced or not reported: $code $out"
mkdir -p "$Q/sub/.agents/hooks/git"
cp "$HOOK" "$Q/sub/.agents/hooks/git/pre-push"
out=$(sh "$USE" "$Q/sub" 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && pass "a folder inside a larger repository is not switched on" || fail "a nested folder returned $code"
mkdir -p "$WORK/plain"
sh "$USE" "$WORK/plain" && pass "a folder that is not a repository yet is left for the founding save" || fail "a plain folder failed"

[ "$FAIL" -eq 0 ] || exit 1
echo "push-guard.sh: all checks passed"
