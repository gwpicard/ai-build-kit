#!/usr/bin/env sh
# secrets-gates.sh: exercise the secret read gate, result redactor and scanner.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
FOUNDATION="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "ok: $1"; }
export SCAN_SECRETS_DISABLE_GITLEAKS=1
export SECRET_TEST_VALUE="kit-test-$(python3 -c 'import secrets; print(secrets.token_hex(12))')"

guard() { printf '%s' "$1" | CLAUDE_PROJECT_DIR="$WORK/project" sh "$FOUNDATION/guard-secrets.sh" >"$WORK/guard-out" 2>"$WORK/guard-err"; }
guard_event() { python3 - "$1" "$2" "$3" <<'PY' | CLAUDE_PROJECT_DIR="$WORK/project" sh "$FOUNDATION/guard-secrets.sh" >"$WORK/guard-out" 2>"$WORK/guard-err"
import json, sys
tool, key, value = sys.argv[1:]
print(json.dumps({"hook_event_name":"PreToolUse", "tool_name":tool,
                  "tool_input":{key:value}}))
PY
}
redact() { printf '%s' "$1" | CLAUDE_PROJECT_DIR="$WORK/project" sh "$FOUNDATION/redact-secrets.sh" >"$WORK/redact-out" 2>"$WORK/redact-err"; }

mkdir -p "$WORK/project/src/nested"
printf 'export SERVICE_TOKEN="%s" # note\nSHORT=abc\nNEXT_PUBLIC_LABEL=browser-visible-value\nNODE_ENV=development\nSITE_URL=http://localhost:3000\nMULTI="-----BEGIN\n%s\nEND-----"\n' "$SECRET_TEST_VALUE" "$SECRET_TEST_VALUE" > "$WORK/project/src/nested/.env.production"
MULTILINE_VALUE="multi-$(python3 -c 'import secrets;print(secrets.token_hex(12))')"
printf 'MULTI_TOKEN="first line\n%s\nlast line"\n' "$MULTILINE_VALUE" >> "$WORK/project/src/nested/.env.production"
MULTILINE_FULL=$(printf 'first line\n%s\nlast line' "$MULTILINE_VALUE")
printf 'SERVICE_TOKEN=placeholder-value\n' > "$WORK/project/.env.example"
printf '%s\n' "$SECRET_TEST_VALUE" > "$WORK/project/db-password"
cp "$ROOT/.agents/skills/setup-ai-build-kit/templates/masterplan.md" "$WORK/project/masterplan.md"
runner_status=0
sh "$ROOT/.agents/skills/setup-hosting/scripts/run-recipe.sh" --project "$WORK/project" \
  --set "DB_PASSWORD_FILE=$WORK/project/db-password" none >"$WORK/runner-out" 2>&1 || runner_status=$?
grep -qx "Password files: $WORK/project/db-password" "$WORK/project/masterplan.md" || fail "setup-hosting did not record the password file"

python3 - "$FOUNDATION/claude-settings.json" <<'PY'
import json,sys
s=json.load(open(sys.argv[1]))
denies=s["permissions"]["deny"]
for rule in ("Read(**/.env)","Read(**/.env.local)","Read(**/.env.*.local)",
             "Read(**/.env.production)","Read(**/.env.development)"):
    assert rule in denies, rule
assert "Read(**/.env.example)" not in denies
assert denies.index("Read(**/.env.*)") < denies.index("Read(!**/.env.example)")
asks=s["permissions"]["ask"]
for name in ("GATE_READ","PREVIEW_HEALTH"):
    for quote in ('', '"', "'"):
        assert f"Bash(*{name}={quote}yes{quote}*)" in asks
PY
pass "deny rules cover named .env files and ask rules cover quoted yes values"

mkdir -p "$WORK/missing-hook"
cp "$FOUNDATION/guard-secrets.sh" "$WORK/missing-hook/guard-secrets.sh"
if printf '{}' | sh "$WORK/missing-hook/guard-secrets.sh" >"$WORK/missing-out" 2>"$WORK/missing-err"; then
  fail "guard wrapper ran without its Python hook"
else code=$?; [ "$code" -eq 2 ] && grep -q 'could not run' "$WORK/missing-err" \
  && pass "guard wrapper fails closed when its Python file is missing" || fail "missing guard hook returned $code"; fi
cp "$FOUNDATION/redact-secrets.sh" "$WORK/missing-hook/redact-secrets.sh"
if printf '{}' | sh "$WORK/missing-hook/redact-secrets.sh" Bash >"$WORK/missing-out" 2>"$WORK/missing-err"; then
  fail "redactor wrapper ran without its Python hook"
else code=$?; [ "$code" -eq 2 ] && grep -q 'could not run' "$WORK/missing-err" \
  && pass "redactor wrapper reports could not run when its Python file is missing" \
  || fail "missing redactor hook returned $code"; fi
mkdir -p "$WORK/no-python"
ln -s "$(command -v cat)" "$WORK/no-python/cat"
ln -s "$(command -v sed)" "$WORK/no-python/sed"
for tool in Bash Grep Read; do
  event=$(python3 - "$tool" <<'PY'
import json,sys
print(json.dumps({"tool_name":sys.argv[1],"tool_response":{}}))
PY
)
  status=0
  printf '%s' "$event" | PATH="$WORK/no-python" /bin/sh "$FOUNDATION/redact-secrets.sh" >"$WORK/missing-out" 2>"$WORK/missing-err" || status=$?
  [ "$status" -eq 2 ] && python3 - "$WORK/missing-out" "$tool" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))["hookSpecificOutput"]
assert r["hookEventName"]=="PostToolUse"
o=r["updatedToolOutput"]
if sys.argv[2]=="Bash": assert o=={"stdout":"[output hidden: the secret check could not run]","stderr":"","interrupted":False}
elif sys.argv[2]=="Grep": assert o=={"numFiles":0,"filenames":[]}
else: assert o["type"]=="text" and "hidden" in o["file"]["content"]
PY
  [ "$status" -eq 2 ] && pass "missing Python returns a fixed $tool result in the hook envelope" || fail "missing Python fallback failed for $tool"
done

echo "== Read and Grep guard =="
for path in .env .env.local .env.production src/.env.staging .env.production.local; do
  guard_event Read file_path "$WORK/project/$path" && grep -q '"permissionDecision":"deny"' "$WORK/guard-out" \
    && pass "Read refuses $path" || fail "Read did not refuse $path"
done
if redact '{"tool_name":"Read","tool_response":{"type":"unknown","content":"visible secret"}}' && \
  python3 - "$WORK/redact-out" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))["hookSpecificOutput"]["updatedToolOutput"]
assert r["type"]=="unknown"
assert r["content"]=="[tool result hidden because it could not be checked]"
PY
then pass "an unknown Read result keeps its structure and hides every string"; else fail "unknown Read shape leaked text"; fi
guard_event Grep path "$WORK/project/src/nested/.env.production" && grep -q '"permissionDecision":"deny"' "$WORK/guard-out" \
  && pass "Grep refuses a nested .env path" || fail "Grep did not refuse a nested .env path"
for path in .env.example PasswordField.tsx passport.ts compass.svg secretsManager.ts; do
  guard_event Read file_path "$WORK/project/$path" && [ ! -s "$WORK/guard-out" ] \
    && pass "Read allows $path" || fail "Read blocked $path"
done
guard_event Grep path "$WORK/project/src" && [ ! -s "$WORK/guard-out" ] \
  && pass "Grep allows pattern text, including password" || fail "Grep pattern was treated as a path"

echo "== Bash guard: allowed ordinary work =="
for command in \
  'sh .agents/hooks/scan-secrets.sh --all' \
  'sh .agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/scripts/secrets.sh' \
  'live-check.sh --password-file x' \
  'run-recipe.sh --set DB_PASSWORD_FILE=/tmp/db-password' \
  'cp .env.example .env' \
  'echo .env >> .gitignore' \
  'git check-ignore .env .env.local' \
  'vercel env ls' \
  'python3 -m venv env' \
  'ls -la .env' \
  'test -f .env.local' \
  '[ -f .env ]' \
  'git rm --cached .env' \
  'grep .env .gitignore' \
  'python3 -m venv .env' \
  'git commit -m "Mention .env.local handling"' \
  'ls src/env' \
  '/usr/bin/env node x.js' \
  'env NODE_ENV=test npm test' \
  'git commit -m "Update password and env handling"' \
  'git add src/app/reset-password/page.tsx' \
  'supabase secrets list' \
  'grep -R password src'; do
  encoded=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$command")
  guard "$encoded" && [ ! -s "$WORK/guard-out" ] && pass "allows: $command" || fail "blocked ordinary command: $command"
done

echo "== Bash guard: refused reads =="
for command in 'cat .env' 'cat src/nested/.env.production' 'grep x .env.local' 'source .env' 'cat .env*' 'cat <.env' 'env -0' 'printenv -0' 'zsh -c env' 'bash -c env' 'echo `env`' 'echo $(env)'; do
  encoded=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$command")
  guard "$encoded" && grep -q '"permissionDecision":"deny"' "$WORK/guard-out" \
    && pass "refuses: $command" || fail "did not refuse: $command"
done
for key in glob path; do
  guard_event Grep "$key" '.env.local' && grep -q '"permissionDecision":"deny"' "$WORK/guard-out" \
    && pass "Grep refuses .env file $key" || fail "Grep allowed .env file $key"
done
for command in 'env' 'env|sort' '(env)' 'sh -c env' 'printenv' 'export -p' 'set' 'declare -p' 'declare -x' 'typeset -p' 'compgen -v'; do
  encoded=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$command")
  guard "$encoded" && grep -q '"permissionDecision":"deny"' "$WORK/guard-out" \
    && pass "refuses environment dump: $command" || fail "did not refuse environment dump: $command"
done
recorded="$WORK/project/db-password"
encoded=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Read","tool_input":{"file_path":sys.argv[1]}}))' "$recorded")
guard "$encoded" && grep -q '"permissionDecision":"deny"' "$WORK/guard-out" \
  && pass "Read refuses the recorded password path" || fail "Read allowed the recorded password path"
encoded=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":"run-recipe.sh --set DB_PASSWORD_FILE="+sys.argv[1]}}))' "$recorded")
guard "$encoded" && [ ! -s "$WORK/guard-out" ] && pass "kit script can receive the recorded password path" \
  || fail "guard blocked a kit script password-file argument"
guard '{broken' && code=0 || code=$?
[ "$code" -eq 2 ] && pass "guard reports could not run on malformed input" || fail "guard returned $code for malformed input"

echo "== Claude Code result redaction =="
# Fixture shapes copied from the installed Claude Code SDK types:
# /Users/guillaumepicard/.nvm/versions/node/v22.14.0/lib/node_modules/@anthropic-ai/claude-code/sdk-tools.d.ts
for tool in Bash Read Grep; do
  case "$tool" in
    Bash) response=$(python3 - "$SECRET_TEST_VALUE" <<'PY'
import json,sys
print(json.dumps({"stdout":"output " + sys.argv[1],"stderr":"","interrupted":False,
                  "isImage":False,"backgroundTaskId":"task-1"}))
PY
);;
    Read) response=$(python3 - "$SECRET_TEST_VALUE" <<'PY'
import json,sys
print(json.dumps({"type":"text","file":{"filePath":"src/nested/.env.production",
  "content":"value=" + sys.argv[1],"numLines":1,"startLine":1,"totalLines":1}}))
PY
);;
    Grep) response=$(python3 - "$SECRET_TEST_VALUE" <<'PY'
import json,sys
print(json.dumps({"mode":"content","numFiles":1,"filenames":["src/nested/.env.production"],
                  "content":"value=" + sys.argv[1],"numLines":1,"numMatches":1}))
PY
);;
  esac
  event=$(python3 - "$tool" "$response" <<'PY'
import json,sys
print(json.dumps({"hook_event_name":"PostToolUse","tool_name":sys.argv[1],"tool_response":json.loads(sys.argv[2])}))
PY
)
  if redact "$event" && python3 - "$WORK/redact-out" "$tool" "$SECRET_TEST_VALUE" <<'PY'
import json,sys
outer=json.load(open(sys.argv[1]))
r=outer["hookSpecificOutput"]["updatedToolOutput"]
tool,needle=sys.argv[2:]
assert isinstance(r,dict) and needle not in json.dumps(r)
assert "SERVICE_TOKEN hidden" in json.dumps(r)
if tool=="Read": assert r["type"]=="text" and r["file"]["numLines"]==1
if tool=="Grep": assert r["numFiles"]==1 and isinstance(r["filenames"],list) and "[SERVICE_TOKEN hidden]" in r["content"]
if tool=="Bash": assert r["interrupted"] is False and r["backgroundTaskId"]=="task-1"
PY
  then pass "$tool result is redacted in its own object shape"; else fail "$tool result lost its shape or value"; fi
done
image_event=$(python3 - "$SECRET_TEST_VALUE" <<'PY'
import json,sys
print(json.dumps({"tool_name":"Read","tool_response":{"type":"image","file":{"base64":sys.argv[1],"type":"image/png","originalSize":1}}}))
PY
)
if redact "$image_event" && [ ! -s "$WORK/redact-out" ]; then
  pass "unchanged Read images do not replace another hook's output"
else
  fail "Read image result was changed"
fi
if redact "$(python3 - "$SECRET_TEST_VALUE" "$MULTILINE_FULL" <<'PY'
import json,sys
print(json.dumps({"tool_name":"Bash","tool_response":{"stdout":"x="+sys.argv[1]+" SHORT=abc browser-visible-value NODE_ENV=development SITE_URL=http://localhost:3000 multi="+sys.argv[2],"stderr":"password="+sys.argv[1],"interrupted":False}}))
PY
)" && python3 - "$WORK/redact-out" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))["hookSpecificOutput"]["updatedToolOutput"]
assert "SHORT=abc" in r["stdout"]
assert "browser-visible-value" in r["stdout"]
assert "NODE_ENV=development" in r["stdout"]
assert "SITE_URL=http://localhost:3000" in r["stdout"]
assert "[SERVICE_TOKEN hidden]" in r["stdout"]
assert "multi-" not in r["stdout"]
PY
then pass "only named secret values are hidden, including multiline values"; else fail "secret name and multiline handling was wrong"; fi
identity=$(python3 - <<'PY'
import json
print(json.dumps({"tool_name":"Bash","tool_response":{"stdout":"ordinary output","stderr":"","interrupted":False}}))
PY
)
if redact "$identity" && ! grep -q 'updatedToolOutput' "$WORK/redact-out"; then
  pass "unchanged results do not replace another hook's output"
else fail "the redactor returned an unchanged result"; fi
if redact "$(python3 - "$SECRET_TEST_VALUE" <<'PY'
import json,sys
print(json.dumps({"tool_name":"Read","tool_response":{"type":"text","file":{"filePath":"x","content":sys.argv[1],"numLines":1,"startLine":1,"totalLines":1}}}))
PY
)" >/dev/null; then pass "nested .env values are included"; else fail "nested .env redaction failed"; fi

mkdir -p "$WORK/broken"
printf 'Password files: %s/missing\n' "$WORK/broken" > "$WORK/broken/masterplan.md"
for tool in Read Grep; do
  input=$(python3 - "$tool" <<'PY'
import json,sys
t=sys.argv[1]
r=({"type":"text","file":{"filePath":"x","content":"sensitive","numLines":1,"startLine":1,"totalLines":1}}
   if t=="Read" else {"mode":"content","numFiles":1,"filenames":["secret.txt"],"content":"sensitive"})
print(json.dumps({"tool_name":t,"tool_response":r}))
PY
)
  if printf '%s' "$input" | CLAUDE_PROJECT_DIR="$WORK/broken" sh "$FOUNDATION/redact-secrets.sh" >"$WORK/redact-out" 2>/dev/null && \
    python3 - "$WORK/redact-out" "$tool" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))["hookSpecificOutput"]["updatedToolOutput"]
assert isinstance(r,dict)
assert "hidden" in json.dumps(r)
assert "sensitive" not in json.dumps(r)
assert (r.get("type")=="text" if sys.argv[2]=="Read" else r.get("numFiles")==1)
PY
  then pass "$tool read failure hides text and preserves its object shape"; else fail "$tool fail-closed shape failed"; fi
done

echo "== Git scan =="
PROJECT="$WORK/git-project"
mkdir -p "$PROJECT/.agents/hooks"
cp "$FOUNDATION/scan-secrets.sh" "$PROJECT/.agents/hooks/scan-secrets.sh"
cp "$FOUNDATION/scan-secrets.py" "$PROJECT/.agents/hooks/scan-secrets.py"
git init -q -b main "$PROJECT"
git -C "$PROJECT" config user.name Rehearsal
git -C "$PROJECT" config user.email rehearsal@example.invalid
git -C "$PROJECT" config commit.gpgsign false
echo clean > "$PROJECT/app.txt"
git -C "$PROJECT" add app.txt && git -C "$PROJECT" commit -q -m clean
BASE=$(git -C "$PROJECT" rev-parse HEAD)
for shape in sbp sb_secret anthropic openai slack google stripe githubpat aws pem servicejwt; do
  case "$shape" in
    sbp) line="sbp_$(python3 -c 'import secrets;print(secrets.token_urlsafe(24))')";;
    sb_secret) line="sb_secret_$(python3 -c 'import secrets;print(secrets.token_urlsafe(24))')";;
    anthropic) line="sk-ant-$(python3 -c 'import secrets;print(secrets.token_urlsafe(24))')";;
    openai) line="sk-proj-$(python3 -c 'import secrets;print(secrets.token_urlsafe(24))')";;
    slack) line="xoxb-$(python3 -c 'import secrets;print(secrets.token_hex(24))')";;
    google) line="AIza$(python3 -c 'import secrets;print(secrets.token_urlsafe(28))')";;
    stripe) line="sk_live_$(python3 -c 'import secrets;print(secrets.token_hex(16))')";;
    githubpat) line="github_pat_$(python3 -c 'import secrets;print(secrets.token_hex(32))')";;
    aws) line="AKIA1234567890ABCDEF";;
    pem) line="-----BEGIN ENCRYPTED PRIVATE KEY-----";;
    servicejwt) line="$(python3 - <<'PY'
import base64,json,secrets
enc=lambda b:base64.urlsafe_b64encode(b).decode().rstrip('=')
print(enc(b'{"alg":"HS256"}')+'.'+enc(b'{"role":"service_role"}')+'.'+enc(secrets.token_bytes(24)))
PY
)";;
  esac
  printf '%s\n' "$line" > "$PROJECT/$shape.txt"
  git -C "$PROJECT" add "$shape.txt" && git -C "$PROJECT" commit -q -m "fixture $shape"
  if (cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=HEAD~1..HEAD") >"$WORK/scan-out" 2>&1; then
    fail "scanner missed $shape"
  else
    code=$?
    [ "$code" -eq 1 ] && grep -q 'possible secret in commit .* file ' "$WORK/scan-out" && ! grep -Fq -- "$line" "$WORK/scan-out" \
      && pass "scanner catches $shape and names its file without the value" || fail "scanner returned $code for $shape"
  fi
done
for prefix in ghp_ gho_ ghs_; do
  value="$prefix$(python3 -c 'import secrets;print(secrets.token_hex(24))')"
  printf '%s\n' "$value" > "$PROJECT/github-token.txt"
  git -C "$PROJECT" add github-token.txt && git -C "$PROJECT" commit -q -m "fixture ${prefix%_}"
  if (cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=HEAD~1..HEAD") >"$WORK/scan-out" 2>&1; then
    fail "scanner missed $prefix"
  else code=$?; [ "$code" -eq 1 ] && ! grep -Fq -- "$value" "$WORK/scan-out" \
    && pass "scanner catches $prefix without printing it" || fail "scanner returned $code for $prefix"; fi
done
for header in 'RSA PRIVATE KEY' 'EC PRIVATE KEY' 'DSA PRIVATE KEY' 'OPENSSH PRIVATE KEY' 'ENCRYPTED PRIVATE KEY' 'PGP PRIVATE KEY BLOCK'; do
  printf '%s\n' "-----BEGIN $header-----" > "$PROJECT/private-key.txt"
  git -C "$PROJECT" add private-key.txt && git -C "$PROJECT" commit -q -m pem-form
  if (cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=HEAD~1..HEAD") >"$WORK/scan-out" 2>&1; then
    fail "scanner missed PEM form $header"
  else code=$?; [ "$code" -eq 1 ] && pass "scanner catches PEM form $header" || fail "scanner returned $code for PEM form $header"; fi
done
printf 'SERVICE_TOKEN=%s\nNODE_ENV=development\nSITE_URL=http://localhost:3000\n' "$SECRET_TEST_VALUE" > "$PROJECT/.env"
printf 'const config = { NODE_ENV: "development", SITE_URL: "http://localhost:3000" };\nconst leak = "%s";\n' "$SECRET_TEST_VALUE" > "$PROJECT/next.config.js"
git -C "$PROJECT" add next.config.js && git -C "$PROJECT" commit -q -m env-shapes
if (cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=HEAD~1..HEAD") >"$WORK/scan-out" 2>&1; then
  fail "scanner missed a value whose environment name says secret"
else code=$?; [ "$code" -eq 1 ] && ! grep -Fq -- "$SECRET_TEST_VALUE" "$WORK/scan-out" \
  && pass "named secrets trigger while ordinary env values in next.config.js stay clear" \
  || fail "secret-name classification returned $code"; fi
rm "$PROJECT/.env"
printf 'const config = { NODE_ENV: "development", SITE_URL: "http://localhost:3000" };\n' > "$PROJECT/next.config.js"
git -C "$PROJECT" add next.config.js && git -C "$PROJECT" commit -q -m local-config
(cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=HEAD~1..HEAD") \
  && pass "development environment and localhost URL values do not trigger the scan" \
  || fail "ordinary environment values were treated as secrets"
printf 'SHORT=abc\nNEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiJ9.signature\n' > "$PROJECT/public.env"
PUBLIC_BASE=$(git -C "$PROJECT" rev-parse HEAD)
git -C "$PROJECT" add public.env && git -C "$PROJECT" commit -q -m public-values
(cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=HEAD~1..HEAD") \
  && pass "short values and the public Supabase anon JWT stay clear" || fail "scanner treated public values as secrets"
if (cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=$PROJECT/missing..HEAD") >"$WORK/scan-out" 2>&1; then
  pass "a missing base falls back to available history"
else code=$?; [ "$code" -eq 1 ] && pass "a missing base scans available history and can find a secret" \
  || fail "missing base fallback returned $code"; fi
printf 'APP_TOKEN=%s\n' "literal-$(python3 -c 'import secrets;print(secrets.token_hex(12))')" > "$PROJECT/.env.production"
git -C "$PROJECT" add .env.production && git -C "$PROJECT" commit -q -m literal-env-assignment
rm "$PROJECT/.env.production"
if (cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=HEAD~1..HEAD") >"$WORK/scan-out" 2>&1; then
  fail "scanner missed a named literal in a committed .env file"
else code=$?; [ "$code" -eq 1 ] && grep -q 'possible secret in commit .* file .env.production' "$WORK/scan-out" \
  && ! grep -q 'literal-' "$WORK/scan-out" \
  && pass "scanner catches a named literal in a committed .env file without printing it" \
  || fail "committed .env assignment returned $code"; fi
printf 'const APP_TOKEN = process.env.APP_TOKEN;\n' > "$PROJECT/app-config.js"
git -C "$PROJECT" add app-config.js && git -C "$PROJECT" commit -q -m env-code-expression
(cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=HEAD~1..HEAD") \
  && pass "code expressions that read process.env are not treated as literal assignments" \
  || fail "a process.env expression was treated as a committed secret"
mkdir -p "$WORK/no-git"
if (cd "$WORK/no-git" && sh "$FOUNDATION/scan-secrets.sh" --all) >"$WORK/scan-out" 2>&1; then
  fail "scanner passed without a Git repository"
else code=$?; [ "$code" -eq 2 ] && pass "Git failure returns could not run" || fail "Git failure returned $code"; fi

echo "== Shipped starter scan =="
if sh "$ROOT/.agents/tools/build-release.sh" v0.0.0-secrets-rehearsal "$WORK/release" >"$WORK/release-out" 2>&1; then
  for hook in guard-secrets.sh guard-secrets.py redact-secrets.sh redact-secrets.py scan-secrets.sh scan-secrets.py; do
    [ -f "$WORK/release/.agents/hooks/$hook" ] || fail "starter release is missing .agents/hooks/$hook"
  done
  git init -q -b main "$WORK/release"
  git -C "$WORK/release" config user.name Rehearsal
  git -C "$WORK/release" config user.email rehearsal@example.invalid
  git -C "$WORK/release" config commit.gpgsign false
  git -C "$WORK/release" add . && git -C "$WORK/release" commit -q -m starter
  if (cd "$WORK/release" && sh .agents/hooks/scan-secrets.sh --all); then
    pass "the assembled starter ships all hooks and passes its initial whole-history scan"
  else fail "the assembled starter's initial scan failed"; fi
else fail "release builder could not assemble the starter"; fi

exit "$FAIL"
