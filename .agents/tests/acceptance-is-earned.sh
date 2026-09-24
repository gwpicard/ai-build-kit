#!/usr/bin/env sh
# acceptance-is-earned.sh: guard what has to be true before flagged work is built.
#
# The kit refuses nothing, and where the person can judge a risk it no longer
# stops either. It gives the risk notice once, in full, and if the person carries
# on, that is the acceptance: the kit writes the `Accepted:` line with their
# words and the date, and the work goes ahead.
#
# That used to be the opposite rule. "Try something else" and "just build it"
# were read as instructions about the work rather than decisions about the risk,
# so a run that gave the notice then waited for a cleaner yes. The maintainer
# decided the person who has heard who is exposed has decided, whatever words
# they use. So this guards the new definition, and it guards the two things that
# still earn the acceptance: the notice came first, and the line is on the record
# before the work starts. Silence is not carrying on, and an instruction given
# before the notice is not either.
#
# The read-back stays. Measured runs gave the notice correctly and built with
# nothing recorded, because the rule said to do the steps in order and a run
# believes it did. Reading the line back is what tells it whether it did.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

FIX="$ROOT/.agents/skills/fix/SKILL.md"
FIT="$ROOT/.agents/skills/setup-ai-build-kit/references/fit-check.md"

rs_init "Acceptance checks"
rs_exists "$FIX" "$FIT"

rs_rule "the notice is given once, in full, before the next attempt" \
  'give the notice once, in full, in one reply'
rs_rule "carrying on after the notice is the acceptance" \
  'take carrying on as the acceptance'
rs_rule "any instruction to go on counts" \
  'any instruction to go on with the work after the notice counts'
rs_rule "silence does not count, nor an instruction before the notice" \
  'silence does not, and neither does a question or an instruction given before the notice'
rs_rule "the acceptance is recorded before the work starts" \
  'build-path section before the replacement starts, with the date and the person.s own words'
rs_rule "and one collected afterwards is not an acceptance" \
  'a note about something that already happened'
rs_rule "the masterplan is read back before building" \
  'read the masterplan back before the replacement starts'
rs_rule "and the line being there decides whether building happens" \
  'let the .accepted:. line being there decide'
rs_rule "a missing line means it was not recorded, whatever was said" \
  'was not recorded whatever was said'
rs_rule "and the work waits until it is written" 'and the work waits until it is written'
rs_rule "the believed-versus-read distinction is stated" \
  'is what a run believes it did'
rs_rule "no second question for a cleaner yes" \
  'do not ask again for a cleaner yes'
rs_rule "a reply that asks for no work leaves the notice standing" \
  'leaves the work waiting and the notice standing'
rs_guard "$FIX" "the fix skill"

# fit-check.md is where every skill reads the rule from, so the definition has
# to hold there too.
rs_reset
rs_rule "the notice says what the person can do" \
  'what the person can do: have that done first, take the flagged thing out of scope, or carry on'
rs_rule "the notice is given once, in full, in one reply" \
  'give it once, in full, in one reply'
rs_rule "an accepted area gets no second notice" \
  'once an acceptance is recorded for an area, do not give the notice for that area again'
rs_rule "carrying on is accepting" \
  'any instruction to go on with the flagged work is the person accepting the named risk'
rs_rule "no second question for a cleaner yes" \
  'do not ask a second question to get a cleaner yes'
rs_rule "silence is not carrying on" \
  'silence, or a reply that does not ask for the flagged work'
rs_rule "an instruction before the notice is not acceptance" \
  'a person who has not been told cannot have accepted'
rs_rule "other work is not the flagged work" \
  'going on with the work outside the area is not going on with the area'
rs_rule "the line carries the date and the person's words" \
  'with the date and their own words'
rs_rule "the record goes in before the work starts" \
  'add both before the flagged work starts, not after it lands'
rs_rule "the line is read back before the work starts" \
  'let the line being there decide whether the work starts'
rs_rule "then the work goes ahead without asking again" \
  'then build what was asked for, without asking again'
rs_rule "an acceptance is never the caution done" \
  'an acceptance is never the caution done'
# A measured run recorded an acceptance and built on it after referring to "my
# earlier message" that named the options, when no reply had named who was
# exposed. Carrying on only counts after a notice the kit can point to.
rs_rule "the notice is found in a reply before anything is written" \
  'find the notice in one of your own replies'
rs_rule "remembering the notice is not finding it" \
  'remembering that you meant to give it is not finding it'
rs_guard "$FIT" "the shipped fit-check.md"

# /ship and founding are the other two places the kit used to stop. Each now
# gives the notice and carries on when the person does, and neither may drift
# back to a stop.
SHIP="$ROOT/.agents/skills/ship/SKILL.md"
SETUP="$ROOT/.agents/skills/setup-ai-build-kit/SKILL.md"
FOUNDATION="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md"

rs_reset
rs_rule "ship gives the notice once at a person caution" \
  'give the risk notice here, once and in full'
rs_rule "an area already accepted gets no second notice" \
  'where an acceptance is already recorded for the area, give no notice'
rs_rule "carrying on writes the line with words and date" \
  'if the person carries on after the notice, write the .accepted:. line with their words and the date'
rs_rule "the area reads accepted, never done" \
  'line .accepted., never .done.'
rs_rule "silence or other work leaves only that area behind" \
  'silence, a question, or a request for other work is not carrying on'
rs_guard "$SHIP" "ship's Build with care steps"
rs_require_absent "ship no longer stops at a person caution" "$SHIP" 'stop at it'
rs_require_absent "ship no longer halts on an area without a status" "$SHIP" 'do not carry on past one'

rs_reset
rs_rule "founding gives the notice once" \
  'give the risk notice fit-check.md describes, once and in full'
rs_rule "carrying on writes the acceptance with words and date" \
  'if the person carries on after it, write their acceptance'
rs_rule "founding goes on either way" \
  'founding goes on anyway'
rs_guard "$SETUP" "the founding fit-check step"

rs_reset
rs_rule "the project's instructions give the notice once" \
  'give the risk notice once, in full'
rs_rule "carrying on is the acceptance there too" \
  'if the person carries on after the notice, that is their acceptance'
rs_rule "silence is not carrying on" 'silence is not carrying on'
rs_rule "the record never calls the caution done" \
  'accepted, never that the caution was done'
rs_guard "$FOUNDATION" "the project's own AGENTS.md template"
rs_require_absent "the project's instructions no longer stop at a person" "$FOUNDATION" "stop where it is a person"

rs_done
