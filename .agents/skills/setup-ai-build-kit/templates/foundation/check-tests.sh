#!/usr/bin/env sh
# Fail when a test changes after its red commit without a reason.
#
# Test: commits freeze their tests in Git history. A later edit needs a
# Test fix: subject with a reason. A Trim: commit never changes a test.
#
# Usage: check-tests.sh [RANGE]. RANGE defaults to the pull request's commits,
# origin/<base>..HEAD, with the base GitHub names or main.
#
# TEST_PATH below is the kit's one rule for which paths are tests. The kit's
# test and trim guards read it from this file, so they always agree. Keep it
# on one line, in single quotes, readable by both
# grep -E and Python.

set -u

TEST_PATH='(^|/)(tests?|__tests__|__mocks__|spec|testdata|__snapshots__|e2e|cypress|fixtures?)/|\.test\.[^/]+$|[.-]spec\.[^/]+$|_spec\.rb$|(^|/)test_[^/]*\.py$|(^|/)tests\.py$|_test\.(py|go)$|(^|/)(conftest\.py|pytest\.ini|setupTests\.[^/]+|(jest|vitest|playwright|cypress|karma)\.(config|setup|workspace)\.[^/]+)$'

range=${1:-origin/${GITHUB_BASE_REF:-main}..HEAD}

commits=$(git log --format='%H %s' "$range" 2>/dev/null) || {
  echo "Test check: the commits in $range could not be read, so no test change was checked. The check needs the whole history: the checkout step must fetch it, with fetch-depth: 0." >&2
  exit 2
}

failed=0

# A Trim: commit cannot change any test, whether or not it was written in
# this piece.
for commit in $(git log --format='%H' --grep='^Trim:' "$range" 2>/dev/null); do
  git diff-tree --no-commit-id --name-only -r "$commit" | grep -E "$TEST_PATH" |
    while IFS= read -r file; do
      echo "Test check: the trim commit $(printf '%.7s' "$commit") changed the test $file. A trim never changes a test." >&2
      echo fail
    done
done | grep -q fail && failed=1

# Test files changed by a Test: commit are frozen for the rest of this range.
# A Test fix: commit may change them only when its subject gives a reason.
for commit in $(git log --format='%H' --grep='^Test:' "$range" 2>/dev/null); do
  subject=$(git show -s --format=%s "$commit")
  for file in $(git diff-tree --no-commit-id --name-only -r "$commit" | grep -E "$TEST_PATH" || true); do
    changed=$(git log --format='%H %s' "$commit..HEAD" -- "$file")
    [ -n "$changed" ] || continue
    while IFS= read -r line; do
      later=${line%% *}
      later_subject=${line#* }
      case "$later_subject" in
        'Test fix:'*)
          reason=${later_subject#Test fix:}
          [ -n "$(printf '%s' "$reason" | tr -d '[:space:]')" ] || {
            echo "Test check: $file changed in $later without a reason." >&2
            failed=1
          }
          ;;
        Trim:*)
          echo "Test check: the trim commit $(printf '%.7s' "$later") changed the test $file. A trim never changes a test." >&2
          failed=1
          ;;
        *)
          echo "Test check: $file from $commit changed in $later without a Test fix: reason." >&2
          failed=1
          ;;
      esac
    done <<EOF
$changed
EOF
  done
done

[ "$failed" -eq 0 ] || exit 1
exit 0
