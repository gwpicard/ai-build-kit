---
name: shape
description: The command for turning any request into a ready piece before anything is built, a new idea or something that is broken. Typed with words after it, it takes the request in plain language, works out what kind of work it is, shapes it into a piece, and settles any open question. Asked only to note an idea, it files the piece and stops. Typed alone it shapes the next piece still waiting on one. It records and stops; it never builds, though it offers to hand a ready piece to implement.
---

# Shape

This command turns an idea or a fault into a piece somebody could build, and
settles anything the piece still waits on. Shape itself never builds.

You sort the request; the person never does, and the masterplan is the
referee. Read masterplan.md first, build-path section first, then refresh the
printout and read it. The `records` skill's `references/pieces.md`
is the one home for how a piece is written, its labels, the "rests on"
clauses, and what to do when somebody acts on GitHub by hand. Follow it.

## Typed with words

Run the `triage` skill before any work happens. It understands the request,
classifies its intent and consequence, and chooses one route. Then act on the
route.

Piece-sized and clear (one sitting, a done line you could write now) becomes a
ready piece at once. Write it to pieces.md's shape with its subjects, and
label it `ready` by running the `records` skill's `scripts/mark-ready.sh` on its
number. It refuses without `## Done when`, and refreshes the printout. A new
issue starts unassigned; `/implement` assigns it when it picks the piece up.
Then make the build offer.

## Writing the piece

Write the piece in pieces.md's two layers: a plain surface that names every
fact that could change a product decision, and `Under the hood` for build
context. A whole-product decision goes to the masterplan, a whole-codebase
convention to AGENTS.md's stack section. Groundwork is its own vertical slice,
ordered ahead, never a "database" or "API" layer.

Write `## Masterplan change` before marking ready, by pieces.md's test. Read it
back in the reply that reports the piece: "When this lands, the masterplan
gains a weekly summary email." For "nothing", say the masterplan already covers
it. Never apply it while shaping.

Write `Live side needs:` only where the live copy needs a new secret, setting
or service, each by name, never a value.

For `Under the hood` on a project with code, run `quality.py reach --paths
<likely files>` and act on its exit code. Add a `Reaches:` line with the files,
routes, tables and tests it reports.

## Shaping now, or filing for later

Typed with words, this command shapes now; do not offer that choice again. A
source check or a search simply starts. An interview or a prototype takes a
sitting, so say so in one line and start: "This needs a short interview, which
takes a sitting. Say 'later' at any point and I'll file it."

On "later", or when asked only to note the idea, route it as usual, then file
it with what is already agreed: the person's own words, the open question in
plain language, and the `needs-` label that says who can settle it. Then stop,
and do not raise the question again this session. A clear, piece-sized request
filed this way is simply a ready piece, with no build offer.

## When a piece is waiting on a question

A piece labelled `needs-clarification`, `needs-prototype` or `needs-research`
is settled here. An issue with no `## Done when` was typed by hand and is
treated as `needs-clarification`.

Run the step the label names, write what settled it into `## Decided`, then run
the `records` skill's `scripts/mark-ready.sh` on the piece. It refuses while
`## Decided` or `## Done when` is missing and says which: write it, then run it
again.

- `needs-clarification` runs the `clarify` skill. Write the result in
  pieces.md's shape and keep the person's original words underneath.
- `needs-prototype`: where the person has a mock, sketch or anything that
  shows it, follow the `clarify` skill's `references/existing-artifact.md`.
  Otherwise run the `clarify` skill's `references/decision-prototype.md`. The
  decision goes back onto the piece in words.
- `needs-research` runs one step of the `research` skill: the source check
  for one external fact, the search for existing work otherwise. Say which and
  why in one line. The `researcher` agent may run it in a fresh context where
  the coding agent has one.

An interview and a prototype need the person present; research does not.
Never answer a person-present question yourself. With nobody there, name the
pieces waiting on them and leave their labels as they are. A guess marked
`ready` is worse than an open question.

When the interview shows a different block, swap to the matching `needs-`
label and follow it.

## Typed alone, or given a piece

Typed alone, take a repair not yet reproduced first (under `Broken` without
`ready`). Otherwise take the lowest-numbered piece waiting on a question, or
the next unsized note. When every piece is ready, say the plan is shaped and
point at `/implement`.

Given an issue number, settle that piece. If it is already ready, say so and
make the build offer.

Where the person is not staying, settle every `needs-research` piece, then
name the pieces that need them and why, in one short list.

## The build offer

When a piece is ready, name it and offer `/implement` to build it, or "not now"
to leave it ready for later. A small, clear repair can be built here and now.
Otherwise suggest a fresh chat only when this conversation has grown long, so
the planning does not crowd the build. Declining leaves a ready piece any
`/implement` session picks up.

A question asked while shaping never offers building as an answer. Build here
only when the person asks to after the build offer; that is `/implement`
running on the piece.

## Record only durable information

The piece is the record. Add a changelog line only when the masterplan or the
build path changes, a risk notice is accepted, an idea is parked or rejected
for a durable reason, a sensitive area changes, or work lands.

## Done when

The request has exactly one route and the reason is written down, no work
started before the route was chosen, the piece is written into its proper shape
and labelled `ready` or with the question it still waits on, a routed question
was started unless the person asked to file it, the person's original words are
kept underneath a refinement, and nothing was built except through an accepted
build offer.
