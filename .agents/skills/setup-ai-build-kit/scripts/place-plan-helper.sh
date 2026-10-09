#!/usr/bin/env sh
# place-plan-helper.sh: put the plan printout helper into a founded project.
#
# Founding copies the helper in. A project founded before the helper shipped
# inside this skill has no copy, or holds the older copy a whole copy of the kit
# carried, and an update only ever refreshes skills. So /maintain runs this on
# any visit whose upgrade check finds the helper missing, older or not
# runnable, and this is how the helper reaches such a project.
#
# It is safe to run again. A copy that already matches is left alone. A copy
# that differs is replaced, because the helper is the kit's machinery rather
# than the project's own work, and /maintain runs this only after its clean
# checkpoint, so the older copy stays in the project's saved history.
#
# Usage: place-plan-helper.sh [project-folder]
# With no folder, the current folder is the project.

set -eu

SKILL_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
HELPER="$SKILL_ROOT/templates/foundation/plan-refresh.sh"
TARGET=.agents/tools/plan-refresh.sh

fail() {
  echo "AI Build Kit could not place the plan helper: $1" >&2
  exit 1
}

case "$#" in
  0) PROJECT_ROOT=$(pwd -P) ;;
  1) PROJECT_ROOT=$1 ;;
  *) fail "usage: place-plan-helper.sh [project-folder]" ;;
esac

[ -d "$PROJECT_ROOT" ] || fail "project folder does not exist: $PROJECT_ROOT"
PROJECT_ROOT=$(CDPATH= cd -- "$PROJECT_ROOT" && pwd -P)
[ -f "$HELPER" ] && [ ! -L "$HELPER" ] || \
  fail "the installed setup-ai-build-kit skill carries no helper to copy"
# A founded project has a masterplan. Without one this is not a project the kit
# founded, and writing into it would be a guess about somebody else's folder.
[ -f "$PROJECT_ROOT/masterplan.md" ] || \
  fail "this folder holds no masterplan.md, so it is not a founded project"

for part in .agents .agents/tools; do
  [ ! -L "$PROJECT_ROOT/$part" ] || \
    fail "project path is redirected outside the project: $part"
  [ ! -e "$PROJECT_ROOT/$part" ] || [ -d "$PROJECT_ROOT/$part" ] || \
    fail "project path is not a folder: $part"
done

destination="$PROJECT_ROOT/$TARGET"
[ ! -L "$destination" ] || fail "$TARGET is a link, so it was left alone"
[ ! -e "$destination" ] || [ -f "$destination" ] || \
  fail "$TARGET is not a file, so it was left alone"

# The recovery message belongs to the printout too. Older plugin projects need
# the installed skill's location because their skills live outside the project.
for companion in codex-github-check.py codex-setup-path; do
  companion_target="$PROJECT_ROOT/.agents/tools/$companion"
  [ ! -L "$companion_target" ] || fail "$companion is a link, so it was left alone"
  [ ! -e "$companion_target" ] || [ -f "$companion_target" ] || \
    fail "$companion is not a file, so it was left alone"
done
mkdir -p "$PROJECT_ROOT/.agents/tools"
recovery="$PROJECT_ROOT/.agents/tools/codex-github-check.py"
if ! cmp -s "$SKILL_ROOT/templates/foundation/codex-github-check.py" "$recovery" 2>/dev/null; then
  cp "$SKILL_ROOT/templates/foundation/codex-github-check.py" "$recovery"
  chmod 755 "$recovery"
fi
location="$PROJECT_ROOT/.agents/tools/codex-setup-path"
if [ ! -f "$location" ] || [ "$(cat "$location")" != "$SKILL_ROOT" ]; then
  printf '%s\n' "$SKILL_ROOT" > "$location"
fi

if [ -f "$destination" ] && cmp -s "$HELPER" "$destination"; then
  if [ -x "$destination" ]; then
    echo "plan helper: already current at $TARGET"
  else
    chmod 755 "$destination"
    echo "plan helper: already current at $TARGET, and made runnable again, which is a change to save"
  fi
  exit 0
fi

if [ -f "$destination" ]; then
  outcome="replaced a copy that differed at $TARGET. Any change somebody made to it by hand was replaced too, and the earlier copy is in the checkpoint saved before this ran"
else
  outcome="added $TARGET"
fi

mkdir -p "$PROJECT_ROOT/.agents/tools"
cp "$HELPER" "$destination"
chmod 755 "$destination"
echo "plan helper: $outcome"
