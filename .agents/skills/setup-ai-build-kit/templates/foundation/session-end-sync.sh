#!/usr/bin/env sh
# Runs when a working session ends. This hook never edits project records and
# never launches another agent: it only checks whether tracked files changed
# since the last commit and, if so, reminds whoever is watching that the
# work is not saved yet. Recovery is a human or agent choice, made with
# /what-now, never something this hook decides on its own. The file keeps its
# old name because a project that wired it points at that name.
#
# This is opt-in, not wired by default. Wiring, per tool:
#   Claude Code: add a SessionEnd hook block to .claude/settings.json pointing
#                at this script, if wanted.
#   Cursor:      add this script as a session/stop hook in Cursor's hooks, if
#                wanted.
#   Others:      if your tool has no hooks, typing /what-now at the start of
#                the next session does the same job, and is the portable
#                default.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

if git diff --quiet && git diff --cached --quiet && [ -z "$(git status --porcelain)" ]; then
  exit 0
fi

echo "Session ended with changes in this project that are not saved yet."
echo "They are edits to its files since the last saved checkpoint, listed in .agents/tmp/session-end-drift.txt."
echo "The records (CHANGELOG.md, masterplan.md) may not describe them yet."
echo "Next session, /what-now says what they belong to and offers to continue, save or clear them."
echo "/maintain then makes the records true. This hook does not edit anything itself."

mkdir -p "$ROOT/.agents/tmp"
{
  echo "session-end drift report, generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "git status --porcelain:"
  git status --porcelain
} > "$ROOT/.agents/tmp/session-end-drift.txt" 2>/dev/null || true

exit 0
