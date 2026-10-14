#!/usr/bin/env sh
# founding-menu.sh: run the shipped recipe-menu.sh on made-up menus in every
# installation layout.
#
# If this breaks, founding could skip a menu of one, show a recipe that does
# not fit, record the wrong menu, or find no menu at all on a plugin install.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
ok() { echo "  ok: $1"; pass=$((pass + 1)); }
fail() { echo "FAIL: $1" >&2; exit 1; }

SETUP="$ROOT/.agents/skills/setup-ai-build-kit/SKILL.md"
MENU="$ROOT/.agents/skills/setup-hosting/recipes"
PROJECT_PATH='\.agents/skills/setup-hosting/(recipes|references)'

# --- the script, on every route ------------------------------------------
# The script runs against menus of one, two and none, in each layout an
# installation leaves: a whole copy of the kit with its two copies of every
# skill, the shared installer for several coding agents, with Claude Code
# reaching the skills through links, the shared installer for Claude Code
# alone, and a plugin, whose skills sit outside the project. The recipes are
# made up here, so a product added to or taken off the real menu changes
# nothing in this check.

SAY_ONE='The kit has one recipe for a tool like this: a way to build it and run it that the kit can check at launch.'
SAY_NONE='No recipe the kit knows fits this tool, so I will set it up on a common stack, and the kit cannot check its launch steps for you.'

write_recipe() {
  # write_recipe <recipes folder> <recipe> <name>: a recipe folder.
  mkdir -p "$1/$2"
  printf '# Recipe: %s\n\nFits: a web app people use in a browser, with sign-in and saved data\nRecommended when: %s.\nFramework: Alpha 1\nDatabase: Data store\nDeploy target: North\n' \
    "$3" "the team wants $3" > "$1/$2/recipe.md"
}

fill_menu() {
  # fill_menu <recipes folder> <none|one|two>
  rm -rf "$1"
  mkdir -p "$1/parts"
  printf '# Shared part: a part\n' > "$1/parts/shared-part.md"
  case $2 in
    one) write_recipe "$1" alpha-on-north "Alpha on North" ;;
    two) write_recipe "$1" alpha-on-north "Alpha on North"
         write_recipe "$1" beta-on-south "Beta on South" ;;
  esac
}

said() {
  # said <output file>: the lines after the "Say this" heading.
  sed -n '/^Say this in your reply/,$p' "$1" | sed '1d'
}

tree_sum() {
  # Everything under a folder but the check-up record, so a write anywhere
  # else shows.
  (cd "$1" && find . -path ./.ai-build-kit-maintenance -prune -o -type f -print | LC_ALL=C sort | xargs cat 2>/dev/null) | cksum
}

menu_route() {
  # menu_route <route name> <project> <script> <recipes folder>...
  route=$1; project=$2; script=$3; shift 3
  today=$(date +%Y-%m-%d)
  out="$WORK/menu-out"
  record="$project/.ai-build-kit-maintenance"

  # A menu of one: shown, recommended, named the default, with an own stack.
  for f in "$@"; do fill_menu "$f" one; done
  printf 'founded|2026-01-02\nfounding-menu|2025-01-01|old-recipe.md\nmonthly|\n' > "$record"
  before=$(tree_sum "$project")
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance alpha-on-north > "$out" 2>&1) ||
    fail "$route: the script failed on a menu of one"
  said "$out" > "$WORK/said"
  [ "$(sed -n 1p "$WORK/said")" = "For a work team, the recommended recipe is Recipe 1, Alpha and Data on North, on Pro plans." ] ||
    fail "$route: the work-team default is not named"
  [ "$(sed -n 2p "$WORK/said")" = "$SAY_ONE" ] ||
    fail "$route: a menu of one does not open with the sentence naming one recipe"
  [ "$(sed -n 3p "$WORK/said")" = "1. Alpha on North (recommended)" ] ||
    fail "$route: the single recipe is not shown as recommended"
  [ "$(sed -n 4p "$WORK/said")" = "Alpha on North is the default. Founding carries on with it unless you pick another recipe, and you may bring your own stack instead." ] ||
    fail "$route: a menu of one is not named the default, with an own stack offered"
  [ "$(grep -c . "$WORK/said")" -eq 4 ] ||
    fail "$route: a menu of one says more than its four lines"
  grep -qxF "Recipe folder: $(CDPATH= cd -- "$1" && pwd -P)/alpha-on-north" "$out" ||
    fail "$route: the script does not give the chosen recipe's path for the tool report"
  [ "$(grep -c '^founding-menu|' "$record")" -eq 1 ] &&
    grep -qxF "founding-menu|$today|alpha-on-north" "$record" ||
    fail "$route: the menu line does not name the one recipe, dated today, in place of the old one"
  grep -qxF 'founded|2026-01-02' "$record" && grep -qxF 'monthly|' "$record" ||
    fail "$route: writing the menu line lost another line of the check-up record"
  grep -q 'shared-part' "$out" && fail "$route: a shared part reached the menu"
  [ "$(tree_sum "$project")" = "$before" ] ||
    fail "$route: the script wrote somewhere other than the check-up record"

  # A menu of two: no lines to say until one is chosen, then exactly one
  # recommended, and the record lists both.
  for f in "$@"; do fill_menu "$f" two; done
  set +e
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance > "$out" 2>&1)
  code=$?
  set -e
  [ "$code" -eq 3 ] || fail "$route: two recipes with none chosen exited $code, not 3"
  grep -q '^Say this' "$out" && fail "$route: two recipes with none chosen still printed lines to say"
  grep -q 'Recommended when: the team wants Beta on South' "$out" ||
    fail "$route: two recipes with none chosen do not show what each says"
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance --recommend beta-on-south > "$out" 2>&1) ||
    fail "$route: the script failed on a menu of two with one chosen"
  said "$out" > "$WORK/said"
  [ "$(grep -c '(recommended)$' "$WORK/said")" -eq 1 ] &&
    grep -qxF '2. Beta on South (recommended)' "$WORK/said" &&
    grep -qxF '1. Alpha on North' "$WORK/said" ||
    fail "$route: a menu of two does not mark exactly the chosen recipe"
  grep -qxF 'Beta on South is the default. Founding carries on with it unless you pick another recipe, and you may bring your own stack instead.' "$WORK/said" ||
    fail "$route: a menu of two does not name the chosen recipe the default"
  [ "$(grep -c '^For a work team, the recommended recipe is Recipe 1, Alpha and Data on North, on Pro plans\.$' "$WORK/said")" -eq 1 ] ||
    fail "$route: the work-team default is missing or repeated"
  grep -qxF "founding-menu|$today|alpha-on-north,beta-on-south" "$record" ||
    fail "$route: the menu line does not list both recipes"

  # Two on the menu, one that fits: only that one is shown, both are recorded.
  # It is named as an older project's Recipe: line names it, with .md.
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance alpha-on-north.md > "$out" 2>&1) ||
    fail "$route: the script failed with one of two recipes fitting, named with .md"
  said "$out" | grep -q 'Beta' && fail "$route: a recipe that does not fit was shown"
  grep -qxF "founding-menu|$today|alpha-on-north,beta-on-south" "$record" ||
    fail "$route: a recipe that does not fit was left off the menu line"

  # None fits, and an empty menu: one sentence, and the menu line still written.
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance --none > "$out" 2>&1) ||
    fail "$route: the script failed when no recipe fits"
  [ "$(said "$out")" = "$SAY_NONE" ] || fail "$route: no fitting recipe is not said in its one line"
  grep -qxF "founding-menu|$today|alpha-on-north,beta-on-south" "$record" ||
    fail "$route: no fitting recipe left the menu line unwritten"
  for f in "$@"; do fill_menu "$f" none; done
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance > "$out" 2>&1) ||
    fail "$route: the script failed on an empty menu"
  grep -qxF 'Menu: none' "$out" && [ "$(said "$out")" = "$SAY_NONE" ] ||
    fail "$route: an empty menu is not said in its one line"
  grep -qxF "founding-menu|$today|" "$record" ||
    fail "$route: an empty menu left no menu line"

  # A recipe that is not on the menu, and a missing folder, stop it.
  for f in "$@"; do fill_menu "$f" one; done
  set +e
  (cd "$project" && sh "$script" not-on-the-menu > "$out" 2>&1)
  [ $? -eq 4 ] || fail "$route: a recipe not on the menu did not exit 4"
  (cd "$project" && sh "$script" --recommend not-on-the-menu.md > "$out" 2>&1)
  [ $? -eq 4 ] || fail "$route: a recommendation not on the menu did not exit 4"
  mkdir -p "$project/stray-recipe"
  (cd "$project" && sh "$script" '*' > "$out" 2>&1)
  [ $? -eq 4 ] || fail "$route: a pattern for a name was expanded rather than refused"
  rmdir "$project/stray-recipe"
  set -e
  true
  for f in "$@"; do rm -rf "$f"; done
  (cd "$project" && sh "$script" > "$out" 2>&1) &&
    fail "$route: a missing recipes folder was read as a menu"
  ok "$route: menus of one, two and none print their lines, and the menu line is written"
}

menu_runs() {
  lay="$WORK/layouts"
  mkdir -p "$lay"
  SKILLS="$ROOT/.agents/skills"

  whole="$lay/whole"
  mkdir -p "$whole/.agents" "$whole/agent-plugin"
  cp -R "$SKILLS" "$whole/.agents/skills"
  cp -R "$SKILLS" "$whole/agent-plugin/skills"
  menu_route "whole copy, its .agents copy" "$whole" \
    "$whole/.agents/skills/setup-ai-build-kit/scripts/recipe-menu.sh" \
    "$whole/.agents/skills/setup-hosting/recipes"
  menu_route "whole copy, its agent-plugin copy" "$whole" \
    "$whole/agent-plugin/skills/setup-ai-build-kit/scripts/recipe-menu.sh" \
    "$whole/agent-plugin/skills/setup-hosting/recipes"

  shared="$lay/shared"
  mkdir -p "$shared/.agents" "$shared/.claude/skills"
  cp -R "$SKILLS" "$shared/.agents/skills"
  for skill in "$shared/.agents/skills"/*; do
    ln -s "../../.agents/skills/$(basename "$skill")" "$shared/.claude/skills/$(basename "$skill")"
  done
  menu_route "shared installer, several coding agents" "$shared" \
    "$shared/.claude/skills/setup-ai-build-kit/scripts/recipe-menu.sh" \
    "$shared/.agents/skills/setup-hosting/recipes"

  claude_only="$lay/claude-only"
  mkdir -p "$claude_only/.claude"
  cp -R "$SKILLS" "$claude_only/.claude/skills"
  menu_route "shared installer, Claude Code alone" "$claude_only" \
    "$claude_only/.claude/skills/setup-ai-build-kit/scripts/recipe-menu.sh" \
    "$claude_only/.claude/skills/setup-hosting/recipes"

  plugin="$lay/plugin/ai-build-kit"
  mkdir -p "$plugin" "$lay/plugin-project"
  cp -R "$SKILLS" "$plugin/skills"
  menu_route "a plugin, skills outside the project" "$lay/plugin-project" \
    "$plugin/skills/setup-ai-build-kit/scripts/recipe-menu.sh" \
    "$plugin/skills/setup-hosting/recipes"
}

# --- the half that runs --------------------------------------------------
# Every recipe folder on the menu carries the two lines founding reads. The
# shared parts folder holds no recipe.md, and never has to, because it is not
# on the menu.
entries=0
for recipe in "$MENU"/*/recipe.md; do
  [ -f "$recipe" ] || continue
  entries=$((entries + 1))
  [ "$(grep -c '^Fits: ' "$recipe")" -eq 1 ] ||
    fail "$recipe has no single Fits: line for founding to read"
  [ "$(grep -c '^Recommended when: ' "$recipe")" -eq 1 ] ||
    fail "$recipe has no single Recommended when: line for founding to read"
done
[ "$entries" -ge 1 ] || fail "the menu folder holds no recipe"
ok "each of the $entries menu entries carries Fits: and Recommended when:"

# The founding skill never names a project path to the recipes, since a plugin
# install has none. The check must notice one planted in a copy.
if grep -qE "$PROJECT_PATH" "$SETUP"; then
  fail "the founding skill names a project path to the recipes"
fi
cp "$SETUP" "$WORK/setup-copy"
printf '%s\n' 'The menu is the files in .agents/skills/setup-hosting/recipes/.' >> "$WORK/setup-copy"
grep -qE "$PROJECT_PATH" "$WORK/setup-copy" ||
  fail "a project path planted in a copy of the skill was not noticed"
ok "the founding skill names no project path to the recipes, and a planted one is noticed"

real_out="$WORK/real-menu"
sh "$ROOT/.agents/skills/setup-ai-build-kit/scripts/recipe-menu.sh" \
  --recommend nextjs-supabase-on-vercel > "$real_out"
grep -qxF 'For a work team, the recommended recipe is Recipe 1, Next.js and Supabase on Vercel, on Pro plans.' "$real_out" ||
  fail "the real menu does not name the work-team default"
[ "$(grep -c '^For a work team, the recommended recipe is ' "$real_out")" -eq 1 ] ||
  fail "the real menu names the work-team default more than once"
grep -qxF '1. Next.js 16, TypeScript and Supabase on Vercel (recommended)' "$real_out" ||
  fail "the Vercel recipe is not the first recipe in the menu"
[ "$(grep -c '^  Plan terms: ' "$real_out")" -eq 3 ] ||
  fail "the menu does not show each service's free-plan terms"
ok "the real menu names Recipe 1 once, puts it first and shows each service's plan terms"

menu_runs

echo
echo "$(basename -- "$0"): all $pass checks passed"
