---
name: plan
description: The command for turning an idea into a ready piece before anything is built. Typed with words after it, it takes the request in plain language, works out what kind of work it is, shapes it into a piece, and settles any open question. Typed alone it shapes the next piece still waiting on one. It records and stops; it never builds, though it offers to hand a ready piece to implement. Type this command when you want it; it never starts on its own.
disable-model-invocation: true
---

# Plan

Plan shapes work; it does not build it. It takes an idea in plain language, works
out what kind of work it is, writes it into a piece somebody could build, and
settles anything the piece is still waiting on. When a piece is ready it offers
to hand it to `/implement`, but building is always a separate, deliberate step.

Read masterplan.md first, build-path section first, then the project's pieces,
the same way `/implement` does. Refresh the printout and read that.
`.agents/skills/start/references/pieces.md` describes how the pieces are kept.

## Typed with words

Run change-triage on the request and follow its route: shape it into a ready
piece now, run clarify first, run a decision prototype, run a source check,
update the masterplan first, or stop and rerun the fit check. Say which route
you chose and why, in one line.

Clear, piece-sized work becomes a ready piece straight away: write it into the
shape `.agents/skills/start/references/pieces.md` describes, take its subjects
from change-triage rather than choosing them yourself, and label it `ready`.
That is a new issue, and it starts unassigned: a person is assigned only when
`/implement` picks the piece up to build it, never when `/plan` creates it. Then
make the build offer below.

Where the request is bigger than a piece, it goes into the masterplan first and
is cut into pieces on the plan, order confirmed with the user. Where it would
change what kind of project this is, stop and rerun the fit check before shaping
anything.

## When a piece is waiting on a question

A piece labelled `needs-clarification`, `needs-prototype`, or `needs-research`
has a question to settle before its code could be written. Settling that
question is the work of this command. An issue with no `## Done when` was typed
by hand and never sized, so treat it as `needs-clarification`.

Run the step the label names, then take the label off and mark the piece `ready`:

- `needs-clarification` runs clarify. Write what comes out into the shape
  `.agents/skills/start/references/pieces.md` describes, and keep the person's
  original words underneath, because their words are what a refinement can be
  checked against and what to return to when it reads wrong.
- `needs-prototype` runs the decision prototype in
  `.agents/skills/clarify/references/decision-prototype.md`, which answers the
  one question it exists for and writes the decision back onto the piece.
- `needs-research` runs a source check, and records the fact it finds on the
  piece.

The interview may show that the real block is a different one and swap
`needs-clarification` for `needs-prototype` or `needs-research`. Follow the new
label rather than shaping past it. A piece whose question is settled carries the
`ready` label and no `needs-` label; the two never sit together.

## Typed alone

Take the lowest-numbered piece still waiting on a question, or the next unsized
note, and shape it as above. When nothing is waiting and every piece is already
ready, say so and point the person at `/implement` to build the next one. Plan
does not run out of things to do quietly; it says the plan is shaped.

## The build offer

When a piece is ready, offer to build it now: name the piece, and offer to hand
it to `/implement` in this session, or "not now" to leave it as a ready piece
for later. The offer is genuinely optional, and declining leaves a shaped,
recorded piece that any `/implement` session picks up.

Plan itself never builds. Where the person accepts, that is `/implement` running
on the piece just shaped, not this command writing code. Where a founding
session or a long planning session is ending, prefer pointing at `/implement` in
a fresh session over building here, so a heavy context does not carry into the
build.

## Record only durable information

Follow change-triage's rule: add a changelog line only when work actually lands,
the masterplan changes, the build path changes, a risk notice is accepted, or an
idea is parked or rejected for a durable reason. Shaping a piece is not itself a
changelog entry; the piece is the record.

## Done when

The request has exactly one route, the piece is written into its proper shape
and labelled `ready` or with the question it still waits on, the person's
original words are kept underneath a refinement, and nothing was built except
through an accepted build offer.
