#!/usr/bin/env sh
# Guard recovery that keeps existing work while settling what it must do.
# Instruction deletion checks do not measure a model following the route.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"
SKILLS="$ROOT/.agents/skills"
rs_init "Shaping recovery rules"

rs_rule "missing shaping has an actionable route" 'for missing shaping, offer `/shape <number>`'
rs_rule "missing review has its own independent route" 'offer `/shape <number> check readiness` in a session that did not shape it'
rs_rule "orientation changes no state or preserved work" 'change no state, branch or pull request during `/what-now`'
rs_rule "a recovery piece is not presented as merge-ready" 'do not also describe it as ready for the person.s merge click'
rs_guard "$SKILLS/what-now/SKILL.md" "/what-now"

rs_reset
rs_rule "the whole piece and comments decide the route" 'read its body and comments before routing it'
rs_rule "full shaping removes the actual prior state" '<number> --add-label shaping --add-label needs-clarification --remove-label <old state>'
rs_rule "review alone repeats no interview" 'run the existing independent readiness review alone, without repeating the interview'
rs_rule "waiting for review preserves current state" 'keep `building` or `to check` while the review is missing or waiting'
rs_rule "passing review preserves state, gap returns to shaping" 'a ready verdict keeps that state; a blocking gap returns the piece to `shaping`'
rs_rule "gap move pairs its state change" '<number> --add-label shaping --add-label <its needs- label> --remove-label <old state>'
rs_rule "shaping does not change code" 'shape itself changes no implementation code'
rs_guard "$SKILLS/shape/SKILL.md" "/shape"

rs_reset
rs_rule "preserved artifacts cannot be removed" 'never delete the branch, close the pull request or discard its work during recovery'
rs_rule "identify branch and pull request at its head" 'identify the preserved branch and link the pull request, with its current head commit'
rs_rule "pull request visibly waits" 'make that wait visible on the preserved pull request too'
rs_rule "no invented artifacts or work evidence" 'invent neither an artifact nor evidence of work'
rs_rule "merge waits for both recovery and recorded verification" 'ineligible to merge until shaping and readiness are complete and its preserved work has been checked against the now agreed requirements, with the result recorded'
rs_rule "old checks against incomplete requirements cannot count" 'earlier checks against an incomplete specification do not count'
rs_rule "existing verification route checks preserved branch" 'use section-builder.s existing verification route, including the done when checks and walk-through, on the preserved branch'
rs_rule "evidence names coverage and checked head" 'record which agreed requirements were checked, the branch head tested, what passed or failed and what could not be checked'
rs_rule "missing or failed checks prevent merge" 'a failed or missing check keeps the merge waiting'
rs_rule "changed requirements or work invalidates verification" 'a later change to the requirements or work needs current verification again'
rs_rule "recovery grants no merge permission" 'recovery grants no permission to merge'
rs_guard "$SKILLS/setup-ai-build-kit/references/pieces.md" "pieces.md"

rs_require_load_bearing "readiness guidance defers recovery states to their owner" \
  "$SKILLS/shape/references/readiness-check.md" 'a readiness-only recovery follows pieces.md.s recovery state rules'
rs_require_load_bearing "every merge reads the recovery gate" \
  "$SKILLS/section-builder/references/merge.md" 'read the recovery record before treating its pull request as eligible'
rs_require_load_bearing "specific-piece recovery reaches existing verification" \
  "$SKILLS/implement/SKILL.md" 'for a single piece with an explicit preserved-work recovery record'
rs_require_load_bearing "recovery opens no duplicate pull request" \
  "$SKILLS/implement/SKILL.md" 'open no second pull request'
rs_require_load_bearing "existing under-way recovery is not claimed again" \
  "$SKILLS/implement/SKILL.md" 'an already `building` or `to check` piece needs no new claim'
rs_done
