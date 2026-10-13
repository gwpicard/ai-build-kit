#!/usr/bin/env sh
# Fail when a trim commit changed a test.
#
# The trim removes and folds code, and never changes a test or the data a test
# reads. Its commits carry a subject starting "Trim:". This reads each such
# commit in the pull request and fails, naming the commit and the file, when
# one of them changed a test path. When it cannot read the commits, it fails
# too, since a trim it never read is not a trim it checked.
#
# Usage: check-trim.sh [RANGE]. RANGE defaults to the pull request's commits,
# origin/<base>..HEAD, with the base GitHub names or main.
#
# TEST_PATH below is the kit's one rule for which paths are tests. The kit's
# trim script and trim commit guard read it from this file, so all three
# always agree. Keep it on one line, in single quotes, readable by both
# grep -E and Python.

set -u

TEST_PATH='(^|/)(tests?|__tests__|__mocks__|spec|testdata|__snapshots__|e2e|cypress|fixtures?)/|\.test\.[^/]+$|[.-]spec\.[^/]+$|_spec\.rb$|(^|/)test_[^/]*\.py$|(^|/)tests\.py$|_test\.(py|go)$|(^|/)(conftest\.py|pytest\.ini|setupTests\.[^/]+|(jest|vitest|playwright|cypress|karma)\.(config|setup|workspace)\.[^/]+)$'

range=${1:-origin/${GITHUB_BASE_REF:-main}..HEAD}

commits=$(git log --format='%H %s' "$range" 2>/dev/null) || {
  echo "Trim check: the commits in $range could not be read, so no trim commit was checked. The check needs the whole history: the checkout step must fetch it, with fetch-depth: 0." >&2
  exit 2
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
