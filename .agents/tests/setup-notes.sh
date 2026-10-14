#!/usr/bin/env sh
# setup-notes.sh: prove in a throwaway project that the founding interview's
# working notes under .agents/tmp/ stay out of a commit. If this breaks, the
# person's half-agreed answers get swept into their project's history.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
IGNORE="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/gitignore"
[ -f "$IGNORE" ] || { echo "FAIL: missing $IGNORE" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
check() {
  if [ "$2" = yes ]; then echo "  ok: $1"; else echo "FAIL: $1" >&2; exit 1; fi
}

echo "Setup working-notes check:"
PROJECT="$tmp/project"
mkdir -p "$PROJECT/.agents/tmp"
git init -q "$PROJECT"
cp "$IGNORE" "$PROJECT/.gitignore"
printf 'Who uses it: the shop manager.\n' > "$PROJECT/.agents/tmp/setup-notes.md"

untracked=$(git -C "$PROJECT" status --porcelain --untracked-files=all | \
  grep -c 'setup-notes\.md' || true)
[ "$untracked" -eq 0 ] && r=yes || r=no
check "working notes stay out of a project's tracked work" "$r"

# The control: without the ignore line the same file would show up, so the check
# above is reading the ignore rule rather than an empty folder.
grep -v '^\.agents/tmp/$' "$PROJECT/.gitignore" > "$PROJECT/.gitignore.new"
mv "$PROJECT/.gitignore.new" "$PROJECT/.gitignore"
untracked=$(git -C "$PROJECT" status --porcelain --untracked-files=all | \
  grep -c 'setup-notes\.md' || true)
[ "$untracked" -eq 1 ] && r=yes || r=no
check "without the ignore line the same file would be offered for commit" "$r"

echo "setup-notes.sh: all checks passed"
