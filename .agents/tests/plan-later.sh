#!/usr/bin/env sh
# plan-later.sh: guard the route that files a piece now and shapes it later.
#
# The kit knew what planning was and had never decided when it happens.
# Every route out of triage was work started in that session, while /plan's Done
# when already permitted a piece left with its open question, so the only way to
# reach that outcome was to interrupt.
#
# Two failures matter, and they pull against each other. An offer worded as
# reluctance is worse than no offer at all. An easy deferral with nothing that
# points at the backlog afterwards is worse still: pieces pile up and no session
# ever calls itself a planning one. So the offer and the /what-now half are
# guarded together here, and neither can be dropped without this check failing.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

PLAN="$ROOT/.agents/skills/plan/SKILL.md"
TRIAGE="$ROOT/.agents/skills/change-triage/SKILL.md"
PIECES="$ROOT/.agents/skills/setup-ai-build-kit/references/pieces.md"
WHATNOW="$ROOT/.agents/skills/what-now/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "File-it-for-later checks"
rs_exists "$PLAN" "$TRIAGE" "$PIECES" "$WHATNOW" "$WORKFLOW"

# The route itself. Remove any one of these and the offer stops being an offer:
# it becomes an interview that starts before the person was asked, or a piece
# filed so thin that coming back to it means starting again.
rs_rule "the choice comes before the step starts" 'offer the choice before'
rs_rule "the choice is settle now or file for later" 'file the piece with its question'
rs_rule "the offer says what settling now would take" 'roughly what settling it now would take'
rs_rule "it is offered every time, not when the agent guesses at a hurry" 'every time a request routes to a question'
rs_rule "the filed piece keeps the person's own words" "the person's own words"
rs_rule "it carries the question in plain language" 'the question it still waits on in plain language'
rs_rule "a fresh session can pick it up" 'a fresh session picks it up with nothing lost'
rs_rule "the session stops rather than starting the step" 'do not begin the step'
rs_rule "deferring never opens a route into /implement" 'never lets the piece be built with the question still open'
rs_guard "$PLAN" "the /plan skill"

# Without this the two files disagree about whether a routed question is work
# that starts now, which is the contradiction this check exists to hold shut.
rs_require_load_bearing "change-triage says a routed question does not start the step" \
  "$TRIAGE" 'does not mean the step starts now'

# The cost is what makes the choice informed rather than a coin toss.
rs_reset
rs_rule "the waiting labels cost different amounts" 'cost different amounts to settle'
rs_rule "research is minutes" 'is minutes, and nobody has to'
rs_rule "an interview or a prototype is a sitting" 'are a sitting'
rs_rule "the estimate stays coarse" 'guess dressed as a number'
rs_guard "$PIECES" "pieces.md"

# The half that stops a silent backlog. An offer to defer without this makes
# things worse than leaving both out.
rs_reset
rs_rule "waiting pieces are weighed against ready ones" 'weigh the waiting pieces against the ready ones'
rs_rule "it never outranks something broken" 'never ahead of anything broken'
rs_rule "it says when the session is a planning one" 'better spent planning than building'
rs_rule "it stays quiet when ready pieces outnumber waiting ones" 'say nothing about it and let the usual advice stand'
rs_guard "$WHATNOW" "the /what-now skill"

rs_require "/plan's Done when records that the choice was offered" \
  "$PLAN" 'offered the choice between settling that question now and filing it for later'
rs_require "WORKFLOW.md explains it in plain words" \
  "$WORKFLOW" 'never made to settle it there and then'
rs_require "and says a filed piece still cannot be built" \
  "$WORKFLOW" 'nothing filed that way can be built until the question is answered'

rs_done
