#!/usr/bin/env sh
# check-review.sh: hold the project check while a review finding is unticked.

set -eu
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Review check: run this inside the project" >&2
  exit 2
}
PARSER="$ROOT/.agents/skills/merge/scripts/review_boxes.py"
[ -r "$PARSER" ] || { echo "Review check: shared review-box reader is missing" >&2; exit 2; }
PR_NUMBER=${PR_NUMBER:-}
case "$PR_NUMBER" in
  ''|*[!0-9]*) echo "Review check: pull request number is missing" >&2; exit 2 ;;
esac
if ! body=$(gh pr view "$PR_NUMBER" --json body --jq .body); then
  echo "Review check: could not read the pull request" >&2
  exit 2
fi
printf '%s\n' "$body" | PYTHONPATH="$(dirname "$PARSER")" python3 -c '
import sys
from review_boxes import open_review_box

try:
    opened = open_review_box(sys.stdin.read())
except (OSError, UnicodeError) as error:
    print("Review check: could not read the pull request body: " + str(error), file=sys.stderr)
    raise SystemExit(2)
if opened:
    print("Review check: a finding under Worth stopping for is unticked", file=sys.stderr)
    raise SystemExit(1)
print("Review check: no unticked findings")
'
