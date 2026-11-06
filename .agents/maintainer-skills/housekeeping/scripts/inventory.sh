#!/usr/bin/env bash
# inventory.sh: list what maintainer work on the kit has left on this computer.
#
# Read-only. It deletes, moves and changes nothing, and it never opens a file
# that may hold a credential: it reports names, sizes and dates only. Deciding
# what goes is the housekeeping skill's job and the maintainer's approval.
#
# Each line is tab-separated: kind, path, size, last modified, note. A note of
# "in use" means a running process names the path, so leave it alone however
# old it looks.
#
# Usage: inventory.sh [repository-root]
#
# The places come from the tools that write them: mutate.sh ($TMPDIR),
# replay/run.sh and seeded/run.sh (~/.local/state), testbed.sh and
# testbed-update.sh (abk-testbeds/.runs and REPLAY_WORK folders, often under
# /var/tmp), Codex and hand runs (/private/tmp), and worktrees and branches in
# the repository. VAR_TMP and PRIVATE_TMP override the two system folders, so a
# test can point the script at a throwaway tree.

set -u

ROOT=$(cd -- "${1:-$(dirname -- "$0")/../../../..}" && pwd)
PROJECTS=$(dirname -- "$ROOT")
VAR_TMP=${VAR_TMP:-/var/tmp}
PRIVATE_TMP=${PRIVATE_TMP:-/private/tmp}
USER_TMP=${TMPDIR:-/tmp}
USER_TMP=${USER_TMP%/}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}

running=$(ps -axo command= 2>/dev/null)

row() {
  kind=$1
  path=$2
  note=${3:-}
  [ -e "$path" ] || return 0
  size=$(du -sh "$path" 2>/dev/null | cut -f1)
  modified=$(date -r "$path" +%Y-%m-%d 2>/dev/null || stat -c %y "$path" 2>/dev/null | cut -c1-10)
  if printf '%s\n' "$running" | grep -qF -- "$path"; then
    note="in use${note:+; $note}"
  fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$kind" "$path" "${size:-?}" "${modified:-?}" "$note"
}

each() {
  kind=$1
  shift
  for path in "$@"; do
    row "$kind" "$path"
  done
}

shopt -s nullglob

printf 'kind\tpath\tsize\tmodified\tnote\n'

# Inside the repository. .agents/tmp is git-ignored scratch; each top-level
# entry is listed so a stray file is as visible as a folder.
each repo-tmp "$ROOT"/.agents/tmp/*

# Worktrees, with unsaved edits named, because a worktree with unsaved work is
# never cleared.
git -C "$ROOT" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' |
  while IFS= read -r tree; do
    [ "$tree" = "$ROOT" ] && continue
    dirty=$(git -C "$tree" status --porcelain 2>/dev/null | head -1)
    row worktree "$tree" "${dirty:+unsaved edits}"
  done

# Local branches. "merged" means main already contains the branch's last commit.
in_worktree=$(git -C "$ROOT" worktree list --porcelain 2>/dev/null | sed -n 's|^branch refs/heads/||p')
git -C "$ROOT" for-each-ref --format='%(refname:short)	%(committerdate:short)' refs/heads 2>/dev/null |
  while IFS=$'\t' read -r branch date; do
    case "$branch" in main|stable) continue ;; esac
    note=unmerged
    git -C "$ROOT" merge-base --is-ancestor "$branch" main 2>/dev/null && note=merged
    printf '%s\n' "$in_worktree" | grep -qx -- "$branch" && note="$note; checked out in a worktree"
    printf 'branch\t%s\t-\t%s\t%s\n' "$branch" "$date" "$note"
  done

# Sibling folders that kit runs write beside the repository.
each sibling "$PROJECTS"/abk-wt/* "$PROJECTS"/abk-testbeds/.runs/*/work

# Run folders the tools leave behind.
each var-tmp "$VAR_TMP"/abk-* "$VAR_TMP"/nextscaffold-*
each mutate "$USER_TMP"/abk-mutate-*
each private-tmp "$PRIVATE_TMP"/abk-*
each replay-state "$STATE"/abk-replay/results-* "$STATE"/abk-seeded/* "$STATE"/abk-cutover

# Files named like credentials, by name only and never opened, in the places
# above. Each one needs its online service checked before its folder goes.
for base in "$ROOT/.agents/tmp" "$PROJECTS/abk-wt" "$VAR_TMP" "$PRIVATE_TMP"; do
  [ -d "$base" ] || continue
  find "$base" -maxdepth 4 \( -name '.env' -o -name '.env.*' -o -name '*secret*' \
    -o -name '*.pem' -o -name '*.key' -o -name 'service_role*' \) \
    -not -name '.env.example' -not -path '*/node_modules/*' 2>/dev/null |
    while IFS= read -r found; do
      printf 'credential-name\t%s\t-\t-\tnamed like a credential; not opened\n' "$found"
    done
done
