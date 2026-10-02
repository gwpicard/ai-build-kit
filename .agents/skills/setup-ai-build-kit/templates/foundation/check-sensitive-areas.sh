#!/usr/bin/env sh
# Check that the Build with care map still names every source area.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)
PLAN="$ROOT/masterplan.md"

[ -f "$PLAN" ] || exit 0
[ ! -L "$PLAN" ] || { echo "Project overview is redirected; /sync can restore the record." >&2; exit 1; }
if grep -q 'ai-build-kit:records' "$PLAN"; then
  [ "$(grep -o 'ai-build-kit:records' "$PLAN" | wc -l | tr -d ' ')" -eq 1 ] &&
    grep -Fxq '<!-- ai-build-kit:records:v1 -->' "$PLAN" ||
    { echo "Project record format is unknown or repeated." >&2; exit 1; }
  [ ! -L "$ROOT/docs" ] || { echo "Record folder is redirected." >&2; exit 1; }
  PLAN="$ROOT/docs/working-rules.md"
  [ -f "$PLAN" ] && [ ! -L "$PLAN" ] || { echo "Working rules are missing or redirected; /sync can restore the record." >&2; exit 1; }
  [ "$(grep -c '^Path:' "$PLAN")" -eq 1 ] || { echo "Working rules need exactly one Path field." >&2; exit 1; }
fi
path=$(sed -n 's/^Path:[[:space:]]*//p' "$PLAN" | head -n 1)
[ "$path" = "Build with care" ] || exit 0

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

sed -n -E 's/^[[:space:]]+(paths|none):[[:space:]]*//p' "$PLAN" |
  tr ',' '\n' |
  sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; /^$/d' > "$tmp/listed"

failed=0
: > "$tmp/assigned"
while IFS= read -r listed; do
  clean=${listed#./}
  top=${clean%%/*}
  printf '%s\n' "$top" >> "$tmp/assigned"
  if [ ! -e "$ROOT/$clean" ]; then
    echo "Sensitive-area map: $clean is listed but does not exist. Say where it moved." >&2
    failed=1
  fi
done < "$tmp/listed"

for dir in "$ROOT"/*; do
  [ -d "$dir" ] || continue
  name=$(basename -- "$dir")
  case "$name" in
    build|coverage|dist|docs|node_modules|test|tests|vendor) continue ;;
  esac
  if find "$dir" -type f \( \
      -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.cs' -o \
      -name '*.go' -o -name '*.java' -o -name '*.js' -o -name '*.jsx' -o \
      -name '*.kt' -o -name '*.php' -o -name '*.py' -o -name '*.rb' -o \
      -name '*.rs' -o -name '*.swift' -o -name '*.ts' -o -name '*.tsx' \
    \) -print -quit | grep -q .; then
    if ! grep -Fxq "$name" "$tmp/assigned"; then
      echo "Sensitive-area map: $name is a source folder with no area or none line. Say where it belongs." >&2
      failed=1
    fi
  fi
done

exit "$failed"
