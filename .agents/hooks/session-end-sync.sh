#!/usr/bin/env sh
# Runs the sync skill when a working session ends, so the documents stay true
# without anyone having to remember at 6pm.
#
# Wiring, per tool:
#   Claude Code — already wired in .claude/settings.json (SessionEnd hook).
#   Cursor      — add this script as a session/stop hook in Cursor's hooks.
#   Others      — if your tool has no hooks, typing /sync by hand at the end of
#                 a session does the same job.
#
# The command below asks a fresh headless agent to run /sync with no chat.
# It defaults to the Claude Code CLI; set AI_BUILD_KIT_AGENT_CMD to your tool's
# non-interactive form if it differs (for example: "codex exec" or "gemini -p").

set -eu

# Guard against recursion: the headless agent we spawn ends too, which would
# re-fire this hook. The exported marker makes the nested run exit immediately.
if [ -n "${AI_BUILD_KIT_SYNC_RUNNING:-}" ]; then
  exit 0
fi
export AI_BUILD_KIT_SYNC_RUNNING=1

echo "Session ended: running /sync so the documents match reality."

PROMPT="Run the sync skill in .agents/skills/sync/SKILL.md: reconcile plan.md, CHANGELOG.md and masterplan.md against the repository, and report what had drifted."
AGENT_CMD="${AI_BUILD_KIT_AGENT_CMD:-claude -p}"

# shellcheck disable=SC2086
$AGENT_CMD "$PROMPT" || true
