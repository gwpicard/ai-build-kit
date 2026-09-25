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
# own stack turns a choice into an argument. And a product name written into
# the skill is one the next recipe makes wrong.
#
# So this reads the rules back out of the founding skill and proves each one is
# load-bearing. It then reads the names the recipes carry, from the recipe files
# themselves, and requires that none of them appears in the files founding
# writes from or the page that explains it.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SETUP="$ROOT/.agents/skills/setup-ai-build-kit/SKILL.md"
REPORT="$ROOT/.agents/skills/setup-ai-build-kit/references/completion-report.md"
FOUNDATION="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"
MASTERPLAN="$ROOT/.agents/skills/setup-ai-build-kit/templates/masterplan.md"
WORKFLOW="$ROOT/WORKFLOW.md"
MENU="$ROOT/.agents/skills/ship/recipes"
WAITING="$ROOT/.agents/tests/recipes-awaiting-run"

rs_init "Founding menu checks"
rs_exists "$SETUP" "$REPORT" "$FOUNDATION" "$MASTERPLAN" "$WORKFLOW"

# --- the menu is the folder ----------------------------------------------
rs_rule "the shape is named first" 'name the app.s shape in one plain sentence'
rs_rule "the menu is read from the folder" \
  'the menu is the files directly in .\.agents/skills/ship/recipes/., read now rather than remembered'
rs_rule "the parts folder is not on the menu" 'not the .parts/. folder'
rs_rule "a recipe waiting for its real run is not on the menu" \
  'not a recipe kept anywhere else while it waits for its real run'
rs_rule "only the recipes that fit are shown" \
  'read each file.s .fits:. line and keep the ones that fit the shape'

# --- one recommended, in plain words -------------------------------------
rs_rule "exactly one is recommended" 'show them with exactly one recommended'
rs_rule "chosen by the recipe's own line" 'chosen by its .recommended when:. line'
rs_rule "each says what it promises" 'say in plain words what it promises'
rs_rule "each says what it costs to run" 'say what it costs to run in the same plain words'
rs_rule "no price is quoted" 'never quote a price'
rs_rule "names are read from the recipe at run time" \
  'take every product name from the recipe file at this moment'
rs_rule "and never written into the skill" 'never write one into this skill'

# --- their own stack, with one warning -----------------------------------
rs_rule "the person may bring their own stack" 'they may bring their own stack instead'
rs_rule "the kit says once what it cannot check" 'say once what the kit then cannot check'
rs_rule "the own stack is recorded" 'record their choice and .recipe: none.'
rs_rule "and not raised again" 'and do not raise it again'

# --- nothing stops founding ----------------------------------------------
rs_rule "no answer takes the recommended recipe" \
  'if they give no answer, or say to get on with it, take the recommended recipe'
rs_rule "the menu is never a condition of founding" \
  'the menu is never a condition of founding'
rs_rule "no fitting recipe is said in one line and recorded" \
  'say so in one line, record .recipe: none., and set up as below without a menu'
rs_rule "a chosen recipe is recorded in the stack section" \
  'record .recipe: <file name>. in agents\.md.s stack section'
rs_rule "the recipe's tools are checked" \
  'run .scripts/check-tooling\.sh --recipe <recipe file>.'
rs_rule "a missing tool becomes a setup task" \
  'add it to the masterplan as a setup task, and carry on'
rs_rule "and that report never stops founding" 'that report never stops founding'
rs_guard "$SETUP" "founding step 11"

# The menu sits inside the stand-up step, after the two questions it reads
# and before the fallback that applies without a recipe.
rs_require_order "the menu comes after the step opens" "$SETUP" \
  '^## 11\. Stand the project up' 'Then offer the recipe menu'
rs_require_order "and before the stack chosen without a recipe" "$SETUP" \
  'Then offer the recipe menu' '^Without a recipe, set up accordingly'

# --- where the choice shows ----------------------------------------------
rs_require_load_bearing "the project's AGENTS.md has a place for the recipe" \
  "$FOUNDATION" '.recipe: <file name>. or .recipe: none.'
rs_require_load_bearing "the completion report says what a recipe gives" \
  "$REPORT" '.recipe: <file name>. in agents\.md -> '
rs_require_load_bearing "and what an own stack does not" \
  "$REPORT" 'so it cannot check the launch steps a recipe would'
rs_require_load_bearing "the masterplan links the recipe rather than copying it" \
  "$MASTERPLAN" 'link it rather than copying it'
rs_require_load_bearing "WORKFLOW says one is recommended" \
  "$WORKFLOW" 'shows the recipes that fit, with one recommended'
rs_require_load_bearing "WORKFLOW says an own stack gets one warning" \
  "$WORKFLOW" 'you can bring your own stack instead: it says once what it then cannot check'
rs_require_load_bearing "WORKFLOW says no answer takes the recommended one" \
  "$WORKFLOW" 'if you do not answer, it takes the recommended recipe and carries on'

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

  # The names a recipe carries, read from its title: "Recipe: A and hosted B on
  # C" gives A, B and C. Read from the menu and from the recipes still waiting,
  # so a name arriving with the next recipe is covered before it is offered.
  recipe_names() {
    for rn_file in "$MENU"/*.md "$WAITING"/*.md; do
      [ -f "$rn_file" ] || continue
      sed -n 's/^# Recipe: //p' "$rn_file" | head -1
    done | awk '{
      gsub(/ and | on /, "\n")
      n = split($0, part, "\n")
      for (i = 1; i <= n; i++) {
        sub(/^hosted /, "", part[i])
        if (part[i] != "") print part[i]
      }
    }' | sort -u
  }
  recipe_names > "$rs_dir/names"
  [ -s "$rs_dir/names" ] || rs_fail "no product name could be read from a recipe title"

  names_in() {
    # names_in <file>...: each recipe name found in the files, one per line.
    while IFS= read -r ni_name; do
      grep -F -i -l -- "$ni_name" "$@" 2>/dev/null | sed "s#\$# names $ni_name#" || true
    done < "$rs_dir/names"
  }

  found=$(names_in "$SETUP" "$REPORT" "$FOUNDATION" "$MASTERPLAN" "$WORKFLOW")
  if [ -n "$found" ]; then
    printf '%s\n' "$found" >&2
    rs_fail "a file founding writes from names a product a recipe carries"
  fi
  rs_ok "founding and its page name none of $(tr '\n' ',' < "$rs_dir/names" | sed 's/,$//')"

  # The read has to notice a name, or it proves nothing.
  first=$(head -1 "$rs_dir/names")
  cp "$SETUP" "$rs_dir/setup-copy"
  printf '%s\n' "Recommend $first for a web app." >> "$rs_dir/setup-copy"
  [ -n "$(names_in "$rs_dir/setup-copy")" ] ||
    rs_fail "a product name planted in a copy of the skill was not noticed"
  rs_ok "a product name planted in a copy of the skill is noticed"
fi

rs_done
