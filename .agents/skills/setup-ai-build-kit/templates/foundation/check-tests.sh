#!/usr/bin/env sh
# Test subjects freeze existing test lines; Test fix: subjects need a reason.
set -u
# The broad rule protects test files, fixtures and runner configuration from a trim.
TEST_PATH='(^|/)(tests?|__tests__|__mocks__|spec|e2e|cypress|testdata|testfixtures?|fixtures?)(/|$)|(^|/)(conftest\.py|pytest\.(ini|toml))$|(^|/)setupTests\.[^/]+$|(^|/)(jest|vitest|playwright|cypress|karma|mocha)\.config\.[^/]+$|\.test\.[^/]+$|[.-]spec\.[^/]+$|_spec\.rb$|(^|/)test_[^/]*\.py$|(^|/)tests\.py$|_test\.(py|go)$'
# Only named test files are frozen by a red commit.
TEST_FILE_PATH='(^|/)(tests?|__tests__|__mocks__|spec|e2e|cypress)/(.*/)?[^/]+\.(js|jsx|ts|tsx|mjs|cjs|mts|cts|py|rb|go)$|\.test\.[^/]+$|[.-]spec\.[^/]+$|_spec\.rb$|(^|/)test_[^/]*\.py$|(^|/)tests\.py$|_test\.(py|go)$'
range=${1:-origin/${GITHUB_BASE_REF:-main}..HEAD}
commits=$(git log --format='%H%x09%s' "$range" 2>/dev/null) || {
  echo "Test check: commits in $range could not be read; fetch the full history." >&2; exit 2;
}
failed=0
reported=$(mktemp)
trap 'rm -f "$reported"' EXIT HUP INT TERM

report_once() {
  message=$1
  key=$(printf '%s\n' "$message" | sed -E 's/[0-9a-f]{40}/<commit>/g')
  if ! grep -Fqx "$key" "$reported"; then
    printf '%s\n' "$key" >> "$reported"
    printf '%s\n' "$message" >&2
  fi
}

# Subject matching is deliberate: tags in a commit body do not count.
while IFS="$(printf '\t')" read -r commit subject; do
  case "$subject" in
    Trim:*)
      git diff-tree --root --no-commit-id --name-only -r "$commit" | while IFS= read -r file; do
        if printf '%s\n' "$file" | grep -Eq "$TEST_PATH"; then
          report_once "Test check: trim commit changed test $file."
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
    printf '%s\n' "$file" | grep -Eq "$TEST_FILE_PATH" || continue
    later_commits=$(git log --format='%H%x09%s' --reverse "$test_commit..HEAD" -- "$file")
    [ -n "$later_commits" ] || continue
    while IFS="$(printf '\t')" read -r later later_subject; do
      parent=$(git rev-parse "$later^" 2>/dev/null) || parent=$(git rev-list --max-parents=0 "$later")
      case "$later_subject" in
        'Test fix:'*)
          reason=${later_subject#Test fix:}
          if [ -z "$(printf '%s' "$reason" | tr -d '[:space:]')" ]; then
            report_once "Test check: $file changed in $later with an empty Test fix: reason."; failed=1
          fi
          ;;
        'Test:'*)
          if git diff --unified=0 "$parent" "$later" -- "$file" | awk 'substr($0, 1, 1) == "-" && substr($0, 1, 4) != "--- " { found=1 } END { exit !found }'; then
            report_once "Test check: $file changed existing lines in $later without Test fix: reason."; failed=1
          fi
          ;;
        Trim:*)
          report_once "Test check: trim commit changed test $file."; failed=1
          ;;
        *)
          if ! git diff --quiet "$parent" "$later" -- "$file"; then
            report_once "Test check: $file changed in $later without a Test fix: reason."; failed=1
          fi
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
