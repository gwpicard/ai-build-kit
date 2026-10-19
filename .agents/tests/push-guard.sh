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
SCAN="$SKILL/templates/foundation/scan-secrets.sh"
SCAN_PY="$SKILL/templates/foundation/scan-secrets.py"

copy_scan() {
  project=$1
  cp "$SCAN" "$project/.agents/hooks/scan-secrets.sh"
  cp "$SCAN_PY" "$project/.agents/hooks/scan-secrets.py"
}
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
git -C "$P" remote add origin "$R"
git -C "$P" commit -q --allow-empty -m first
# main reaches the remote before the guard is on, as the first upload's API
# call puts it there.
git -C "$P" push -q origin main

echo "== Switching the guard on =="
mkdir -p "$P/.agents/skills"
ln -s "$SKILL" "$P/.agents/skills/setup-ai-build-kit"
sh "$SKILL/scripts/bootstrap-project.sh" "$P" && code=0 || code=$?
[ "$code" -eq 0 ] && sh "$USE" --check "$P" \
  && pass "founding installs a guard Git would run" \
  || fail "founding did not enable the guard, exit $code"
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

# Feed Git's hook the deletion record directly. A bare remote also refuses a
# main deletion, so a real push alone would not prove this guard did it.
main_sha=$(remote_main)
if printf 'refs/heads/main %040d refs/heads/main %s\n' 0 "$main_sha" | \
  sh "$P/.agents/hooks/git/pre-push" >"$WORK/delete-main-out" 2>&1; then
  fail "pre-push accepted Git's main deletion input"
else
  grep -q 'would change main directly' "$WORK/delete-main-out" \
    && pass "the hook itself refuses deleting main" \
    || fail "main deletion failed for a reason other than the hook's main rule"
fi

pushes -u origin sign-out && pass "a piece branch pushes" || fail "a piece branch was stopped"
git -C "$P" commit -q --allow-empty -m "Sign it back in"
pushes origin sign-out && pass "a piece branch that only moves forward pushes again" || fail "a fast-forward push was stopped"

# Existing branches must scan only the commits after the remote SHA. Reversing
# that range would let this newly added key-shaped value through.
push_value="ghp_$(python3 -c 'import secrets; print(secrets.token_hex(24))')"
printf '%s\n' "$push_value" > "$P/push-key.txt"
git -C "$P" add push-key.txt
git -C "$P" commit -q -m "Test existing branch range"
if pushes origin sign-out >"$WORK/secret-push-out" 2>&1; then
  fail "an existing-branch push containing a key-shaped value was allowed"
else
  ! grep -Fq -- "$push_value" "$WORK/secret-push-out" \
    && pass "an existing-branch push scans only its new commits and hides the value" \
    || fail "the existing-branch scan printed the test value"
fi

git -C "$P" reset -q --soft HEAD~2
git -C "$P" rm -q --cached push-key.txt
rm "$P/push-key.txt"
git -C "$P" commit -q --allow-empty -m "Sign it back in, rewritten"
for spelling in "--force origin sign-out" "--force-with-lease origin sign-out" "origin +sign-out" "-uf origin sign-out"; do
  # shellcheck disable=SC2086
  if git -C "$P" push $spelling >"$WORK/force-out" 2>&1; then
    fail "git push $spelling replaced work on the remote"
  else
    grep -q 'would replace work' "$WORK/force-out" \
      && pass "git push $spelling is stopped by the hook's work guard" \
      || fail "git push $spelling failed for a reason other than replacing work"
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
git -C "$P" tag v1 main
pushes origin v1 && pass "a tag pushes" || fail "a tag was stopped"
tag_before=$(git -C "$R" rev-parse refs/tags/v1)
git -C "$P" tag -f v1 sign-out >/dev/null
if git -C "$P" push --force origin v1 >"$WORK/tag-replace-out" 2>&1; then
  fail "a force push replaced an existing tag"
else
  grep -q 'would replace work on an existing tag' "$WORK/tag-replace-out" \
    && [ "$(git -C "$R" rev-parse refs/tags/v1)" = "$tag_before" ] \
    && pass "an existing tag cannot be replaced by a descendant commit" || fail "tag replacement gave no guard refusal"
fi
pushes origin --delete v1 && pass "deleting a tag remains allowed" || fail "deleting a tag was stopped"
git -C "$P" checkout -q -b tag-secret main
tag_value="AKIA$(python3 -c 'import secrets; print(secrets.token_hex(8).upper())')"
printf '%s\n' "$tag_value" > "$P/tag-key.txt"
git -C "$P" add tag-key.txt && git -C "$P" commit -q -m "Tag carries a key"
git -C "$P" tag secret-key
if git -C "$P" push origin secret-key >"$WORK/tag-secret-out" 2>&1; then
  fail "a tag push containing a key-shaped value was allowed"
else
  grep -q 'secret scan found a secret' "$WORK/tag-secret-out" \
    && ! grep -Fq -- "$tag_value" "$WORK/tag-secret-out" \
    && pass "a tag push scans its new commits and names the secret refusal" \
    || fail "tag scan did not give the secret refusal"
fi
U="$WORK/could-not-run"
git init -q "$U"
mkdir -p "$U/.agents/hooks/git" "$U/.agents/hooks"
cp "$HOOK" "$U/.agents/hooks/git/pre-push"
git -C "$U" commit -q --allow-empty -m start
printf '#!/bin/sh\necho "Secret scan: could not run: rehearsal" >&2\nexit 2\n' > "$U/.agents/hooks/scan-secrets.sh"
sha=$(git -C "$U" rev-parse HEAD)
status=0
printf 'refs/heads/topic %s refs/heads/topic %040d\n' "$sha" 0 | \
  sh "$U/.agents/hooks/git/pre-push" >"$WORK/could-not-run-out" 2>&1 || status=$?
[ "$status" -ne 0 ] && grep -q 'secret scan could not run' "$WORK/could-not-run-out" \
  && ! grep -q 'found a secret' "$WORK/could-not-run-out" \
  && pass "a scanner error has its own refusal message" \
  || fail "could not-run scan was not distinguished from a found secret"
git -C "$P" checkout -q main
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

echo "== Keeping existing hooks =="
Q="$WORK/husky"
git init -q "$Q"
mkdir -p "$Q/.agents/skills" "$Q/.husky"
ln -s "$SKILL" "$Q/.agents/skills/setup-ai-build-kit"
# The person's hook consumes the same input and arguments after the guard.
printf '#!/bin/sh\ncat > own-input\nprintf "%%s\\n" "$@" > own-args\nexit 0\n' > "$Q/.husky/pre-push"
chmod +x "$Q/.husky/pre-push"
git -C "$Q" config core.hooksPath .husky
sh "$SKILL/scripts/bootstrap-project.sh" "$Q" >/dev/null && sh "$USE" --check "$Q" \
  && [ "$(git -C "$Q" config core.hooksPath)" = .husky ] \
  && pass "founding chains the guard into .husky and keeps the hooks path" \
  || fail "founding did not chain the guard into .husky"
cp "$Q/.husky/pre-push" "$WORK/chained-before"
sh "$USE" "$Q" && cmp -s "$WORK/chained-before" "$Q/.husky/pre-push" \
  && pass "a second installation keeps the chain unchanged" || fail "the chain was duplicated"
git -C "$Q" commit -q --allow-empty -m first
git -C "$Q" remote add origin "$R"
if git -C "$Q" push origin HEAD:main >"$WORK/husky-out" 2>&1; then
  fail "the .husky chain allowed a push to main"
else
  grep -q 'would change main directly' "$WORK/husky-out" && [ ! -e "$Q/own-input" ] \
    && pass "the .husky chain refuses main before the person's hook" || fail "the chain missed main"
fi
git -C "$Q" push origin HEAD:refs/heads/husky-piece >/dev/null 2>&1 \
  && grep -q 'refs/heads/husky-piece' "$Q/own-input" && grep -qx origin "$Q/own-args" \
  && pass "the person's hook still receives the input and arguments" || fail "the person's hook broke"
sed 's/^exit 0$/exit 23/' "$Q/.husky/pre-push" > "$WORK/refusing-hook"
cat "$WORK/refusing-hook" > "$Q/.husky/pre-push"
if git -C "$Q" push origin HEAD:refs/heads/husky-refuses >/dev/null 2>&1; then
  fail "the person's hook refusal was ignored"
else
  pass "the person's hook can still refuse a push"
fi
# An unsupported hook cannot be changed safely; both founding stages stop.
printf '#!/usr/bin/env python3\nraise SystemExit(0)\n' > "$Q/.husky/pre-push"
printf 'Trued against: not yet checked\n' > "$Q/masterplan.md"
before=$(git -C "$Q" rev-parse HEAD)
for installer in bootstrap-project found-save; do
  if (cd "$Q" && sh "$SKILL/scripts/$installer.sh") >"$WORK/founding-stop" 2>&1; then
    fail "$installer succeeded without an active guard"
  else
    grep -q 'push guard is not on' "$WORK/founding-stop" \
      && [ "$(git -C "$Q" rev-parse HEAD)" = "$before" ] \
      && pass "$installer stops plainly before saving without a guard" || fail "$installer gave no cause"
  fi
done
mkdir -p "$Q/sub/.agents/hooks/git"
cp "$HOOK" "$Q/sub/.agents/hooks/git/pre-push"
mkdir -p "$Q/sub/.agents/hooks"
cp "$SCAN" "$Q/sub/.agents/hooks/scan-secrets.sh"
cp "$SCAN_PY" "$Q/sub/.agents/hooks/scan-secrets.py"
out=$(sh "$USE" "$Q/sub" 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && pass "a folder inside a larger repository is not switched on" || fail "a nested folder returned $code"
mkdir -p "$WORK/plain"
sh "$USE" "$WORK/plain" && pass "a folder that is not a repository yet is left for the founding save" || fail "a plain folder failed"

# A tool such as lefthook, git-lfs or an older husky puts its hooks in Git's
# own hooks folder. Pointing Git elsewhere would silently stop them running.
H="$WORK/lefthook"
git init -q "$H"
mkdir -p "$H/.agents/hooks/git"
cp "$HOOK" "$H/.agents/hooks/git/pre-push"
copy_scan "$H"
printf '#!/bin/sh\nexit 0\n' > "$H/.git/hooks/pre-commit"
chmod +x "$H/.git/hooks/pre-commit"
sh "$USE" "$H" && sh "$USE" --check "$H" \
  && [ -z "$(git -C "$H" config --local --get core.hooksPath || true)" ] \
  && [ -x "$H/.git/hooks/pre-commit" ] \
  && pass "Git's existing hooks keep running alongside the guard" \
  || fail "existing default hooks stopped the guard or were switched off"

# A hooks folder set for every project on this computer.
G="$WORK/global"
git init -q "$G"
mkdir -p "$G/.agents/hooks/git"
cp "$HOOK" "$G/.agents/hooks/git/pre-push"
copy_scan "$G"
git config --global core.hooksPath "$HOME/.githooks"
out=$(sh "$USE" "$G" 2>&1) && code=0 || code=$?
[ "$code" -eq 1 ] && [ -z "$(git -C "$G" config --local --get core.hooksPath || true)" ] \
  && printf '%s' "$out" | grep -q 'push guard is not on' \
  && pass "a hooks folder set for every project is not overridden, and the line says so" \
  || fail "a user-wide hooks path was overridden or not reported: $code $out"
git config --global --unset core.hooksPath

# A hook copied without its executable bit is one Git skips.
X="$WORK/noexec"
git init -q "$X"
mkdir -p "$X/.agents/hooks/git"
cp "$HOOK" "$X/.agents/hooks/git/pre-push"
copy_scan "$X"
chmod a-x "$X/.agents/hooks/git/pre-push"
sh "$USE" "$X" >/dev/null 2>&1 && code=0 || code=$?
[ "$code" -eq 0 ] && [ -x "$X/.agents/hooks/git/pre-push" ] \
  && pass "a hook without its executable bit gets it, so Git runs it" \
  || fail "the hook was left unrunnable, exit $code"

[ "$FAIL" -eq 0 ] || exit 1
echo "push-guard.sh: all checks passed"
