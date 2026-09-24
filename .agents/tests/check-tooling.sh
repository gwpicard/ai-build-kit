#!/usr/bin/env sh
# check-tooling.sh: check what the setup tooling report says and when it stops.
#
# The report is what catches a missing tool before founding leans on it, so the
# thing that matters is the exit code: it stops with a non-zero result when a
# tool that blocks founding is absent, and returns cleanly when they are all
# ready. A grep over the script cannot judge that. This runs it against a set of
# throwaway PATHs and reads what it does.
#
# A stand-in for the GitHub command line tool supplies the sign-in and the
# repository. The report asks gh for JSON and filters it with python3, which is
# what makes that substitution honest.
#
# Everything here runs in a throwaway directory. No network, no account.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CHECK="$ROOT/skills/setup-ai-build-kit/scripts/check-tooling.sh"

FAIL=0
fail() {
  echo "FAIL: $1" >&2
  FAIL=1
}
pass() {
  echo "ok: $1"
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

# A bin holding only the tools each case is meant to have. Git, python3, and the
# shell are the real ones, reached through a symlink, so the controlled PATH
# still resolves the shebang and the report's own commands, and only the GitHub
# command line tool is ever the stand-in. Dropping gh from this bin is what makes
# it genuinely missing.
mkdir -p "$WORK/bin"
ln -s "$(command -v git)" "$WORK/bin/git"
ln -s "$(command -v python3)" "$WORK/bin/python3"
ln -s "$(command -v sh)" "$WORK/bin/sh"

# A stand-in that answers only the sign-in and the repository lookup the report
# makes, with echo alone so it needs nothing else on the controlled PATH.
write_gh() {
  cat >"$WORK/bin/gh" <<SH
#!/usr/bin/env sh
case "\$1 \$2" in
  "auth status") exit $1 ;;
  "repo view") echo '$2' ;;
  *) echo '{}' ;;
esac
SH
  chmod +x "$WORK/bin/gh"
}

run_check() {
  # Run the report with PATH set to the controlled bin alone, so a tool left out
  # of it is genuinely missing.
  PATH="$WORK/bin" HOME="$HOME" "$CHECK" 2>&1
}

echo "== Everything ready =="

write_gh 0 '{"nameWithOwner":"someone/project","hasIssuesEnabled":true,"viewerPermission":"ADMIN"}'
out=$(run_check) && code=0 || code=$?
[ "$code" -eq 0 ] \
  && pass "the report returns cleanly when every tool is ready" \
  || fail "a clean setup returned $code"
printf '%s\n' "$out" | grep -q "Every tool the kit needs" \
  && pass "it says the tools are ready" \
  || fail "the ready summary is missing"
printf '%s\n' "$out" | grep -q "Issues are switched on" \
  && pass "it reports issues switched on" \
  || fail "the issues-on line is missing"
printf '%s\n' "$out" | grep -q "Labels can be put in order" \
  && pass "it reports the account can manage labels" \
  || fail "the labels line is missing"

echo "== The GitHub command line tool missing =="

rm -f "$WORK/bin/gh"
out=$(run_check) && code=0 || code=$?
[ "$code" -ne 0 ] \
  && pass "a missing GitHub command line tool stops founding" \
  || fail "a missing GitHub command line tool did not stop the report"
printf '%s\n' "$out" | grep -q "GitHub command line tool is missing" \
  && pass "it names the missing tool" \
  || fail "the missing-tool line is missing"

echo "== Installed but signed out =="

write_gh 1 '{}'
out=$(run_check) && code=0 || code=$?
[ "$code" -ne 0 ] \
  && pass "nobody signed in stops founding" \
  || fail "signed out did not stop the report"
printf '%s\n' "$out" | grep -q "nobody is signed in" \
  && pass "it says nobody is signed in" \
  || fail "the signed-out line is missing"

echo "== Signed in, but a soft repository state =="

# Issues off and a read-only account do not block founding: the report says so
# and returns cleanly, because the pieces still become issues.
write_gh 0 '{"nameWithOwner":"someone/project","hasIssuesEnabled":false,"viewerPermission":"READ"}'
out=$(run_check) && code=0 || code=$?
[ "$code" -eq 0 ] \
  && pass "issues off and read-only access do not stop founding" \
  || fail "a soft repository state returned $code"
printf '%s\n' "$out" | grep -q "Issues are switched off" \
  && pass "it reports issues switched off" \
  || fail "the issues-off line is missing"
printf '%s\n' "$out" | grep -q "cannot create or delete labels" \
  && pass "it reports the account cannot manage labels" \
  || fail "the no-labels line is missing"

echo "== Signed in, no repository yet =="

# A fresh project has no repository, so the issue and label checks wait.
write_gh 0 ''
out=$(run_check) && code=0 || code=$?
[ "$code" -eq 0 ] \
  && pass "a fresh project with no repository still returns cleanly" \
  || fail "no repository returned $code"
printf '%s\n' "$out" | grep -q "No GitHub repository is set up yet" \
  && pass "it says the repository checks wait until one exists" \
  || fail "the no-repository line is missing"

echo "== The tools a recipe's checks run =="

# A recipe names the command-line tools its launch checks run. They are asked
# for only when a recipe is named, and a missing one never stops founding, since
# a project that uses no recipe needs none of them. The real recipes are read
# where they are, on the menu or still waiting for their real run.
write_gh 0 '{"nameWithOwner":"someone/project","hasIssuesEnabled":true,"viewerPermission":"ADMIN"}'
out=$(run_check) && code=0 || code=$?
printf '%s\n' "$out" | grep -q "launch checks" \
  && fail "a project that names no recipe was asked about recipe tools" \
  || pass "with no recipe named, no recipe tool is asked about"

printf '%s\n' 'Fits: a test' 'Command-line tools: git, stand-in-deploy-tool' > "$WORK/recipe.md"
out=$(PATH="$WORK/bin" HOME="$HOME" "$CHECK" --recipe "$WORK/recipe.md" 2>&1) && code=0 || code=$?
[ "$code" -eq 0 ] \
  && pass "a missing recipe tool does not stop founding" \
  || fail "a missing recipe tool returned $code"
printf '%s\n' "$out" | grep -q "^git is ready: the recipe's launch checks run it" \
  && pass "it reports a recipe tool that is ready" \
  || fail "the ready recipe tool line is missing"
printf '%s\n' "$out" | grep -q "^stand-in-deploy-tool is missing: .*before the first /ship. It does not stop founding" \
  && pass "it names a missing recipe tool as needed before the first launch" \
  || fail "the missing recipe tool line is missing"

rm -f "$WORK/bin/gh"
out=$(PATH="$WORK/bin" HOME="$HOME" "$CHECK" --recipe "$WORK/recipe.md" 2>&1) && code=0 || code=$?
[ "$code" -ne 0 ] \
  && pass "naming a recipe does not excuse a missing founding tool" \
  || fail "a recipe hid the missing GitHub command line tool"
write_gh 0 '{"nameWithOwner":"someone/project","hasIssuesEnabled":true,"viewerPermission":"ADMIN"}'

for name in nextjs-supabase-on-vercel nextjs-supabase-on-coolify; do
  recipe="$ROOT/skills/ship/recipes/$name.md"
  [ -f "$recipe" ] || recipe="$ROOT/tests/recipes-awaiting-run/$name.md"
  [ -f "$recipe" ] || { fail "$name is neither on the menu nor waiting"; continue; }
  out=$(PATH="$WORK/bin" HOME="$HOME" "$CHECK" --recipe "$recipe" 2>&1) && code=0 || code=$?
  [ "$code" -eq 0 ] || fail "$name's tools stopped founding"
  for tool in supabase docker psql curl; do
    printf '%s\n' "$out" | grep -q "^$tool is \(ready\|missing\)" || fail "$name's report says nothing about $tool"
  done
  pass "$name's tools are each reported, and none stops founding"
done

echo
if [ "$FAIL" -eq 0 ]; then
  echo "check-tooling.sh: all checks passed"
else
  echo "check-tooling.sh: FAILED" >&2
fi
exit "$FAIL"
