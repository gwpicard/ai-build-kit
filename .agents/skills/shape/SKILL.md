---
name: shape
description: The command for turning any request into a ready piece before anything is built, a new idea or something that is broken. Typed with words after it, it takes the request in plain language, works out what kind of work it is, shapes it into a piece, and settles any open question. Asked only to note an idea, it files the piece and stops. Typed alone it shapes the next piece still waiting on one. It records and stops; it never builds, though it offers to hand a ready piece to implement.
---

# Shape

This command shapes work; it does not build it. It takes an idea or a fault in
plain language, works out what kind of work it is, writes it into a piece
somebody could build, and settles anything the piece is still waiting on. When
a piece is ready it offers to hand it to `/implement`, but building is always a
separate, deliberate step.

The person never sorts their own request; you do, and the masterplan is the
referee. Read masterplan.md first, build-path section first, then the
project's pieces, the same way `/implement` does. Refresh the printout and read
that. The `setup-ai-build-kit` skill's `references/pieces.md` describes how the
pieces are kept.

Whenever shaping touches a decision, re-read any "rests on" clause in the
piece's `## Decided` or the masterplan, following pieces.md's decision rules.
Check what it names before relying on it, including when the piece is already
ready. When its support has gone, say in one line: "The rule that a job closes
once rested on a test that no longer exists." Name the actual rule in plain
words, then settle any question this opens through the usual shaping route.

## Typed with words

Work through these steps before any work happens, and say the route you chose
and why, in one line.

### 1. Understand the request

Compare it with the masterplan, the project's pieces, parked ideas, the recent
changelog, and existing behaviour where that's cheap to check. Before accepting
it as new work, check: does this already exist under another name? Was it
deliberately parked or rejected before?

A parked idea is a closed issue labelled `parked`, so search closed issues too,
not only open ones. The reason was written down to stop the same idea coming
back around and getting built by accident, and it only works if somebody looks.
Is the report actually a misunderstanding or a setup problem rather than a real
gap? Does it contradict an existing rule in the masterplan?

A report that something is broken comes here too, in whatever words it
arrives. Load `references/repair.md` and run its four checks first, in order:
whether the behaviour was ever promised, a live break after a recent merge, a
fault that has survived three attempts, and a small, clear repair. A repair is
then shaped by reproducing it, as that file describes. That case is the
piece's `## Done when`, and the piece is ready once it is reproduced. Shaping
changes no file the project saves.

### 2. Classify intent

One of: repair of promised behaviour; new behaviour; clarification or
copy/presentation change; setup or operational task; a decision that needs
clarify; a decision that needs a prototype; a decision that needs source
research; a change that alters the build path or a sensitive area.

### 3. Classify consequence

Every consequence that applies, from: presentation-only; behaviour; data;
access; integration or service; money; automatic or irreversible action;
operational reliance. This classification is what later decides the evidence,
the review, and the save route; `/implement` reads it rather than re-deriving
it.

When the request is, or becomes, a piece, store the classification on it as
subject labels, mapped to the small vocabulary the kit uses everywhere:

| Internal consequence | Subject |
|---|---|
| presentation-only | visual |
| behaviour | how it works |
| data | data |
| access | accounts and permissions |
| money | finance |
| integration or service | external service |
| automatic action, operational reliance | background automation |

An irreversible action takes the subject of whatever it is irreversible about,
which is usually `data`.

A request often lands on more than one row, and every row it lands on is stored.
A checkout takes `finance` and `external service`. A nightly backup takes `data`
and `background automation`. Do not pick the closest single subject: the one
dropped takes its evidence with it. A later session reads the stored subjects
rather than reclassifying the piece from scratch.

With the subjects settled, look at the open pieces that carry one of the same
ones, and at anything labelled `building`. Read their titles and their `## So
that` lines. Where one would plainly be built in the same place as this request,
name it before routing: which piece, and what the two have in common. Nothing is
blocked and nothing waits. The person decides whether to carry on, hold this
until the other piece lands, or fold the two together.

Say nothing where no open piece shares a subject, or where the only thing in
common is that both touch this project. A pause on every request teaches people
to skip the pause.

### 4. Route

Route to one of: a repair, shaped by reproducing it; a ready piece; clarify; a
decision prototype; a source check; a search for existing work; a step only the
person can do; update the masterplan first; rerun the fit check; prepare the
handover; give the risk notice where a sensitive area survives redesign.

Piece-sized and clear (one sitting, a done line you could write now, small
enough for a fresh session to hold whole) becomes a ready piece straight away:
write it into the shape the `setup-ai-build-kit` skill's `references/pieces.md`
describes, with the subjects from step 3, and label it `ready` by running this
skill's `scripts/mark-ready.sh` on the piece's number. That is a new issue, and
it starts unassigned: a person is assigned only when `/implement` picks the
piece up to build it, never when `/shape` creates it. Then make the build offer
below.

Whenever this step puts a label on a piece, refresh the printout afterwards, so
the person's list matches what was just agreed. `mark-ready.sh` refreshes it
for you.

Too vague to size runs clarify first. A question rather than a ready piece
puts its route on the issue as a label, as "When a piece is waiting on a
question" below says. Without the label the reason a piece is waiting lives
only in the session that found it, and the next person to open the list sees a
piece that has simply stopped.

Where the request is bigger than a piece, it goes into the masterplan first and
is cut into pieces on the plan, order confirmed with the user. Parts of one
outcome become sub-issues of a parent piece, each a vertical slice; separate
outcomes that must come in order become separate pieces linked by blocked-by. The
test is the outcome: one shared `## So that` means parts of a whole, and the
parent is done when its parts are.

A setup or operational task the person has to do themselves is written onto the
piece as its `## Waiting on you` section, in the shape pieces.md describes. Do
the step yourself where you can; write it down only where you cannot.

A repair takes `broken` as well as its subjects, which is what points
`/what-now`, `/shape` and `/implement` at it. It is ready once it is reproduced.

The request touches what data is stored, who can see or do what, or money:
update the masterplan first and say what changed before routing further. If
it changes the shape of data the tool already holds, and that data is real
rather than made-up, treat it as flagged territory: a backup first, the
change rehearsed on a copy, and only then done for real.

The request would change what kind of project this is (outside users, real
money moving, a promise to someone, a new kind of data about people,
autonomous action): stop, rerun the fit check, record the new build path, and
only then route the work. The build path decides how the whole system
behaves, and building past it is how safe projects quietly become unsafe
ones.

Where that check leaves a trigger standing, give the risk notice described in
the `setup-ai-build-kit` skill's `references/fit-check.md` before routing the flagged work,
and hold it. Nothing is refused and nothing stops there: if the person carries
on after the notice, record the acceptance as fit-check.md says and route the
work. What may not happen is the notice quietly going away, or you deciding on
their behalf that it no longer applies because they pushed back. Repeat the
request back, however many times it arrives, and route it the same way each
time.

### Writing the piece

Shape the piece in its two layers. The surface stays plain and comprehensive
about anything that affects the product, so it never reads as simpler than the
work is: a fact that would change a product decision goes on the surface, in the
person's words. The build context that only affects how the code gets written
goes in the collapsed `Under the hood` section, so the person never has to read
it and `/implement` still has it. Route context that reaches past this piece by
how far it reaches: a whole-product decision to the masterplan, in plain words,
and a whole-codebase convention to AGENTS.md's stack section. Anything
particular to one piece stays on that piece. A piece must be small enough for a
fresh session to hold whole; where it is not, cut it down. Any groundwork the
piece needs is itself a vertical slice, ordered ahead of the piece that needs
it, never a separate "database" or "API" layer.

On every piece you shape or refine, write `## Masterplan change` on the
surface before marking it ready, following pieces.md. Say what the masterplan
gains, changes or loses when it lands. Write "nothing" only when the masterplan
already says every line of `## Done when`; pieces.md has the test, and a new
rule the person could check is a change even when it narrows an existing
promise. Read it back in the reply that reports the piece: "When this lands, the
masterplan gains a weekly summary email." Use the actual change in that line;
for "nothing", say the masterplan already covers it. Do not apply a future change while shaping.

Where the piece needs a new secret, setting or outside service on the live copy,
write its `Live side needs:` line on the surface, following pieces.md: each by
name, never a value. Leave the line out otherwise.

When writing the `Under the hood` notes for a project with code, load
the `implement` skill's `references/reach-check.md` and run its reach
check. Use the live result to name the code seams and existing covering tests,
instead of researching them again from nothing. Keep the result on the piece as
build context only; never create a separate index or record for it.

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
"note this for later" or "just file this idea". Route the request as usual so
the piece gets its route and its subjects, then file it without starting any
step. It is not a separate command. A clear, piece-sized request filed this way
is simply a ready piece, written without the build offer.

Filing writes the piece in full: the person's own words, the question it still
waits on in plain language, and the label that names who can settle it. It is
the same piece a session settling the question now would have started from, so
a fresh session picks it up with nothing lost. Then stop. Do not begin the step,
or carry on with one already started, and do not raise the question again in
the same session.

A piece filed this way carries its `needs-` label and no `ready` label, which is
what keeps it out of `/implement` until its question is answered. Deferring the
question never lets the piece be built with the question still open.

## When a piece is waiting on a question

A piece labelled `needs-clarification`, `needs-prototype`, or `needs-research`
has a question to settle before its code could be written. Settling that
question is the work of this command. An issue with no `## Done when` was typed
by hand and never sized, so treat it as `needs-clarification`.

Run the step the label names, write what settled it into the piece's `## Decided`
section, and only then take the label off and mark the piece `ready`, with
this skill's `scripts/mark-ready.sh` on the piece's number. It refuses while either section
below is missing, and says which. The record
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
- `needs-prototype` settles the piece with something to look at. Where the
  person already has a mock, a sketch, or anything else that shows it, follow
  the `clarify` skill's `references/existing-artifact.md` and build toward
  that, rather than building a throwaway to rediscover a decision they have
  already made. Otherwise run the decision prototype in
  the `clarify` skill's `references/decision-prototype.md`. Either way, the
  decision goes back onto the piece in words.
- `needs-research` runs one of the two steps in `references/research.md` and
  records what it finds on the piece. A question about one external fact, such
  as what a provider's API supports, runs the source check. A question about
  whether something already exists that could do the work runs the search for
  existing work. Say which step you ran and why, in one line, because a
  question can plausibly match either.

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

Typed alone, take a repair not yet reproduced first: a piece under the
printout's `Broken` group without `ready`. Something that used to work and no
longer does outranks anything new. Where there is none, take the
lowest-numbered piece still waiting on a question, or the next unsized note,
and shape it as above. When nothing is waiting and every piece is already
ready, say so and point the person at `/implement` to build the next one. The
command does not run out of things to do quietly; it says the plan is shaped.

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
carry into the build. A small, clear repair is the one exception: the session
is still light, so offer to build it here and now, which is `/implement`
running on it. The offer is genuinely optional, and declining leaves a
shaped, recorded piece that any `/implement` session picks up.

Shape itself never builds. Where the person asks to build here and now anyway,
that is `/implement` running on the piece just shaped, not this command writing
code, and a fresh session stays the better path whenever the planning context
has grown heavy.

A question asked while shaping never offers building as one of its answers,
and the answer to it is never a request to build. Build here only when the
person asks to after the build offer, in their own words.

## Record only durable information

Most shaping conversations leave no trace worth keeping, and shaping a piece is
not itself a changelog entry: the piece is the record. Add a changelog line
only when the masterplan changes, the build path changes, a risk notice is
accepted, an idea is parked or rejected for a durable reason, a sensitive area
changes, or work actually lands.

## Done when

The request has exactly one route and the reason is written down, no work
started before the route was chosen, the piece is written into its proper shape
and labelled `ready` or with the question it still waits on, a routed question
was started unless the person asked to file it, the person's original words are
kept underneath a refinement, and nothing was built except through an accepted
build offer.
