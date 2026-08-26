#!/usr/bin/env sh
# acceptance-is-earned.sh: guard what has to be true before flagged work is built.
#
# The kit refuses nothing. Once a risk notice has been given and the person has
# accepted the risk on the record, it may build anything. Both halves of that
# have to actually happen, and measured runs show the second half quietly
# skipped: the notice was given correctly, naming who was exposed, and then the
# flagged work went ahead "on an instruction to carry on rather than a plainly
# accepted, recorded acceptance".
#
# Two failures share that sentence. The acceptance was never earned, because
# "try something else" is an instruction about the work rather than a decision
# about the risk. And it was never recorded, because the rule said to do the
# steps in order and a run believes it did.
#
# So this guards a read-back and a definition, not the order. The order was
# already written down and already believed.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

FIX="$ROOT/.agents/skills/fix/SKILL.md"

rs_init "Acceptance checks"
rs_exists "$FIX"

rs_rule "the acceptance is recorded before the work starts" \
  'build-path section before the replacement starts'
rs_rule "and one collected afterwards is not an acceptance" \
  'a note about something that already happened'
rs_rule "the masterplan is read back before building" \
  'read the masterplan back before the replacement starts'
rs_rule "and the line being there decides whether building happens" \
  'let the .accepted:. line being there decide'
rs_rule "a missing line means it was not recorded, whatever was said" \
  'was not recorded whatever was said'
rs_rule "and the work waits" 'and the work waits'
rs_rule "the believed-versus-read distinction is stated" \
  'is what a run believes it did'
rs_rule "being told to carry on is not an acceptance" \
  'being told to carry on is not an acceptance'
rs_rule "instructions about the work are not decisions about the risk" \
  'instructions about the work, not decisions about the risk'
rs_rule "what the line records is the person accepting the exposure" \
  'hearing who is exposed and saying they accept'
rs_rule "an unquotable acceptance is not one" \
  'if you cannot quote them accepting it'
rs_rule "so it is asked once, plainly, with the exposure named again" \
  'ask once, plainly, naming the exposure'
rs_rule "rather than read into whatever they say next" \
  'reading one into the next thing they say'
rs_guard "$FIX" "the fix skill"

rs_done
