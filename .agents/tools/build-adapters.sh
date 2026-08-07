#!/usr/bin/env sh
# build-adapters.sh: regenerate the per-tool adapter files from the canonical
# skills in .agents/skills/. Run this after adding, renaming, or removing a
# skill. End users never run it; the output is committed so a fresh clone works
# in every tool straight away.
#
# Single source of truth: .agents/skills/<name>/SKILL.md
# Generated (thin) adapters, all pointing back at canonical:
#   .claude/commands/<word>.md       the seven words as Claude Code slash commands
#   .claude/skills/<discipline>/      the four disciplines as auto-triggering skills
#   .claude/skills/humanizer/         the callable maintainer writing skill
#   .cursor/commands/<word>.md        the seven words as Cursor slash commands
#   .gemini/commands/<word>.toml      the seven words as Gemini CLI slash commands
#
# Codex, Cursor, and Gemini discover the canonical .agents/skills/ tree
# directly. Claude Code needs its project skill under .claude/skills/.
#
# Adapters carry only what each tool must index locally (the description) and
# defer the body to the canonical file, so editing a skill means editing one
# file. Not touched here: .claude/settings.json (hand-maintained deny list).
#
# Usage:
#   build-adapters.sh          regenerate the adapters in place (the normal use).
#   build-adapters.sh --check  generate into a scratch directory and diff
#                               against what's committed, without touching the
#                               real adapter trees. Exits non-zero on drift.
#                               Used by CI and validate-kit.sh so a stale,
#                               hand-edited, or forgotten-to-regenerate adapter
#                               fails the build instead of shipping quietly.
#
# POSIX sh, no dependencies beyond awk/sed/grep/find/sort/diff.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SKILLS="$ROOT/.agents/skills"
GENERATED_DIRS="commands skills"

CHECK=0
case "${1:-}" in
  --check) CHECK=1 ;;
  "") ;;
  *) echo "usage: $0 [--check]" >&2; exit 2 ;;
esac

[ -d "$SKILLS" ] || { echo "error: $SKILLS not found" >&2; exit 1; }

# Read one frontmatter field from a SKILL.md file. Fold a YAML block scalar
# into one line so portable upstream skills can supply a longer description.
field() {
  # $1 = field name, $2 = file
  awk -v k="$1" '
    /^---[ \t]*$/ { fm++; next }
    fm==1 {
      if (block) {
        if ($0 ~ /^[ \t]+/) {
          sub(/^[ \t]+/, "")
          printf "%s%s", separator, $0
          separator=" "
          next
        }
        print ""
        exit
      }
      if ($0 ~ "^" k ":[ \t]") {
        sub("^" k ":[ \t]*", "")
        if ($0 == "|" || $0 == ">") { block=1; next }
        print
        exit
      }
    }
    END { if (block) print "" }
  ' "$2"
}

# Generate the full adapter tree under $1 (either $ROOT for a real run, or a
# scratch directory for --check). Prints the count of commands and
# disciplines and maintainer skills generated on fd 3, so the caller can
# validate the inventory without a second parsing pass over the skills.
generate_all() {
  OUT="$1"

  rm -rf \
    "$OUT/.claude/commands" "$OUT/.claude/skills" \
    "$OUT/.cursor/commands" \
    "$OUT/.gemini/commands"
  mkdir -p \
    "$OUT/.claude/commands" "$OUT/.claude/skills" \
    "$OUT/.cursor/commands" \
    "$OUT/.gemini/commands"

  commands=0
  disciplines=0
  maintainer_skills=0

  for dir in $(find "$SKILLS" -mindepth 1 -maxdepth 1 -type d | sort); do
    name=$(basename "$dir")
    file="$dir/SKILL.md"
    [ -f "$file" ] || continue

    fm_name=$(field name "$file")
    desc=$(field description "$file")
    [ -n "$desc" ] || { echo "warn: $name has no description, skipping" >&2; continue; }
    if [ "$fm_name" != "$name" ]; then
      echo "error: $name/SKILL.md declares name '$fm_name', which does not match its folder" >&2
      exit 1
    fi
    # First sentence, for short help strings.
    short=$(printf '%s' "$desc" | sed 's/\([^.]*\.\).*/\1/')
    # TOML-safe: escape backslash and double-quote for the description string.
    short_toml=$(printf '%s' "$short" | sed 's/\\/\\\\/g; s/"/\\"/g')

    if [ -f "$dir/.maintainer-only" ]; then
      kind=maintainer
      maintainer_skills=$((maintainer_skills + 1))
    elif grep -q '^disable-model-invocation:[ \t]*true' "$file"; then
      kind=command
      commands=$((commands + 1))
    else
      kind=discipline
      disciplines=$((disciplines + 1))
    fi

    claude_banner="<!-- GENERATED from .agents/skills/$name/. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->"

    if [ "$kind" = command ]; then
      # Claude Code slash command
      {
        printf '%s\n' "---"
        printf 'description: %s\n' "$short"
        printf '%s\n' "---"
        printf '%s\n\n' "$claude_banner"
        printf 'Load and follow `.agents/skills/%s/SKILL.md`, the single source of truth for the `/%s` command. Treat anything typed after the command as the user'"'"'s request and pass it through unchanged.\n' "$name" "$name"
      } > "$OUT/.claude/commands/$name.md"

      # Cursor slash command
      {
        printf '%s\n\n' "$claude_banner"
        printf 'Load and follow `.agents/skills/%s/SKILL.md`, the single source of truth for the `/%s` command. Treat anything typed after the command as the user'"'"'s request and pass it through unchanged.\n' "$name" "$name"
      } > "$OUT/.cursor/commands/$name.md"

      # Gemini CLI slash command (TOML)
      {
        printf '# GENERATED from .agents/skills/%s/. Do not edit here.\n' "$name"
        printf '# Regenerate with .agents/tools/build-adapters.sh\n'
        printf 'description = "%s"\n' "$short_toml"
        printf 'prompt = """\n'
        printf 'Load and follow the instructions in `.agents/skills/%s/SKILL.md`, the single source of truth for the /%s command.\n' "$name" "$name"
        printf 'Treat the following as the user'"'"'s request (it may be empty): {{args}}\n'
        printf '"""\n'
      } > "$OUT/.gemini/commands/$name.toml"
    elif [ "$kind" = discipline ]; then
      # Claude Code auto-triggering skill (disciplines only), hidden from the
      # user command menu but still available for a command to compose.
      mkdir -p "$OUT/.claude/skills/$name"
      {
        printf '%s\n' "---"
        printf 'name: %s\n' "$name"
        printf 'description: %s\n' "$desc"
        printf 'user-invocable: false\n'
        printf '%s\n' "---"
        printf '%s\n\n' "$claude_banner"
        printf 'Load and follow `.agents/skills/%s/SKILL.md`, the single source of truth for this skill.\n' "$name"
      } > "$OUT/.claude/skills/$name/SKILL.md"
    else
      # Claude Code does not discover the portable .agents/skills alias, so a
      # callable maintainer skill gets a thin project adapter of its own.
      mkdir -p "$OUT/.claude/skills/$name"
      {
        printf '%s\n' "---"
        printf 'name: %s\n' "$name"
        printf 'description: %s\n' "$desc"
        printf 'user-invocable: true\n'
        printf '%s\n' "---"
        printf '%s\n\n' "$claude_banner"
        printf 'Load and follow `.agents/skills/%s/SKILL.md`, the single source of truth for this skill.\n' "$name"
      } > "$OUT/.claude/skills/$name/SKILL.md"
    fi
  done

  if [ "$commands" -ne 7 ] || [ "$disciplines" -ne 4 ] || [ "$maintainer_skills" -gt 1 ]; then
    echo "error: expected 7 commands, 4 disciplines, and no more than 1 maintainer skill; found $commands, $disciplines, and $maintainer_skills" >&2
    exit 1
  fi

  echo "$commands $disciplines $maintainer_skills" >&3
}

if [ "$CHECK" -eq 1 ]; then
  SCRATCH=$(mktemp -d)
  trap 'rm -rf "$SCRATCH"' EXIT

  counts=$(generate_all "$SCRATCH" 3>&1 1>&2)
  read -r commands disciplines maintainer_skills <<EOF
$counts
EOF

  drift=0
  for d in .claude/commands .claude/skills .cursor/commands .gemini/commands; do
    if ! diff -rq "$ROOT/$d" "$SCRATCH/$d" >/tmp/adapter-check-diff.$$ 2>&1; then
      echo "drift in $d:" >&2
      cat /tmp/adapter-check-diff.$$ >&2
      drift=1
    fi
    rm -f /tmp/adapter-check-diff.$$
  done

  if [ "$drift" -ne 0 ]; then
    echo "error: committed adapters do not match what .agents/skills/ generates. Run .agents/tools/build-adapters.sh and commit the result." >&2
    exit 1
  fi

  echo "adapters match: $commands commands, $disciplines disciplines, $maintainer_skills maintainer skill, no drift"
  exit 0
fi

counts=$(generate_all "$ROOT" 3>&1 1>&2)
read -r commands disciplines maintainer_skills <<EOF
$counts
EOF

echo "Regenerated adapters for $((commands + disciplines + maintainer_skills)) skills ($commands commands, $disciplines disciplines, $maintainer_skills maintainer skill) into .claude/ .cursor/ .gemini/"
echo "Generated files:"
find "$ROOT/.claude/commands" "$ROOT/.claude/skills" "$ROOT/.cursor/commands" "$ROOT/.gemini/commands" -type f | sed "s|^$ROOT/||" | sort
