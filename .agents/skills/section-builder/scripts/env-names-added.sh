#!/usr/bin/env sh
# env-names-added.sh: name each setting a piece's branch adds to .env.example.
#
# On a live project the merge is a deploy. A piece that needs a new secret or
# service says so on a `Live side needs:` line, and the merge waits until the
# host has it. A piece shaped before that line existed has no line, so its new
# setting would reach the live copy with nothing checking the host first. The
# names in .env.example are the project's own list of what the tool reads, so
# comparing them between the branch and `main` finds such a setting by reading
# files rather than by judgement.
#
# Usage: sh env-names-added.sh [BRANCH [BASE]]
#
#   BRANCH  the piece's branch; HEAD when left out
#   BASE    what it merges into; origin/main where it exists, else main
#
# A name is a line such as `NAME=` or `export NAME=`. A commented example such
# as `# NAME=` is not a name the tool reads, so it does not count. Only names
# are printed, never a value.
#
# Exit 0: the branch adds no name.
# Exit 1: it adds at least one; each is printed on its own line.
# Exit 2: it could not tell, for example outside a Git project or with a
#         branch that does not exist. The last line printed says which.

set -u

me=env-names-added.sh

cannot() {
  echo "$me: $1" >&2
  exit 2
}

[ "$#" -le 2 ] || cannot "usage: sh $me [BRANCH [BASE]]"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || cannot "this folder is not a Git project"

branch=${1:-HEAD}
if [ "$#" -ge 2 ]; then
  base=$2
elif git rev-parse --verify -q origin/main >/dev/null 2>&1; then
  base=origin/main
else
  base=main
fi
for ref in "$branch" "$base"; do
  git rev-parse --verify -q "$ref^{commit}" >/dev/null 2>&1 || cannot "no branch or commit named $ref"
done

names() {
  # names <ref>: the setting names .env.example holds at that ref, sorted.
  if git cat-file -e "$1:.env.example" 2>/dev/null; then
    git show "$1:.env.example" | tr -d '\r' \
      | sed -n -E 's/^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=.*/\2/p' \
      | sort -u
  fi
}

tmp=$(mktemp -d) || cannot "no temporary folder"
trap 'rm -r "$tmp"' EXIT INT TERM
names "$base" > "$tmp/base"
names "$branch" > "$tmp/branch"
added=$(comm -13 "$tmp/base" "$tmp/branch")
[ -n "$added" ] || exit 0
printf '%s\n' "$added"
exit 1
