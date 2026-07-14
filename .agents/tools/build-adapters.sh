#!/usr/bin/env sh
# build-adapters.sh — regenerate the per-tool adapter files from the canonical
# skills in .agents/skills/. Run this after adding, renaming, or removing a
# skill. End users never run it; the output is committed so a fresh clone works
# in every tool straight away.
#
# Single source of truth: .agents/skills/<name>/SKILL.md
# Generated (thin) adapters, all pointing back at canonical:
#   .claude/commands/<word>.md       the seven words as Claude Code slash commands
#   .claude/skills/<discipline>/      the four disciplines as auto-triggering skills
#   .cursor/commands/<word>.md        the seven words as Cursor slash commands
#   .gemini/commands/<word>.toml      the seven words as Gemini CLI slash commands
#   .codex/skills/<name>/             all eleven skills as Codex skills
#
# Adapters carry only what each tool must index locally (the description) and
# defer the body to the canonical file, so editing a skill means editing one
# file. Not touched here: .claude/settings.json (hand-maintained hook + deny list).
#
# POSIX sh, no dependencies beyond awk/sed/grep.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SKILLS="$ROOT/.agents/skills"

[ -d "$SKILLS" ] || { echo "error: $SKILLS not found" >&2; exit 1; }

# Wipe only the generated trees, then rebuild — so a removed skill leaves no
# stale adapter behind. .claude/settings.json is deliberately left alone.
rm -rf \
  "$ROOT/.claude/commands" "$ROOT/.claude/skills" \
  "$ROOT/.cursor/commands" \
  "$ROOT/.gemini/commands" \
  "$ROOT/.codex/skills"
mkdir -p \
  "$ROOT/.claude/commands" "$ROOT/.claude/skills" \
  "$ROOT/.cursor/commands" \
  "$ROOT/.gemini/commands" \
  "$ROOT/.codex/skills"

# Read one frontmatter field (first match) from a SKILL.md file.
field() {
  # $1 = field name, $2 = file
  awk -v k="$1" '
    /^---[ \t]*$/ { fm++; next }
    fm==1 {
      if ($0 ~ "^" k ":[ \t]") { sub("^" k ":[ \t]*", ""); print; exit }
    }
  ' "$2"
}

count=0
for dir in "$SKILLS"/*/; do
  name=$(basename "$dir")
  file="$dir/SKILL.md"
  [ -f "$file" ] || continue

  desc=$(field description "$file")
  [ -n "$desc" ] || { echo "warn: $name has no description, skipping" >&2; continue; }
  # First sentence, for short help strings.
  short=$(printf '%s' "$desc" | sed 's/\([^.]*\.\).*/\1/')
  # TOML-safe: escape backslash and double-quote for the description string.
  short_toml=$(printf '%s' "$short" | sed 's/\\/\\\\/g; s/"/\\"/g')

  if grep -q '^disable-model-invocation:[ \t]*true' "$file"; then
    kind=command
  else
    kind=discipline
  fi

  claude_banner="<!-- GENERATED from .agents/skills/$name/ — do not edit here. Regenerate with .agents/tools/build-adapters.sh -->"

  if [ "$kind" = command ]; then
    # Claude Code slash command
    {
      printf '%s\n' "---"
      printf 'description: %s\n' "$short"
      printf '%s\n' "---"
      printf '%s\n\n' "$claude_banner"
      printf 'Load and follow `.agents/skills/%s/SKILL.md` — the single source of truth for the `/%s` command. Treat anything typed after the command as the user'"'"'s request and pass it through unchanged.\n' "$name" "$name"
    } > "$ROOT/.claude/commands/$name.md"

    # Cursor slash command
    {
      printf '%s\n\n' "$claude_banner"
      printf 'Load and follow `.agents/skills/%s/SKILL.md` — the single source of truth for the `/%s` command. Treat anything typed after the command as the user'"'"'s request and pass it through unchanged.\n' "$name" "$name"
    } > "$ROOT/.cursor/commands/$name.md"

    # Gemini CLI slash command (TOML)
    {
      printf '# GENERATED from .agents/skills/%s/ — do not edit here.\n' "$name"
      printf '# Regenerate with .agents/tools/build-adapters.sh\n'
      printf 'description = "%s"\n' "$short_toml"
      printf 'prompt = """\n'
      printf 'Load and follow the instructions in `.agents/skills/%s/SKILL.md` — the single source of truth for the /%s command.\n' "$name" "$name"
      printf 'Treat the following as the user'"'"'s request (it may be empty): {{args}}\n'
      printf '"""\n'
    } > "$ROOT/.gemini/commands/$name.toml"
  else
    # Claude Code auto-triggering skill (disciplines only)
    mkdir -p "$ROOT/.claude/skills/$name"
    {
      printf '%s\n' "---"
      printf 'name: %s\n' "$name"
      printf 'description: %s\n' "$desc"
      printf '%s\n' "---"
      printf '%s\n\n' "$claude_banner"
      printf 'Load and follow `.agents/skills/%s/SKILL.md` — the single source of truth for this skill.\n' "$name"
    } > "$ROOT/.claude/skills/$name/SKILL.md"
  fi

  # Codex skill (all skills, commands and disciplines alike)
  mkdir -p "$ROOT/.codex/skills/$name"
  {
    printf '%s\n' "---"
    printf 'name: %s\n' "$name"
    printf 'description: %s\n' "$desc"
    printf '%s\n' "---"
    printf '%s\n\n' "$claude_banner"
    printf 'Load and follow `.agents/skills/%s/SKILL.md` — the single source of truth for this skill.\n' "$name"
  } > "$ROOT/.codex/skills/$name/SKILL.md"

  count=$((count + 1))
done

echo "Regenerated adapters for $count skills into .claude/ .cursor/ .gemini/ .codex/"
