---
name: change-triage
description: Classify a request written in plain words before any work happens. Used by plan when the user typed a request, and by fix to check a report before repairing. Decides whether the request is new work, a repair, too vague to size, or a change that needs the masterplan or the fit check first.
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

## Step 2: Classify intent

One of: repair of promised behaviour; new behaviour; clarification or
copy/presentation change; setup or operational task; a decision that needs
clarify; a decision that needs a prototype; a decision that needs source
research; a change that alters the build path or the outside-help scope.

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

Those are labels on the issue, and the issue is written to the shape in
`.agents/skills/start/references/pieces.md`. Refresh the printout afterwards, so
the person's list matches what was just agreed.

A later session reads the stored subjects rather than reclassifying the piece
from scratch.

## Step 4: Route

Route to one of: `/fix`; a ready piece; clarify; a decision
prototype; a source check; update the masterplan first; rerun the fit
check; prepare an expert brief; give the risk notice at the professional-led
boundary. Say the route and the reason in one line.

Piece-sized and clear (one sitting, a done line you could write now) becomes a
ready piece. Too vague to size runs clarify first. Bigger
than a piece gets written into the masterplan and cut into pieces on the
plan, order confirmed with the user.

Where the request is a piece and the route is a question rather than a ready
piece, put the route on the issue: `needs-clarification` for clarify,
`needs-prototype` for a decision prototype, `needs-research` for a source check.
Take the label off and mark it `ready` once the question is answered. Without this the reason a
piece is waiting lives only in the session that found it, and the next person to
open the list sees a piece that has simply stopped.

A repair takes `broken` as well as its subjects, which is what points `/what-now`
and `/fix` at it.

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
`.agents/skills/start/references/fit-check.md` before routing the flagged work,
and hold it. Nothing is refused: the person may accept the risk and have it
built. What may not happen is the notice quietly going away, or you deciding on
their behalf that it no longer applies because they pushed back. Repeat the
request back, however many times it arrives, and route it the same way each
time.

## Step 5: Record only durable information

Do not add a changelog line for every classification; most triage
conversations leave no trace worth keeping. Record only when: the masterplan
changes, the build path changes, a risk notice is accepted, an idea is parked
or rejected for a durable reason, the outside-help scope changes, or work
actually lands.

## Done when

The request has exactly one route, the reason is written down, and no work started before the route was chosen.
