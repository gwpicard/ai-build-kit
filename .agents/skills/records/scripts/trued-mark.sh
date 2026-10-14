#!/usr/bin/env sh
# trued-mark.sh: say whether the masterplan's "Trued against:" mark can be used.
#
# The mark names the saved code state last checked against the masterplan. A
# build moves it on only from a mark it can trust; with none, the whole page
# needs comparing with the code, and that comparison belongs to /maintain.
# Whether a mark can be trusted is a fact about the repository, so this script
# answers it, and the build acts on its exit code.
#
# Usage: sh trued-mark.sh [<masterplan file>]   (default: masterplan.md)
#
# Run it from inside the project. It reads and changes nothing else.
#
# Exit 0: the mark is a full commit hash in the current branch's history.
#         It prints "usable: <hash>".
# Exit 1: the mark is missing, says "not yet checked", or does not resolve to
#         a commit in this branch's complete history. It prints
#         "not usable: <reason>".

set -u

plan=${1:-masterplan.md}

no() {
  echo "not usable: $1"
  exit 1
}

[ -f "$plan" ] || no "there is no $plan"

mark=$(sed -n 's/^Trued against:[[:space:]]*//p' "$plan" | head -n 1 | sed 's/[[:space:]]*$//')
count=$(grep -c '^Trued against:' "$plan" || true)
[ "$count" -gt 0 ] || no "the masterplan has no Trued against: line"
[ "$count" -eq 1 ] || no "the masterplan has $count Trued against: lines"
[ -n "$mark" ] || no "the Trued against: line is empty"
[ "$mark" != "not yet checked" ] || no "the masterplan has not been checked against the code yet"

case $mark in
  *[!0-9a-f]*) no "the mark is not a commit hash: $mark" ;;
esac
[ "${#mark}" -eq 40 ] || [ "${#mark}" -eq 64 ] || no "the mark is not a full commit hash: $mark"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || no "this folder is not a git repository"
[ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = false ] ||
  no "the history here is incomplete, so the mark cannot be placed in it"
git cat-file -e "$mark^{commit}" 2>/dev/null || no "the mark names no commit in this repository"
git merge-base --is-ancestor "$mark" HEAD 2>/dev/null ||
  no "the mark is outside the current branch's history"

echo "usable: $mark"
exit 0
