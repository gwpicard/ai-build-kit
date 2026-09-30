#!/usr/bin/env sh
# test-guard.sh: list the test files a piece changed without naming them.
#
# An existing test may change only when the piece's Under the hood names it and
# gives the reason. A builder working alone can otherwise weaken a test until it
# passes, and a green check then proves nothing. section-builder runs this
# before it saves a piece, and /fix before it saves a repair.
#
# Usage: test-guard.sh <base> <piece-file>
#   base        the commit the piece's branch started from
#   piece-file  the piece's text, or - to read it from standard input
#
# Run it from inside the project. It compares the base with the working tree,
# so a change that is committed, staged or not yet staged all count. A new test
# file is never listed: adding a check changes no existing test.
#
# A test file is any file under a folder named test, tests or __tests__, or
# whose name contains .test. or .spec., or ends in _test before its extension.
#
# A changed test counts as named when its path, as the listing prints it,
# appears in the piece's Under the hood section. A piece with no such section
# names no test.
#
# Prints one path per line. Exits 0 when nothing is listed, 1 when something
# is, and 2 when it could not run.

set -eu

fail() {
  echo "test-guard: $1" >&2
  exit 2
}

[ "$#" -eq 2 ] || fail "usage: test-guard.sh <base> <piece-file>"
base=$1
piece=$2

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || \
  fail "run it from inside the project's folder"
git rev-parse --verify --quiet "$base^{commit}" >/dev/null || \
  fail "the base '$base' is not a commit in this project"

if [ "$piece" = "-" ]; then
  text=$(cat)
else
  [ -f "$piece" ] || fail "the piece file '$piece' does not exist"
  text=$(cat "$piece")
fi

# Only the Under the hood section names the tests a piece may change. It is a
# collapsed details block on a piece written from the template, or a heading on
# one written by hand.
hood=$(printf '%s\n' "$text" | awk '
  /<summary>[[:space:]]*Under the hood[[:space:]]*<\/summary>/ { inside = 1; next }
  inside && /<\/details>/ { inside = 0; next }
  /^#+[[:space:]]*Under the hood[[:space:]]*$/ { inside = 2; next }
  inside == 2 && /^#+[[:space:]]/ { inside = 0 }
  inside { print }
')

is_test() {
  case "/$1" in
    */test/*|*/tests/*|*/__tests__/*) return 0 ;;
  esac
  name=${1##*/}
  case "$name" in
    *.test.*|*.spec.*) return 0 ;;
  esac
  stem=${name%.*}
  case "$stem" in
    *_test) return 0 ;;
  esac
  return 1
}

# Renames are split into a deletion and an addition, so a test moved away
# counts as changed at its old path.
unnamed=$(git diff --no-renames --name-status "$base" -- | \
  while IFS="$(printf '\t')" read -r status path; do
    [ "$status" = "A" ] && continue
    is_test "$path" || continue
    printf '%s\n' "$hood" | grep -qF -- "$path" && continue
    printf '%s\n' "$path"
  done)

[ -n "$unnamed" ] || exit 0
printf '%s\n' "$unnamed"
exit 1
