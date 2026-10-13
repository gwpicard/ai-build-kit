#!/usr/bin/env sh
# hosting-request.sh: refuse a hosting, data or deploy product named in any
# skill file outside setup-hosting/recipes/. If this breaks, a skill can learn
# one service's behaviour and then read wrongly on every project that runs
# somewhere else, with nothing on screen to say so.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
ok() { echo "  ok: $1"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

echo "Product names stay in the recipes:"

# The screen rules link Vercel's interface guidelines, a design guide rather
# than a place a tool runs, so that one link is set aside before the read.
PRODUCTS='coolify|vercel|supabase|netlify|heroku|railway|railpack|fly\.io|hetzner|hostinger|firebase|digitalocean'
products_named() {
  # products_named <skills folder>: each file and line that names a product.
  # The founding settings template is a list of rules Claude Code applies, not
  # words a skill learns from. It names the recipes' own commands that change a
  # live service, so a box asks before each one, and it is read whole by
  # push-to-main-rules.sh.
  find "$1" -type f ! -path '*/setup-hosting/recipes/*' ! -path '*/maintain/scripts/kit-released-copies.json' ! -path '*/maintain/scripts/kit-retired-skills.json' ! -path '*/templates/foundation/claude-settings.json' | sort | while IFS= read -r pn_file; do
    tr '[:upper:]' '[:lower:]' < "$pn_file" \
      | sed -e 's#vercel web interface guidelines##g' \
            -e 's#github\.com/vercel-labs/web-interface-guidelines##g' \
      | grep -nE "$PRODUCTS" | sed "s#^#$pn_file:#" || true
  done
}
named=$(products_named "$ROOT/.agents/skills")
if [ -n "$named" ]; then
  printf '%s\n' "$named" >&2
  fail "a skill file outside the recipes names a hosting, data or deploy product"
fi
ok "no skill file outside the recipes names a hosting, data or deploy product"

# The read has to notice a name, keep the exemption narrow, and leave the
# recipes alone, or it proves nothing.
mkdir -p "$tmp/skills/setup-hosting/recipes/parts" "$tmp/skills/screen-check" "$tmp/skills/setup-hosting/references"
grep -i 'web interface guidelines' "$ROOT/.agents/skills/screen-check/SKILL.md" > "$tmp/skills/screen-check/SKILL.md"
printf '%s\n' 'Runs on Vercel with a Supabase database.' > "$tmp/skills/setup-hosting/recipes/on-vercel.md"
printf '%s\n' 'Backups on Supabase.' > "$tmp/skills/setup-hosting/recipes/parts/backup.md"
[ -z "$(products_named "$tmp/skills")" ] ||
  fail "the guidelines link, a recipe or a part was counted as a product name"
ok "the guidelines link, a recipe and a part are left alone"
printf '%s\n' 'Deploy it to Vercel.' > "$tmp/skills/setup-hosting/references/steps.md"
[ -n "$(products_named "$tmp/skills")" ] ||
  fail "a skill file naming a hosting product was not noticed"
ok "a skill file naming a hosting product is noticed"
printf '%s\n' 'Vercel is fast.' 'The Vercel Web Interface Guidelines' > "$tmp/skills/setup-hosting/references/steps.md"
[ -n "$(products_named "$tmp/skills")" ] ||
  fail "the guidelines exemption hid a product named elsewhere in the same file"
ok "the guidelines exemption hides nothing else in the same file"

echo "hosting-request.sh: all checks passed"
