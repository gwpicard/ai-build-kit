#!/usr/bin/env sh
# use-push-guard.sh: point Git at the project's own hooks, so the pre-push
# guard runs on every push.
#
# Usage: sh use-push-guard.sh [project-folder]   (default: the current folder)
#
# Git reads core.hooksPath from this copy's own settings, which a clone does
# not carry. So founding runs this, and the founding save runs it again once
# the project is a Git repository.
#
# It sets core.hooksPath to .agents/hooks/git only when nothing is set. A
# project whose Git already runs hooks from somewhere else keeps them, and the
# script says the guard is not on.
#
# Exit 0: the guard is on, or there is no Git repository yet.
# Exit 1: the guard could not be switched on; the line printed says why.

set -u

project=${1:-.}
cd "$project" 2>/dev/null || { echo "push guard: no such folder: $project" >&2; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

top=$(git rev-parse --show-toplevel 2>/dev/null)
here=$(pwd -P)
top=$(CDPATH= cd -- "$top" 2>/dev/null && pwd -P)
if [ "$top" != "$here" ]; then
  echo "push guard: not switched on, because this folder sits inside a larger Git repository" >&2
  exit 1
fi

if [ ! -f .agents/hooks/git/pre-push ]; then
  echo "push guard: not switched on, because .agents/hooks/git/pre-push is missing" >&2
  exit 1
fi

current=$(git config --local --get core.hooksPath 2>/dev/null || true)
case "$current" in
  "")
    git config --local core.hooksPath .agents/hooks/git
    ;;
  .agents/hooks/git | .agents/hooks/git/ | "$here/.agents/hooks/git" | "$here/.agents/hooks/git/")
    ;;
  *)
    echo "push guard: not switched on, because Git already runs this project's hooks from $current" >&2
    exit 1
    ;;
esac
exit 0
