#!/usr/bin/env sh
# offer-recipe-move.sh: guard the monthly offer to move a project onto a recipe.
#
# A project founded before recipes existed, or on a stack of its own, can be
# built much like a recipe on the menu. On a recipe /ship checks the launch
# steps, and off one it can only name what it could not check. So the monthly
# visit offers the move. The rules worth holding are the ones whose loss would
# be quiet: the move is offered and never required, nothing changes without a
# yes, a yes becomes a piece rather than work done inside the visit, a no is not
# asked again that visit, the offer names what the move gains, and nothing is
# said when no recipe is close. A visit that nagged, or moved a project without
# asking, would read perfectly well in a transcript.
#
# The menu is read from the ship skill's recipes folder at run time, so the
# skill names no hosting, data or deploy product. The product list is read from
# hosting-request.sh, which owns it, rather than kept here as a second copy.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

MAINTAIN="$ROOT/.agents/skills/maintain/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"
HOSTING="$ROOT/.agents/tests/hosting-request.sh"

rs_init "Recipe-move checks"
rs_exists "$MAINTAIN" "$WORKFLOW" "$HOSTING"

# The monthly pass calls it, and not where nothing goes live.
rs_rule "the monthly pass runs it" \
  'unless the project explores privately, run .offering a move onto a recipe. below'
rs_rule "explore privately is skipped" 'skip this on explore privately'

# Offered, never required.
rs_rule "the move is never required" 'the move is never required'

# Which projects count as off a recipe.
rs_rule "none, no line or a missing file is off a recipe" \
  'no line at all, or a file that is no longer there counts as off a recipe'

# The menu is read from the recipes folder, and names come from it.
rs_rule "the menu is read from the installed recipes folder" \
  'each file directly in the installed ship skill.s .recipes/. folder, not the .parts/. folder'
rs_rule "product names come from the recipe files" \
  'take every product name from those files, and never write one into this skill'

# What close means.
rs_rule "close is the same framework and data service" \
  'the same framework and the same data service\. it stays close'
rs_rule "a different deploy target is still close" \
  'it stays close when the project deploys somewhere else, or lacks something the recipe adds'
rs_rule "the stack is read from the project" \
  'read that from the project.s code and dependency files, not from memory'

# A person who chose their own stack.
rs_rule "own stack is offered only when it has become close" \
  'offer the move only when the stack has become close since'
rs_rule "and a choice made against a close stack stands" \
  'where it was already that close when they chose their own, their choice stands'

# Silence when nothing is close.
rs_rule "nothing is said when no recipe is close" 'when no recipe is close, say nothing'

# The offer: once, with the gain and the change named.
rs_rule "the move is offered once" 'offer the move once, in one reply'
rs_rule "the gain is named" \
  'say what it gains in plain words: the launch checks /ship would then run'
rs_rule "the change is named" 'say what it would change, from the differences'

# Approval first, and a yes becomes a piece.
rs_rule "nothing changes without approval" 'change nothing without approval\. on a yes'
rs_rule "a yes becomes a piece like any other" \
  'leave it for /shape and /implement like any other piece'
rs_rule "the move is not made during the visit" 'do not make the move during the visit'

# A no.
rs_rule "a no is not asked again that visit" \
  'on a no, leave the project alone and do not ask again this visit'
rs_guard "$MAINTAIN" "maintain's recipe-move step"

# The skill names no product. The list lives in hosting-request.sh.
PRODUCTS=$(sed -n "s/^PRODUCTS='\(.*\)'\$/\1/p" "$HOSTING")
[ -n "$PRODUCTS" ] || rs_fail "could not read the product list from hosting-request.sh"
rs_require_absent "the maintain skill names no hosting, data or deploy product" \
  "$MAINTAIN" "$PRODUCTS"
if [ -z "${RS_LIST:-}" ]; then
  { cat "$MAINTAIN"; echo 'Move the tool to Vercel.'; } > "$rs_dir/named.md"
  rs_fold "$rs_dir/named.md" | grep -qE "$PRODUCTS" ||
    rs_fail "a product named in the maintain skill was not noticed"
  rs_ok "a product named in the maintain skill is noticed"
fi

# The story is told in WORKFLOW.md too.
rs_require "WORKFLOW says the visit offers the move once with its gain" "$WORKFLOW" \
  'the monthly visit then offers the move once, and says what it gains'
rs_require "WORKFLOW says a yes becomes a piece and a no is not asked again" \
  "$WORKFLOW" 'a yes becomes a piece, shaped and built like any other, and a no is not asked again that visit'
rs_require "WORKFLOW says the move is never required" "$WORKFLOW" \
  'the move is never required\. when no recipe is close, you hear nothing'

rs_done
