#!/usr/bin/env sh
# Fail when a trim commit changed a test.
#
# The trim removes and folds code, and never changes a test or the data a test
# reads. Its commits carry a subject starting "Trim:". This reads each such
# commit in the pull request and fails, naming the commit and the file, when
# one of them changed a test path.
#
# Usage: check-trim.sh [RANGE]. RANGE defaults to the pull request's commits,
# origin/<base>..HEAD, with the base GitHub names or main.

set -u

TEST_PATH='(^|/)(tests?|__tests__|spec|testdata|__snapshots__|e2e|fixtures?)/|\.(test|spec)\.[^/]+$|(^|/)test_[^/]*\.py$|_test\.(py|go)$|(^|/)conftest\.py$'

range=${1:-origin/${GITHUB_BASE_REF:-main}..HEAD}

commits=$(git log --format='%H %s' "$range" 2>/dev/null) || {
  echo "Trim check: the commits in $range could not be read, so no trim commit was checked."
  exit 0
}

failed=0
printf '%s\n' "$commits" | while read -r commit subject; do
  case $subject in
    Trim:*) ;;
    *) continue ;;
  esac
  git diff-tree --no-commit-id --name-only -r "$commit" | grep -E "$TEST_PATH" |
    while IFS= read -r file; do
      echo "Trim check: the trim commit $(printf '%.7s' "$commit") changed the test $file. The trim never changes a test. Undo that commit and run the trim again." >&2
      echo fail
    done
done | grep -q fail && failed=1

exit $failed
