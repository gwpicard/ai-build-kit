#!/usr/bin/env sh
# housekeeping-inventory.sh: the housekeeping inventory lists leftovers and changes nothing.
#
# The inventory is the first step of clearing up, and the only one that runs
# without approval, so two things must hold. It must find what the kit's tools
# leave behind, or the maintainer approves a list with holes in it. And it must
# not move, delete or open anything, including a file named like a key.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
INVENTORY="$ROOT/.agents/maintainer-skills/housekeeping/scripts/inventory.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }
pass=0
ok() { echo "  ok: $1"; pass=$((pass + 1)); }

# A throwaway repository beside the places the tools write.
repo="$WORK/projects/kit"
mkdir -p "$repo/.agents/tmp" "$WORK/projects/abk-wt/old-run" "$WORK/var/abk-tbu" \
  "$WORK/private/abk-check" "$WORK/user/abk-mutate-1" "$WORK/home/.local/state/abk-replay/results-old"
git -C "$repo" init -q -b main
git -C "$repo" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m start
git -C "$repo" branch merged-branch
git -C "$repo" checkout -q -b open-branch
git -C "$repo" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m work
git -C "$repo" checkout -q main
printf 'note\n' > "$repo/.agents/tmp/old-note.md"
printf 'SECRET=do-not-print\n' > "$WORK/projects/abk-wt/old-run/.env"
before=$(cd "$WORK" && find . -print | sort; cat projects/abk-wt/old-run/.env)

out=$(HOME="$WORK/home" TMPDIR="$WORK/user" VAR_TMP="$WORK/var" PRIVATE_TMP="$WORK/private" \
  "$INVENTORY" "$repo")

echo "Housekeeping inventory checks:"
for expected in "repo-tmp	$repo/.agents/tmp/old-note.md" "sibling	$WORK/projects/abk-wt/old-run" \
    "var-tmp	$WORK/var/abk-tbu" "private-tmp	$WORK/private/abk-check" \
    "mutate	$WORK/user/abk-mutate-1" "replay-state	$WORK/home/.local/state/abk-replay/results-old"; do
  printf '%s\n' "$out" | grep -qF "$expected" || fail "the inventory missed: $expected"
done
ok "it finds a leftover in each place the kit's tools write"

printf '%s\n' "$out" | grep -q "^branch	merged-branch	.*	merged" || fail "a merged branch was not marked merged"
printf '%s\n' "$out" | grep -q "^branch	open-branch	.*	unmerged" || fail "an unmerged branch was not marked unmerged"
ok "it tells a merged branch from an unmerged one"

printf '%s\n' "$out" | grep -qF "credential-name	$WORK/projects/abk-wt/old-run/.env" || \
  fail "a file named like a key was not flagged"
printf '%s\n' "$out" | grep -q 'do-not-print' && fail "the inventory printed a key's value"
ok "it flags a file named like a key without printing what is in it"

after=$(cd "$WORK" && find . -print | sort; cat projects/abk-wt/old-run/.env)
[ "$before" = "$after" ] || fail "the inventory changed the files it listed"
ok "it moves, deletes and changes nothing"

echo "housekeeping-inventory.sh: all $pass checks passed"
