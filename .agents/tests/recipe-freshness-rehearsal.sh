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
mkdir -p "$WORK/.claude/skills/setup-hosting/recipes/claude-demo"
sed -i.bak 's/Recipe: demo/Recipe: claude-demo/' "$WORK/AGENTS.md"
cat > "$WORK/.claude/skills/setup-hosting/recipes/claude-demo/recipe.md" <<'EOF'
Last checked: 2026-10-16
Superseded settings: none
EOF
python3 "$SCRIPT" "$WORK" >/dev/null || { echo "FAIL: a current Claude-only recipe was reported missing"; exit 1; }
echo "ok: a current recipe under .claude/skills is found"
sed -i.bak 's/Recipe: claude-demo/Recipe: demo/' "$WORK/AGENTS.md"
sed -i.bak 's/2026-10-16/2026-01-01/' "$WORK/.agents/skills/setup-hosting/recipes/demo/recipe.md"
set +e
output=$(python3 "$SCRIPT" "$WORK")
status=$?
set -e
[ "$status" -eq 1 ] || { echo "FAIL: old check date returned $status"; exit 1; }
case "$output" in *"last checked 2026-01-01"*) ;; *) echo "FAIL: old check date was not named"; exit 1 ;; esac
echo "ok: reports a recipe whose upstream check is over 90 days old"
sed -i.bak 's/2026-01-01/2099-01-01/' "$WORK/.agents/skills/setup-hosting/recipes/demo/recipe.md"
set +e
output=$(python3 "$SCRIPT" "$WORK")
status=$?
set -e
[ "$status" -eq 2 ] || { echo "FAIL: future check date returned $status"; exit 1; }
case "$output" in *"Last checked date is in the future"*) ;; *) echo "FAIL: future check date was not rejected"; exit 1 ;; esac
echo "ok: refuses a recipe check date in the future"
