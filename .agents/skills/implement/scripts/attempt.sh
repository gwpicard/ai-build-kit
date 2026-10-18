#!/usr/bin/env sh
# Count a piece's unattended build attempts in Git's private metadata.

set -eu

[ "$#" = 1 ] && [ -n "$1" ] || {
  echo "attempt: usage: attempt.sh <piece>" >&2
  exit 2
}
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "attempt: run this inside a Git project" >&2
  exit 2
}
piece=$1
case "$piece" in *[!0-9]*|'') echo "attempt: piece must be a number" >&2; exit 2 ;; esac
setting=$(git show main:masterplan.md 2>/dev/null || cat masterplan.md 2>/dev/null || true)
printf '%s\n' "$setting" | grep -Eq '^Runs on its own:.*[[:space:],]loop([[:space:],(]|$)' || {
  echo "attempt: the loop is off on main" >&2
  exit 1
}
git_dir=$(git rev-parse --git-common-dir) || exit 2
case "$git_dir" in
  /*) ;;
  *) git_dir="$(git rev-parse --show-toplevel)/$git_dir" ;;
esac
git_dir="$git_dir/ai-build-kit-attempts"
mkdir -p "$git_dir"
counter="$git_dir/$piece"
count=0
if [ -f "$counter" ]; then
  IFS= read -r count < "$counter" || count=0
fi
case "$count" in *[!0-9]*|'') echo "attempt: unreadable attempt count for piece $piece" >&2; exit 2 ;; esac
if [ "$count" -ge 3 ]; then
  if command -v gh >/dev/null 2>&1 && gh issue edit "$piece" --add-label blocked >/dev/null 2>&1; then
    echo "attempt: piece $piece has reached three attempts and is now blocked; ask the person" >&2
  else
    echo "attempt: piece $piece has reached three attempts; it needs the blocked label and the person's attention" >&2
  fi
  exit 1
fi
start_file="$counter.start"
if [ ! -f "$start_file" ]; then
  git rev-parse HEAD > "$start_file" || exit 2
fi
start=$(cat "$start_file")
if git log "$start..HEAD" --format=%s 2>/dev/null | grep -q '^Test fix:'; then
  echo "attempt: a Test fix commit ends the loop; ask the person to review the test change" >&2
  exit 1
fi
count=$((count + 1))
printf '%s\n' "$count" > "$counter"
printf 'attempt: piece %s, attempt %s of 3\n' "$piece" "$count"
