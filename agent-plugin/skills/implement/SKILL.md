---
name: implement
description: The everyday command for building a piece that has already been shaped and marked ready. Typed alone it takes the next ready piece from the plan. Given an issue number, or a request that matches a ready piece, it builds that one. A request that is not yet a ready piece goes to plan first; implement builds, it does not shape. "/implement auto" builds several ready pieces in a row. Do not use for repairs of promised behaviour; that is fix. Type this command when you want it; it never starts on its own.
disable-model-invocation: true
---

# Implement

Use the current session for related, well-bounded work while the context
remains clear. Start fresh after a long, confused, interrupted, or unrelated
session, and whenever an independent review is required. The documents are
the source of truth either way. Read masterplan.md first, build-path section
first, then the project's pieces.

This command builds; it does not shape. It takes a piece that `/plan` has
already shaped and marked ready, and carries it to a confirmed, saved change.
Shaping, sizing, and settling a question all happen in `/plan`, so this command
never has to guess what a piece means. A request that is not yet a ready piece
belongs to `/plan` first.

`.agents/tools/plan-refresh.sh` prints the open issues into `plan.local.md`.
Refresh first, then read that. `.agents/skills/setup-ai-build-kit/references/pieces.md`
describes how the pieces are kept.

When GitHub cannot be reached, say so, say when the printout was last written,
and work from it. The piece already in hand carries on. Anything that would
change what is on the plan waits, because an issue that cannot be updated is
not a record of anything.

## Typed alone

Take the lowest-numbered ready piece that nothing open is holding up and whose
class the current build path allows. A ready piece is one `/plan` has finished
shaping: it carries the `ready` label, has a `## Done when` line, and waits on no
open question. The issue list says which are held up, so this needs no digging.

A piece with open parts is a container, not a slice to build directly. Skip it
and take one of its parts, the same way you would take any other ready piece; the
parent closes on its own when its parts all close. The issue list carries the
sub-issue count, so a parent is known without digging, the way a blocker is.

Before handing an eligible piece to section-builder, confirm it's genuinely
unblocked, confirm the current build path allows it, and identify its
evidence and save route from the piece and the build path. Read the piece's
subject labels rather than reclassifying it; the classification was settled in
`/plan` and section-builder reads it rather than re-deriving it.

A piece labelled `blocked` needs attention before it counts as buildable again:
one safely prepared and stopped at a recorded condition stays skipped until that
condition is met, or until the person accepts the risk on the record; one parked
after repeated failure (references/running-longer.md) needs routing back to
`/plan` first, for another look.

## When a piece waits on the person

A piece carrying a `## Waiting on you` section cannot be built until that step is
done. Do not attempt it, and do not pass it over in silence. Say what the step
is, in the words the piece uses, and that building carries on once it is done.

In an unattended run, name the step, leave the piece where it is, and take the
next ready piece, so the run keeps working and the step is waiting when the
person comes back.

Where the step turns out to be something you can do yourself, do it and carry on
rather than asking. A piece should never hold work up for something the agent
could have gone and done.

## When the next piece is not ready

A piece that still carries `needs-clarification`, `needs-prototype`, or
`needs-research` has a question to settle before its code is written. An issue
with no `## Done when` was typed by hand and never sized. Neither is ready, and
building either one only guesses the answer.

This command does not settle the question. Settling it is planning, and planning
is what `/plan` is for. Say in one sentence what the piece is waiting on, and
point the person at `/plan` to shape it. Then take the next ready piece instead,
so a session that asked to build still builds something. Where nothing else is
ready, say so plainly rather than shaping the waiting piece here.

## Given a specific piece or a request

Typed alone, take the next ready piece as above.

Given an issue number, build that piece if it is ready, and send it to `/plan`
if it is not, saying in one line why it is not ready.

Given a request in plain words, check whether it already matches a ready piece.
Where it does, build that piece. Where it does not, this is new or unshaped
work: point the person at `/plan`, which shapes a request into a piece. This
command never shapes a typed request itself, and it never builds past an open
question.

## When the pieces contradict each other

The blocked-by link is the truth and the `blocked` label is only a hint, so read
the link. A piece whose blockers have all closed is buildable even with the
label still on it. Say the label looks stale, and leave taking it off to `/sync`.

When nothing is ready, because everything open is held up, still waiting on a
question, or two pieces hold each other up, say so plainly and name what is
waiting on what. Standing there with nothing to say is the one unhelpful answer.
Two pieces blocking each other is a planning mistake rather than a state to wait
out, so offer to break it in `/plan`.

A piece assigned to somebody else is theirs. Skip it and say who has it. Where
that person is no longer around, offer to take it over and let the person
decide, because reassigning somebody's work is their call.

Two people building the same piece is what claiming a piece exists to prevent,
so say it the moment you see it rather than at the end.

## Typed with auto, or handed to a goal mode

Auto is not an ordinary peer to normal building; it is earned, not default.
Before enabling it, require: at least three normal pieces completed cleanly,
no unresolved review or flagged work waiting, clean Git state, evidence a machine can
check for every selected piece, no piece still waiting on a question
(`needs-clarification`, `needs-prototype`, or `needs-research`), every selected
piece self-sufficient enough to build without a person present, meaning its
`Under the hood` notes carry what the build needs, nothing needing
human judgement in the batch,
no pending build-path transition, and the user's explicit approval of the
batch. A project has earned auto mode when its records and checks have
repeatedly predicted successful ordinary builds; the presence of an agent
feature called "goal" or "auto" does not itself make the project eligible.

Once eligible, load references/running-longer.md before starting and follow
it. The shape, so the person knows what they are agreeing to: the plan is
approved once, only ready pieces a machine can prove get taken, a failing piece is
retried three times and then parked, flags and expert scopes stop the run,
and it ends through the route required by the build path: normally one pull
request carrying a checklist of things to try before merging, or a confirmed
checkpoint for eligible private exploration.

## Done when

The route was followed, the records are true, and the piece is confirmed and saved through the required route, safely blocked at a recorded condition, or the user knows exactly where things stopped and why.
