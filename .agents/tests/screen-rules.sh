#!/usr/bin/env sh
# screen-rules.sh: guard the rules applied when a build touches a screen.
#
# A checklist can make an agent sound certain without earning that certainty.
# The costly version is a report that calls a screen accessible, compliant, or
# good after reading code and applying a few rules. A person may rely on that
# claim and skip the keyboard, screen-reader, or colleague check that would
# have found the problem.
#
# This check reads the screen skill back, proves the refusal is load-bearing,
# and checks the two build-time routes that call it. Conversation quality still
# needs a person to judge it. The shell check owns the quieter failure where the
# limiting rule disappears while the rest of the skill still reads well.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SCREEN="$ROOT/.agents/skills/screen-check/SKILL.md"
SECTION="$ROOT/.agents/skills/section-builder/SKILL.md"
SECOND="$ROOT/.agents/skills/second-opinion/SKILL.md"
FOUNDATION="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Screen-rule checks"
rs_exists "$SCREEN" "$SECTION" "$SECOND" "$FOUNDATION" "$WORKFLOW"

rs_rule "the skill refuses an accessibility, compliance, or quality claim" \
  'never call a screen accessible, compliant, or good'
rs_rule "following a rule proves only that rule was applied" \
  'a rule followed is evidence only that the rule was applied'
rs_rule "the report separates applied rules from unchecked ones" \
  'say which rules you applied, which you could not check'
rs_rule "the report names what a person still has to try" \
  'what a person still has to try'
rs_rule "the remaining checks include a screen reader" 'a screen reader'
rs_rule "the remaining checks include a real keyboard pass" \
  'a real keyboard pass'
rs_rule "the remaining checks include a colleague who uses the tool" \
  'a colleague who uses the tool'
rs_guard "$SCREEN" "the screen-check skill's claim boundary"

rs_require "section-builder fires for a visual piece" \
  "$SECTION" 'piece carries .visual.'
rs_require "section-builder also fires from a screen file" \
  "$SECTION" 'change touches a screen file'
rs_require_order "screen rules run before the guided manual check" \
  "$SECTION" 'load and follow .screen-check.' 'guided manual check'

rs_require "second-opinion checks screens during a build review" \
  "$SECOND" 'during a build review'
rs_require "second-opinion keeps the two report headings" \
  "$SECOND" 'inside the two existing report headings'
rs_require_absent "second-opinion does not add a screen report heading" \
  "$SECOND" '^## screen'

rs_require "project instructions name the fifth background skill" \
  "$FOUNDATION" 'screen-check'
rs_require "WORKFLOW explains when the rules run" \
  "$WORKFLOW" 'screen rules'

rs_done
