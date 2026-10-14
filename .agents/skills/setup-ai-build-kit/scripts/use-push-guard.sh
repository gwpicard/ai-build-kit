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
# It sets core.hooksPath to .agents/hooks/git only when nothing is set, here or
# for every project on this computer, and Git's own hooks folder holds no hook
# of its own. Pointing Git elsewhere would stop those hooks running, with
# nothing to say so, so in each of those cases the project keeps them and the
# script says in one line that the guard is not on.
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

hook=.agents/hooks/git/pre-push
if [ ! -f "$hook" ]; then
  echo "push guard: not switched on, because $hook is missing" >&2
  exit 1
fi
# Git skips a hook it cannot run.
[ -x "$hook" ] || chmod +x "$hook" 2>/dev/null
if [ ! -x "$hook" ]; then
  echo "push guard: not switched on, because $hook could not be made runnable" >&2
  exit 1
fi

current=$(git config --local --get core.hooksPath 2>/dev/null || true)
case "$current" in
  "")
    wide=$(git config --get core.hooksPath 2>/dev/null || true)
    if [ -n "$wide" ]; then
      echo "push guard: not switched on, because Git runs hooks from $wide for every project on this computer, and the guard would stop them here" >&2
      exit 1
    fi
    own=$(git rev-parse --git-common-dir 2>/dev/null)/hooks
    found=
    for file in "$own"/*; do
      [ -f "$file" ] && [ -x "$file" ] || continue
      case "$file" in *.sample) continue ;; esac
      found="$found${found:+, }${file##*/}"
    done
    if [ -n "$found" ]; then
      echo "push guard: not switched on, because Git already runs this project's own hooks ($found), and the guard would stop them" >&2
      exit 1
    fi
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
