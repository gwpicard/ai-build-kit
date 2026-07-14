#!/usr/bin/env bash
# Runs the sync skill when a working session ends, so the documents stay
# true without anyone having to remember at 6pm. Register this as a
# session-end hook in your agent tool's settings; Cursor and Claude Code
# both support hooks. If your tool has none, typing $sync by hand at the
# end of a session does the same job.

echo "Session ended: running sync so the documents match reality."

# The line below asks the agent CLI to run the sync skill without a chat.
# This is the Claude Code form; adjust the command name to your tool.
claude -p "Run the sync skill: reconcile plan.md, CHANGELOG.md and masterplan.md against the repository, and report what had drifted." || true
