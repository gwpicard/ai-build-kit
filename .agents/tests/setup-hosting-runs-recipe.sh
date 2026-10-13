#!/usr/bin/env sh
# setup-hosting-runs-recipe.sh: refuse a deploy target from any recipe title,
# or another obvious product, named in /setup-hosting or its evidence run. If
# this breaks, the skill can learn one recipe's commands and then read wrongly
# on every other recipe, with nothing on screen to say so.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
HOSTING="$ROOT/.agents/skills/setup-hosting/SKILL.md"
EVIDENCE="$ROOT/.agents/skills/setup-hosting/references/evidence-run.md"
for f in "$HOSTING" "$EVIDENCE"; do
  [ -f "$f" ] || { echo "FAIL: missing $f" >&2; exit 1; }
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
ok() { echo "  ok: $1"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

echo "Setup-hosting names no recipe's product:"

targets=$(for rf in "$ROOT"/.agents/skills/setup-hosting/recipes/*.md "$ROOT"/.agents/tests/recipes-awaiting-run/*.md; do
  [ -f "$rf" ] || continue
  sed -n 's/^# Recipe: .* on \(.*\)$/\1/p' "$rf" | head -1
done | tr '[:upper:]' '[:lower:]' | sort -u | paste -sd'|' -)
[ -n "$targets" ] || fail "no recipe title named a deploy target, so the product read would check nothing"
PRODUCTS="$targets|supabase|netlify|heroku|railway|fly\.io|firebase"
names_in() {
  tr '[:upper:]' '[:lower:]' < "$1" | grep -nE "$PRODUCTS" || true
}
for sf in "$HOSTING" "$EVIDENCE"; do
  found=$(names_in "$sf")
  if [ -n "$found" ]; then
    printf '%s\n' "$found" >&2
    fail "$sf names a product that belongs in a recipe"
  fi
done
ok "setup-hosting and the evidence run name no product from any recipe"
cp "$HOSTING" "$tmp/hosting-named"
first_target=$(printf '%s' "$targets" | cut -d'|' -f1)
printf '%s\n' "Deploy it with $first_target." >> "$tmp/hosting-named"
[ -n "$(names_in "$tmp/hosting-named")" ] ||
  fail "a product named in the skill was not noticed"
ok "a product named in the skill is noticed"

echo "setup-hosting-runs-recipe.sh: all checks passed"
