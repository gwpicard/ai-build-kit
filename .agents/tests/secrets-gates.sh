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
printf 'export SERVICE_TOKEN="%s" # note\nSHORT=abc\nNEXT_PUBLIC_LABEL=browser-visible-value\nMULTI="-----BEGIN\n%s\nEND-----"\n' "$SECRET_TEST_VALUE" "$SECRET_TEST_VALUE" > "$WORK/project/src/nested/.env.production"
printf 'SERVICE_TOKEN=placeholder-value\n' > "$WORK/project/.env.example"
printf 'DB_PASSWORD_FILE=%s/db-password\n' "$WORK/project" > "$WORK/project/masterplan.md"
printf '%s\n' "$SECRET_TEST_VALUE" > "$WORK/project/db-password"

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

echo "== Read and Grep guard =="
for path in .env .env.local .env.production src/.env.staging .env.production.local; do
  guard_event Read file_path "$WORK/project/$path" && grep -q '"permissionDecision":"deny"' "$WORK/guard-out" \
    && pass "Read refuses $path" || fail "Read did not refuse $path"
done
if redact '{"tool_name":"Read","tool_response":{"type":"unknown","content":"visible secret"}}' && \
  python3 - "$WORK/redact-out" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))["hookSpecificOutput"]["updatedToolOutput"]
assert r["type"]=="[tool result hidden because it could not be checked]"
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
for command in 'cat .env' 'cat src/nested/.env.production' 'grep x .env.local' 'source .env'; do
  encoded=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$command")
  guard "$encoded" && grep -q '"permissionDecision":"deny"' "$WORK/guard-out" \
    && pass "refuses: $command" || fail "did not refuse: $command"
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
if redact "$image_event" && python3 - "$WORK/redact-out" "$SECRET_TEST_VALUE" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))["hookSpecificOutput"]["updatedToolOutput"]
assert r["type"]=="image" and r["file"]["base64"]==sys.argv[2]
PY
then pass "Read image base64 is left unchanged"; else fail "image bytes were altered"; fi
if redact "$(python3 - "$SECRET_TEST_VALUE" <<'PY'
import json,sys
print(json.dumps({"tool_name":"Bash","tool_response":{"stdout":"x="+sys.argv[1]+" SHORT=abc browser-visible-value "+sys.argv[1],"stderr":"password="+sys.argv[1],"interrupted":False}}))
PY
)" && python3 - "$WORK/redact-out" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))["hookSpecificOutput"]["updatedToolOutput"]
assert "SHORT=abc" in r["stdout"]
assert "browser-visible-value" in r["stdout"]
assert "[SERVICE_TOKEN hidden]" in r["stdout"]
PY
then pass "short and NEXT_PUBLIC values stay visible while recorded passwords are hidden"; else fail "short/public/password handling was wrong"; fi
if redact "$(python3 - "$SECRET_TEST_VALUE" <<'PY'
import json,sys
print(json.dumps({"tool_name":"Read","tool_response":{"type":"text","file":{"filePath":"x","content":sys.argv[1],"numLines":1,"startLine":1,"totalLines":1}}}))
PY
)" >/dev/null; then pass "nested .env values are included"; else fail "nested .env redaction failed"; fi

mkdir -p "$WORK/broken"
printf 'DB_PASSWORD_FILE=%s/missing\n' "$WORK/broken" > "$WORK/broken/masterplan.md"
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
    slack) line="xoxb-$(python3 -c 'import secrets;print(secrets.token_urlsafe(24))')";;
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
  if (cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=$BASE..HEAD") >"$WORK/scan-out" 2>&1; then
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
  if (cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=$BASE..HEAD") >"$WORK/scan-out" 2>&1; then
    fail "scanner missed $prefix"
  else code=$?; [ "$code" -eq 1 ] && ! grep -Fq -- "$value" "$WORK/scan-out" \
    && pass "scanner catches $prefix without printing it" || fail "scanner returned $code for $prefix"; fi
done
for header in 'RSA PRIVATE KEY' 'EC PRIVATE KEY' 'DSA PRIVATE KEY' 'OPENSSH PRIVATE KEY' 'ENCRYPTED PRIVATE KEY' 'PGP PRIVATE KEY BLOCK'; do
  printf '%s\n' "-----BEGIN $header-----" > "$PROJECT/private-key.txt"
  git -C "$PROJECT" add private-key.txt && git -C "$PROJECT" commit -q -m pem-form
  if (cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=$BASE..HEAD") >"$WORK/scan-out" 2>&1; then
    fail "scanner missed PEM form $header"
  else code=$?; [ "$code" -eq 1 ] && pass "scanner catches PEM form $header" || fail "scanner returned $code for PEM form $header"; fi
done
printf 'SHORT=abc\nNEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiJ9.signature\n' > "$PROJECT/public.env"
PUBLIC_BASE=$(git -C "$PROJECT" rev-parse HEAD)
git -C "$PROJECT" add public.env && git -C "$PROJECT" commit -q -m public-values
(cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=$PUBLIC_BASE..HEAD") \
  && pass "short values and the public Supabase anon JWT stay clear" || fail "scanner treated public values as secrets"
if (cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=$PROJECT/missing..HEAD") >"$WORK/scan-out" 2>&1; then
  fail "scanner accepted a missing remote commit"
else code=$?; [ "$code" -eq 2 ] && grep -q "remote side's commit is missing locally" "$WORK/scan-out" \
  && pass "a missing remote commit says could not run" || fail "missing remote commit returned $code"; fi

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
