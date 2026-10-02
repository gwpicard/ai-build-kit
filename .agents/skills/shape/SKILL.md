---
name: shape
description: The command for turning an idea into a ready piece before anything is built. Typed with words after it, it takes the request in plain language, works out what kind of work it is, shapes it into a piece, and settles any open question. Asked only to note an idea, it files the piece and stops. Typed alone it shapes the next piece still waiting on one. It records and stops; it never builds, though it offers to hand a ready piece to implement.
---

# Shape

For project record reads and writes, load the `setup-ai-build-kit` skill's
`references/project-records.md`. Its marker selects authoritative concept,
working-rule and operations records for the new format; legacy projects keep
their existing route. This changes record ownership, not safety or merge authority.


This command shapes work; it does not build it. It takes an idea in plain
language, works out what kind of work it is, writes it into a piece somebody
could build, and settles anything the piece is still waiting on. When a piece
is ready it offers to hand it to `/implement`, but building is always a
separate, deliberate step.

Read masterplan.md first, build-path section first, then the project's pieces,
the same way `/implement` does. Refresh the printout and read that.
The `setup-ai-build-kit` skill's `references/pieces.md` describes how the pieces are kept.

Whenever shaping touches a decision, re-read any "rests on" clause in the
piece's `## Decided` or the masterplan, following pieces.md's decision rules.
Check what it names before relying on it, including when the piece is already
ready. When its support has gone, say in one line: "The rule that a job closes
once rested on a test that no longer exists." Name the actual rule in plain
words, then settle any question this opens through the usual shaping route.

## Typed with words

Typed as `/shape <number> check readiness`, this is not a request. Skip
change-triage and run the readiness check on that piece, as the readiness check
section below says. For work already under way, first read "Recovering work
started too soon" below; missing requirements take that recovery route.

Otherwise run change-triage on the request and follow its route: shape it into a ready
piece now, run clarify first, run a decision prototype, run a source check,
record the intended product-rule change on the piece first, or stop and rerun
the fit check. Planning never applies it to current records. Say which route
you chose and why, in one line.

Clear, piece-sized work becomes a ready piece straight away: write it into the
shape the `setup-ai-build-kit` skill's `references/pieces.md` describes, take its subjects
from change-triage rather than choosing them yourself, and label it `ready`
once the readiness check below finds no blocking gap. That is a new issue,
opened as `shaping` so the check has a piece to read, and it starts unassigned:
a person is assigned only when `/implement` picks the piece up to build it,
never when `/shape` creates it. Then make the build offer below.

Shape the piece in its two layers, as pieces.md describes. The header stays
short and plain, so it never reads as simpler than the work is. The agent layer
is complete: consider every field, and where one does not apply, say why in one
line. Every choice a person would notice by trying the tool is decided in
`## Decided`, with its reason, rather than left for the build. Scale the piece to
its change: a colour change answers most fields in one line. The build context
that only affects how the code gets written goes in the collapsed
`Under the hood` section, so the person never has to read it and `/implement`
still has it. Route context that reaches past this piece by
how far it reaches: a whole-product decision to the masterplan, a whole-codebase
convention to AGENTS.md's stack section, lasting technical design to its concept
file listed in `docs/README.md`. A piece must be small enough for a fresh
session to hold whole; where it is not, cut it down. Any groundwork the piece
needs is itself a vertical slice, ordered ahead of the piece that needs it, never
a separate "database" or "API" layer.

On every piece you shape or refine, write `## Masterplan change` on the
surface before marking it ready, following pieces.md. Say what the masterplan
gains, changes or loses when it lands. Write "nothing" only when the masterplan
already says every line of `## Done when`; pieces.md has the test, and a new
rule the person could check is a change even when it narrows an existing
promise. Read it back in the reply that reports the piece: "When this lands, the
masterplan gains a weekly summary email." Use the actual change in that line;
for "nothing", say the masterplan already covers it. Do not apply a future change while shaping.

When writing the `Under the hood` notes for a project with code, load
the `section-builder` skill's `references/reach-check.md` and run its reach
check. Use the live result to name the code seams and existing covering tests,
instead of researching them again from nothing. Keep the result on the piece as
build context only; never create a separate index or record for it.

Where the request is bigger than a piece, it goes into the masterplan first and
is cut into pieces on the plan, order confirmed with the user. Parts of one
outcome become sub-issues of a parent piece, each a vertical slice; separate
outcomes that must come in order become separate pieces linked by blocked-by. The
test is the outcome: one shared `## So that` means parts of a whole, and the
parent is done when its parts are. Where it would change what kind of project
this is, stop and rerun the fit check before shaping anything.

## Shaping now, or filing for later

Typed with words, this command shapes now. The person already chose to shape
when they typed it, so offering them the choice again asks the same question
twice. Where the route is a question rather than a ready piece, start the step
the route names. A source check or a search for existing work simply starts.
An interview or a prototype takes a sitting, so say so in one line and start:
"This needs a short interview, which takes a sitting. Say 'later' at any point
and I'll file it."

The person can say "later" at any point in a step. File the piece then, with
anything the step has already agreed written onto it, and stop.

Filing is also something the person can ask for outright, in words such as
"note this for later" or "just file this idea", or by typing `/shape later` or
`/shape idea` with the idea. That is capture, and change-triage handles it: file
it without starting any step, as an issue labelled `idea`, in their own words,
with nothing settled. It is not a separate command. The idea is shaped the next
time somebody runs `/shape` on it.

Filing part-way through a step writes the piece in full: the person's own words,
the question it still waits on in plain language, and the label that names who
can settle it. It is the same piece a session settling the question now would
have started from, so a fresh session picks it up with nothing lost. Then stop.
Do not begin the step, or carry on with one already started, and do not raise
the question again in the same session.

A piece filed part-way stays `shaping`: it carries its `needs-` label and no
`ready` label, which is what keeps it out of `/implement` until its question is
answered. Deferring the question never lets the piece be built with the question
still open.

## Moving a piece's state

This command takes the old state off in the same step as it puts the new one
on, with one command, so a piece never shows in two columns of the board. It
follows pieces.md for an older project, creating the label first if the project
lacks it.

- Starting on an idea moves it to `shaping`, with `needs-clarification` beside
  it until the interview finds a different reason:
  `gh issue edit <number> --add-label shaping --add-label needs-clarification --remove-label idea`.
- A piece reaches `ready` only when the readiness check finds no blocking gap:
  a session that did not shape it has written a `## Readiness` section saying
  Ready, and the piece is read back as the sections below say. Then, in one
  step:
  `gh issue edit <number> --add-label ready --remove-label shaping --remove-label <its needs- label>`.
- A piece this command cannot finish stays `shaping` with the `needs-` label that
  says why, and the question written on it. A blocking gap the check found is
  such a question: it stays written on the piece, and the piece stays `shaping`.
- A `parked` piece sent back for another look moves to `shaping` the same way,
  with the reason it was parked kept on it:
  `gh issue edit <number> --add-label shaping --add-label needs-clarification --remove-label parked`.

Where GitHub cannot be reached, the label cannot move, so say so and leave the
piece as it is.

## The readiness check

Before a piece moves to `ready`, a session that did not shape it checks it
against the fixed list in the `shape` skill's `references/readiness-check.md`.
The session that shaped a piece has the same blind spots when it judges the
piece, so it would miss the same gaps twice. Start a subagent that carries none
of this conversation, where the coding agent has one, and give it the piece's
number and that file. A fork of this session does not count.

Where the coding agent cannot start a subagent, say in one line that the check
needs a new session, and give the exact line to paste there:
"This piece needs a check by a session that did not shape it. In a new session,
paste: /shape <number> check readiness". Leave the piece `shaping` meanwhile,
except a readiness-only recovery keeps its current state while waiting, as below.
Typed that way, in a session that did not shape the piece, run the check
yourself.

The check writes a `## Readiness` section on the piece: the date, "checked by a
session that did not shape it", Ready or Not ready, and its notes. Read that
section back and let it decide the move. With no blocking gap, move the piece to
`ready`, except readiness-only recovery follows the state rule below. A blocking
gap keeps the piece in `shaping`, with the gap written on it
and the `needs-` label that says who can close it. Notes stay on the piece
for the builder. Say the result in one line, such as "A session that did not
shape this piece checked it: ready, with two notes for the builder." After a gap
is closed, run the check again in a new subagent.

## Recovering work started too soon

Given a piece already in `building` or `to check`, read its body and comments
before routing it. Follow the `setup-ai-build-kit` skill's
`references/pieces.md`, "Recovering work started too soon", for the recovery
record, preservation and the check before merge. Identify the existing branch
and pull request as preserved work before making a state move.

With no Done when, or incomplete requirements, move the piece to `shaping`
with `needs-clarification`, removing its actual old state in the same command:
`gh issue edit <number> --add-label shaping --add-label needs-clarification --remove-label <old state>`.
Shape the missing requirements through the usual route, keeping already agreed
decisions and the original report. Then run the independent readiness check.

With complete requirements and only Readiness missing, run the existing
independent readiness review alone, without repeating the interview. Keep
`building` or `to check` while the review is missing or waiting. A Ready verdict
keeps that state; a blocking gap returns the piece to `shaping` in one step,
with the matching `needs-` label and the gap written on it:
`gh issue edit <number> --add-label shaping --add-label <its needs- label> --remove-label <old state>`.
After closing a gap, use the ordinary readiness route to reach `ready`.

Read the stored verdict back before reporting recovery complete. Say: "The
requirements are ready. The preserved work still needs checking against them
before its pull request can merge." Point to `/implement <number>` to resume
and check that work through section-builder's existing verification route;
`to check` work takes that verification on its preserved branch without a new
claim or a second pull request. Shape itself changes no implementation code.

## When a piece is waiting on a question

A piece labelled `needs-clarification`, `needs-prototype`, or `needs-research`
has a question to settle before its code could be written. Settling that
question is the work of this command. An issue with no `## Done when` was typed
by hand and never sized. It is an idea, so move it to `shaping` with
`needs-clarification`, as the section above says, and shape it.

First check "Answers already on the piece" below. A complete recorded answer
needs reconciliation, not another interview or prototype reaction. Take that
route and skip the label's interview or prototype step when it settles the
question; run only the step required by a remaining gap.

Run the step the label names, write what settled it into the piece's `## Decided`
section, and only then take the label off, with `shaping`, and mark the piece
`ready` once the readiness check finds no blocking gap. The record
goes first because the label is the only thing saying the question was ever open:
once it is gone, a piece settled properly and a piece nobody looked at read
exactly alike.

Read the piece back before the label comes off, and let what you read decide
whether it does. `## Decided` has to hold what settled the question, and
`## Done when` has to be there at all. Where either is missing, the writing did
not happen however well the conversation went: write it, read it again, and only
then relabel.

This is a check, not a reminder. Doing the steps in the right order is what a
run believes it did; reading the piece back is what tells it whether it did. It
is the one part of settling a question nobody in the conversation can see, which
is why a piece has reached `ready` with no `## Done when` in it and nobody
noticed until the files were read.

- `needs-clarification` runs clarify. Write what comes out into the shape
  the `setup-ai-build-kit` skill's `references/pieces.md` describes, and keep the person's
  original words underneath, because their words are what a refinement can be
  checked against and what to return to when it reads wrong.

  A piece another account opened holds a colleague's words, not the person's.
  Read its author first, as the `setup-ai-build-kit` skill's
  `references/pieces.md` describes under "Speaking for the person". Keep their
  words whole under "Original report", and name the author in your reply, so
  the person knows whose request is being reshaped. Ask before saving a changed
  title or scope, and show the new wording when you ask. A body that only adds
  the shaped sections above, with the original kept whole, is not a change of
  scope. Post nothing to that author until the person has said yes to the words.
- `needs-prototype` settles the piece with something to look at. Where the
  person already has a mock, a sketch, or anything else that shows it, follow
  the `clarify` skill's `references/existing-artifact.md` and build toward
  that, rather than building a throwaway to rediscover a decision they have
  already made. Otherwise run the decision prototype in
  the `clarify` skill's `references/decision-prototype.md`. Either way, the
  decision goes back onto the piece in words.
- `needs-research` runs one of two steps and records what it finds on the
  piece. A question about one external fact, such as what a provider's API
  supports, runs the source check in
  the `change-triage` skill's `references/source-check.md`. A question about
  whether something already exists that could do the work runs
  the `change-triage` skill's `references/existing-work.md`. Say which step you
  ran and why, in one line, because a question can plausibly match either.
  Before it starts, write one line on the piece: "Needs your decision: yes" or
  "Needs your decision: no", saying whether its result will need the person to
  choose. With no, and a result that settles every question, move the piece to
  `ready` once the readiness check finds no blocking gap, with nobody there.
  With no, and a result that leaves a question open, the piece stays `shaping`
  with `needs-research` and the gap written on it. With yes, write what it
  found, then swap `needs-research` for `needs-clarification` in one step, so
  the piece waits for the person rather than for a guess:
  `gh issue edit <number> --add-label needs-clarification --remove-label needs-research`.

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

## Answers already on the piece

This route applies when shaping or a run revisits an open, already-shaped
piece with a waiting record. Read the full current body and comments, including
the original question and every remaining gap. A comment or body edit can
answer it; invoking `/shape` manually is not required. Identify exactly what
the person answered and which evidence it settles. Incomplete, unrelated,
ambiguous and empty-form answers leave every remaining gap open. Silence,
labels or an unrelated edit never supply a decision or sensitive-area
acceptance. Keep the unanswered question visible without repeating an
interview when no new answer exists.

For a complete answer, reconcile the piece's Done when, Decided and affected
agent-layer fields, preserving agreed scope and the original words. Remove
the stale Readiness verdict before saving the reconciled specification. Move
a parked or still-ready waiting piece into shaping in one paired command:
`gh issue edit <number> --add-label shaping --remove-label <old state>`.
Keep its failure evidence and preserved branch. A piece already shaping stays
there. Work in building or to check takes "Recovering work started too soon"
first. Remove a settled `needs-` reason only after reading the saved
specification back and confirming that no gap of that kind remains. With
another gap, keep its matching reason and concrete next action. A piece with
only review left stays shaping without a `needs-` reason.

Preserve the original waiting-start history, question, evidence and answer
source when updating the issue. Keep one authoritative Waiting on you section
for the remaining actions; move settled questions and their answers into
labelled history outside that active section. A history heading must not be
`## Waiting on you`, which the printout reads as an active step. Do not replace
the history with the issue's latest updated time. A partly answered section
keeps every unanswered action, even when the specification changed elsewhere.

A technical factual gap takes the existing source-check or existing-work
route, reading the relevant source and current primary evidence. Record the
verified fact and its source on the piece, then reconcile it by this same
route. Research grants no paid experiments, real-account actions or expanded
product scope. A newly uncovered product choice moves to `needs-clarification`
with its concrete question; insufficient evidence keeps `needs-research` and
the gap. Do not guess either answer. Nobody needs to be present for a fact
that the evidence actually settles.

After reconciliation, obtain the existing independent readiness check in a
session that did not shape this specification, with none of the reconciliation
conversation. Read its saved verdict back before moving to ready. An
unavailable independent review keeps the piece unbuildable: record the missing
route and the exact `/shape <number> check readiness` line for a new session.
A blocking result leaves shaping and its matching `needs-` reason. An older
Ready verdict or the reconciling session's confidence cannot substitute.

Save and read back each issue record before calling it settled. If a write or
read-back fails, retain the pending record privately in the ignored run notes
and report the gap; it grants no readiness. In a run, return to the
`implement` skill's `references/running-longer.md` for preservation and
continuation. Shape changes no implementation code. A complete answer and
passing review can return the piece to the same run's plan, but only that
run's existing plan approval, dependency, eligibility and acceptance gates
authorise building it.

## Typed alone, or given a piece

Typed alone, take the lowest-numbered piece still waiting on a question, or the
next idea, and shape it as above. A `shaping` piece with no `needs-` label is
waiting for its readiness check: its shaping finished and the check never ran,
so run the check on it rather than shaping it again. When nothing is waiting and every
piece is already ready, say so and point the person at `/implement` to build the
next one. The command does not run out of things to do quietly; it says the
plan is shaped.

Given an issue number, settle that piece rather than the lowest-numbered one, so
somebody with one piece in mind is not made to work through the list. Given it
as `/shape <number> check readiness`, run the readiness check on that piece and
nothing else. Where that
piece is already ready, say so and make the build offer instead. Route a piece
already being built or checked through "Recovering work started too soon"
before the ordinary idea or ready handling.
Read an existing waiting record through "Answers already on the piece"
before that ordinary ready handling, even when its label still says ready.

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

Shape itself never builds. Where the person asks to build here and now anyway,
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
with every field considered and labelled `ready` only after a session that did
not shape it wrote a `## Readiness` section naming no blocking gap, or `shaping`
with the question it still waits on, or `idea` when the person only asked to
note it, each move took the old state off in the
same step, a routed question was
started unless the person asked to file it, the person's original words are kept
underneath a refinement, and nothing was built except
through an accepted build offer. For recovery of work already under way, the
recovery record identifies preserved work and the unresolved check before merge;
a readiness-only Ready result retains its existing `building` or `to check` state.
