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
`.agents/skills/setup-ai-build-kit/references/pieces.md` describes how the pieces are kept.

## Typed with words

Run change-triage on the request and follow its route: shape it into a ready
piece now, run clarify first, run a decision prototype, run a source check,
update the masterplan first, or stop and rerun the fit check. Say which route
you chose and why, in one line.

Clear, piece-sized work becomes a ready piece straight away: write it into the
shape `.agents/skills/setup-ai-build-kit/references/pieces.md` describes, take its subjects
from change-triage rather than choosing them yourself, and label it `ready`.
That is a new issue, and it starts unassigned: a person is assigned only when
`/implement` picks the piece up to build it, never when `/plan` creates it. Then
make the build offer below.

Shape the piece in its two layers. The surface stays plain and comprehensive
about anything that affects the product, so it never reads as simpler than the
work is: a fact that would change a product decision goes on the surface, in the
person's words. The build context that only affects how the code gets written
goes in the collapsed `Under the hood` section, so the person never has to read
it and `/implement` still has it. Route context that reaches past this piece by
how far it reaches: a whole-product decision to the masterplan, a whole-codebase
convention to AGENTS.md's stack section. A piece must be small enough for a fresh
session to hold whole; where it is not, cut it down. Any groundwork the piece
needs is itself a vertical slice, ordered ahead of the piece that needs it, never
a separate "database" or "API" layer.

Where the request is bigger than a piece, it goes into the masterplan first and
is cut into pieces on the plan, order confirmed with the user. Parts of one
outcome become sub-issues of a parent piece, each a vertical slice; separate
outcomes that must come in order become separate pieces linked by blocked-by. The
test is the outcome: one shared `## So that` means parts of a whole, and the
parent is done when its parts are. Where it would change what kind of project
this is, stop and rerun the fit check before shaping anything.

## Settling it now, or filing it for later

Where the route is a question rather than a ready piece, offer the choice before
the step starts: settle it now, or file the piece with its question and come back
to it. Say roughly what settling it now would take, so the choice is informed
rather than blind. A source check or a search for existing work is minutes. An
interview or a prototype is a sitting.

Make the offer every time a request routes to a question. Guessing at how much
time somebody has is worse than asking them, and an offer that appears only when
the agent judges them to be in a hurry is one nobody learns to expect. Word it as
two ways of working, not as a reason to put the work off.

Filing it for later writes the piece in full: the person's own words, the
question it still waits on in plain language, and the label that names who can
settle it. It is the same piece a session settling the question now would have
started from, so a fresh session picks it up with nothing lost. Then stop.
Do not begin the step, and do not ask a second time in the same session.

A piece filed this way carries its `needs-` label and no `ready` label, which is
what keeps it out of `/implement` until its question is answered. Deferring the
question never lets the piece be built with the question still open.

## When a piece is waiting on a question

A piece labelled `needs-clarification`, `needs-prototype`, or `needs-research`
has a question to settle before its code could be written. Settling that
question is the work of this command. An issue with no `## Done when` was typed
by hand and never sized, so treat it as `needs-clarification`.

Run the step the label names, write what settled it into the piece's `## Decided`
section, and only then take the label off and mark the piece `ready`. The record
goes first because the label is the only thing saying the question was ever open:
once it is gone, a piece settled properly and a piece nobody looked at read
exactly alike.

- `needs-clarification` runs clarify. Write what comes out into the shape
  `.agents/skills/setup-ai-build-kit/references/pieces.md` describes, and keep the person's
  original words underneath, because their words are what a refinement can be
  checked against and what to return to when it reads wrong.
- `needs-prototype` settles the piece with something to look at. Where the
  person already has a mock, a sketch, or anything else that shows it, follow
  `.agents/skills/clarify/references/existing-artifact.md` and build toward
  that, rather than building a throwaway to rediscover a decision they have
  already made. Otherwise run the decision prototype in
  `.agents/skills/clarify/references/decision-prototype.md`. Either way, the
  decision goes back onto the piece in words.
- `needs-research` runs one of two steps and records what it finds on the
  piece. A question about one external fact, such as what a provider's API
  supports, runs the source check in
  `.agents/skills/change-triage/references/source-check.md`. A question about
  whether something already exists that could do the work runs
  `.agents/skills/change-triage/references/existing-work.md`. Say which step you
  ran and why, in one line, because a question can plausibly match either.

Two of those three need the person in the room. An interview needs somebody to
interview, and a prototype exists so somebody can react to it. Research does
not: the agent settles it alone.

Never answer a person-present question yourself. With nobody there, say which
pieces are waiting on them and leave those pieces labelled as they are. A guess
written onto a piece and marked `ready` is worse than an open question, because
the label that said it was open has gone and `/implement` builds on the guess.

The interview may show that the real block is a different one and swap
`needs-clarification` for `needs-prototype` or `needs-research`. Follow the new
label rather than shaping past it. A piece whose question is settled carries the
`ready` label and no `needs-` label; the two never sit together.

## Typed alone, or given a piece

Typed alone, take the lowest-numbered piece still waiting on a question, or the
next unsized note, and shape it as above. When nothing is waiting and every
piece is already ready, say so and point the person at `/implement` to build the
next one. Plan does not run out of things to do quietly; it says the plan is
shaped.

Given an issue number, settle that piece rather than the lowest-numbered one, so
somebody with one piece in mind is not made to work through the list. Where that
piece is already ready, say so and make the build offer instead.

Where the person says they are not staying, take the pieces the agent can settle
alone, which is every piece labelled `needs-research`. Then name the ones that
need them and why, in one short list, so they know what is waiting for their
return. Settle none of those in their absence.

## The build offer

When a piece is ready, offer to build it: name the piece, and point at
`/implement` in a fresh session as the way to build it, or "not now" to leave it
as a ready piece for later. A fresh session is the offer for every piece, not
only when a founding or long session ends, so a heavy planning context does not
carry into the build. The offer is genuinely optional, and declining leaves a
shaped, recorded piece that any `/implement` session picks up.

Plan itself never builds. Where the person asks to build here and now anyway,
that is `/implement` running on the piece just shaped, not this command writing
code, and a fresh session stays the better path whenever the planning context
has grown heavy.

## Record only durable information

Follow change-triage's rule: add a changelog line only when work actually lands,
the masterplan changes, the build path changes, a risk notice is accepted, or an
idea is parked or rejected for a durable reason. Shaping a piece is not itself a
changelog entry; the piece is the record.

## Done when

The request has exactly one route, the piece is written into its proper shape
and labelled `ready` or with the question it still waits on, the person was
offered the choice between settling that question now and filing it for later, the person's
original words are kept underneath a refinement, and nothing was built except
through an accepted build offer.
