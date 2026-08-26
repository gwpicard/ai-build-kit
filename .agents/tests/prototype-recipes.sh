#!/usr/bin/env sh
# prototype-recipes.sh: guard what a prototype is supposed to be.
#
# decision-prototype.md said what a prototype must obey and never what to build,
# so a `needs-prototype` piece produced whatever that session improvised. It now
# names which of two questions it is answering first, and follows
# a recipe for that one.
#
# The branch is the load-bearing part: a session that reads the wrong recipe
# wastes the whole prototype, and the person cannot say it was the wrong kind
# until it is in front of them. So the branch, and the rules that make each
# recipe worth following, are read on every push.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

PROTOTYPE="$ROOT/.agents/skills/clarify/references/decision-prototype.md"
BEHAVIOUR="$ROOT/.agents/skills/clarify/references/prototype-behaviour.md"
STRUCTURE="$ROOT/.agents/skills/clarify/references/prototype-structure.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Prototype-recipe checks"
rs_exists "$PROTOTYPE" "$BEHAVIOUR" "$STRUCTURE" "$WORKFLOW"

# --- the branch comes first ----------------------------------------------
rs_rule "the two kinds of question are named" 'which kind of question is it'
rs_rule "the session says which one it is answering, before building" \
  'say which of these two you are answering, and why, before building'
rs_rule "a behaviour question has its own recipe" 'prototype-behaviour\.md'
rs_rule "a shape question has its own recipe" 'prototype-structure\.md'
rs_rule "a question that is both is two questions" 'it is two questions'
rs_guard "$PROTOTYPE" "decision-prototype.md"

# Building it before the shared rules would let a session read the constraints,
# start building, and meet the branch too late to use it.
rs_require_order "the branch is written before the rules it chooses between" \
  "$PROTOTYPE" '## Which kind of question is it' '^## Rules'

# --- the behaviour recipe -------------------------------------------------
: > "$rs_dir/rules"
rs_rule "one file, opened by double-clicking" 'open by double-clicking'
rs_rule "nothing installed and nothing running" 'needs nothing installed'
rs_rule "it can be sent to somebody without the project" 'can be sent to them'
rs_rule "it does not reach for the real project's parts" \
  'rules out reaching for the parts'
rs_rule "labelled in the words of their work" 'the words of their work'
rs_rule "shows the state after every action" 'state after every action'
rs_rule "walks the awkward cases rather than free play" \
  'guided path through the awkward cases, not only free play'
rs_rule "brings back the decision and what to keep" \
  'what the production build must keep'
rs_guard "$BEHAVIOUR" "prototype-behaviour.md"

# --- the structure recipe -------------------------------------------------
: > "$rs_dir/rules"
rs_rule "three options by default" 'three by default'
rs_rule "more when they ask, and a point past which they stop differing" \
  'past about five'
rs_rule "they differ in layout and order" 'layout and order'
rs_rule "not in colour, wording, or spacing" 'not colour, not wording'
rs_rule "shown inside the real page where one exists" \
  'inside the real page'
rs_rule "with the data it really carries" 'really carries'
rs_rule "a way between them the person finds unaided" 'without being told'
rs_rule "the arrangements still never announce themselves" \
  'never announce that they are prototypes'
rs_rule "a combination of two is itself the decision" 'they wanted parts of two'
rs_guard "$STRUCTURE" "prototype-structure.md"

# --- the prose stays readable by the person it is for ---------------------
# The rule the issue set: no framework, file path, or code construct in either
# recipe. A recipe written in build words cannot be checked by the person whose
# decision it exists to serve.
for recipe in "$BEHAVIOUR" "$STRUCTURE"; do
  name=$(basename -- "$recipe")
  rs_require_absent "$name names no framework or code construct" \
    "$recipe" '(reactjs|react app|vue|svelte|npm |node_modules|\.html|\.js\b|\.css|<div|function \()'
done

rs_require "WORKFLOW.md says what the person will get" \
  "$WORKFLOW" 'file you open and click through'

rs_done
