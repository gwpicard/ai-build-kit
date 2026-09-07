#!/usr/bin/env sh
# queue-groups.sh: guard what /queue is allowed to call safe to build together.
#
# The command exists to stop somebody making a mess by taking on several pieces
# at once, so the one thing it must never do is put two pieces in the same group
# when one is waiting on the other. That safety does not come from /queue
# working anything out. It comes from the printout: a piece with an open blocker
# is never under To build, so everything in that group is free of the others.
# The rule is therefore "read the group", and a version that re-derived safety
# for itself would be the defect this guards against.
#
# The other rules here are the ones a person would notice going: a blocker named
# by number instead of by name, a group printed empty, a command that reports and
# then builds something anyway.
#
# plan-printout.sh proves the printout really behaves that way. This proves the
# skill still says to rely on it.

. "$(dirname -- "$0")/lib/rule-shape.sh"

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SKILL="$ROOT/.agents/skills/queue/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"
PIECES="$ROOT/.agents/skills/setup-ai-build-kit/references/pieces.md"
WHATNOW="$ROOT/.agents/skills/what-now/SKILL.md"

rs_init "Queue grouping checks"

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
# marker, and neither /queue nor /implement will take it. Silence about it is
# worst when that piece is the one holding another up.
rs_rule "a sized but unmarked piece is named, not silently dropped" \
  'carrying no marker at all has been sized but never marked ready'
rs_rule "it never asks for a secret in a message" \
  'never ask for a key, a password, or a token in a message'
rs_rule "it reports and does not build" 'this command only ever reports'

rs_guard "$SKILL" "the /queue skill"

# The house rule is that a behaviour is told in three places or it is not
# finished. The skill above is one. WORKFLOW.md carries the plain explanation
# and the row in the command table, which is the other two.
rs_require_twice "WORKFLOW.md explains /queue and lists it in the table" \
  "$WORKFLOW" "/queue"

rs_require "WORKFLOW.md says what makes the first list safe to take on together" \
  "$WORKFLOW" 'a piece waiting on another piece is never in it'
rs_require "WORKFLOW.md says how to deal with a stale list" \
  "$WORKFLOW" 'type /queue again'

# Where the label is defined, the record has to say that ready alone does not
# mean startable. Getting this wrong is the easy mistake: a piece can be fully
# shaped and still be held up by another.
rs_require "pieces.md says ready alone does not mean startable" \
  "$PIECES" 'ready` alone does not mean startable'
rs_require "pieces.md says what /queue actually offers" \
  "$PIECES" 'the printout has already put under `to build`'

# /what-now keeps its own job. If it ever grew the whole list, the split that
# justified a ninth command would have been undone and both commands would be
# doing the same thing.
rs_require "what-now still caps itself at three things" \
  "$WHATNOW" 'name at most three things'

rs_done
