#!/usr/bin/env sh
# Prepare the project-owned files that are needed before the start interview.

set -eu

SKILL_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
FOUNDATION="$SKILL_ROOT/templates/foundation"

fail() {
  echo "AI Build Kit setup stopped: $1" >&2
  exit 1
}

case "$#" in
  0) PROJECT_ROOT=$(pwd -P) ;;
  1) PROJECT_ROOT=$1 ;;
  *) fail "usage: bootstrap-project.sh [project-folder]" ;;
esac

[ -d "$PROJECT_ROOT" ] || fail "project folder does not exist: $PROJECT_ROOT"
PROJECT_ROOT=$(CDPATH= cd -- "$PROJECT_ROOT" && pwd -P)
[ "$PROJECT_ROOT" != "/" ] || fail "choose a project folder, not the filesystem root"
if [ -n "${HOME:-}" ]; then
  home_root=$(CDPATH= cd -- "$HOME" 2>/dev/null && pwd -P || true)
  [ "$PROJECT_ROOT" != "$home_root" ] || fail "choose a project folder, not the home folder"
fi
[ "$PROJECT_ROOT" != "$SKILL_ROOT" ] || fail "choose the project folder, not the start skill folder"
EXPECTED_START="$PROJECT_ROOT/.agents/skills/start"

PLUGIN_ROOT=$(CDPATH= cd -- "$SKILL_ROOT/../../.." && pwd -P)
PLUGIN_MANIFEST="$PLUGIN_ROOT/.claude-plugin/plugin.json"
PLUGIN_INSTALLATION=no
if [ -f "$PLUGIN_MANIFEST" ] && [ ! -L "$PLUGIN_MANIFEST" ] && \
   grep -Eq '"name"[[:space:]]*:[[:space:]]*"ai-build-kit"' "$PLUGIN_MANIFEST" && \
   grep -Eq '"\./\.claude/commands/start\.md"' "$PLUGIN_MANIFEST"; then
  PLUGIN_START="$PLUGIN_ROOT/.agents/skills/start"
  if [ -d "$PLUGIN_START" ]; then
    PLUGIN_START=$(CDPATH= cd -- "$PLUGIN_START" && pwd -P)
    [ "$PLUGIN_START" != "$SKILL_ROOT" ] || PLUGIN_INSTALLATION=yes
  fi
fi

if [ -d "$EXPECTED_START" ]; then
  EXPECTED_START=$(CDPATH= cd -- "$EXPECTED_START" && pwd -P)
  if [ "$EXPECTED_START" != "$SKILL_ROOT" ]; then
    [ "$PLUGIN_INSTALLATION" != "yes" ] || \
      fail "this project has both the Claude plugin and a separate AI Build Kit skill installation; keep one before running start"
    fail "the chosen project belongs to a different start skill installation"
  fi
else
  [ "$PLUGIN_INSTALLATION" = "yes" ] || \
    fail "the chosen project does not contain this installed start skill"
fi

validate_foundation_file() {
  source_relative=$1
  destination_relative=$2
  source_file="$FOUNDATION/$source_relative"
  destination_file="$PROJECT_ROOT/$destination_relative"

  [ -f "$source_file" ] && [ ! -L "$source_file" ] || \
    fail "foundation file is missing: $source_relative"

  relative_parent=$(dirname -- "$destination_relative")
  current_parent=$PROJECT_ROOT
  old_ifs=$IFS
  IFS=/
  for component in $relative_parent; do
    [ "$component" = "." ] && continue
    current_parent="$current_parent/$component"
    [ ! -L "$current_parent" ] || \
      fail "project path is redirected outside the project: $relative_parent"
    [ ! -e "$current_parent" ] || [ -d "$current_parent" ] || \
      fail "project path is not a folder: $relative_parent"
  done
  IFS=$old_ifs
}

while IFS='|' read -r source_relative destination_relative; do
  validate_foundation_file "$source_relative" "$destination_relative"
done <<'FOUNDATION_FILES'
AGENTS.md|AGENTS.md
README.md|README.md
CLAUDE.md|CLAUDE.md
GEMINI.md|GEMINI.md
copilot-instructions.md|.github/copilot-instructions.md
checks.yml|.github/workflows/checks.yml
claude-settings.json|.claude/settings.json
env.example|.env.example
gitignore|.gitignore
FOUNDATION_FILES

created=0
kept=0

copy_foundation_file() {
  source_relative=$1
  destination_relative=$2
  source_file="$FOUNDATION/$source_relative"
  destination_file="$PROJECT_ROOT/$destination_relative"

  if [ -e "$destination_file" ] || [ -L "$destination_file" ]; then
    kept=$((kept + 1))
    return
  fi

  destination_parent=$(dirname -- "$destination_file")
  mkdir -p "$destination_parent"
  cp -p "$source_file" "$destination_file"
  created=$((created + 1))
}

while IFS='|' read -r source_relative destination_relative; do
  copy_foundation_file "$source_relative" "$destination_relative"
done <<'FOUNDATION_FILES'
AGENTS.md|AGENTS.md
README.md|README.md
CLAUDE.md|CLAUDE.md
GEMINI.md|GEMINI.md
copilot-instructions.md|.github/copilot-instructions.md
checks.yml|.github/workflows/checks.yml
claude-settings.json|.claude/settings.json
env.example|.env.example
gitignore|.gitignore
FOUNDATION_FILES

echo "AI Build Kit prepared $created project file(s) and kept $kept existing file(s)"
