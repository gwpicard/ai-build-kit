#!/usr/bin/env sh
# check-review.sh: hold the project check while a review finding is unticked,
# or while the review record does not name the commit under check.

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
if ! view=$(gh pr view "$PR_NUMBER" --json body,headRefOid); then
  echo "Review check: could not read the pull request" >&2
  exit 2
fi
base=${PR_BASE_SHA:-main}
plan=$(git -C "$ROOT" show "$base:masterplan.md" 2>/dev/null || true)
printf '%s\n' "$view" | REVIEW_PLAN="$plan" PYTHONPATH="$(dirname "$PARSER")" python3 -c '
import json
import os
import re
import sys
import review_boxes

try:
    data = json.loads(sys.stdin.read())
    body = data.get("body") or ""
    head = str(data.get("headRefOid") or "")
    opened = review_boxes.open_review_box(body)
except (OSError, UnicodeError, ValueError, AttributeError) as error:
    print("Review check: could not read the pull request: " + str(error), file=sys.stderr)
    raise SystemExit(2)
if opened:
    print("Review check: a finding under Worth stopping for is unticked", file=sys.stderr)
    raise SystemExit(1)
plan = os.environ.get("REVIEW_PLAN", "")
path = re.search(r"(?m)^Path:\s*(.+?)\s*$", plan)
if not path:
    print("Review check: build path is missing from the pull-request base", file=sys.stderr)
    raise SystemExit(2)
if path.group(1) != "Explore privately":
    if not hasattr(review_boxes, "review_hold"):
        print("Review check: the shared review reader is out of date. Update the kit copy.", file=sys.stderr)
        raise SystemExit(2)
    if not head:
        print("Review check: the pull request names no head commit", file=sys.stderr)
        raise SystemExit(2)
    reason = review_boxes.review_hold(body, head)
    if not re.search(r"(?m)^## Worth stopping for[ \t]*\r?$", body):
        reason = "no review recorded yet"
    if reason:
        print("Review check: " + reason, file=sys.stderr)
        raise SystemExit(1)
    if not review_boxes.review_verified(body):
        print("Review check: the review is unverified. The kit could not confirm that a second person read this version.")
print("Review check: no unticked findings")
'
