#!/usr/bin/env sh
# sensitive-area-map.sh: run the shipped sensitive-area check in a throwaway
# project. If this breaks, a Build with care project whose risky code moves, or
# gains a source folder nobody assigned, keeps a green tick while its map of
# where the money or personal data lives quietly goes stale.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
CHECK="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh"
[ -f "$CHECK" ] || { echo "FAIL: missing $CHECK" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
check() {
  if [ "$2" = yes ]; then echo "  ok: $1"; else echo "FAIL: $1" >&2; exit 1; fi
}

echo "Sensitive-area map check:"
project="$tmp/project"
mkdir -p "$project/.agents/hooks" "$project/src/billing"
cp "$CHECK" "$project/.agents/hooks/check-sensitive-areas.sh"
printf '%s\n' 'export const charge = true' > "$project/src/billing/charge.ts"
printf '%s\n' \
  '# Masterplan' \
  '## Build path' \
  'Path: Build with care' \
  'Sensitive areas:' \
  '  money: refunds; caution: checked; done 2026-09-18' \
  '    paths: src/billing/' \
  '    boundary: reached only through src/billing/charge.ts' \
  > "$project/masterplan.md"

if sh "$project/.agents/hooks/check-sensitive-areas.sh" > "$tmp/out" 2>&1; then
  pass=yes
else
  pass=no
fi
check "a current map passes" "$pass"

mv "$project/src/billing" "$project/src/payments"
if sh "$project/.agents/hooks/check-sensitive-areas.sh" > "$tmp/out" 2>&1; then
  moved=no
else
  moved=yes
fi
check "a moved listed folder fails" "$moved"
grep -Fq 'src/billing/ is listed but does not exist' "$tmp/out" && named=yes || named=no
check "the failure names the moved path" "$named"

sed 's@src/billing/@src/payments/@g' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
mkdir -p "$project/services"
printf '%s\n' 'export const send = true' > "$project/services/send.ts"
if sh "$project/.agents/hooks/check-sensitive-areas.sh" > "$tmp/out" 2>&1; then
  unassigned=no
else
  unassigned=yes
fi
check "an unassigned source folder fails" "$unassigned"
grep -Fq 'services is a source folder with no area or none line' "$tmp/out" && named=yes || named=no
check "the failure names the unassigned folder" "$named"

sed 's/Path: Build with care/Path: Build and run it/' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
if [ -z "$(sh "$project/.agents/hooks/check-sensitive-areas.sh" 2>&1)" ]; then
  silent=yes
else
  silent=no
fi
check "the check is silent on another build path" "$silent"

echo "sensitive-area-map.sh: all checks passed"
