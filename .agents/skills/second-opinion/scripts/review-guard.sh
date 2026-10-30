#!/usr/bin/env sh
# review-guard.sh: keep a review from changing the work it reviews.
#
# A reviewer runs in the same project folder as the work, and in some coding
# agents it can run commands, so nothing but its brief stops it editing a file.
# At founding the masterplan under review is not even saved yet, so an edit
# would change the person's draft with no record of it. Run this around every
# review that shares the folder.
#
# Usage, from the project root:
#   review-guard.sh snapshot FILE...   before the review: keep a copy of each
#                                      file under review and all pre-existing
#                                      uncommitted files, plus Git status
#   review-guard.sh check              after the review: compare
#
# check exits:
#   0  nothing changed
#   1  something changed. Each snapshotted file that changed, or went, is put
#      back from its copy and named on a "restored" line. Any other change in
#      the working tree is named on a "changed" line and left as it is.
#   2  it could not run: no snapshot, or a copy could not be read
#
# snapshot exits 0 once the copies are kept, and 2 when it cannot keep them.
# The copies sit in .agents/tmp/review-guard/, which the project keeps out of
# Git, and each check removes them.

set -u

GUARD=.agents/tmp/review-guard

status() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git status --porcelain --untracked-files=all 2>/dev/null | grep -v '\.agents/tmp/' || true
  fi
}

case "${1:-}" in
  snapshot)
    shift
    [ "$#" -gt 0 ] || { echo "review-guard: name the files under review" >&2; exit 2; }
    rm -rf "$GUARD"
    mkdir -p "$GUARD/files" || exit 2
    : > "$GUARD/list"
    python3 - "$@" > "$GUARD/paths" <<'PY' || exit 2
import subprocess
import sys

paths = set(sys.argv[1:])
if subprocess.run(["git", "rev-parse", "--is-inside-work-tree"],
                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
    for args in (["ls-files", "--modified", "--deleted", "--others", "--exclude-standard", "-z"],
                 ["diff", "--cached", "--name-only", "--no-renames", "-z"]):
        raw = subprocess.check_output(["git", *args])
        paths.update(p.decode("utf-8", "surrogateescape") for p in raw.split(b"\0") if p)
for path in sorted(paths):
    if path.startswith(".agents/tmp/"):
        continue
    if "\n" in path or "\t" in path:
        sys.exit("review-guard: a filename contains a tab or newline; snapshot could not be kept")
    print(path)
PY
    while IFS= read -r file; do
      case "$file" in
        /*|../*|*/../*) echo "review-guard: $file is not inside the project" >&2; exit 2 ;;
      esac
      if [ -f "$file" ]; then
        mkdir -p "$GUARD/files/$(dirname -- "$file")" || exit 2
        cp -p "$file" "$GUARD/files/$file" || exit 2
        printf 'present\t%s\t%s\n' "$(cksum < "$file" | tr ' ' ':')" "$file" >> "$GUARD/list"
      else
        printf 'absent\t-\t%s\n' "$file" >> "$GUARD/list"
      fi
    done < "$GUARD/paths"
    status > "$GUARD/status-before"
    echo "review-guard: kept $(grep -c . "$GUARD/list") file(s) before review"
    exit 0
    ;;
  check)
    [ -f "$GUARD/list" ] || { echo "review-guard: no snapshot to compare with" >&2; exit 2; }
    changed=0
    while IFS="$(printf '\t')" read -r state sum file; do
      [ -n "$file" ] || continue
      if [ "$state" = present ]; then
        if [ -f "$file" ] && cmp -s "$file" "$GUARD/files/$file"; then
          continue
        fi
        mkdir -p "$(dirname -- "$file")" || exit 2
        cp -p "$GUARD/files/$file" "$file" || exit 2
        echo "restored	$file"
        changed=1
      elif [ -e "$file" ]; then
        echo "changed	$file	it did not exist before the review"
        changed=1
      fi
    done < "$GUARD/list"
    status > "$GUARD/status-after"
    new=$(grep -vxF -f "$GUARD/status-before" "$GUARD/status-after" 2>/dev/null || true)
    [ -s "$GUARD/status-before" ] || new=$(cat "$GUARD/status-after")
    if [ -n "$new" ]; then
      printf '%s\n' "$new" | while IFS= read -r line; do echo "changed	$line"; done
      changed=1
    fi
    rm -rf "$GUARD"
    exit "$changed"
    ;;
  *)
    echo "usage: review-guard.sh snapshot FILE... | check" >&2
    exit 2
    ;;
esac
