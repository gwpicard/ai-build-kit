#!/usr/bin/env sh
# Save the trim as its own commit, and refuse it when it touched a test.
#
# The trim may remove and fold code, and never change a test or the data a
# test reads. A pass allowed to change tests learns to delete what the tests
# do not cover, and every step still looks green. So this commits every change
# in the working tree with a subject that starts "Trim:", which the project
# check reads, and refuses when any changed path is a test path.
#
# Usage, from inside the project, after the piece is committed:
#
#     trim-commit.sh [SUBJECT]
#
# Exit codes:
#     0  the trim is committed, or there was nothing to commit (it says which)
#     1  a test path changed; nothing was committed, and each path is named
#     2  not a project under Git

set -u

TEST_PATH='(^|/)(tests?|__tests__|spec|testdata|__snapshots__|e2e|fixtures?)/|\.(test|spec)\.[^/]+$|(^|/)test_[^/]*\.py$|_test\.(py|go)$|(^|/)conftest\.py$'

top=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "trim-commit: this folder is not a project under Git" >&2
  exit 2
}
cd "$top" || exit 2

subject=${1:-take out what the piece did not need}

changed=$(git status --porcelain --untracked-files=all | sed -E 's/^.. //; s/^.* -> //; s/^"//; s/"$//')
if [ -z "$changed" ]; then
  echo "trim-commit: nothing to commit, so the trim changed nothing"
  exit 0
fi

tests=$(printf '%s\n' "$changed" | grep -E "$TEST_PATH" || true)
if [ -n "$tests" ]; then
  echo "trim-commit: refused. The trim never changes a test, and these changed:" >&2
  printf '  %s\n' $tests >&2
  echo "Undo the edit that changed them, then run this again." >&2
  exit 1
fi

git add -A || exit 2
git commit -q -m "Trim: $subject" || exit 2
echo "trim-commit: saved as $(git rev-parse --short HEAD)"
