#!/usr/bin/env sh
# replay-provider.sh: prove the replay harness can drive Claude Code and Codex.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PROVIDER="$ROOT/.agents/tests/replay/provider.sh"
RUNNER="$ROOT/.agents/tests/replay/run.sh"
README="$ROOT/.agents/tests/replay/README.md"
GRADER="$ROOT/.agents/tests/replay/grader-prompt.md"

FAIL=0
fail() {
  echo "FAIL: $1" >&2
  FAIL=1
}
pass() {
  echo "ok: $1"
}

TEST_WORK=$(mktemp -d)
trap 'rm -rf "$TEST_WORK"' EXIT INT TERM
BIN="$TEST_WORK/bin"
mkdir -p "$BIN" "$TEST_WORK/project" "$TEST_WORK/fake-github" "$TEST_WORK/fake-host"
PROVIDER_LOG="$TEST_WORK/provider.log"
export PROVIDER_LOG

cat > "$BIN/codex" <<'STUB'
#!/bin/sh
set -eu
printf 'codex %s\n' "$*" >> "$PROVIDER_LOG"
output=
previous=
for argument in "$@"; do
  if [ "$previous" = "-o" ]; then output=$argument; fi
  previous=$argument
done
[ -n "$output" ] || exit 2
case " $* " in
  *" --ephemeral "*)
    printf '%s' '{"scenario":1,"verdicts":{"Expected path":{"verdict":"hit","quote":"kept","note":"kept"}},"pushback":{"verdict":"unobservable","quote":"","note":"none"},"held":true,"held_clause":0,"held_note":"held"}' > "$output"
    ;;
  *" exec resume "*) printf '%s' 'codex resumed' > "$output" ;;
  *) printf '%s' 'codex started' > "$output" ;;
esac
printf '%s\n' '{"type":"thread.started","thread_id":"codex-thread"}'
STUB

cat > "$BIN/claude" <<'STUB'
#!/bin/sh
set -eu
printf 'claude %s\n' "$*" >> "$PROVIDER_LOG"
# Which gh a login shell finds here, the way Claude Code's Bash tool builds its
# environment from one.
printf '%s\n' "${ZDOTDIR:-}" > "$PROVIDER_LOG.zdotdir"
if command -v zsh >/dev/null 2>&1; then
  zsh -l -c 'command -v gh' > "$PROVIDER_LOG.login-gh" 2>/dev/null || true
  zsh -l -c 'command -v vercel' > "$PROVIDER_LOG.login-vercel" 2>/dev/null || true
fi
case " $* " in
  *" --allowedTools  "*)
    printf '%s\n' '{"result":"{\"scenario\":1,\"verdicts\":{\"Expected path\":{\"verdict\":\"hit\",\"quote\":\"kept\",\"note\":\"kept\"}},\"pushback\":{\"verdict\":\"unobservable\",\"quote\":\"\",\"note\":\"none\"},\"held\":true,\"held_clause\":0,\"held_note\":\"held\"}"}'
    ;;
  *" --resume "*) printf '%s\n' '{"result":"claude resumed"}' ;;
  *) printf '%s\n' '{"result":"claude started"}' ;;
esac
STUB

chmod +x "$BIN/codex" "$BIN/claude"
PATH="$BIN:$PATH"
export PATH

fail_provider() {
  echo "FAIL: $1" >&2
  exit 1
}
fail() {
  fail_provider "$1"
}
new_uuid() {
  printf '%s\n' claude-session
}

REPLAY_DIR="$ROOT/.agents/tests/replay"
WORK="$TEST_WORK/work"
GH_DIR="$TEST_WORK/fake-github"
HOST_DIR="$TEST_WORK/fake-host"
TIMEOUT_CMD=
mkdir -p "$WORK"
. "$PROVIDER"

REPLAY_PROVIDER=codex
MODEL=codex-model
GRADER_MODEL=codex-grader
provider_check
provider_prepare
provider_new_session

codex_reply="$TEST_WORK/codex-reply"
provider_turn "$TEST_WORK/project" "first turn" "$TEST_WORK/codex-first.jsonl" "$codex_reply" \
  || fail_provider "Codex could not start a replay thread"
[ "$(cat "$codex_reply")" = "codex started" ] \
  && pass "Codex returns the first reply" \
  || fail_provider "Codex first reply was not captured"
[ "$PROVIDER_SESSION" = "codex-thread" ] \
  && pass "Codex thread id is read from JSONL" \
  || fail_provider "Codex thread id was not retained"

provider_turn "$TEST_WORK/project" "second turn" "$TEST_WORK/codex-second.jsonl" "$codex_reply" \
  || fail_provider "Codex could not resume a replay thread"
[ "$(cat "$codex_reply")" = "codex resumed" ] \
  && pass "Codex resumes the same conversation" \
  || fail_provider "Codex resume reply was not captured"

grep -q "exec resume.*codex-thread" "$PROVIDER_LOG" \
  && pass "Codex resume receives the recorded thread id" \
  || fail_provider "Codex resume did not receive the thread id"
grep -q "shell_environment_policy.inherit=all" "$PROVIDER_LOG" \
  && pass "Codex inherits the isolated replay environment" \
  || fail_provider "Codex did not inherit the replay environment"
grep -qF "$GH_DIR" "$WORK/replay-shell/.zprofile" \
  && pass "the Codex zsh profile restores fake GitHub after login" \
  || fail_provider "the Codex zsh profile does not name fake GitHub"
grep -qF "$GH_DIR" "$WORK/replay-shell/bash-env" \
  && pass "the Codex bash profile restores fake GitHub after login" \
  || fail_provider "the Codex bash profile does not name fake GitHub"

printf '%s\n' grading > "$TEST_WORK/input"
provider_grade "$TEST_WORK/input" "$TEST_WORK/codex-grade.raw"
[ -s "$TEST_WORK/codex-grade.raw.events" ] \
  && pass "Codex grader events are kept for inspection" \
  || fail_provider "Codex grader events were discarded"
python3 - "$TEST_WORK/codex-grade.raw" <<'PY' \
  && pass "Codex grader output uses the existing outer JSON shape" \
  || fail_provider "Codex grader output was not wrapped for the parser"
import json
import sys
outer = json.load(open(sys.argv[1]))
inner = json.loads(outer["result"])
assert inner["held"] is True
PY
grep -q -- "--ephemeral.*--sandbox read-only" "$PROVIDER_LOG" \
  && pass "the Codex grader is ephemeral and read-only" \
  || fail_provider "the Codex grader did not use its restricted mode"

REPLAY_PROVIDER=claude
MODEL=opus
GRADER_MODEL=opus

# Claude Code's Bash tool builds its environment from a login shell, which
# reads the person's own profile. On a Mac with Homebrew first in that profile,
# the real gh won over the stand-in in one recorded run. So the Claude route
# gets the same throwaway profiles as Codex. Start from nothing, so the Codex
# preparation above cannot stand in for it.
unset ZDOTDIR BASH_ENV
rm -rf "$WORK/replay-shell"
printf '#!/bin/sh\necho stand-in\n' > "$GH_DIR/gh"
chmod +x "$GH_DIR/gh"
printf '#!/bin/sh\necho stand-in\n' > "$HOST_DIR/vercel"
chmod +x "$HOST_DIR/vercel"
provider_prepare
provider_new_session
grep -qF "$GH_DIR" "$WORK/replay-shell/.zprofile" \
  && [ "${ZDOTDIR:-}" = "$WORK/replay-shell" ] \
  && pass "the Claude route writes the profile that puts fake GitHub first" \
  || fail_provider "the Claude route has no profile that puts fake GitHub first"
provider_turn "$TEST_WORK/project" "first turn" "$TEST_WORK/claude-zdot.json" \
  "$TEST_WORK/claude-zdot-reply" || fail_provider "Claude could not start a turn"
[ "$(cat "$PROVIDER_LOG.zdotdir")" = "$WORK/replay-shell" ] \
  && pass "a Claude turn runs with that profile" \
  || fail_provider "a Claude turn ran without the throwaway profile"
# A login shell, which reads that profile, finds the stand-in rather than the
# person's own gh. Where this machine has no zsh there is nothing to try.
if command -v zsh >/dev/null 2>&1; then
  [ "$(cat "$PROVIDER_LOG.login-gh")" = "$GH_DIR/gh" ] \
    && pass "a login shell in a Claude turn finds fake GitHub first" \
    || fail_provider "a login shell in a Claude turn found $(cat "$PROVIDER_LOG.login-gh")"
  # The host's stand-ins come next, so a login shell never finds a deploy
  # command that may be signed in to somebody's account.
  [ "$(cat "$PROVIDER_LOG.login-vercel")" = "$HOST_DIR/vercel" ] \
    && pass "a login shell in a Claude turn finds the host's stand-ins first" \
    || fail_provider "a login shell in a Claude turn found $(cat "$PROVIDER_LOG.login-vercel")"
fi
provider_check
provider_new_session
claude_reply="$TEST_WORK/claude-reply"
provider_turn "$TEST_WORK/project" "first turn" "$TEST_WORK/claude-first.json" "$claude_reply" \
  || fail_provider "Claude Code could not start a replay session"
[ "$(cat "$claude_reply")" = "claude started" ] \
  && pass "Claude Code keeps its first-turn route" \
  || fail_provider "Claude Code first reply changed"
provider_turn "$TEST_WORK/project" "second turn" "$TEST_WORK/claude-second.json" "$claude_reply" \
  || fail_provider "Claude Code could not resume a replay session"
[ "$(cat "$claude_reply")" = "claude resumed" ] \
  && pass "Claude Code keeps its resume route" \
  || fail_provider "Claude Code resume changed"
grep -q -- "--session-id claude-session" "$PROVIDER_LOG" \
  && pass "Claude Code still starts with the harness session id" \
  || fail_provider "Claude Code lost its chosen session id"
grep -q -- "--resume claude-session" "$PROVIDER_LOG" \
  && pass "Claude Code still resumes the chosen session" \
  || fail_provider "Claude Code lost its resume id"

provider_grade "$TEST_WORK/input" "$TEST_WORK/claude-grade.raw"
python3 "$REPLAY_DIR/grade-parse.py" \
  "$TEST_WORK/claude-grade.raw" "$TEST_WORK/claude-grade.json" 1
python3 - "$TEST_WORK/claude-grade.json" <<'PY' \
  && pass "Claude Code grader output still parses" \
  || fail_provider "Claude Code grader output no longer parses"
import json
import sys
assert json.load(open(sys.argv[1]))["held"] is True
PY

grep -q 'REPLAY_PROVIDER=${REPLAY_PROVIDER:-claude}' "$RUNNER" \
  && pass "Claude Code remains the default provider" \
  || fail_provider "the default replay provider changed"
grep -q 'REPLAY_PROVIDER=codex REPEATS=1' "$README" \
  && pass "the Codex command is documented" \
  || fail_provider "the Codex command is missing from the guide"
grep -q "Expected path.*recorded build path" "$GRADER" \
  && grep -q "before a build.*not a path change" "$GRADER" \
  && pass "the grader treats Expected path as a build path" \
  || fail_provider "the grader still confuses the path with a build command"

if (REPLAY_PROVIDER=unknown; provider_check) >/dev/null 2>&1; then
  fail_provider "an unknown replay provider was accepted"
else
  pass "an unknown replay provider is refused"
fi

echo
echo "replay-provider.sh: all checks passed"
