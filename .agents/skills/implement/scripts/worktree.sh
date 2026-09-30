#!/usr/bin/env sh
# worktree.sh: open, check and clear away the worktree each piece in a run is
# built in, as the implement skill's references/running-longer.md describes.
#
# A worktree is a second working copy of the project, on its own branch, in a
# folder of its own. Each piece in a run on Claude Code gets one at
# .agents/worktrees/<issue number>-<short name>, so the main folder never
# moves off its branch. This script is the only thing that opens or removes
# one, so the rules hold whichever session runs it:
#
#   open [--resume] <name> <branch> <base>
#       Make .agents/worktrees/<name> on <branch>, cut from <base> when the
#       branch does not exist yet. Link the main folder's .env into it, never
#       copy it. Reuse a worktree already at that path only when it is on the
#       same branch and holds no unsaved work; with --resume, only when it
#       holds no uncommitted change. Exit 1 to skip the piece, 3 when the disk
#       is full.
#   unsaved <path>
#       Say whether a worktree holds unsaved work. Exit 1 when it does.
#   tidy
#       Remove each worktree whose pull request has merged or closed and that
#       holds no unsaved work. Keep and name one that holds some.
#   leftovers
#       List each worktree with no open pull request that no unfinished run is
#       building. Change nothing.
#   remove <path>
#       Remove one worktree on the person's yes, after checking again.
#   port <issue number>
#       Print a free port for the piece's dev server.
#
# Unsaved work is an uncommitted change, counting a new file git does not
# ignore, or a commit missing from every remote branch. A worktree is removed
# with `git worktree remove`, never forced, and no branch is ever deleted.
#
# Run it from anywhere inside the project. It needs git, and python3 and the
# GitHub command line tool for the steps that read pull requests.

set -eu

say() { printf '%s\n' "$*"; }
die() { printf 'worktree.sh: %s\n' "$*" >&2; exit 2; }

# The main folder is the first worktree git lists. Every path below comes from
# that same listing, so a folder reached through a symbolic link still matches.
MAIN=$(git worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')
[ -n "$MAIN" ] || die "run this from inside a git project"
cd "$MAIN"
WT_DIR="$MAIN/.agents/worktrees"

# listed: each worktree under .agents/worktrees/, as "<path><tab><branch>".
listed() {
  git worktree list --porcelain | awk -v pre="$WT_DIR/" '
    function emit() { if (p != "" && index(p, pre) == 1) print p "\t" b }
    /^worktree / { emit(); p = substr($0, 10); b = ""; next }
    /^branch / { b = substr($0, 8); sub("^refs/heads/", "", b) }
    END { emit() }'
}

# relative <path>: the path from the main folder, as the run state records it.
relative() { printf '%s' "${1#"$MAIN"/}"; }

# find_listed <path>: the listed worktree at <path>, however it was written.
find_listed() {
  want=$(cd "$1" 2>/dev/null && pwd -P) || return 1
  listed | while IFS="$(printf '\t')" read -r lpath lbranch; do
    if [ "$(cd "$lpath" 2>/dev/null && pwd -P)" = "$want" ]; then
      printf '%s\t%s\n' "$lpath" "$lbranch"
      break
    fi
  done
}

# count: the number of lines on stdin, with no padding.
count() { awk 'END { print NR }'; }

# unsaved_reason <worktree> [commit]: what is unsaved, or nothing. A commit
# given here is saved too: the head of a merged pull request, which counts
# even after its branch has gone from the remote.
unsaved_reason() {
  changes=$(git -C "$1" status --porcelain | count)
  saved_too=""
  if [ -n "${2:-}" ] && git -C "$1" cat-file -e "$2^{commit}" 2>/dev/null; then
    saved_too=$2
  fi
  # shellcheck disable=SC2086
  commits=$(git -C "$1" rev-list HEAD --not --remotes $saved_too | count)
  reason=""
  [ "$changes" -eq 0 ] || reason="$changes uncommitted change(s)"
  if [ "$commits" -ne 0 ]; then
    [ -z "$reason" ] || reason="$reason and "
    reason="$reason$commits commit(s) missing from every remote branch"
  fi
  printf '%s' "$reason"
}

# pr_state <branch>: open, merged <head commit>, closed or none. Fails when the
# pull requests cannot be read.
pr_state() {
  command -v gh >/dev/null 2>&1 || return 1
  json=$(gh pr list --head "$1" --state all --json state,headRefOid 2>/dev/null </dev/null) || return 1
  printf '%s' "$json" | python3 -c '
import json, sys
pulls = json.load(sys.stdin)
states = [p.get("state", "") for p in pulls]
if "OPEN" in states:
    print("open")
elif "MERGED" in states:
    print("merged " + next(p.get("headRefOid", "") for p in pulls if p.get("state") == "MERGED"))
elif "CLOSED" in states:
    print("closed")
else:
    print("none")
' 2>/dev/null || return 1
}

# being_built <path> <branch>: true when an unfinished run lists a piece in
# this worktree, or on this branch, as waiting or building.
being_built() {
  [ -d "$MAIN/.agents/runs" ] || return 1
  python3 - "$MAIN" "$(relative "$1")" "$2" <<'PY' 2>/dev/null
import glob, json, os, sys
main, rel, branch = sys.argv[1:4]
for path in glob.glob(os.path.join(main, ".agents", "runs", "*", "state.json")):
    try:
        run = json.load(open(path))
    except Exception:
        continue
    for piece in run.get("pieces", []):
        if piece.get("state") not in ("waiting", "building"):
            continue
        if piece.get("worktree") == rel or (branch and piece.get("branch") == branch):
            sys.exit(0)
sys.exit(1)
PY
}

# link_env <worktree>: link each env file git ignores in the main folder.
link_env() {
  linked=""
  failed=""
  for source in "$MAIN"/.env "$MAIN"/.env.*; do
    [ -f "$source" ] || continue
    name=${source##*/}
    # A file git does not ignore is either tracked, so the worktree already has
    # it, or would show as a new file in every worktree. Neither is linked.
    git check-ignore -q "$name" 2>/dev/null || continue
    if [ -L "$1/$name" ]; then
      linked="$linked $name"
      continue
    fi
    [ ! -e "$1/$name" ] || continue
    if ln -s "../../../$name" "$1/$name" 2>/dev/null && [ -L "$1/$name" ]; then
      linked="$linked $name"
    else
      failed="$failed $name"
    fi
  done
  if [ -n "$failed" ]; then
    say "The link to${failed} could not be made here, so this piece runs without secrets. Say so once, and flag anything in it that needs a key. Never copy the file instead."
  fi
  if [ -n "$linked" ]; then
    say "Linked${linked} to the main folder's own, so each secret stays in one file."
  elif [ -z "$failed" ]; then
    say "No .env in the main folder, so nothing was linked."
  fi
}

# ignore_folder: make sure git ignores .agents/worktrees/ before anything is
# made in it, so nothing tracked changes.
ignore_folder() {
  git check-ignore -q ".agents/worktrees/$1" 2>/dev/null && return 0
  mkdir -p "$WT_DIR"
  printf '*\n' >> "$WT_DIR/.gitignore"
}

cmd_open() {
  resume=no
  if [ "${1:-}" = "--resume" ]; then
    resume=yes
    shift
  fi
  [ $# -eq 3 ] || die "usage: worktree.sh open [--resume] <name> <branch> <base>"
  name=$1 branch=$2 base=$3
  case $name in
    '' | */* | .*) die "the name must be <issue number>-<short name>, with no slash" ;;
  esac
  wt="$WT_DIR/$name"
  rel=".agents/worktrees/$name"
  ignore_folder "$name"

  if [ -e "$wt" ]; then
    found=$(find_listed "$wt" || true)
    if [ -z "$found" ]; then
      say "Skip this piece: $rel already exists and is not a worktree of this project."
      exit 1
    fi
    on=${found#*"$(printf '\t')"}
    if [ "$on" != "$branch" ]; then
      say "Skip this piece: $rel already exists on branch ${on:-none}, not $branch."
      exit 1
    fi
    reason=$(unsaved_reason "$wt")
    if [ "$resume" = yes ]; then
      changes=$(git -C "$wt" status --porcelain | count)
      if [ "$changes" -ne 0 ]; then
        say "Skip this piece: $rel holds $changes uncommitted change(s) from an earlier session. It is kept as it is."
        exit 1
      fi
    elif [ -n "$reason" ]; then
      say "Skip this piece: $rel already exists and holds unsaved work: $reason. It is kept as it is."
      exit 1
    fi
    say "Reused $rel: it is already on branch $branch."
    link_env "$wt"
    exit 0
  fi

  mkdir -p "$WT_DIR"
  added=yes
  if git show-ref --verify -q "refs/heads/$branch"; then
    err=$(git worktree add "$wt" "$branch" 2>&1 >/dev/null) || added=no
  else
    err=$(git worktree add -b "$branch" "$wt" "$base" 2>&1 >/dev/null) || added=no
    # A branch cut from origin/main would track it, and a plain pull would
    # then bring main in. The piece's branch gets its own upstream when pushed.
    [ "$added" = no ] || git -C "$wt" branch --unset-upstream >/dev/null 2>&1 || true
  fi
  if [ "$added" = no ]; then
    case $err in
      *"No space left"* | *"no space left"* | *"Disk quota"*)
        say "The disk is full, so $rel could not be made. Stop the run before the next piece, and give this as the reason in the report."
        exit 3 ;;
    esac
    say "Skip this piece: $rel could not be made: $(printf '%s' "$err" | sed -n '1p')"
    exit 1
  fi
  say "Opened $rel on branch $branch, from $base."
  link_env "$wt"
}

cmd_unsaved() {
  [ $# -eq 1 ] || die "usage: worktree.sh unsaved <path>"
  found=$(find_listed "$1" || true)
  [ -n "$found" ] || die "$1 is not a worktree under .agents/worktrees/"
  wt=${found%%"$(printf '\t')"*}
  reason=$(unsaved_reason "$wt")
  if [ -n "$reason" ]; then
    say "$(relative "$wt") holds unsaved work: $reason."
    exit 1
  fi
  say "$(relative "$wt") holds no unsaved work."
}

cmd_tidy() {
  listed | while IFS="$(printf '\t')" read -r wt branch; do
    rel=$(relative "$wt")
    if [ ! -d "$wt" ]; then
      say "$rel is gone from this computer, and git still lists it. Running git worktree prune clears that record."
      continue
    fi
    being_built "$wt" "$branch" && continue
    state=$(pr_state "$branch") || {
      say "Could not read the pull requests, so no worktree was removed."
      break
    }
    case $state in
      open* | none) continue ;;
    esac
    how=${state%% *}
    head=""
    [ "$how" != merged ] || head=${state#merged }
    reason=$(unsaved_reason "$wt" "$head")
    if [ -n "$reason" ]; then
      say "Kept $rel: its pull request $how, but it holds unsaved work: $reason."
      continue
    fi
    if err=$(git worktree remove "$wt" 2>&1); then
      say "Removed $rel: its pull request $how and nothing in it was unsaved. Its branch $branch is kept."
    else
      say "Kept $rel: git would not remove it: $(printf '%s' "$err" | sed -n '1p')"
    fi
  done
}

cmd_leftovers() {
  listed | while IFS="$(printf '\t')" read -r wt branch; do
    rel=$(relative "$wt")
    if [ ! -d "$wt" ]; then
      say "$rel is gone from this computer, and git still lists it. Running git worktree prune clears that record."
      continue
    fi
    being_built "$wt" "$branch" && continue
    state=$(pr_state "$branch") || {
      say "Could not read the pull requests, so no leftover worktree can be named."
      break
    }
    case $state in
      open*) continue ;;
      none) what="there is no pull request from its branch $branch" ; head="" ;;
      merged*) what="its pull request merged" ; head=${state#merged } ;;
      *) what="its pull request closed" ; head="" ;;
    esac
    reason=$(unsaved_reason "$wt" "$head")
    if [ -n "$reason" ]; then
      say "$rel: $what, and it holds unsaved work: $reason."
    else
      say "$rel: $what, and nothing in it is unsaved."
    fi
  done
}

cmd_remove() {
  [ $# -eq 1 ] || die "usage: worktree.sh remove <path>"
  found=$(find_listed "$1" || true)
  if [ -z "$found" ]; then
    say "Refused: $1 is not a worktree under .agents/worktrees/."
    exit 1
  fi
  wt=${found%%"$(printf '\t')"*}
  branch=${found#*"$(printf '\t')"}
  rel=$(relative "$wt")
  if being_built "$wt" "$branch"; then
    say "Kept $rel: an unfinished run is still building it."
    exit 1
  fi
  state=$(pr_state "$branch") || {
    say "Kept $rel: the pull requests could not be read, so whether one is open is unknown."
    exit 1
  }
  case $state in
    open*)
      say "Kept $rel: its pull request is still open."
      exit 1 ;;
  esac
  head=""
  case $state in merged*) head=${state#merged } ;; esac
  reason=$(unsaved_reason "$wt" "$head")
  if [ -n "$reason" ]; then
    say "Kept $rel: it holds unsaved work: $reason."
    exit 1
  fi
  if err=$(git worktree remove "$wt" 2>&1); then
    say "Removed $rel. Its branch $branch is kept."
  else
    say "Kept $rel: git would not remove it: $(printf '%s' "$err" | sed -n '1p')"
    exit 1
  fi
}

cmd_port() {
  [ $# -eq 1 ] || die "usage: worktree.sh port <issue number>"
  case $1 in '' | *[!0-9]*) die "the issue number must be a number" ;; esac
  python3 - "$1" <<'PY'
import socket, sys
start = 4000 + int(sys.argv[1]) % 1000
for port in list(range(start, 5000)) + list(range(4000, start)):
    probe = socket.socket()
    probe.settimeout(0.2)
    try:
        answered = probe.connect_ex(("127.0.0.1", port)) == 0
    finally:
        probe.close()
    if answered:
        continue
    listener = socket.socket()
    try:
        listener.bind(("", port))
    except OSError:
        continue
    finally:
        listener.close()
    print(port)
    sys.exit(0)
sys.exit("no free port between 4000 and 4999")
PY
}

sub=${1:-}
[ $# -eq 0 ] || shift
case $sub in
  open) cmd_open "$@" ;;
  unsaved) cmd_unsaved "$@" ;;
  tidy) cmd_tidy ;;
  leftovers) cmd_leftovers ;;
  remove) cmd_remove "$@" ;;
  port) cmd_port "$@" ;;
  *) die "usage: worktree.sh open|unsaved|tidy|leftovers|remove|port ..." ;;
esac
