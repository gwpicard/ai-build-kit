---
name: change-triage
description: Classify a request written in plain words before any work happens. Used by shape for every request, a report that something is broken included. Decides whether the request is new work, a repair, too vague to size, or a change that needs the masterplan or the fit check first, and offers the earlier version back first when the live tool broke after a recent merge.
user-invocable: false
---

# Change triage

The user never sorts their own request; you do, and the masterplan is the referee. Read it first, build-path section first.

## Step 1: Understand the request

Compare it with the masterplan, the project's pieces, parked ideas, the recent
changelog, and existing behaviour where that's cheap to check. Before accepting
it as new work, check: does this already exist under another name? Was it
deliberately parked or rejected before?

A parked idea is a closed issue labelled `parked`, so search closed issues too,
not only open ones. The reason was written down to stop the same idea coming
back around and getting built by accident, and it only works if somebody looks. Is the report actually a
misunderstanding or a setup problem rather than a real gap? Does it contradict
an existing rule in the masterplan?

## A report that something is broken

A bug is a piece like any other, so a report of a fault comes here too, in
whatever words it arrives. These three checks come before the usual steps.

### A live break after a recent merge

Where the report is that the live tool
broke, and a merge in the last few days is the likely cause, offer the earlier
version back first, before shaping the repair. Read the masterplan's "How it
stays running" section and the project's recipe. On a recipe, say in one line
what the rollback brings back and that it puts nothing else right, close to:
"The live tool broke after Tuesday's change. I can put the version from before
it back while we find the cause. Shall I roll back?"

Run it only after a yes
that names it, following the `setup-hosting` skill's "Rolling back". Off a
recipe, say what a rollback would need and that the kit cannot do it here, as
that section says. Either way, then shape the repair. A no leaves the live tool
as it is, and the repair is shaped the same way.

### Was this ever promised?

Read the masterplan, build-path section first. A
report is a repair only where the behaviour it asks for was promised. Where it
was never promised, say so kindly and route it as new behaviour: a new wish
treated as a repair ends up in the wrong procedure. Nobody can misfile work by
typing the wrong words; catching that is this check's whole job.

### A small, clear repair

Where the fault is plain from the report or one look
at the screen or the code, and the change is a few lines, such as a typo or a
wrong label, that look is the reproduction. Mark the piece ready at once, with
the failing case as its `## Done when`, and offer to build it in this same
session rather than a fresh one. Anything less certain is shaped by reproducing
it, as the `section-builder` skill's `references/repair.md` describes under
"Shaping a repair".

## Step 2: Classify intent

One of: repair of promised behaviour; new behaviour; clarification or
copy/presentation change; setup or operational task; a decision that needs
clarify; a decision that needs a prototype; a decision that needs source
research; a change that alters the build path or a sensitive area.

## Step 3: Classify consequence

Every consequence that applies, from: presentation-only; behaviour; data;
access; integration or service; money; automatic or irreversible action;
operational reliance. This classification is what later decides the evidence,
the review, and the save route; section-builder reads it rather than re-deriving
it.

When the request is, or becomes, a piece, store the classification on it, mapped
to the small vocabulary the kit uses everywhere:

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
dropped takes its evidence with it.

With the subjects settled, look at the open pieces that carry one of the same
ones, and at anything labelled `building`. Read their titles and their `## So
that` lines. Where one would plainly be built in the same place as this request,
name it before routing: which piece, and what the two have in common. Nothing is
blocked and nothing waits. The person decides whether to carry on, hold this
until the other piece lands, or fold the two together.

Say nothing where no open piece shares a subject, or where the only thing in
common is that both touch this project. A pause on every request teaches people
to skip the pause.

Those are labels on the issue, and the issue is written to the shape in
the `setup-ai-build-kit` skill's `references/pieces.md`. Refresh the printout afterwards, so
the person's list matches what was just agreed.

A later session reads the stored subjects rather than reclassifying the piece
from scratch.

## Step 4: Route

Route to one of: a repair, shaped by reproducing it; a ready piece; clarify; a decision
prototype; a source check; a search for existing work; a step only the person
can do; update the masterplan first; rerun the fit
check; prepare the handover; give the risk notice where a sensitive area
survives redesign. Say the route and the reason in one line.

Piece-sized and clear (one sitting, a done line you could write now, small
enough for a fresh session to hold whole) becomes a ready piece. Too vague to
size runs clarify first. Bigger than a piece gets written into the masterplan
and cut into pieces on the plan, order confirmed with the user.

Context is routed by how far it reaches. A decision that affects the whole
product goes into the masterplan, in plain words. A technical convention that
affects the whole codebase goes into AGENTS.md's stack section. Anything
particular to one piece stays on that piece. This keeps the masterplan free of
implementation terms and keeps each concept in one home.

Where the request is a piece and the route is a question rather than a ready
piece, put the route on the issue: `needs-clarification` for clarify,
`needs-prototype` for a decision prototype, `needs-research` for a source check
or a search for existing work.
Take the label off and mark it `ready` once the question is answered.
Without the label the reason a piece is waiting lives only in the session that
found it, and the next person to open the list sees a piece that has simply
stopped.

`/shape` starts the routed step straight away unless the person asked only to
file the piece. Recognise that request in their plain words, such as "note this
for later" or "just file this idea". Route the piece as usual and hand it back
marked for filing, so `/shape` writes it with its label and starts nothing.

A setup or operational task the person has to do themselves is written onto the
piece as its `## Waiting on you` section, in the shape
the `setup-ai-build-kit` skill's `references/pieces.md` describes. Do the step
yourself where you can; write it down only where you cannot.

A repair takes `broken` as well as its subjects, which is what points `/what-now`,
`/shape` and `/implement` at it. It is ready once it is reproduced.

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

## Step 5: Record only durable information

Do not add a changelog line for every classification; most triage
conversations leave no trace worth keeping. Record only when: the masterplan
changes, the build path changes, a risk notice is accepted, an idea is parked
or rejected for a durable reason, a sensitive area changes, or work
actually lands.

## Done when

The request has exactly one route, the reason is written down, and no work started before the route was chosen.
