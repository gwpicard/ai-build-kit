#!/usr/bin/env sh
# Test subjects freeze existing test lines; Test fix: subjects need a reason.
set -u
TEST_PATH='(^|/)(tests?|__tests__|__mocks__|spec|testdata|__snapshots__|e2e|cypress)/|\.test\.[^/]+$|[.-]spec\.[^/]+$|_spec\.rb$|(^|/)test_[^/]*\.py$|(^|/)tests\.py$|_test\.(py|go)$'
range=${1:-origin/${GITHUB_BASE_REF:-main}..HEAD}
commits=$(git log --format='%H%x09%s' "$range" 2>/dev/null) || {
  echo "Test check: commits in $range could not be read; fetch the full history." >&2; exit 2;
}
failed=0

# Subject matching is deliberate: tags in a commit body do not count.
while IFS="$(printf '\t')" read -r commit subject; do
  case "$subject" in
    Trim:*)
      git diff-tree --root --no-commit-id --name-only -r "$commit" | while IFS= read -r file; do
        if printf '%s\n' "$file" | grep -Eq "$TEST_PATH"; then
          echo "Test check: trim commit $(printf '%.7s' "$commit") changed test $file." >&2
          echo fail
        fi
      done | grep -q fail && failed=1
      ;;
  esac
done <<EOF_COMMITS
$commits
EOF_COMMITS

while IFS="$(printf '\t')" read -r test_commit subject; do
  case "$subject" in Test:*) ;; *) continue ;; esac
  while IFS= read -r file; do
    printf '%s\n' "$file" | grep -Eq "$TEST_PATH" || continue
    later_commits=$(git log --format='%H%x09%s' "$test_commit..HEAD" -- "$file")
    [ -n "$later_commits" ] || continue
    while IFS="$(printf '\t')" read -r later later_subject; do
      case "$later_subject" in
        'Test fix:'*)
          reason=${later_subject#Test fix:}
          if [ -z "$(printf '%s' "$reason" | tr -d '[:space:]')" ]; then
            echo "Test check: $file changed in $later with an empty Test fix: reason." >&2; failed=1
          fi
          ;;
        'Test:'*)
          if git diff --unified=0 "$test_commit" "$later" -- "$file" | grep -Eq '^-[^-]'; then
            echo "Test check: $file changed existing lines in $later without Test fix: reason." >&2; failed=1
          fi
          ;;
        Trim:*)
          echo "Test check: trim commit $(printf '%.7s' "$later") changed test $file." >&2; failed=1
          ;;
        *)
          echo "Test check: $file from $test_commit changed in $later without a Test fix: reason." >&2; failed=1
          ;;
      esac
    done <<EOF_LATER
$later_commits
EOF_LATER
  done <<EOF_FILES
$(git diff-tree --root --no-commit-id --name-only -r "$test_commit")
EOF_FILES
done <<EOF_TESTS
$commits
EOF_TESTS
[ "$failed" -eq 0 ] || exit 1
exit 0
