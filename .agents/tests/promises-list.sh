#!/usr/bin/env sh
# promises-list.sh: named checks in the promise list still exist.

set -eu
ROOT=${PROMISES_ROOT:-$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)}
LIST="$ROOT/docs/PROMISES.md"
SCENARIOS="$ROOT/.agents/tests/scenarios.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$LIST" ] || fail "docs/PROMISES.md is missing"
[ -f "$SCENARIOS" ] || fail ".agents/tests/scenarios.md is missing"

while IFS= read -r path; do
  [ -n "$path" ] || continue
  [ -f "$ROOT/$path" ] || fail "named checker is missing: $path"
done <<EOF
$(awk -F'`' '/^\|/ { for (i = 2; i <= NF; i += 2) if ($i ~ /^\.agents\/.*\.(sh|py)$/) print $i }' "$LIST")
EOF

while IFS= read -r number; do
  [ -n "$number" ] || continue
  grep -q "^## $number\. " "$SCENARIOS" || fail "named replay scenario is missing: $number"
done <<EOF
$(sed -n '/^|.*replay scenario[s]* /s/^.*replay scenario[s]* //p' "$LIST" | grep -oE '[0-9]+')
EOF

echo "promises-list.sh: named scripts and replay scenarios exist"
