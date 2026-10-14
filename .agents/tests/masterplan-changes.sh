#!/usr/bin/env sh
# masterplan-changes.sh: run the shipped trued-mark.sh in throwaway repositories.
#
# If this breaks, a build could treat a stale or made-up trued-against mark as
# usable, and the masterplan would look checked against code it never saw.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
ok() { echo "  ok: $1"; pass=$((pass + 1)); }
fail() { echo "FAIL: $1" >&2; exit 1; }

MARK="$ROOT/.agents/skills/setup-ai-build-kit/scripts/trued-mark.sh"
[ -f "$MARK" ] || fail "missing file $MARK"
repo="$WORK/repo"
git init -q "$repo"
git -C "$repo" config user.email rehearsal@example.com
git -C "$repo" config user.name Rehearsal
git -C "$repo" config commit.gpgsign false
printf '# Masterplan\n\nTrued against: not yet checked\n' > "$repo/masterplan.md"
git -C "$repo" add -A
git -C "$repo" commit -q -m first
first=$(git -C "$repo" rev-parse HEAD)
mark_is() {
  # mark_is <expected exit> <description> <mark line or "none">
  if [ "$3" = none ]; then
    printf '# Masterplan\n' > "$repo/masterplan.md"
  else
    printf '# Masterplan\n\n%s\n' "$3" > "$repo/masterplan.md"
  fi
  set +e
  out=$(cd "$repo" && sh "$MARK")
  got=$?
  set -e
  [ "$got" -eq "$1" ] || fail "$2: exited $got, not $1 ($out)"
  ok "$2"
}
mark_is 0 "a mark naming a commit in this branch is usable" "Trued against: $first"
[ "$out" = "usable: $first" ] || fail "a usable mark does not print its commit: $out"
ok "and the commit is printed for the build to move it on from"
mark_is 1 "a page never checked is not usable" "Trued against: not yet checked"
mark_is 1 "words of founding's own are not usable" "Trued against: founding starter; no features built yet"
mark_is 1 "a page with no mark is not usable" none
mark_is 1 "an empty mark is not usable" "Trued against:"
mark_is 1 "a short hash is not usable" "Trued against: $(printf '%s' "$first" | cut -c1-12)"
mark_is 1 "a hash naming no commit is not usable" "Trued against: 0123456789abcdef0123456789abcdef01234567"
mark_is 1 "two marks are not usable" "Trued against: $first
Trued against: $first"
git -C "$repo" checkout -q -b elsewhere
git -C "$repo" commit -q --allow-empty -m "off to one side"
aside=$(git -C "$repo" rev-parse HEAD)
git -C "$repo" checkout -q -
mark_is 1 "a commit outside this branch is not usable" "Trued against: $aside"
git -C "$repo" commit -q --allow-empty -m second
mark_is 0 "an older commit in this branch is still usable" "Trued against: $first"
shallow="$WORK/shallow"
git clone -q --depth 1 "file://$repo" "$shallow" 2>/dev/null
printf '# Masterplan\n\nTrued against: %s\n' "$(git -C "$shallow" rev-parse HEAD)" > "$shallow/masterplan.md"
set +e
out=$(cd "$shallow" && sh "$MARK")
got=$?
set -e
[ "$got" -eq 1 ] || fail "a mark in incomplete history was called usable: $out"
ok "a mark in incomplete history is not usable"
before=$(cd "$repo" && git status --porcelain && cat masterplan.md)
(cd "$repo" && sh "$MARK" >/dev/null 2>&1) || true
[ "$(cd "$repo" && git status --porcelain && cat masterplan.md)" = "$before" ] ||
  fail "the script changed something in the project"
ok "the script changes nothing in the project"

echo
echo "$(basename -- "$0"): all $pass checks passed"
