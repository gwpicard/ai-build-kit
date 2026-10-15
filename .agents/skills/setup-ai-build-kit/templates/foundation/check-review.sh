#!/usr/bin/env sh
# check-review.sh: hold the project check while a review finding is unticked.

set -eu
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Review check: run this inside the project" >&2
  exit 2
}
PARSER="$ROOT/.agents/hooks/review_boxes.py"
[ -r "$PARSER" ] || { echo "Review check: shared review-box reader is missing" >&2; exit 2; }
PR_NUMBER=${PR_NUMBER:-}
case "$PR_NUMBER" in
  ''|*[!0-9]*) echo "Review check: pull request number is missing" >&2; exit 2 ;;
esac
if ! body=$(gh pr view "$PR_NUMBER" --json body --jq .body); then
  echo "Review check: could not read the pull request" >&2
  exit 2
fi
base=${PR_BASE_SHA:-main}
plan=$(git -C "$ROOT" show "$base:masterplan.md" 2>/dev/null || true)
printf '%s\n' "$body" | REVIEW_PLAN="$plan" PYTHONPATH="$(dirname "$PARSER")" python3 -c '
import sys
import re
from review_boxes import open_review_box

try:
    body = sys.stdin.read()
    opened = open_review_box(body)
except (OSError, UnicodeError) as error:
    print("Review check: could not read the pull request body: " + str(error), file=sys.stderr)
    raise SystemExit(2)
if opened:
    print("Review check: a finding under Worth stopping for is unticked", file=sys.stderr)
    raise SystemExit(1)
plan = __import__("os").environ.get("REVIEW_PLAN", "")
path = re.search(r"(?m)^Path:\s*(.+?)\s*$", plan)
if not path:
    print("Review check: build path is missing from the pull-request base", file=sys.stderr)
    raise SystemExit(2)
if not re.search(r"(?m)^## Worth stopping for\s*$", body) or not re.search(r"(?m)^Review record: reviewed=.+; tried=\d+; open=\d+\s*$", body):
    if path and path.group(1) != "Explore privately":
        print("Review check: no review recorded yet", file=sys.stderr)
        raise SystemExit(1)
print("Review check: no unticked findings")
'
