#!/usr/bin/env sh
# reset-attempt.sh: throw away a failed repair attempt, back to the last saved
# state.
#
# Usage: sh reset-attempt.sh
#
# A repair tries one cause at a time, and a failed attempt is undone before the
# next one, so failed fixes never stack. The coding agent's settings refuse the
# plain commands that throw changes away, so this named script is the one way
# a repair resets. It is the reset step in the implement skill's
# references/repair.md, and nothing else should run it.
#
# It puts every saved file back as the last commit holds it, staged or not, and
# lists what it changed. New files the attempt created are listed and left in
# place, since they may be somebody's.
#
# Run it from the project root.
#
# Exit 0: the saved files match the last commit; what changed is listed.
# Exit 2: this is not a Git repository with a commit, or Git failed.

set -u

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "reset-attempt: this folder is not a Git repository" >&2; exit 2; }
git rev-parse -q --verify HEAD >/dev/null || { echo "reset-attempt: there is no saved state to go back to" >&2; exit 2; }

changed=$(git diff --name-only HEAD --)
if [ -z "$changed" ]; then
  echo "reset: nothing to throw away; the saved files already match the last commit"
else
  git restore --source=HEAD --staged --worktree -- . || { echo "reset-attempt: Git could not restore the files" >&2; exit 2; }
  echo "reset: put back as last saved:"
  printf '%s\n' "$changed" | sed 's/^/  /'
fi

untracked=$(git ls-files --others --exclude-standard)
if [ -n "$untracked" ]; then
  echo "left in place, never saved:"
  printf '%s\n' "$untracked" | sed 's/^/  /'
fi
exit 0
