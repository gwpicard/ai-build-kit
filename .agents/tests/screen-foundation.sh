#!/usr/bin/env sh
# screen-foundation.sh: guard the screen foundation recorded at founding.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SETUP="$ROOT/.agents/skills/setup-ai-build-kit/SKILL.md"
FOUNDATION="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"
WORKFLOW="$ROOT/WORKFLOW.md"
REPORT="$ROOT/.agents/skills/setup-ai-build-kit/references/completion-report.md"
TASTE="$ROOT/.agents/skills/setup-ai-build-kit/templates/screen-foundation/frontend-design/SKILL.md"
LICENCE="$ROOT/.agents/skills/setup-ai-build-kit/templates/screen-foundation/frontend-design/LICENSE.txt"

rs_init "Screen-foundation checks"

rs_rule "only a project with a screen gets the foundation" \
  'when the project has a screen'
rs_rule "a project without a screen records nothing" \
  'when the project has no screen, do not add or record either'
rs_rule "the taste skill comes from the vendored copy" \
  'copy the vendored .frontend-design. folder'
rs_rule "the vendored licence stays beside the skill" \
  'keep its .license.txt. beside it'
rs_rule "React takes the shadcn and tweakcn route" \
  'react.*shadcn/ui.*tweakcn theme'
rs_rule "another screen stack takes DaisyUI" \
  'not react.*daisyui'
rs_rule "the person is asked once in plain words" \
  'ask once, in plain words'
rs_rule "the question comes before the installation command" \
  'before adding the foundation or running the one .npx.'
rs_rule "declining keeps and records the default" \
  'if they say no.*add neither part.*default.*stack section'
rs_rule "the stack section records both choices" \
  'record the design-taste skill and component route'
rs_rule "the stack section says how to swap both choices" \
  'where to replace either one later'
rs_rule "founding does not create DESIGN.md" \
  'do not create .design.md.'
rs_guard "$SETUP" "the setup skill's screen-foundation step"

rs_require_order "the question comes before the vendored copy" \
  "$SETUP" '^Ask once, in plain words' '^the vendored `frontend-design` folder'

rs_require "the project stack template names the two records" \
  "$FOUNDATION" 'design-taste skill and component route'
rs_require "the project stack template says both can be swapped there" \
  "$FOUNDATION" 'replace either choice here'
rs_require "WORKFLOW explains the one founding choice" \
  "$WORKFLOW" 'asked once before anything is added'
rs_require "WORKFLOW says a no keeps the default" \
  "$WORKFLOW" 'keep the default'
rs_require "the completion report names what a screen project received" \
  "$REPORT" 'design taste and component route'
rs_require "the vendored taste skill is present" "$TASTE" '# frontend design'
rs_require "the Apache licence travels with it" \
  "$LICENCE" 'apache license.*version 2\.0'

rs_done
