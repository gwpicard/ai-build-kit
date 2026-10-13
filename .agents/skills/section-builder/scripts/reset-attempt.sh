#!/usr/bin/env sh
# reset-attempt.sh: throw away a failed repair attempt, back to the last saved
# state.
#
# Usage: sh reset-attempt.sh --start   record where an attempt starts
#        sh reset-attempt.sh           throw the attempt away
#
# A repair tries one cause at a time, and a failed attempt is undone before the
# next one, so failed fixes never stack. The coding agent's settings refuse the
# plain commands that throw changes away, so this named script is the one way
# a repair resets. It is the reset step in section-builder's
# references/repair.md, and nothing else should run it.
#
# --start writes down which files Git does not track yet, inside Git's own
# folder, so it is never saved or pushed. Run it once the repair's test is
# committed and before the attempt changes anything.
#
# The reset first keeps everything it is about to throw away in a snapshot: a
# commit under refs/ai-build-kit/attempts/ that no branch points at and no push
# sends. It prints that name, so any file can be read back with
# `git show <snapshot>:<path>`. It then puts every saved file back as the last
# commit holds it, staged or not, and removes the files the attempt added since
# its start, saved or not. A file that was there before the start is kept.
# Without a recorded start it removes no new file and lists them all.
#
# It works from any folder inside the project.
#
# Output lines have fields separated by tabs, and each file has a line of its
# own under its heading:
#   snapshot    REF  COMMIT
#   reset: put back as last saved:
#   removed, added by the attempt:
#   left in place, never saved:
#
# Exit 0: the saved files match the last commit; what changed is listed.
# Exit 2: this is not a Git repository with a commit, or Git failed.

set -u

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "reset-attempt: this folder is not a Git repository" >&2; exit 2; }
top=$(git rev-parse --show-toplevel) && cd "$top" || { echo "reset-attempt: the project folder could not be reached" >&2; exit 2; }
git rev-parse -q --verify HEAD >/dev/null || { echo "reset-attempt: there is no saved state to go back to" >&2; exit 2; }
start=$(git rev-parse --git-path ai-build-kit-attempt-start)

untracked() { git -c core.quotepath=off ls-files --others --exclude-standard; }

case "${1:-}" in
  --start)
    { echo "head $(git rev-parse HEAD)"; untracked | sed 's/^/file /'; } > "$start" ||
      { echo "reset-attempt: the start could not be written" >&2; exit 2; }
    echo "start: recorded at $(git rev-parse --short HEAD)"
    exit 0 ;;
  "") ;;
  *) echo "usage: reset-attempt.sh [--start]" >&2; exit 2 ;;
esac

# Every path that differs from the last commit, staged or not, and the files
# Git does not track.
changed=$(git -c core.quotepath=off diff --name-only HEAD --)
new=$(untracked)

# Which new files are the attempt's: those not listed at its start.
if [ -f "$start" ]; then
  added=$(printf '%s\n' "$new" | while IFS= read -r file; do
    [ -n "$file" ] || continue
    grep -qxF -- "file $file" "$start" || printf '%s\n' "$file"
  done)
  kept=$(printf '%s\n' "$new" | while IFS= read -r file; do
    [ -n "$file" ] || continue
    grep -qxF -- "file $file" "$start" && printf '%s\n' "$file"
  done)
else
  added=
  kept=$new
fi

report_kept() {
  [ -n "$kept" ] || return 0
  if [ -f "$start" ]; then
    echo "left in place, never saved:"
  else
    echo "left in place, never saved, since no start was recorded:"
  fi
  printf '%s\n' "$kept" | sed 's/^/  /'
}

if [ -z "$changed" ] && [ -z "$added" ]; then
  echo "reset: nothing to throw away; the saved files already match the last commit"
  report_kept
  exit 0
fi

# The snapshot: the working files as they are now, the attempt's new files
# included, written with an index of its own so the project's is untouched.
index=$(git rev-parse --git-path ai-build-kit-attempt-index)
rm -f "$index"
snapshot_ok=no
if GIT_INDEX_FILE=$index git read-tree HEAD &&
   GIT_INDEX_FILE=$index git add -A -- . &&
   tree=$(GIT_INDEX_FILE=$index git write-tree) &&
   commit=$(git commit-tree "$tree" -p HEAD -m "Failed repair attempt, kept before the reset") &&
   ref=refs/ai-build-kit/attempts/$(date +%Y%m%d-%H%M%S)-$(printf '%s' "$commit" | cut -c1-7) &&
   git update-ref "$ref" "$commit"; then
  snapshot_ok=yes
fi
rm -f "$index"
[ "$snapshot_ok" = yes ] || { echo "reset-attempt: the snapshot could not be made, so nothing was thrown away" >&2; exit 2; }
echo "snapshot	$ref	$commit"

restored=
if [ -n "$changed" ]; then
  git restore --source=HEAD --staged --worktree -- :/ || { echo "reset-attempt: Git could not restore the files" >&2; exit 2; }
  # A file the attempt staged that the last commit never held is gone now,
  # so it is reported as removed rather than put back.
  restored=$(printf '%s\n' "$changed" | while IFS= read -r file; do
    [ -n "$file" ] || continue
    if git cat-file -e "HEAD:$file" 2>/dev/null; then
      printf '%s\n' "$file"
    else
      echo "gone $file"
    fi
  done)
fi

removed=$(printf '%s\n' "$restored" | sed -n 's/^gone //p')
printf '%s\n' "$added" | while IFS= read -r file; do
  [ -n "$file" ] || continue
  rm -f -- "$file"
  dir=$(dirname -- "$file")
  while [ "$dir" != "." ] && rmdir -- "$dir" 2>/dev/null; do dir=$(dirname -- "$dir"); done
done
removed=$(printf '%s\n%s\n' "$removed" "$added" | sed '/^$/d' | sort -u)

put_back=$(printf '%s\n' "$restored" | sed '/^gone /d;/^$/d')
if [ -n "$put_back" ]; then
  echo "reset: put back as last saved:"
  printf '%s\n' "$put_back" | sed 's/^/  /'
fi
if [ -n "$removed" ]; then
  echo "removed, added by the attempt:"
  printf '%s\n' "$removed" | sed 's/^/  /'
fi
report_kept
exit 0
