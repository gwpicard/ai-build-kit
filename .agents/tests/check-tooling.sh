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
unset CODEX_THREAD_ID CODEX_SANDBOX

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
  "auth status") echo "\${WORKFLOW_STATUS:-}"; exit $1 ;;
  "repo view") echo '$2' ;;
  *) echo '{}' ;;
esac
SH
  chmod +x "$WORK/bin/gh"
}

run_check() {
  # Run the report with PATH set to the controlled bin alone, so a tool left out
  # of it is genuinely missing. The report reads `origin`, so it runs from a
  # folder of its own: run from this repository, it would find the kit's own
  # repository and rightly skip the checks these cases are about.
  (cd "$WORK/plain" && PATH="$WORK/bin" HOME="$HOME" "$CHECK" 2>&1)
}
mkdir -p "$WORK/plain"

echo "== Everything ready =="

write_gh 0 '{"nameWithOwner":"someone/project","hasIssuesEnabled":true,"viewerPermission":"ADMIN"}'
out=$(run_check) && code=0 || code=$?
[ "$code" -eq 0 ] \
  && pass "the report returns cleanly when every tool is ready" \
  || fail "a clean setup returned $code"
printf '%s\n' "$out" | grep -q "All tools needed for founding" \
  && pass "it says the tools are ready" \
  || fail "the ready summary is missing"
printf '%s\n' "$out" | grep -q "Issues are switched on" \
  && pass "it reports issues switched on" \
  || fail "the issues-on line is missing"
printf '%s\n' "$out" | grep -q "Labels can be put in order" \
  && pass "it reports the account can manage labels" \
  || fail "the labels line is missing"

echo "== Workflow upload permission =="

for scopes in "'repo', 'read:org', 'gist'" "'repo', 'workflow'" "" "'repo', 'workflow_extra'"; do
  export WORKFLOW_STATUS="  - Token scopes: $scopes"
  out=$(run_check) && code=0 || code=$?
  [ "$code" -eq 0 ] || fail "workflow permission warning blocked founding"
  case "$scopes" in
    "'repo', 'read:org', 'gist'" | "'repo', 'workflow_extra'")
      printf '%s\n' "$out" | grep -q 'gh auth refresh -h github.com -s workflow' \
        && printf '%s\n' "$out" | grep -q 'browser once' \
        && pass "known missing workflow permission gives the terminal command" \
        || fail "missing workflow permission has no recovery: $out" ;;
    *)
      ! printf '%s\n' "$out" | grep -q 'gh auth refresh' \
        && pass "present or unreadable scopes get no warning" \
        || fail "present or unreadable scopes were called missing" ;;
  esac
  ! printf '%s\n' "$out" | grep -q 'Token scopes:' \
    || fail "the report printed raw authentication output"
done
unset WORKFLOW_STATUS

python3 - "$ROOT" <<'PYTEST'
import os, pathlib, subprocess, sys, tempfile
root = pathlib.Path(sys.argv[1])
helper = root / 'skills/setup-ai-build-kit/scripts/workflow-upload-check.py'
with tempfile.TemporaryDirectory() as folder:
    folder = pathlib.Path(folder)
    gh = folder / 'gh'
    gh.write_text('#!' + sys.executable + '\n' +
                  'import os, sys\n' +
                  'assert sys.argv[1:] == ["auth", "status", "--active", "--hostname", "github.com"]\n' +
                  'assert "GH_DEBUG" not in os.environ\n' +
                  'print(os.environ["STATUS"])\n' +
                  'sys.exit(int(os.environ.get("STATUS_EXIT", "0")))\n')
    gh.chmod(0o700)
    git = folder / 'git'
    git.write_text('#!' + sys.executable + '\nimport os\nprint(os.environ.get("ORIGIN", ""))\n')
    git.chmod(0o700)
    env = {k:v for k,v in os.environ.items() if k not in ('CODEX_THREAD_ID', 'CODEX_SANDBOX')}
    env.update(PATH=str(folder), GH_DEBUG='api', STATUS="Token: SECRET-FIXTURE\nToken scopes: 'repo', 'gist'",
               ORIGIN='https://github.com/someone/project.git')
    def run(name, changes, args, missing, codex=False):
        case_env = dict(env, **changes)
        result = subprocess.run([sys.executable, str(helper), *args], env=case_env,
                                capture_output=True, text=True, cwd=folder)
        assert result.returncode == int(missing), (name, result)
        output = result.stdout + result.stderr
        assert 'SECRET-FIXTURE' not in output, name
        if missing:
            assert 'gh auth refresh -h github.com -s workflow' in output and 'browser once' in output, name
            assert ('quit and restart Codex' in output) == codex, name
            if codex:
                assert str(helper.parent / 'codex-with-github.py') in output, name
                assert 'session starts' in output, name
        else:
            assert not output, (name, output)
        print('ok: ' + name)
    run('first upload checks active scopes', {}, [], True)
    run('Codex first upload names the absolute restart launcher', {}, ['--codex'], True, True)
    run('Codex founding recognises the session', {'CODEX_THREAD_ID':'fixture'}, [], True, True)
    run('workflow permission is already present', {'STATUS':"Token scopes: 'repo', 'workflow'"}, [], False)
    run('fine-grained token has no readable scopes', {'STATUS':'Token scopes: \nOther diagnostic: unavailable'}, [], False)
    run('failed status is unknown', {'STATUS_EXIT':'1'}, [], False)
    run('SSH origin uses different authentication', {'ORIGIN':'git@github.com:someone/project.git'}, [], False)
    run('SSH protocol before origin exists is unknown', {'ORIGIN':'', 'STATUS':"Git operations protocol: ssh\nToken scopes: 'repo'"}, [], False)
    run('unreadable status stays unknown', {'STATUS':'unreadable'}, [], False)
    run('refused push gives the command even when scopes cannot be read', {'STATUS':'unreadable'}, ['--refused'], True)
    run('refused push in Codex also requires restart', {}, ['--refused', '--codex'], True, True)
PYTEST

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

echo "== Access failures are not called signed out =="

for reason in network permission; do
  case "$reason" in
    network) message='error connecting to api.github.com' ;;
    permission) message='HTTP 403: Resource not accessible by integration' ;;
  esac
  cat >"$WORK/bin/gh" <<SH
#!/usr/bin/env sh
echo '$message' >&2
exit 1
SH
  chmod +x "$WORK/bin/gh"
  out=$(run_check) && code=0 || code=$?
  [ "$code" -ne 0 ] && printf '%s\n' "$out" | grep -q "$reason" \
    && ! printf '%s\n' "$out" | grep -q 'nobody is signed in' \
    && pass "$reason failure blocks founding with the correct recovery" \
    || fail "$reason failure was called signed out or did not block founding: $out"
done

echo "== Authentication cannot be verified inside the session =="
cat >"$WORK/bin/gh" <<'SH'
#!/usr/bin/env sh
echo 'HTTP 401: Requires authentication' >&2
exit 1
SH
chmod +x "$WORK/bin/gh"
out=$(run_check) && code=0 || code=$?
[ "$code" -ne 0 ] && printf '%s\n' "$out" | grep -q 'GH_TOKEN' \
  && ! printf '%s\n' "$out" | grep -q 'nobody is signed in' \
  && pass "authentication refusal asks about credential sources without claiming sign-out" \
  || fail "authentication refusal skipped credential diagnosis: $out"

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

echo "== A whole copy that still points at the kit's own repository =="

# Founding from a whole copy of the kit can keep the kit's `origin`. The GitHub
# tool would then open the person's pieces on the kit's repository, so the
# report says so and skips the lookups, and founding asks for their own. It
# does not stop founding. A fork under another owner is the person's own and
# is left alone. The stand-in logs every call, so a lookup made anyway shows.
write_logging_gh() {
  cat >"$WORK/bin/gh" <<SH
#!/usr/bin/env sh
echo "\$*" >> "$WORK/gh.log"
case "\$1 \$2" in
  "auth status") exit 0 ;;
  "repo view") echo '$1' ;;
  *) echo '{}' ;;
esac
SH
  chmod +x "$WORK/bin/gh"
}
kit_case() {
  # kit_case <description> <origin url> <what gh reports> <kit|not-kit>
  project="$WORK/copy-$(printf '%s' "$1" | tr -c 'a-z' '-')"
  mkdir -p "$project"
  git -C "$project" init -q
  [ -z "$2" ] || git -C "$project" remote add origin "$2"
  write_logging_gh "$3"
  : > "$WORK/gh.log"
  out=$(cd "$project" && PATH="$WORK/bin" HOME="$HOME" "$CHECK" 2>&1) && code=0 || code=$?
  [ "$code" -eq 0 ] || fail "$1: the report stopped founding with $code"
  if [ "$4" = kit ]; then
    printf '%s\n' "$out" | grep -q "still points at the kit's own repository, gwpicard/ai-build-kit: no piece is opened there and nothing is pushed there" \
      && ! printf '%s\n' "$out" | grep -q "Issues are switched\|Labels can" \
      && pass "$1: the report names the kit's repository and skips its lookups" \
      || fail "$1: the kit's repository was not caught"
    # Where `origin` names the kit, the report must not ask GitHub at all.
    if [ -n "$2" ]; then
      grep -q "repo view" "$WORK/gh.log" \
        && fail "$1: the report asked GitHub about the kit's repository anyway" \
        || pass "$1: the report asks GitHub nothing about it"
    fi
  else
    printf '%s\n' "$out" | grep -q "kit's own repository" \
      && fail "$1: a repository of the person's own was taken for the kit's" \
      || pass "$1: the person's own repository is left alone"
  fi
}
KIT_JSON='{"nameWithOwner":"gwpicard/ai-build-kit","hasIssuesEnabled":true,"viewerPermission":"ADMIN"}'
OWN_JSON='{"nameWithOwner":"someone/ai-build-kit","hasIssuesEnabled":true,"viewerPermission":"ADMIN"}'
# Where the origin names the kit, the stand-in reports a neutral name, so only
# the origin match can catch it. The one case with no origin is the only one
# that leans on the name GitHub reports.
NEUTRAL_JSON='{"nameWithOwner":"someone/project","hasIssuesEnabled":true,"viewerPermission":"ADMIN"}'
kit_case "an https origin" "https://github.com/gwpicard/ai-build-kit.git" "$NEUTRAL_JSON" kit
kit_case "an ssh origin in capitals" "git@github.com:GWPicard/AI-Build-Kit.git" "$NEUTRAL_JSON" kit
kit_case "an origin with no .git" "https://github.com/gwpicard/ai-build-kit" "$NEUTRAL_JSON" kit
kit_case "a name only GitHub reports" "" "$KIT_JSON" kit
kit_case "a fork under another owner" "https://github.com/someone/ai-build-kit.git" "$OWN_JSON" not-kit
kit_case "a name that only starts like the kit's" "https://github.com/gwpicard/ai-build-kit-notes.git" '{"nameWithOwner":"gwpicard/ai-build-kit-notes","hasIssuesEnabled":true,"viewerPermission":"ADMIN"}' not-kit
write_gh 0 '{"nameWithOwner":"someone/project","hasIssuesEnabled":true,"viewerPermission":"ADMIN"}'

echo "== The tools a recipe's checks run =="

# A recipe names the command-line tools its launch checks run. They are asked
# for only when a recipe is named, and a missing one stops founding, since the
# chosen recipe cannot launch without it. A project that uses no recipe needs
# none of them. The real recipes are read where they are, on the menu or still
# waiting for their real run.
write_gh 0 '{"nameWithOwner":"someone/project","hasIssuesEnabled":true,"viewerPermission":"ADMIN"}'
out=$(run_check) && code=0 || code=$?
printf '%s\n' "$out" | grep -q "launch checks" \
  && fail "a project that names no recipe was asked about recipe tools" \
  || pass "with no recipe named, no recipe tool is asked about"

printf '%s\n' 'Fits: a test' 'Command-line tools: git, stand-in-deploy-tool' > "$WORK/recipe.md"
out=$(PATH="$WORK/bin" HOME="$HOME" "$CHECK" --recipe "$WORK/recipe.md" 2>&1) && code=0 || code=$?
[ "$code" -ne 0 ] \
  && pass "a missing recipe tool stops founding" \
  || fail "a missing recipe tool returned 0"
printf '%s\n' "$out" | grep -q "^git is ready: the recipe's launch checks run it" \
  && pass "it reports a recipe tool that is ready" \
  || fail "the ready recipe tool line is missing"
printf '%s\n' "$out" | grep -q "^stand-in-deploy-tool is missing: .*Step: install it" \
  && pass "it names the missing recipe tool and the step to take" \
  || fail "the missing recipe tool line is missing"

rm -f "$WORK/bin/gh"
out=$(PATH="$WORK/bin" HOME="$HOME" "$CHECK" --recipe "$WORK/recipe.md" 2>&1) && code=0 || code=$?
[ "$code" -ne 0 ] && printf '%s\n' "$out" | grep -q "GitHub command line tool is missing" \
  && pass "naming a recipe does not hide a missing founding tool" \
  || fail "a recipe hid the missing GitHub command line tool"
write_gh 0 '{"nameWithOwner":"someone/project","hasIssuesEnabled":true,"viewerPermission":"ADMIN"}'

# Stand-ins for every tool the real recipes name, so each is found ready.
for tool in vercel supabase docker psql curl; do
  printf '#!/usr/bin/env sh\nexit 0\n' > "$WORK/bin/$tool"
  chmod +x "$WORK/bin/$tool"
done
for name in nextjs-supabase-on-vercel nextjs-supabase-on-coolify; do
  recipe="$ROOT/skills/setup-hosting/recipes/$name"
  [ -f "$recipe/recipe.md" ] || recipe="$ROOT/tests/recipes-awaiting-run/$name"
  [ -f "$recipe/recipe.md" ] || { fail "$name is neither on the menu nor waiting"; continue; }
  out=$(PATH="$WORK/bin" HOME="$HOME" "$CHECK" --recipe "$recipe" 2>&1) && code=0 || code=$?
  [ "$code" -eq 0 ] || fail "$name stopped founding with every tool ready: $out"
  for tool in supabase docker psql curl git; do
    printf '%s\n' "$out" | grep -q "^$tool is ready" || fail "$name's report says nothing about $tool"
  done
  pass "$name's tools are each reported ready"
done
for tool in vercel supabase docker psql curl; do rm -f "$WORK/bin/$tool"; done

echo "== The working conditions founding needs =="

# --conditions is founding's verdict. A stand-in for the GitHub command line tool
# answers the calls it makes, each shaped by one setting, and logs every call so
# a case can say what was asked. The verdicts are present, missing and could not
# check. Only missing stops founding.
cat >"$WORK/bin/gh" <<'PY'
#!/usr/bin/env python3
import json, os, sys
a = sys.argv[1:]
open(os.environ["GH_LOG"], "a").write(" ".join(a) + "\n")
get = lambda k, d="": os.environ.get(k, d)
def out(text, code=0):
    (sys.stdout if code == 0 else sys.stderr).write(text + "\n"); sys.exit(code)
if a[:2] == ["auth", "status"]:
    sys.exit(1 if get("GH_SIGNED_OUT") else 0)
if a[:2] == ["repo", "view"]:
    if get("GH_REPO") == "none":
        out("no git remotes found", 1)
    if get("GH_REPO") == "refused":
        out("HTTP 403: Resource not accessible by integration", 1)
    if get("GH_REPO") == "network":
        out("error connecting to api.github.com", 1)
    out(json.dumps({"nameWithOwner": "someone/project", "viewerPermission": "ADMIN",
                    "hasIssuesEnabled": get("GH_ISSUES", "true") == "true"}))
if a[:2] == ["label", "create"]:
    sys.exit(0)
write = get("GH_WRITE", "ok")
if a[:2] == ["issue", "create"]:
    if write == "refused": out("HTTP 403: Resource not accessible by integration", 1)
    if write == "network": out("error connecting to api.github.com", 1)
    out("https://github.com/someone/project/issues/7")
if a[:2] == ["issue", "close"]:
    sys.exit(1 if write == "noclose" else 0)
if a[:2] == ["issue", "edit"]:
    sys.exit(0)
if a[:1] == ["api"]:
    method = a[a.index("-X") + 1] if "-X" in a else "GET"
    path = [x for x in a[1:] if "/" in x or x == "user"][0]
    protect = get("GH_PROTECT", "ok")
    if path == "user":
        if not get("GH_LOGIN", "someone"): out("HTTP 401: Bad credentials", 1)
        out(json.dumps({"login": get("GH_LOGIN", "someone"),
                        "plan": {"name": "free" if protect == "nomain-free" else "pro"}}))
    if path == "repos/someone/project":
        if protect == "nomain-unknown": out("HTTP 404: Not Found", 1)
        out(json.dumps({"private": protect != "nomain-public",
                        "owner": {"login": "someone", "type": "User"}}))
    if path.endswith("/branches/main"):
        if protect == "branch-read": out("HTTP 503: Service unavailable", 1)
        if protect == "read-admin": out("HTTP 403: Must have admin rights to Repository.", 1)
        if protect.startswith("nomain"): out("HTTP 404: Branch not found", 1)
        out('{"name": "main"}')
    if path.endswith("/protection") and method == "GET":
        if protect == "network": out("connection timed out", 1)
        if protect == "protection-read": out("HTTP 503: Service unavailable", 1)
        if protect == "fallback-read":
            calls = open(os.environ["GH_LOG"]).read().count("api -X GET " + path + "\n")
            if calls > 1: out("HTTP 503: Service unavailable", 1)
            out('{"required_status_checks":null,"enforce_admins":{"enabled":false}}')
        out("HTTP 404: Branch not protected", 1)
    if path.endswith("/protection/required_status_checks/contexts") and method == "POST":
        if protect == "fallback-read": out("HTTP 404: Not Found", 1)
    if path.endswith("/protection") and method == "PUT":
        sys.stdin.read()
        if protect == "plan": out("HTTP 403: Upgrade to GitHub Pro or make this repository public to enable this feature.", 1)
        if protect == "admin": out("HTTP 403: Must have admin rights to Repository.", 1)
        out("{}")
out("stand-in: unmodelled call: " + " ".join(a), 1)
PY
chmod +x "$WORK/bin/gh"
GH_LOG="$WORK/conditions.log"
export GH_LOG

# conditions <description> <expected exit: 0 or 1> <line pattern> [settings and arguments]
# The settings go to the stand-in for this run only. Arguments after -- go to
# the report.
conditions() {
  what=$1 want=$2 line=$3
  shift 3
  settings=""
  while [ "$#" -gt 0 ] && [ "$1" != -- ]; do settings="$settings $1"; shift; done
  [ "$#" -eq 0 ] || shift
  : >"$GH_LOG"
  out=$(cd "$WORK/plain" && env $settings PATH="$WORK/bin" HOME="$HOME" "$CHECK" --conditions "$@" 2>&1) && code=0 || code=$?
  if [ "$code" -eq "$want" ] && printf '%s\n' "$out" | grep -q "$line"; then
    pass "$what"
  else
    fail "$what: exit $code, wanted $want and a line matching '$line': $out"
  fi
}

conditions "every condition holding lets founding finish" 0 "^All requirements for founding are met"
for line in "^present: The repository someone/project has issues switched on" \
  "^present: This session can open, close and label issues" \
  "^present: Branch protection is set on main" \
  "^could not check: No recipe is chosen" \
  "^review identity: shared\. .*recorded as unverified"; do
  printf '%s\n' "$out" | grep -q "$line" || fail "the clean run lacks '$line': $out"
done
grep -q "^issue create " "$GH_LOG" && grep -q "^issue close 7 " "$GH_LOG" \
  && grep -q "^issue edit 7 .*--add-label skip" "$GH_LOG" \
  && grep -q "^api -X PUT repos/someone/project/branches/main/protection" "$GH_LOG" \
  && pass "it opens, closes and labels one test issue, and sets protection on main" \
  || fail "the write probe or protection call is missing: $(cat "$GH_LOG")"

: >"$GH_LOG"
run_check >/dev/null 2>&1 || true
grep -q "^issue \|PUT" "$GH_LOG" \
  && fail "the report without --conditions wrote to GitHub: $(cat "$GH_LOG")" \
  || pass "without --conditions the report writes nothing"

conditions "no repository stops founding" 1 "^missing: No GitHub repository holds this project" GH_REPO=none
conditions "a refused repository read is could not check, not a missing repository" 0 "^could not check: GitHub did not let this session read the repository" GH_REPO=refused
printf '%s\n' "$out" | grep -q "No GitHub repository holds" && fail "a refused read was reported as no repository: $out" || true
conditions "an unreachable repository read is could not check" 0 "^could not check: GitHub could not be reached to read the repository" GH_REPO=network
conditions "issues switched off stop founding" 1 "^missing: The repository someone/project has issues switched off. Step:" GH_ISSUES=false
grep -q "^issue create" "$GH_LOG" && fail "it opened a test issue with issues off" || true
conditions "a refused issue write stops founding" 1 "^missing: This session cannot open issues on someone/project. Step:" GH_WRITE=refused
conditions "an issue that cannot be closed or labelled stops founding" 1 "^missing: .*could not close it or label it skip" GH_WRITE=noclose
conditions "an unreachable issue write is could not check, not a stop" 0 "^could not check: GitHub could not be reached to open a test issue" GH_WRITE=network
conditions "the plan limit on protection lets founding finish with a named condition" 0 "^protection.*unavailable-private-free" GH_PROTECT=plan
grep -Fxq 'branch-protection|someone/project|main|unavailable-private-free' "$WORK/plain/.ai-build-kit-maintenance" \
  && pass "the working conditions check records the Free private condition" \
  || fail "the working conditions check left no Free private record"
conditions "protection refused for want of admin rights stops founding" 1 "^missing: .*admin rights.*Step: ask the repository's owner" GH_PROTECT=admin
conditions "an unreachable protection call is could not check" 0 "^could not check: .*protection could not be read" GH_PROTECT=network
conditions "an unreadable branch is could not check" 0 "^could not check: .*could not read the branch" GH_PROTECT=branch-read
conditions "an unreadable protection answer is could not check" 0 "^could not check: .*protection could not be read" GH_PROTECT=protection-read
conditions "an unreadable existing-check fallback is could not check" 0 "^could not check: .*existing required checks could not be read" GH_PROTECT=fallback-read
if grep -Eq '^api -X (PUT|PATCH)' "$GH_LOG"; then
  fail "the unreadable fallback replaced existing protection: $(cat "$GH_LOG")"
else
  pass "an unreadable fallback leaves existing protection alone"
fi
conditions "a branch read refused for want of admin rights still stops founding" 1 "^missing: .*admin rights" GH_PROTECT=read-admin
conditions "no main yet on a public repository counts as protection that can be set" 0 "^present: Branch protection can be set: the first upload sets it" GH_PROTECT=nomain-public
conditions "no main yet on a private repository on GitHub Free lets founding finish" 0 "^protection.*unavailable-private-free" GH_PROTECT=nomain-free
conditions "no main yet and an unreadable plan is could not check" 0 "^could not check: main does not exist yet" GH_PROTECT=nomain-unknown
conditions "signed out stops founding" 1 "nobody is signed in" GH_SIGNED_OUT=1
conditions "a named second reviewer login is reported as separate" 0 "^review identity: separate\. The agent acts as someone and the reviewer as second-person" -- --reviewer second-person
conditions "an unreadable login is a report, not a stop" 0 "^review identity: could not check" GH_LOGIN=

printf '%s\n' 'Fits: a test' 'Command-line tools: git, stand-in-host-tool' > "$WORK/hosted.md"
conditions "a recipe tool that is missing stops founding" 1 "^stand-in-host-tool is missing: .*Step: install it" -- --recipe "$WORK/hosted.md"
printf '#!/usr/bin/env sh\nexit 0\n' > "$WORK/bin/stand-in-host-tool"
chmod +x "$WORK/bin/stand-in-host-tool"
conditions "a recipe whose tools are all here passes" 0 "^stand-in-host-tool is ready" -- --recipe "$WORK/hosted.md"
printf '%s\n' "$out" | grep -q "^could not check: The recipe names no sign-in .*host and database" \
  && pass "sign-ins, host and database access beyond the recipe's tools are could not check" \
  || fail "the host and database line is missing: $out"

echo
if [ "$FAIL" -eq 0 ]; then
  echo "check-tooling.sh: all checks passed"
else
  echo "check-tooling.sh: FAILED" >&2
fi
exit "$FAIL"
