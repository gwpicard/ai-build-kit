#!/usr/bin/env sh
# secrets-gates.sh: exercise the installed read guard, result redactor and Git
# scanner, including the result shapes Claude Code accepts.
#
# Claude's hooks reference documents Bash's object result shape explicitly.
# It documents Read results as line-numbered text in tool-result content and
# Grep results as tool-specific output, but does not give their PostToolUse
# schema. This rehearsal assumes those two built-in results arrive as strings,
# as the documented PostToolBatch tool_result content does. Confirm a live
# PostToolUse Read and Grep capture before treating that assumption as tested.

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

guard() {
  printf '%s' "$1" | sh "$FOUNDATION/guard-secrets.sh" >"$WORK/guard-out" 2>"$WORK/guard-err"
}
redact() {
  CLAUDE_PROJECT_DIR="$WORK/project" printf '%s' "$1" | CLAUDE_PROJECT_DIR="$WORK/project" \
    sh "$FOUNDATION/redact-secrets.sh" >"$WORK/redact-out" 2>"$WORK/redact-err"
}

mkdir -p "$WORK/project"
printf 'SERVICE_TOKEN=%s\n' "$SECRET_TEST_VALUE" > "$WORK/project/.env"
printf 'SERVICE_TOKEN=replace-me\n' > "$WORK/project/.env.example"

echo "== Claude Code read guard =="
if guard '{"hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{"file_path":"/project/.env"}}' && \
   grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"' "$WORK/guard-out"; then
  pass "Read refuses .env"
else fail "Read did not refuse .env"; fi
for secret_path in .env.local .env.production .env.preview.local passwords.txt; do
  if guard "{\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"/project/$secret_path\"}}" && \
     grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"' "$WORK/guard-out"; then
    pass "Read refuses $secret_path"
  else fail "Read did not refuse $secret_path"; fi
done
if guard '{"hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{"file_path":"/project/.env.example"}}' && \
   [ ! -s "$WORK/guard-out" ]; then
  pass "Read allows .env.example"
else fail "Read did not allow .env.example"; fi
if guard '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"cat .env"}}' && \
   grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"' "$WORK/guard-out"; then
  pass "Bash refuses a read of .env"
else fail "Bash did not refuse a read of .env"; fi
if guard '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"cat .env.example"}}' && \
   [ ! -s "$WORK/guard-out" ]; then
  pass "Bash allows .env.example"
else fail "Bash did not allow .env.example"; fi
if guard '{"hook_event_name":"PreToolUse","tool_name":"Grep","tool_input":{"path":"/project/passwords.txt","pattern":"x"}}' && \
   grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"' "$WORK/guard-out"; then
  pass "Grep refuses a password file"
else fail "Grep did not refuse a password file"; fi
for command in env printenv /usr/bin/env 'command printenv' 'export -p' set; do
  if guard "{\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$command\"}}" && \
     grep -q '"permissionDecision"[[:space:]]*:[[:space:]]*"deny"' "$WORK/guard-out"; then
    pass "Bash refuses $command"
  else fail "Bash did not refuse $command"; fi
done
guard '{broken' && code=0 || code=$?
[ "$code" -eq 2 ] && pass "guard reports could not run on malformed input" || fail "guard returned $code for malformed input"

echo "== Claude Code result redaction =="
for tool in Bash Read Grep; do
  case "$tool" in
    Bash)
      response="\"stdout\":\"output $SECRET_TEST_VALUE\",\"stderr\":\"\",\"interrupted\":false,\"isImage\":false"
      event="{\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Bash\",\"tool_response\":{$response}}"
      expected_type=object
      ;;
    Read|Grep)
      event=$(python3 - "$tool" "$SECRET_TEST_VALUE" <<'PY'
import json, sys
print(json.dumps({"hook_event_name": "PostToolUse", "tool_name": sys.argv[1],
                  "tool_response": "1: output " + sys.argv[2]}))
PY
)
      expected_type=string
      ;;
  esac
  if redact "$event" && python3 - "$WORK/redact-out" "$SECRET_TEST_VALUE" "$expected_type" <<'PY'
import json, sys
outer = json.load(open(sys.argv[1]))
replacement = outer["hookSpecificOutput"]["updatedToolOutput"]
needle = sys.argv[2]
shape = sys.argv[3]
assert isinstance(replacement, dict if shape == "object" else str)
assert needle not in json.dumps(replacement)
assert "[secret hidden]" in json.dumps(replacement)
if shape == "object":
    assert set(replacement) == {"stdout", "stderr", "interrupted", "isImage"}
    assert replacement["interrupted"] is False and replacement["isImage"] is False
PY
  then pass "$tool result is redacted and keeps its documented shape";
  else fail "$tool result was not redacted with its shape intact"; fi
done

if redact '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_response":null}' && \
   python3 - "$WORK/redact-out" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))["hookSpecificOutput"]["updatedToolOutput"]
assert set(r) == {"stdout", "stderr", "interrupted", "isImage"}
assert "hidden" in r["stdout"]
PY
then pass "a broken Bash result is replaced with a hidden Bash-shaped result";
else fail "a broken Bash result was not hidden"; fi
if printf '%s' '{broken' | CLAUDE_PROJECT_DIR="$WORK/project" \
   sh "$FOUNDATION/redact-secrets.sh" Bash >"$WORK/redact-out" 2>"$WORK/redact-err" && \
   python3 - "$WORK/redact-out" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))["hookSpecificOutput"]["updatedToolOutput"]
assert set(r) == {"stdout", "stderr", "interrupted", "isImage"}
assert "hidden" in r["stdout"]
PY
then pass "unreadable hook input gets a hidden result in the known Bash shape";
else fail "unreadable hook input was not hidden"; fi

echo "== Git scan and push guard =="
PROJECT="$WORK/git-project"
REMOTE="$WORK/remote.git"
mkdir -p "$PROJECT/.agents/hooks/git"
cp "$FOUNDATION/scan-secrets.sh" "$PROJECT/.agents/hooks/scan-secrets.sh"
cp "$FOUNDATION/scan-secrets.py" "$PROJECT/.agents/hooks/scan-secrets.py"
cp "$FOUNDATION/guard-secrets.py" "$PROJECT/.agents/hooks/guard-secrets.py"
cp "$FOUNDATION/pre-push" "$PROJECT/.agents/hooks/git/pre-push"
git init -q --bare "$REMOTE"
git init -q -b main "$PROJECT"
git -C "$PROJECT" config user.name Rehearsal
git -C "$PROJECT" config user.email rehearsal@example.invalid
git -C "$PROJECT" config commit.gpgsign false
git -C "$PROJECT" remote add origin "$REMOTE"
printf 'clean\n' > "$PROJECT/app.txt"
git -C "$PROJECT" add app.txt
git -C "$PROJECT" commit -q -m clean
CLEAN=$(git -C "$PROJECT" rev-parse HEAD)
(cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=$CLEAN") && pass "clean history passes" || fail "clean history did not pass"
git -C "$PROJECT" push -q origin main
git -C "$PROJECT" config core.hooksPath .agents/hooks/git
git -C "$PROJECT" checkout -q -b change
printf 'SERVICE_TOKEN=%s\n' "$SECRET_TEST_VALUE" > "$PROJECT/.env"
printf 'value=%s\n' "$SECRET_TEST_VALUE" > "$PROJECT/leak.txt"
git -C "$PROJECT" add leak.txt
git -C "$PROJECT" commit -q -m planted
LEAK=$(git -C "$PROJECT" rev-parse HEAD)
if (cd "$PROJECT" && sh .agents/hooks/scan-secrets.sh "--range=$CLEAN..$LEAK") >"$WORK/scan-out" 2>&1; then
  fail "scan passed a committed .env value"
else
  code=$?
  [ "$code" -eq 1 ] && ! grep -Fq "$SECRET_TEST_VALUE" "$WORK/scan-out" \
    && pass "scan blocks a committed .env value without printing it" \
    || fail "scan returned $code or printed the planted value"
fi
if git -C "$PROJECT" push -q -u origin change >"$WORK/push-out" 2>&1; then
  fail "pre-push allowed a committed .env value"
else
  ! grep -Fq "$SECRET_TEST_VALUE" "$WORK/push-out" && pass "pre-push refuses the branch containing the test value" \
    || fail "pre-push printed the planted value"
fi
printf 'token=ghp_%s\n' "$(python3 -c 'import secrets; print(secrets.token_urlsafe(28))')" > "$PROJECT/key.txt"
git -C "$PROJECT" add key.txt
git -C "$PROJECT" commit -q -m key-shape
KEY=$(git -C "$PROJECT" rev-parse HEAD)
if (cd "$PROJECT" && CI=true sh .agents/hooks/scan-secrets.sh "--range=$LEAK..$KEY") >/dev/null 2>&1; then
  fail "CI scan passed a key-shaped value"
else
  code=$?
  [ "$code" -eq 1 ] && pass "CI scan catches a key-shaped value" || fail "CI scan returned $code for a key shape"
fi
if (cd "$PROJECT" && CI=true sh .agents/hooks/scan-secrets.sh --all) >/dev/null 2>&1; then
  fail "the project-check scan passed a key-shaped value in Git history"
else
  code=$?
  [ "$code" -eq 1 ] && pass "the project-check scan catches a key-shaped value in history" \
    || fail "the project-check scan returned $code for a key shape"
fi
if (cd "$WORK" && sh "$FOUNDATION/scan-secrets.sh" --all) >/dev/null 2>&1; then
  fail "scan passed outside a Git repository"
else
  code=$?
  [ "$code" -eq 2 ] && pass "scan reports could not run outside Git" || fail "scan returned $code outside Git"
fi

exit "$FAIL"
