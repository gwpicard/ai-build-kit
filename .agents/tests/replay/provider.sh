#!/usr/bin/env sh
# provider.sh: run replay turns and graders through Claude Code or Codex.

# The caller sets REPLAY_PROVIDER, MODEL, GRADER_MODEL, WORK, REPLAY_DIR,
# TIMEOUT_CMD and GH_DIR before loading this file.

provider_check() {
  case "$REPLAY_PROVIDER" in
    claude)
      command -v claude >/dev/null 2>&1 \
        || fail "Claude Code is not installed"
      ;;
    codex)
      command -v codex >/dev/null 2>&1 \
        || fail "Codex CLI is not installed"
      ;;
    *)
      fail "REPLAY_PROVIDER must be 'claude' or 'codex', not '$REPLAY_PROVIDER'"
      ;;
  esac
}

provider_prepare() {
  [ "$REPLAY_PROVIDER" = "codex" ] || return 0

  # Codex executes commands through a login shell. On macOS that shell rebuilds
  # PATH, which used to expose the real signed-in gh instead of the rehearsal
  # stand-in. These throwaway profiles put the stand-in back after login. Bash
  # reads BASH_ENV for its non-interactive shell; zsh reads .zprofile.
  CODEX_SHELL_HOME="$WORK/codex-shell"
  mkdir -p "$CODEX_SHELL_HOME"
  printf 'export PATH="%s:$PATH"\n' "$GH_DIR" \
    > "$CODEX_SHELL_HOME/.zprofile"
  cp "$CODEX_SHELL_HOME/.zprofile" "$CODEX_SHELL_HOME/bash-env"
  ZDOTDIR=$CODEX_SHELL_HOME
  BASH_ENV="$CODEX_SHELL_HOME/bash-env"
  export ZDOTDIR BASH_ENV

  CODEX_GRADER_DIR="$WORK/codex-grader"
  mkdir -p "$CODEX_GRADER_DIR"
}

provider_new_session() {
  if [ "$REPLAY_PROVIDER" = "claude" ]; then
    PROVIDER_SESSION=$(new_uuid)
  else
    PROVIDER_SESSION=
  fi
}

codex_thread_id() {
  python3 - "$1" <<'PY'
import json
import sys

for line in open(sys.argv[1]):
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        continue
    if event.get("type") == "thread.started" and event.get("thread_id"):
        print(event["thread_id"])
        break
PY
}

wrap_codex_result() {
  python3 - "$1" "$2" <<'PY'
import json
import sys

message, output = sys.argv[1:]
try:
    text = open(message).read()
except OSError:
    text = ""
with open(output, "w") as handle:
    json.dump({"result": text}, handle)
PY
}

run_codex_start() {
  message=$1
  raw=$2
  reply=$3
  if [ -n "$MODEL" ]; then
    ${TIMEOUT_CMD:+$TIMEOUT_CMD 1800} \
      codex exec --json --ignore-user-config --ignore-rules \
      -c shell_environment_policy.inherit=all \
      --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox \
      -m "$MODEL" -o "$reply" "$message" > "$raw" 2>/dev/null
  else
    ${TIMEOUT_CMD:+$TIMEOUT_CMD 1800} \
      codex exec --json --ignore-user-config --ignore-rules \
      -c shell_environment_policy.inherit=all \
      --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox \
      -o "$reply" "$message" > "$raw" 2>/dev/null
  fi
}

run_codex_resume() {
  message=$1
  raw=$2
  reply=$3
  if [ -n "$MODEL" ]; then
    ${TIMEOUT_CMD:+$TIMEOUT_CMD 1800} \
      codex exec resume --json --ignore-user-config --ignore-rules \
      -c shell_environment_policy.inherit=all \
      --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox \
      -m "$MODEL" -o "$reply" "$PROVIDER_SESSION" "$message" \
      > "$raw" 2>/dev/null
  else
    ${TIMEOUT_CMD:+$TIMEOUT_CMD 1800} \
      codex exec resume --json --ignore-user-config --ignore-rules \
      -c shell_environment_policy.inherit=all \
      --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox \
      -o "$reply" "$PROVIDER_SESSION" "$message" > "$raw" 2>/dev/null
  fi
}

# provider_turn <project> <message> <raw-output> <last-reply>
provider_turn() {
  project=$1
  message=$2
  raw=$3
  reply=$4
  : > "$reply"

  case "$REPLAY_PROVIDER" in
    claude)
      if [ -e "$reply.session-started" ]; then
        resume_args="--resume $PROVIDER_SESSION"
      else
        resume_args="--session-id $PROVIDER_SESSION"
      fi
      # shellcheck disable=SC2086
      (cd "$project" && PATH="$GH_DIR:$PATH" \
        ${TIMEOUT_CMD:+$TIMEOUT_CMD 1800} claude -p "$message" \
        $resume_args \
        --strict-mcp-config \
        --permission-mode bypassPermissions \
        --output-format json \
        --model "$MODEL" > "$raw" 2>/dev/null) || return 1
      python3 - "$raw" "$reply" <<'PY'
import json
import sys

raw, reply = sys.argv[1:]
try:
    data = json.load(open(raw))
except Exception:
    raise SystemExit(1)
with open(reply, "w") as handle:
    handle.write(data.get("result") or "")
PY
      : > "$reply.session-started"
      ;;
    codex)
      if [ -n "$PROVIDER_SESSION" ]; then
        (cd "$project" && PATH="$GH_DIR:$PATH" \
          run_codex_resume "$message" "$raw" "$reply") || return 1
      else
        (cd "$project" && PATH="$GH_DIR:$PATH" \
          run_codex_start "$message" "$raw" "$reply") || return 1
        PROVIDER_SESSION=$(codex_thread_id "$raw")
        [ -n "$PROVIDER_SESSION" ] || return 1
      fi
      ;;
  esac

  [ -f "$reply" ]
}

run_codex_grader() {
  prompt=$1
  events=$2
  message=$3
  if [ -n "$GRADER_MODEL" ]; then
    ${TIMEOUT_CMD:+$TIMEOUT_CMD 600} \
      codex exec --json --ephemeral --ignore-user-config --ignore-rules \
      -c shell_environment_policy.inherit=all \
      --skip-git-repo-check --sandbox read-only \
      -m "$GRADER_MODEL" -o "$message" "$prompt" > "$events" 2>/dev/null
  else
    ${TIMEOUT_CMD:+$TIMEOUT_CMD 600} \
      codex exec --json --ephemeral --ignore-user-config --ignore-rules \
      -c shell_environment_policy.inherit=all \
      --skip-git-repo-check --sandbox read-only \
      -o "$message" "$prompt" > "$events" 2>/dev/null
  fi
}

# provider_grade <input> <outer-json-output>
provider_grade() {
  input=$1
  outer=$2

  case "$REPLAY_PROVIDER" in
    claude)
      # shellcheck disable=SC2086
      (cd "$WORK" && ${TIMEOUT_CMD:+$TIMEOUT_CMD 600} \
        claude -p "$(cat "$input")" \
        --allowedTools "" \
        --strict-mcp-config \
        --output-format json \
        --model "$GRADER_MODEL" 2>/dev/null) > "$outer" || true
      ;;
    codex)
      events="$outer.events"
      message=$(mktemp "$CODEX_GRADER_DIR/message.XXXXXX")
      # Codex has no command-line switch that removes every tool. The grader
      # runs read-only from an empty folder and receives only the contract and
      # transcript. Its final message is wrapped in the shape grade-parse.py
      # already reads for Claude.
      (cd "$CODEX_GRADER_DIR" && \
        run_codex_grader "$(cat "$input")" "$events" "$message") || true
      wrap_codex_result "$message" "$outer"
      rm -f "$message"
      ;;
  esac
}
