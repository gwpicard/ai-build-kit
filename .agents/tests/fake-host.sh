#!/usr/bin/env sh
# fake-host.sh: check the replay harness's stand-ins for a host's tools.
#
# Scenario 54 replays a second launch on the Vercel recipe. The stand-in host
# keeps a list of deployments, builds `main` when a merge moves it, and answers
# the commands the recipe and a deploying kit reach for. The scenario is graded
# on that list, so the list has to move exactly as a connected host's would: one
# build for one merge, a second build only when something deploys again, and a
# live address that follows the newest working build.
#
# The rest matters as much. A deploy's output carries its success line near the
# end, so a kit that cuts it short cannot tell it worked; the other tools fail
# the way an unsigned, unstarted machine fails; and a run with no host state
# reaches the real command, so every other scenario behaves as before.
#
# Everything here runs against throwaway folders. No network, no account.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
HOST_DIR="$ROOT/.agents/tests/replay/fake-host"
GH="$ROOT/.agents/tests/replay/fake-github/gh"
PREPARE="$ROOT/.agents/tests/replay/prepare/live-on-vercel"

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

# A project the way the harness leaves one for scenario 54: the kit's own
# AGENTS.md and the Vercel recipe, the preparation, the first commit, the remote
# next door, and the preparation's second half.
p="$WORK/s54"
mkdir -p "$p/.agents/skills/ship/recipes"
cp "$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md" "$p/"
cp "$ROOT/.agents/skills/ship/recipes/nextjs-supabase-on-vercel.md" "$p/.agents/skills/ship/recipes/"
cp "$ROOT/.gitignore" "$p/.gitignore"
sh "$PREPARE.sh" "$p"
git -C "$p" init -q
git init -q --bare "$p.git"
git -C "$p" remote add origin "$p.git"
git -C "$p" config user.name "Replay rehearsal"
git -C "$p" config user.email rehearsal@example.invalid
git -C "$p" config commit.gpgsign false
git -C "$p" add -A
git -C "$p" commit -q -m "Project before the scenario"
sh "$PREPARE.after-commit.sh" "$p"
first=$(git -C "$p" rev-parse main)

FAKE_HOST_STATE="$p.host.json"
FAKE_HOST_LOG="$WORK/host.log"
FAKE_GH_STATE="$p/.gh-fixture.json"
FAKE_GH_LOG="$WORK/gh.log"
export FAKE_HOST_STATE FAKE_HOST_LOG FAKE_GH_STATE FAKE_GH_LOG
PATH="$HOST_DIR:$PATH"
export PATH
cd "$p"

# production_count [commit]: production deployments in the list, of one commit
# where one is named.
production_count() {
  python3 - "$FAKE_HOST_STATE" "${1:-}" <<'PY'
import json, sys
state = json.load(open(sys.argv[1]))
print(sum(1 for d in state["deployments"]
          if d["target"] == "production" and (not sys.argv[2] or d["commit"] == sys.argv[2])))
PY
}
health_commit() {
  curl -fsS https://noticeboard-office.vercel.app/api/health \
    | python3 -c 'import json, sys; print(json.load(sys.stdin)["commit"])'
}

echo "== What the first launch left =="
listing=$(vercel ls)
case "$listing" in
  *"Ready"*"Production"*) pass "the list shows the working production build" ;;
  *) fail "the list does not show a working production build: $listing" ;;
esac
case "$listing" in
  *"Error"*) pass "and the build that failed on the first launch" ;;
  *) fail "the list lost the first launch's failed build" ;;
esac
[ "$(health_commit)" = "$first" ] \
  && pass "the live health route reports the commit on main" \
  || fail "the live health route reports another commit"
case "$(curl -fsS https://noticeboard-office.vercel.app/sign-in)" in
  *">Continue<"*) pass "the live sign-in page shows the old wording" ;;
  *) fail "the live sign-in page does not show the old wording" ;;
esac
[ -z "$(git -C "$p" status --porcelain)" ] \
  && pass "the host's state sits outside the project, so nothing there changed" \
  || fail "reading the host changed the project: $(git -C "$p" status --porcelain)"

echo "== A merge builds once =="
before=$(production_count)
"$GH" pr merge 1 >/dev/null
merged=$(git --git-dir "$p.git" rev-parse main)
[ "$merged" != "$first" ] \
  && pass "merging the pull request moves main on the remote" \
  || fail "the merge did not move main"
case "$(vercel ls --prod)" in
  *"Building"*) pass "the host shows the merge as building the first time it is asked" ;;
  *) fail "the host did not show the merge building" ;;
esac
[ "$(health_commit)" = "$merged" ] \
  && pass "the next call finds it ready, and the live address serves it" \
  || fail "the live address does not serve the merge"
case "$(curl -fsS https://noticeboard-office.vercel.app/sign-in)" in
  *">Email me a sign-in link<"*) pass "the live sign-in page shows the new wording" ;;
  *) fail "the live sign-in page does not show the new wording" ;;
esac
vercel ls >/dev/null
vercel inspect noticeboard-office.vercel.app >/dev/null
[ "$(production_count)" = "$((before + 1))" ] && [ "$(production_count "$merged")" = "1" ] \
  && pass "one merge made one production build, however often the list was read" \
  || fail "one merge made $(($(production_count) - before)) production builds"

echo "== A second deploy is visible =="
# A deploy from this computer builds whatever the folder holds, so bring the
# merge down first, as a kit deploying main by hand would.
git -C "$p" pull -q --ff-only origin main
full=$(vercel deploy --prod --yes)
case "$full" in
  *"Production: https://"*"Aliased: https://noticeboard-office.vercel.app"*)
    pass "the whole deploy output says it went live, and where" ;;
  *) fail "the whole deploy output has no success line" ;;
esac
short=$(vercel deploy --prod --yes | tail -3)
case "$short" in
  *"Production: https://"*|*"Aliased"*) fail "the last three lines already show the success line" ;;
  *) pass "its last three lines do not, so output cut short cannot tell it worked" ;;
esac
[ "$(printf '%s\n' "$full" | wc -l | tr -d ' ')" -gt 40 ] \
  && pass "the deploy output is long, as a real build log is" \
  || fail "the deploy output is short enough to read at a glance"
[ "$(production_count "$merged")" = "3" ] \
  && pass "each deploy of the same version adds a production build of it to the list" \
  || fail "deploying the same version again left $(production_count "$merged") builds of it"
vercel redeploy noticeboard-office.vercel.app >/dev/null
[ "$(production_count "$merged")" = "4" ] \
  && pass "a redeploy is another build of the same version too" \
  || fail "a redeploy did not show in the list"

echo "== A rollback is recorded =="
earlier=$(python3 -c 'import json, sys; s = json.load(open(sys.argv[1])); print([d["url"] for d in s["deployments"] if d.get("before_run") and d["state"] == "READY" and d["target"] == "production"][0])' "$FAKE_HOST_STATE")
vercel rollback "$earlier" --yes >/dev/null
[ "$(health_commit)" = "$first" ] \
  && pass "a rollback points the live address back at the earlier build" \
  || fail "a rollback did not move the live address"
python3 -c 'import json, sys; s = json.load(open(sys.argv[1])); sys.exit(0 if [m for m in s.get("moves", []) if m["kind"] == "rollback"] else 1)' "$FAKE_HOST_STATE" \
  && pass "and the host's state records it" \
  || fail "the rollback left no record"

echo "== The recipe's other commands =="
case "$(vercel env ls production)" in
  *SUPABASE_SERVICE_ROLE_KEY*) pass "vercel env ls lists the names and no value" ;;
  *) fail "vercel env ls did not list the names" ;;
esac
vercel logs --environment production --level error --since 1h --no-branch --json >/dev/null \
  && pass "vercel logs answers the recipe's command" \
  || fail "vercel logs refused the recipe's command"
vercel curl /api/health --deployment "https://$earlier" --yes >/dev/null \
  && pass "vercel curl reads a deployment's health through its protection" \
  || fail "vercel curl refused the recipe's command"
if vercel deploy --prod --yse >/dev/null 2>&1; then
  fail "a misspelt option was accepted"
else
  pass "a misspelt option is refused"
fi
if vercel teams ls >/dev/null 2>&1; then
  fail "an unmodelled command was answered"
else
  pass "an unmodelled command is refused"
fi
grep -q "^UNSUPPORTED	vercel teams ls" "$FAKE_HOST_LOG" \
  && pass "and the refusal is written to the log" \
  || fail "the refusal is not in the log"
grep -q "^CALL	vercel ls" "$FAKE_HOST_LOG" && grep -q "^CALL	curl " "$FAKE_HOST_LOG" \
  && pass "every call is logged, so a run shows the stand-ins answered it" \
  || fail "the log does not record the calls"
if supabase db push --dry-run >/dev/null 2>&1 || docker info >/dev/null 2>&1 \
  || psql --tuples-only --command "select 1" >/dev/null 2>&1; then
  fail "a check that needs Supabase, Docker or the database ran"
else
  pass "Supabase is not signed in, Docker's engine is off, and no database answers"
fi
grep -q "^CALL	supabase db push" "$FAKE_HOST_LOG" && grep -q "^CALL	docker info" "$FAKE_HOST_LOG" \
  && pass "and those calls are logged too" \
  || fail "the Supabase or Docker call was not logged"
if curl -fsS https://example.com/ >/dev/null 2>&1; then
  fail "curl reached an address outside the scenario"
else
  pass "curl reaches no address outside the scenario"
fi

echo "== Any other run =="
# With no host state, each stand-in hands the call to the next command of that
# name on PATH, so a scenario that never set one up behaves as before.
mkdir -p "$WORK/real"
for tool in vercel curl docker supabase psql; do
  printf '#!/bin/sh\necho "real %s"\n' "$tool" > "$WORK/real/$tool"
  chmod +x "$WORK/real/$tool"
done
for tool in vercel curl docker supabase psql; do
  got=$(FAKE_HOST_STATE="$WORK/none.json" PATH="$HOST_DIR:$WORK/real:$PATH" "$tool" --version)
  [ "$got" = "real $tool" ] \
    && pass "with no host state, $tool is the real command" \
    || fail "with no host state, $tool answered: $got"
done

echo
if [ "$FAIL" -eq 0 ]; then
  echo "fake-host.sh: all checks passed"
else
  echo "fake-host.sh: FAILED" >&2
fi
exit "$FAIL"
