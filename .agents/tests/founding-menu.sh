#!/usr/bin/env sh
# founding-menu.sh: guard the recipe menu founding offers when it stands a
# project up.
#
# Founding used to pick one conventional stack quietly. It now names the shape
# of the tool, shows the recipes that fit with one recommended, and lets the
# person bring their own stack instead. Each part of that can go wrong without
# anybody noticing. A menu read from memory offers a recipe that was withdrawn,
# or one still waiting for its real run. A menu with no default stops founding
# on a question the person may not want to answer. A second warning about an
# own stack turns a choice into an argument. A menu nobody wrote down leaves
# the monthly visit unable to tell a recipe added later from one the person
# already passed over. And a product name written into the skill is one the
# next recipe makes wrong.
#
# So this reads the rules back out of the founding skill and proves each one is
# load-bearing. The menu is found beside the founding skill rather than at a
# project path, because the Claude plugin and the Agent Plugins folder install
# the skills somewhere else, and a project path there finds an empty menu and
# records no recipe without a word. The product names themselves are guarded by
# hosting-request.sh, which reads every skill file outside the recipes against
# a list of hosting, data and deploy products.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SETUP="$ROOT/.agents/skills/setup-ai-build-kit/SKILL.md"
REPORT="$ROOT/.agents/skills/setup-ai-build-kit/references/completion-report.md"
FOUNDATION="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"
MASTERPLAN="$ROOT/.agents/skills/setup-ai-build-kit/templates/masterplan.md"
WORKFLOW="$ROOT/WORKFLOW.md"
FORMAT="$ROOT/.agents/skills/setup-hosting/references/recipe-format.md"
MENU="$ROOT/.agents/skills/setup-hosting/recipes"

rs_init "Founding menu checks"
rs_exists "$SETUP" "$REPORT" "$FOUNDATION" "$MASTERPLAN" "$WORKFLOW" "$FORMAT"

# --- the menu is the folder ----------------------------------------------
rs_rule "the shape is named first" 'name the app.s shape in one plain sentence'
rs_rule "the menu is read from the folder" \
  'the menu is the files directly in the .recipes/. folder of the installed setup-hosting skill, beside this skill.s folder, read now rather than remembered'
rs_rule "the parts folder is not on the menu" 'not the .parts/. folder'
rs_rule "a recipe waiting for its real run is not on the menu" \
  'not a recipe kept anywhere else while it waits for its real run'
rs_rule "only the recipes that fit are shown" \
  'read each file.s .fits:. line and keep the ones that fit the shape'

# --- the script prints what has to be said --------------------------------
# A menu of one was skipped in four runs out of five, before and after the
# six-command redesign, while every rule below already said to show it. So the
# lines that must reach the person come from a script, the same every time,
# and its exit code decides the next step rather than a reading of the rules.
rs_rule "the menu is shown with the shipped script" \
  'show the menu with .scripts/recipe-menu\.sh. from this installed skill folder'
rs_rule "which finds the menu beside the skill on every route" \
  'it finds the recipes folder beside this skill, so it reads the same menu on every installation route'
rs_rule "and writes the menu line" 'pass .--record \.ai-build-kit-maintenance., which writes the menu line'
rs_rule "it is given the files that fit, or none" 'then the files that fit, or .--none. where none does'
rs_rule "its exit code decides the next step" 'its exit code decides the next step'
rs_rule "3 waits for a choice made by the rule below" \
  '3 means several fit: it prints what each recipe says, so choose one by the rule below and run it again with .--recommend <file>.'
rs_rule "0 means the printed lines are said as printed, before the stand-up" \
  '0 means it printed the lines to say: put them in your reply exactly as printed, before the stand-up begins'
rs_rule "4 means a wrong file name, corrected and run again" '4 means a file name it was given is not on the menu: correct it and run it again'
rs_rule "the plain words go after the list, the printed lines unchanged" 'the plain words below go after the numbered list and before its last sentence, and the printed lines stay word for word'
rs_rule "any other exit falls back to the rules by hand" \
  'any other exit means it could not read the menu, so follow the rules below by hand'

# --- one recommended, in plain words -------------------------------------
rs_rule "a single fitting recipe is recommended" 'if one recipe fits, recommend it'

# --- a menu of one -------------------------------------------------------
# A real founding with one recipe on the menu skipped the menu, its two
# questions and the recipe's tool report, although step 11 already carried the
# rules for any menu. It chose the recipe quietly and reported it afterwards as
# "so I chose it". So a menu of one is named as a menu, with the same rules.
rs_rule "the two questions are asked even for a single recipe" \
  'ask them even when the menu holds a single recipe, unless the interview already answered them'
rs_rule "a single recipe is still shown as a menu" 'recommend it and still show it as a menu'
rs_rule "a menu of one follows the same rules, default sentence included" \
  'a menu of one follows every rule below, as a longer menu does, including the sentence naming it the default'
rs_rule "and is shown before the stand-up begins, not reported afterwards" \
  'shown in a reply before the stand-up begins, never only as a choice reported in the completion report'
rs_rule "several are settled by the recipe's own line" \
  'if several fit, recommend the one whose .recommended when:. line best matches'
rs_rule "and a tie goes to the first by file name" \
  'or the first by file name when none or several match'
rs_rule "exactly one is recommended" 'show the ones that fit with exactly one recommended'
rs_rule "each says what it promises" 'say in plain words what it promises'
rs_rule "each says what running it involves" 'say what running it involves in the same plain words'
rs_rule "no price is quoted" 'never quote a price'
rs_rule "names are read from the recipe at run time" \
  'take every product name from the recipe file at this moment'
rs_rule "and never written into the skill" 'never write one into this skill'

# A plan whose free tier is not for work. Two foundings for a team of six at
# work recommended the same recipe and one called the account free, while the
# free plan was for personal use only. The fact lives in the recipe, since a
# skill names no product, and founding says it only where it applies.
rs_rule "founding reads the recipe's Plan terms line" 'read each offered recipe.s `plan terms:` line, where it has one'
rs_rule "a work team hears it once, beside the recipe" 'when the interview shows the tool is for a work team, a business or any paid work, say that line once, in plain words, beside that recipe'
rs_rule "the account is then never called free" 'never then call that recipe.s account free or say a free plan fits them'
rs_rule "a personal project does not hear it" 'for a personal project nobody is paid to build, leave the line out'
rs_rule "an unknown answer gets a condition, not a question" 'where the interview did not say, ask nothing: give the line once as a condition'

# --- their own stack, with one warning -----------------------------------
rs_rule "the person may bring their own stack" 'they may bring their own stack instead'
rs_rule "the kit says once what it cannot check" 'say once what the kit then cannot check'
rs_rule "the own stack is recorded" 'record their choice and .recipe: none.'
rs_rule "and not raised again" 'and do not raise it again'

# --- nothing stops founding ----------------------------------------------
rs_rule "the default is said in the same reply" \
  'in the same reply, say that the recommended recipe is the default and that founding carries on with it unless they pick another'
rs_rule "showing the menu does not end the turn" 'showing the menu does not end the turn'
rs_rule "no answer keeps the recommended recipe" \
  'if they give no answer, or say to get on with it, keep the recommended recipe'
rs_rule "the menu is never a condition of founding" \
  'the menu is never a condition of founding'
rs_rule "no fitting recipe is said in one line and recorded" \
  'say so in one line, record .recipe: none., and set up as below without a menu'
rs_rule "a chosen recipe is recorded in the stack section" \
  'agents\.md.s stack section as .recipe: <file name>\.md.'
rs_rule "by its file name with .md included" 'the file name exactly as it sits in the folder with .\.md. included'
rs_rule "the recipe's tools are checked" \
  'run .scripts/check-tooling\.sh --recipe <recipe file>.'
rs_rule "with the path found beside this skill" \
  'passing the chosen file.s path inside the setup-hosting skill.s .recipes/. folder beside it'
rs_rule "the report runs whatever the menu held" \
  'run it for every chosen recipe, a menu of one included, before the first checkpoint'
rs_rule "and what it found reaches the completion report" \
  'let the completion report.s recipe line say what it found'
rs_rule "a missing tool becomes a setup task" \
  'add it to the masterplan as a setup task, and carry on'
rs_rule "and that report never stops founding" 'that report never stops founding'

# --- the menu is remembered ----------------------------------------------
# The monthly visit can only tell that a recipe joined the menu after founding
# if founding wrote down the menu it read. Without the line, a close recipe
# added later is never offered to a person who chose their own stack.
rs_rule "the menu read is recorded whatever the choice" \
  'whatever the choice, record the menu this step read'
rs_rule "as one founding-menu line in the check-up file" \
  'in .\.ai-build-kit-maintenance., which step 7 created, add one line, replacing any earlier one without asking, .* .founding-menu\|<yyyy-mm-dd>\|<menu files, comma separated>.'
rs_rule "the line is not a record step 0 protects" \
  'it is kit bookkeeping and not one of the project records step 0 protects'
rs_rule "listing every file in the folder, fitting or not" \
  'list every file directly in the .recipes/. folder, including the ones that did not fit'
rs_rule "each by its file name with .md" \
  'each written exactly as it sits there with .\.md. included'
rs_rule "written before the first checkpoint" \
  'write this line before the first checkpoint, so the save holds it'
rs_guard "$SETUP" "founding step 11"

# The menu sits inside the stand-up step, after the two questions it reads
# and before the fallback that applies without a recipe.
rs_require_order "the menu comes after the step opens" "$SETUP" \
  '^## 11\. Stand the project up' 'Then offer the recipe menu'
rs_require_order "and before the stack chosen without a recipe" "$SETUP" \
  'Then offer the recipe menu' '^Without a recipe, set up accordingly'
# The rules every project needs sit after the branch, so a project on a recipe
# gets them as well as one without.
rs_require_order "the shared setup rules follow the no-recipe branch" "$SETUP" \
  '^Without a recipe, set up accordingly' '^On any stack, recipe or not'
rs_require_load_bearing "the manual-step rule applies on any stack" "$SETUP" \
  'on any stack, recipe or not, use managed services'

# The menu is never read from a project path. Proved on a copy with one planted.
rs_require_absent "the skill does not name the project path to the recipes" \
  "$SETUP" '\.agents/skills/setup-hosting/(recipes|references)'

# --- where the choice shows ----------------------------------------------
rs_require_load_bearing "the project's AGENTS.md has a place for the recipe" \
  "$FOUNDATION" '.recipe: <file name>\.md. or .recipe: none.'
rs_require_load_bearing "the completion report says what a recipe gives" \
  "$REPORT" '.recipe: <file name>\.md. in agents\.md -> '
rs_require_load_bearing "the format records the file name with .md" \
  "$FORMAT" '.recipe: <file name>\.md., the file name with .\.md. included'
rs_require_load_bearing "the completion report says what the tool report found" \
  "$REPORT" 'the recipe.s tool report, on the same line -> '
rs_require_load_bearing "the report's recipe bullet asks for the tools" \
  "$REPORT" 'whether this computer has the tools those checks use\.\]'
rs_require_load_bearing "and what an own stack does not" \
  "$REPORT" 'so it cannot check the launch steps a recipe would'
rs_require_load_bearing "the masterplan links the recipe rather than copying it" \
  "$MASTERPLAN" 'link it rather than copying it'
rs_require_load_bearing "WORKFLOW says one is recommended" \
  "$WORKFLOW" 'shows the recipes that fit, with one recommended'
rs_require_load_bearing "WORKFLOW says an own stack gets one warning" \
  "$WORKFLOW" 'you can bring your own stack instead: it says once what it then cannot check'
rs_require_load_bearing "WORKFLOW says a single recipe is still shown" \
  "$WORKFLOW" 'when only one recipe fits, you still see it the same way, recommended and named the default'
rs_require_load_bearing "WORKFLOW says the recipe's tools are checked" \
  "$WORKFLOW" 'checks this computer for the tools that recipe.s launch checks use'
rs_require_load_bearing "WORKFLOW says no answer takes the recommended one" \
  "$WORKFLOW" 'if you do not answer, it takes the recommended recipe and carries on'
rs_require_load_bearing "WORKFLOW says founding notes the menu" \
  "$WORKFLOW" 'the kit notes which recipes were on the menu, so a later check-up can offer one added since'

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
  # write_recipe <folder> <file> <name>
  printf '# Recipe: %s\n\nFits: a web app people use in a browser, with sign-in and saved data\nRecommended when: %s.\nDeploy target: %s\n' \
    "$3" "the team wants $3" "the host of $3" > "$1/$2"
}

fill_menu() {
  # fill_menu <recipes folder> <none|one|two>
  rm -rf "$1"
  mkdir -p "$1/parts"
  printf '# Shared part: a part\n' > "$1/parts/shared-part.md"
  case $2 in
    one) write_recipe "$1" alpha-on-north.md "Alpha on North" ;;
    two) write_recipe "$1" alpha-on-north.md "Alpha on North"
         write_recipe "$1" beta-on-south.md "Beta on South" ;;
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
  out="$rs_dir/menu-out"
  record="$project/.ai-build-kit-maintenance"

  # A menu of one: shown, recommended, named the default, with an own stack.
  for f in "$@"; do fill_menu "$f" one; done
  printf 'founded|2026-01-02\nfounding-menu|2025-01-01|old-recipe.md\nmonthly|\n' > "$record"
  before=$(tree_sum "$project")
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance alpha-on-north.md > "$out" 2>&1) ||
    rs_fail "$route: the script failed on a menu of one"
  said "$out" > "$rs_dir/said"
  [ "$(sed -n 1p "$rs_dir/said")" = "$SAY_ONE" ] ||
    rs_fail "$route: a menu of one does not open with the sentence naming one recipe"
  [ "$(sed -n 2p "$rs_dir/said")" = "1. Alpha on North (recommended)" ] ||
    rs_fail "$route: the single recipe is not shown as recommended"
  [ "$(sed -n 3p "$rs_dir/said")" = "Alpha on North is the default. Founding carries on with it unless you pick another recipe, and you may bring your own stack instead." ] ||
    rs_fail "$route: a menu of one is not named the default, with an own stack offered"
  [ "$(grep -c . "$rs_dir/said")" -eq 3 ] ||
    rs_fail "$route: a menu of one says more than its three lines"
  grep -qxF "Recipe file: $(CDPATH= cd -- "$1" && pwd -P)/alpha-on-north.md" "$out" ||
    rs_fail "$route: the script does not give the chosen recipe's path for the tool report"
  [ "$(grep -c '^founding-menu|' "$record")" -eq 1 ] &&
    grep -qxF "founding-menu|$today|alpha-on-north.md" "$record" ||
    rs_fail "$route: the menu line does not name the one recipe, dated today, in place of the old one"
  grep -qxF 'founded|2026-01-02' "$record" && grep -qxF 'monthly|' "$record" ||
    rs_fail "$route: writing the menu line lost another line of the check-up record"
  grep -q 'shared-part' "$out" && rs_fail "$route: a shared part reached the menu"
  [ "$(tree_sum "$project")" = "$before" ] ||
    rs_fail "$route: the script wrote somewhere other than the check-up record"

  # A menu of two: no lines to say until one is chosen, then exactly one
  # recommended, and the record lists both.
  for f in "$@"; do fill_menu "$f" two; done
  set +e
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance > "$out" 2>&1)
  code=$?
  set -e
  [ "$code" -eq 3 ] || rs_fail "$route: two recipes with none chosen exited $code, not 3"
  grep -q '^Say this' "$out" && rs_fail "$route: two recipes with none chosen still printed lines to say"
  grep -q 'Recommended when: the team wants Beta on South' "$out" ||
    rs_fail "$route: two recipes with none chosen do not show what each says"
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance --recommend beta-on-south.md > "$out" 2>&1) ||
    rs_fail "$route: the script failed on a menu of two with one chosen"
  said "$out" > "$rs_dir/said"
  [ "$(grep -c '(recommended)$' "$rs_dir/said")" -eq 1 ] &&
    grep -qxF '2. Beta on South (recommended)' "$rs_dir/said" &&
    grep -qxF '1. Alpha on North' "$rs_dir/said" ||
    rs_fail "$route: a menu of two does not mark exactly the chosen recipe"
  grep -qxF 'Beta on South is the default. Founding carries on with it unless you pick another recipe, and you may bring your own stack instead.' "$rs_dir/said" ||
    rs_fail "$route: a menu of two does not name the chosen recipe the default"
  grep -qxF "founding-menu|$today|alpha-on-north.md,beta-on-south.md" "$record" ||
    rs_fail "$route: the menu line does not list both recipes"

  # Two on the menu, one that fits: only that one is shown, both are recorded.
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance alpha-on-north.md > "$out" 2>&1) ||
    rs_fail "$route: the script failed with one of two recipes fitting"
  said "$out" | grep -q 'Beta' && rs_fail "$route: a recipe that does not fit was shown"
  grep -qxF "founding-menu|$today|alpha-on-north.md,beta-on-south.md" "$record" ||
    rs_fail "$route: a recipe that does not fit was left off the menu line"

  # None fits, and an empty menu: one sentence, and the menu line still written.
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance --none > "$out" 2>&1) ||
    rs_fail "$route: the script failed when no recipe fits"
  [ "$(said "$out")" = "$SAY_NONE" ] || rs_fail "$route: no fitting recipe is not said in its one line"
  grep -qxF "founding-menu|$today|alpha-on-north.md,beta-on-south.md" "$record" ||
    rs_fail "$route: no fitting recipe left the menu line unwritten"
  for f in "$@"; do fill_menu "$f" none; done
  (cd "$project" && sh "$script" --record .ai-build-kit-maintenance > "$out" 2>&1) ||
    rs_fail "$route: the script failed on an empty menu"
  grep -qxF 'Menu: none' "$out" && [ "$(said "$out")" = "$SAY_NONE" ] ||
    rs_fail "$route: an empty menu is not said in its one line"
  grep -qxF "founding-menu|$today|" "$record" ||
    rs_fail "$route: an empty menu left no menu line"

  # A file that is not on the menu, and a missing folder, stop it.
  for f in "$@"; do fill_menu "$f" one; done
  set +e
  (cd "$project" && sh "$script" not-on-the-menu.md > "$out" 2>&1)
  [ $? -eq 4 ] || rs_fail "$route: a file not on the menu did not exit 4"
  (cd "$project" && sh "$script" --recommend not-on-the-menu.md > "$out" 2>&1)
  [ $? -eq 4 ] || rs_fail "$route: a recommendation not on the menu did not exit 4"
  : > "$project/stray-recipe.md"
  (cd "$project" && sh "$script" '*.md' > "$out" 2>&1)
  [ $? -eq 4 ] || rs_fail "$route: a pattern for a file name was expanded rather than refused"
  rm -f "$project/stray-recipe.md"
  set -e
  true
  for f in "$@"; do rm -rf "$f"; done
  (cd "$project" && sh "$script" > "$out" 2>&1) &&
    rs_fail "$route: a missing recipes folder was read as a menu"
  rs_ok "$route: menus of one, two and none print their lines, and the menu line is written"
}

menu_runs() {
  lay="$rs_dir/layouts"
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
if [ -z "${RS_LIST:-}" ]; then
  # Every file directly in the menu folder carries the two lines founding reads.
  # A shared part does not, and it never has to, because it is not on the menu.
  entries=0
  for recipe in "$MENU"/*.md; do
    [ -f "$recipe" ] || continue
    entries=$((entries + 1))
    [ "$(grep -c '^Fits: ' "$recipe")" -eq 1 ] ||
      rs_fail "$recipe has no single Fits: line for founding to read"
    [ "$(grep -c '^Recommended when: ' "$recipe")" -eq 1 ] ||
      rs_fail "$recipe has no single Recommended when: line for founding to read"
  done
  [ "$entries" -ge 1 ] || rs_fail "the menu folder holds no recipe"
  rs_ok "each of the $entries menu entries carries Fits: and Recommended when:"

  # The project-path refusal has to notice a planted path, or it proves nothing.
  cp "$SETUP" "$rs_dir/setup-copy"
  printf '%s\n' 'The menu is the files in .agents/skills/setup-hosting/recipes/.' >> "$rs_dir/setup-copy"
  rs_fold "$rs_dir/setup-copy" | grep -qE '\.agents/skills/setup-hosting/(recipes|references)' ||
    rs_fail "a project path planted in a copy of the skill was not noticed"
  rs_ok "a project path planted in a copy of the skill is noticed"

  menu_runs
fi

rs_done
