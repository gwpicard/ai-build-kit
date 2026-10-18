#!/usr/bin/env sh
# sensitive-area-map.sh: run the shipped risk-area check in a throwaway
# project. If this breaks, a project whose risky code moves, or gains a source
# folder nobody assigned, keeps a green tick while its map of where the money or
# personal data lives quietly goes stale, or an area the person already accepted
# keeps holding their work.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
CHECK="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh"
[ -f "$CHECK" ] || { echo "FAIL: missing $CHECK" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
check() {
  if [ "$2" = yes ]; then echo "  ok: $1"; else echo "FAIL: $1" >&2; exit 1; fi
}

echo "Risk-area map check:"
project="$tmp/project"
mkdir -p "$project/.agents/hooks" "$project/src/billing"
git -C "$project" init -q
git -C "$project" config user.name "Test User"
git -C "$project" config user.email "test@example.invalid"
cp "$CHECK" "$project/.agents/hooks/check-sensitive-areas.sh"
run_check() { (cd "$project" && sh .agents/hooks/check-sensitive-areas.sh "$@"); }
printf '%s\n' 'export const charge = true' > "$project/src/billing/charge.ts"
printf '%s\n' \
  '# Masterplan' \
  '## Risk record' \
  'Risk areas:' \
  '  money: refunds; caution: checked; not yet done' \
  '    paths: src/billing/' \
  '    boundary: reached only through src/billing/charge.ts' \
  > "$project/masterplan.md"
git -C "$project" add .
git -C "$project" commit -qm baseline
base=$(git -C "$project" rev-parse HEAD)

if run_check > "$tmp/out" 2>&1; then
  pass=yes
else
  pass=no
fi
check "a current map passes" "$pass"

if run_check --change "" > "$tmp/out" 2>&1; then
  empty_base=no
else
  code=$?
  [ "$code" -eq 2 ] && empty_base=yes || empty_base=no
fi
check "an empty base commit exits 2" "$empty_base"

git -C "$project" checkout -qb change
printf '%s\n' 'export const charge = false' > "$project/src/billing/charge.ts"
git -C "$project" add src/billing/charge.ts
git -C "$project" commit -qm changed
if run_check --change "$base" > "$tmp/out" 2>&1; then
  open=no
else
  open=yes
fi
check "a changed open area fails: $(cat "$tmp/out")" "$open"
grep -Fq 'This changes money, which still needs your decision.' "$tmp/out" && named=yes || named=no
check "the open area and decision are named" "$named"

# A date on the area line is not an acceptance. The record needs the person's words.
sed 's/caution: checked; not yet done/caution: waiting; accepted 2026-09-18/' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
printf '%s\n' 'Accepted: none' >> "$project/masterplan.md"
git -C "$project" add -A
git -C "$project" commit -qm 'Date without words'
if run_check --change "$base" > "$tmp/out" 2>&1; then
  unrecorded=no
else
  unrecorded=yes
fi
check "a dated area with no recorded words still holds" "$unrecorded"
grep -Fq 'still needs your decision' "$tmp/out" && named=yes || named=no
check "the unrecorded acceptance is reported as open" "$named"
git -C "$project" reset -q --hard HEAD~1

sed 's/caution: checked; not yet done/caution: waiting; accepted 2026-09-18/' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
printf '%s\n' '    Accepted: I accept this exposure on 2026-09-18' >> "$project/masterplan.md"
git -C "$project" add -A
git -C "$project" commit -qm accepted
if run_check --change "$base" > "$tmp/out" 2>&1; then
  accepted=yes
else
  accepted=no
fi
check "a changed accepted area passes" "$accepted"
grep -Fq 'This changes money, which you accepted on 18 September 2026.' "$tmp/out" && named=yes || named=no
check "the accepted date is plain and named" "$named"

if run_check --bad > "$tmp/out" 2>&1; then
  usage=no
else
  code=$?
  [ "$code" -eq 2 ] && usage=yes || usage=no
fi
check "an invalid invocation exits 2" "$usage"

mv "$project/src/billing" "$project/src/payments"
if run_check > "$tmp/out" 2>&1; then
  moved=no
else
  moved=yes
fi
check "a moved listed folder fails" "$moved"
grep -Fq 'src/billing/ is listed but does not exist' "$tmp/out" && named=yes || named=no
check "the failure names the moved path" "$named"

sed 's@src/billing/@src/payments/@g' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
sed 's@src/payments/@src/payments/*.ts@' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
git -C "$project" add -A
git -C "$project" commit -qm 'Use a simple glob in the area map'
rename_base=$(git -C "$project" rev-parse HEAD)
git -C "$project" mv src/payments/charge.ts src/elsewhere.ts
git -C "$project" commit -qm 'Move a file out of the mapped area'
if run_check --change "$rename_base" > "$tmp/out" 2>&1; then
  changed=yes
else
  changed=no
fi
grep -Fq 'This changes money, which you accepted on 18 September 2026.' "$tmp/out" \
  && glob=yes || glob=no
check "a completed area passes after a rename" "$changed"
check "the changed path still names the accepted area" "$glob"
mkdir -p "$project/services"
printf '%s\n' 'export const send = true' > "$project/services/send.ts"
if run_check > "$tmp/out" 2>&1; then
  unassigned=no
else
  unassigned=yes
fi
check "an unassigned source folder fails" "$unassigned"
grep -Fq 'services is a source folder with no area or none line' "$tmp/out" && named=yes || named=no
check "the failure names the unassigned folder" "$named"

sed 's/^Risk areas:$/Risk areas: none/' "$project/masterplan.md" > "$tmp/masterplan"
cp "$tmp/masterplan" "$project/masterplan.md"
if [ -z "$(run_check 2>&1)" ]; then
  silent=yes
else
  silent=no
fi
check "a project that names no risk area gets no map check" "$silent"
if run_check --change "$base" > "$tmp/out" 2>&1; then
  none_change=yes
else
  none_change=no
fi
check "a change in a project with no risk area passes" "$none_change"

mv "$project/masterplan.md" "$tmp/masterplan.saved"
if [ -z "$(run_check --change "$base" 2>&1)" ]; then
  no_map=yes
else
  no_map=no
fi
check "a project without a map passes silently" "$no_map"

echo "sensitive-area-map.sh: all checks passed"
