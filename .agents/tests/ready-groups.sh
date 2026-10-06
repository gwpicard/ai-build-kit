#!/usr/bin/env sh
# ready-groups.sh: guard what /implement is allowed to call safe to build
# together when more than one piece is ready.
#
# These rules once belonged to a command of their own, /queue, which folded into
# /implement, since taking on several pieces is a moment of building. The list
# exists to stop somebody making a mess by taking on several pieces at once, so
# the one thing it must never do is put two pieces in the same group when one
# is waiting on the other. That safety does not come from /implement working
# anything out. It comes from the printout: a piece with an open blocker
# is never under To build, so everything in that group is free of the others.
# The rule is therefore "read the group", and a version that re-derived safety
# for itself would be the defect this guards against.
#
# The other rules here are the ones a person would notice going: a blocker named
# by number instead of by name, a group printed empty, a list that is shown and
# then built from before the person chose.
#
# plan-printout.sh proves the printout really behaves that way. This proves the
# skill still says to rely on it.

. "$(dirname -- "$0")/lib/rule-shape.sh"

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORKFLOW="$ROOT/WORKFLOW.md"
README="$ROOT/README.md"
PIECES="$ROOT/.agents/skills/setup-ai-build-kit/references/pieces.md"
WHATNOW="$ROOT/.agents/skills/what-now/SKILL.md"
IMPLEMENT="$ROOT/.agents/skills/implement/SKILL.md"
BUILDER="$ROOT/.agents/skills/section-builder/SKILL.md"

rs_init "Ready grouping checks"

# The queue command is gone, so nothing shipped may send the person to it. The
# mutation audit lists rules only, so these direct reads stay out of its way.
SKILLS="$ROOT/.agents/skills"
if [ -z "${RS_LIST:-}" ]; then
  [ ! -e "$SKILLS/queue" ] || rs_fail "the queue skill folder is still there"
  rs_ok "the queue skill folder is gone"
  stale=$(grep -rlE '/queue([^a-z-]|$)|the queue skill' "$SKILLS" "$WORKFLOW" "$README" \
    "$ROOT/llms.txt" "$ROOT/docs/COMPATIBILITY.md" "$ROOT/.agents/hooks" || true)
  [ -z "$stale" ] || rs_fail "a shipped file still points at /queue: $stale"
  rs_ok "no shipped skill, WORKFLOW, README, llms.txt, COMPATIBILITY or hook points at /queue"
fi

rs_rule "the printout is the only source" 'the only source'
rs_rule "safety is read from the group, not re-derived" \
  'a piece with an open blocker is never under `to build`'
rs_rule "the ready group is what can be built together" \
  'they have no dependency between them'
rs_rule "the waiting group names the piece that releases each one" \
  'saying which piece releases it'
rs_rule "blockers are named, never numbered" 'piece names, never issue numbers'
rs_rule "a stale list still gets shown, with its age" \
  'say when it was written'
rs_rule "a piece waiting on a question is in neither group" \
  'leave it out of both groups'
rs_rule "an empty group is not printed" 'rather than printing an empty group'
# Found by reading a real printout rather than by reasoning about one: a piece
# that is shaped but never marked ready sits in the buildable group with no
# marker, and /implement will not take it. Silence about it is
# worst when that piece is the one holding another up.
rs_rule "a sized but unmarked piece is named, not silently dropped" \
  'carrying no marker at all has been sized but never marked ready'
rs_rule "it never asks for a secret in a message" \
  'never ask for a key, a password, or a token in a message'
# The fold: the groups appear when more than one piece is ready, the person
# chooses, and showing them builds nothing. A list that started building the
# moment it was shown would take the choice the list exists to give.
rs_rule "several ready pieces bring up the groups and a question" \
  'when the printout holds more than one piece under `to build` marked `\(ready\)`, show what can be built together and what waits on what, and ask which to take'
rs_rule "asking for the list alone shows it and stops" 'show it and stop there'
rs_rule "the grouping is never worked out again by hand" \
  'never work that out again from the issues'
rs_rule "the whole list never goes back into what-now" \
  'the whole list lives here, at the moment of building, and never goes back into `/what-now`'
rs_rule "showing the list builds nothing" 'showing the list builds nothing'
rs_rule "the build waits for the person's choice" \
  'wait for the person to name what to take'
rs_rule "typed alone with several ready, the person chooses" \
  'where more than one is, show them as "taking on several pieces" below says, and let the person choose'
rs_rule "an unattended run has nobody to choose" \
  'in an unattended run nobody is there to choose'

rs_guard "$IMPLEMENT" "the /implement skill's ready groups"

# The house rule is that a behaviour is told in three places or it is not
# finished. The skill above is one. WORKFLOW.md carries the plain explanation,
# and the README's command table carries the row.
rs_require "WORKFLOW.md says /implement shows the set first" \
  "$WORKFLOW" 'when more than one piece is ready, /implement shows you the whole set before it builds anything'
rs_require "WORKFLOW.md says nothing is built until the person chooses" \
  "$WORKFLOW" 'nothing is built until you choose'
rs_require "README's table row says so" \
  "$README" 'with several ready, shows what can be built together and asks which to take'

rs_require "WORKFLOW.md says what makes the first list safe to take on together" \
  "$WORKFLOW" 'a piece waiting on another piece is never in it'
rs_require "WORKFLOW.md says how to deal with a stale list" \
  "$WORKFLOW" 'type /implement again'

# Where the label is defined, the record has to say that ready alone does not
# mean startable. Getting this wrong is the easy mistake: a piece can be fully
# shaped and still be held up by another.
rs_require "pieces.md says ready alone does not mean startable" \
  "$PIECES" 'ready` alone does not mean startable'
rs_require "pieces.md says what /implement actually offers" \
  "$PIECES" 'the printout has already put under `to build`'

# /what-now keeps its own job. If it ever grew the whole list, the reason the
# list was split from it would be undone, and orientation would become a
# report again. It points at /implement for the whole list instead.
rs_require "what-now still caps itself at three things" \
  "$WHATNOW" 'name at most three things'
rs_require_load_bearing "what-now sends the whole list to implement" \
  "$WHATNOW" 'where the person wants every ready piece at once, /implement shows the whole list'

# The same safety reaches the end of a build. The report there names what can
# be built next, and it once named a piece that was waiting on another, because
# the list had been read by hand. So the next piece comes from the printout's
# To build group, and from nothing else.
rs_reset
rs_rule "the next piece comes from the refreshed printout's ready group" \
  'name only a piece under `to build` marked `\(ready\)`'
rs_rule "the piece just built is never named as next" 'never the piece just built'
rs_rule "with nothing ready, no piece is named as next" 'name no piece as next'
rs_rule "the next piece is never worked out by hand" \
  'never work the next piece out from the issue list'
rs_guard "$IMPLEMENT" "the /implement skill's next-piece rule"

rs_require_load_bearing "section-builder names a next piece only from To build" \
  "$BUILDER" 'name only a piece under its `to build` group'
rs_require_load_bearing "section-builder never works the next piece out by hand" \
  "$BUILDER" 'never work the next piece out from the issue list by hand'
rs_require_load_bearing "pieces.md forbids sorting the pieces by hand" \
  "$PIECES" 'never sort the pieces by reading the issues by hand'

rs_done
