#!/usr/bin/env sh
# recipe-freshness-rehearsal.sh: prove /maintain reads recipe freshness and old names.
# If this breaks, a project using a stale recommendation gets no notice or a false one.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/maintain/scripts/recipe-freshness.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/.agents/skills/setup-hosting/recipes/demo"
cat > "$WORK/AGENTS.md" <<'EOF'
# Project
Recipe: demo
EOF
cat > "$WORK/.agents/skills/setup-hosting/recipes/demo/recipe.md" <<'EOF'
Last checked: 2026-10-16
Superseded settings: NEXT_PUBLIC_OLD_KEY
EOF
printf 'NEXT_PUBLIC_OLD_KEY=old\n' > "$WORK/.env.example"
set +e
output=$(python3 "$SCRIPT" "$WORK")
status=$?
set -e
[ "$status" -eq 1 ] || { echo "FAIL: old setting returned $status"; exit 1; }
case "$output" in *"superseded setting NEXT_PUBLIC_OLD_KEY"*) ;; *) echo "FAIL: old setting was not named"; exit 1 ;; esac
echo "ok: reports a superseded setting in the project's settings file"
printf 'NEXT_PUBLIC_NEW_KEY=current\n' > "$WORK/.env.example"
python3 "$SCRIPT" "$WORK" >/dev/null || { echo "FAIL: current settings were reported stale"; exit 1; }
echo "ok: a current setting produces no stale warning"
sed -i.bak 's/2026-10-16/2026-01-01/' "$WORK/.agents/skills/setup-hosting/recipes/demo/recipe.md"
set +e
output=$(python3 "$SCRIPT" "$WORK")
status=$?
set -e
[ "$status" -eq 1 ] || { echo "FAIL: old check date returned $status"; exit 1; }
case "$output" in *"last checked 2026-01-01"*) ;; *) echo "FAIL: old check date was not named"; exit 1 ;; esac
echo "ok: reports a recipe whose upstream check is over 90 days old"
