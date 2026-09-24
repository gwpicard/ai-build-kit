#!/usr/bin/env sh
# recipes.sh: guard the recipe format and the check that reads recipe files.
#
# A recipe is one build stack paired with one place to run it, and it is the
# only place in the kit allowed to name a product. That permission is the risky
# half. Without the rules around it, a recipe becomes a list of product tips
# that nobody has tried, offered on a menu as if the kit could vouch for it. So
# this check reads the rules that stop that back out of the format reference,
# and proves each one is load-bearing.
#
# The second half runs the shipped shape check against a recipe filled in from
# the blank, then against copies with one part taken away at a time. A check
# that passed a recipe missing its backup section would let one onto the menu
# with a launch step nobody can check.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

FORMAT="$ROOT/.agents/skills/ship/references/recipe-format.md"
BLANK="$ROOT/.agents/skills/ship/templates/recipe.md"
CHECKER="$ROOT/.agents/tools/check-recipes.sh"
VALIDATOR="$ROOT/.agents/tools/validate-kit.sh"
PHILOSOPHY="$ROOT/docs/PHILOSOPHY.md"
MAINTAINING="$ROOT/docs/MAINTAINING.md"
SOURCES="$ROOT/docs/SOURCES.md"

rs_init "Recipe format checks"
rs_exists "$FORMAT" "$BLANK" "$CHECKER" "$VALIDATOR" "$PHILOSOPHY" "$MAINTAINING" "$SOURCES"

# --- what a recipe is ----------------------------------------------------
rs_rule "a recipe is one stack paired with one place" 'one build stack paired with one place to run it'
rs_rule "two places are two recipes" 'a stack that runs in two places is two recipes'
rs_rule "recipes live in ship/recipes" 'recipes live in .ship/recipes/.'
rs_rule "the folder is the menu" 'the folder is the menu'

# --- what it holds -------------------------------------------------------
rs_rule "the last-checked date moves only on a real read" 'the date moves only when somebody did that'
rs_rule "the eight sections, in order" 'preview, going live, rollback, backup, restore, secrets, logs and health'
rs_rule "a check is by machine where it can be" 'by machine where a machine can judge it'
rs_rule "otherwise a named person checks" 'name who checks by hand and what they look at'
rs_rule "a section with no check is unfinished" 'a section with no check is not finished'

# --- what proven means ---------------------------------------------------
rs_rule "rehearsals guard the rules" 'offline rehearsals guard its rules'
rs_rule "one real deploy, start to finish" 'one real deploy has been run from an empty project to a live address and through all eight sections'
rs_rule "with the maintainer's approval and accounts" 'with the maintainer.s approval and accounts'
rs_rule "the record lives in the recipe" 'the record lives in the recipe.s own proven section'
rs_rule "no draft state" 'there is no draft state'

# --- product names and the project's record ------------------------------
rs_rule "only recipes and the README name products" 'the readme may name them as well\. nothing else in the kit does'
rs_rule "a skill reads the recipe instead" 'a skill that needs to know how a product behaves reads the project.s recipe'
rs_rule "the project records it in the stack section" 'in its own agents\.md, in the stack section'
rs_rule "and not in the build-path block" 'it does not go in the build-path block'
rs_guard "$FORMAT" "recipe-format.md"

# --- the house documents allow it, and only there ------------------------
rs_require "PHILOSOPHY names the recipe as the one place a service is named" "$PHILOSOPHY" \
  'the one exception is a recipe'
rs_require "PHILOSOPHY answers the five questions for recipes" "$PHILOSOPHY" \
  'recipes, added'
rs_require "PHILOSOPHY answers that the kit should get smaller" "$PHILOSOPHY" \
  'recipes make the kit bigger'
rs_require "MAINTAINING allows product names inside recipes and the README only" "$MAINTAINING" \
  'except inside a recipe file under .\.agents/skills/ship/recipes/. and in the readme'
rs_require "MAINTAINING names the recipe home" "$MAINTAINING" \
  '.\.agents/skills/ship/recipes/.: one file for each recipe'
rs_require "SOURCES credits the stack you can prove" "$SOURCES" 'boringstack\.org'

# --- the validator reads recipes -----------------------------------------
rs_require "the validator runs the shape check on every recipe" "$VALIDATOR" \
  'recipe_checker" "\$recipe"'
rs_require "the validator runs the shape check on the blank" "$VALIDATOR" \
  'recipe_checker" --template'
rs_require "the validator wants a rehearsal for every recipe" "$VALIDATOR" \
  'tests/recipe-\$recipe_name\.sh'
rs_require "relative links into recipes are followed" "$VALIDATOR" \
  'relpat=.[(]references[|]templates[|]recipes[)]/'

# --- the shape check itself ----------------------------------------------
FILLED="$rs_dir/filled.md"
sed -e "s/YYYY-MM-DD/2026-01-02/" -e 's/<[^>]*>/filled in/g' "$BLANK" > "$FILLED"

"$CHECKER" --template "$BLANK" >/dev/null
rs_ok "the blank has the shape it asks for"

if "$CHECKER" "$BLANK" >/dev/null; then
  rs_fail "an unfilled blank passed as a recipe"
fi
rs_ok "an unfilled blank is refused as a recipe"

"$CHECKER" "$FILLED" >/dev/null
rs_ok "a filled recipe passes"

refused() {
  # refused <description> <sed-program>: a copy with that edit must fail.
  sed -e "$2" "$FILLED" > "$rs_dir/mutant.md"
  if cmp -s "$FILLED" "$rs_dir/mutant.md"; then
    rs_fail "the edit for '$1' changed nothing, so it proves nothing"
  fi
  if "$CHECKER" "$rs_dir/mutant.md" >/dev/null; then
    rs_fail "a recipe with $1 passed"
  fi
  rs_ok "a recipe with $1 is refused"
}

for section in Preview "Going live" Rollback Backup Restore Secrets Logs Health Proven; do
  refused "no $section section" "/^## $section\$/d"
done
refused "no Fits line" '/^Fits:/d'
refused "no Build stack line" '/^Build stack:/d'
refused "no Deploy target line" '/^Deploy target:/d'
refused "no Last checked line" '/^Last checked:/d'
refused "a Last checked line that is not a date" 's/^Last checked: .*/Last checked: recently/'
refused "a Last checked date in the future" 's/^Last checked: .*/Last checked: 2999-01-01/'
refused "no Real run line" '/^Real run:/d'
refused "a Real run line with no date" 's/^Real run: .*/Real run: soon/'
refused "one section that does not say how it works" '/^## Backup$/,/^## /{/^How it works:/d;}'
refused "one section that does not say how it is checked" '/^## Health$/,/^## /{/^How it is checked:/d;}'
refused "two sections out of order" 's/^## Backup$/## TEMP/; s/^## Restore$/## Backup/; s/^## TEMP$/## Restore/'

rs_done
