---
name: change-triage
description: Classify a request written in plain words before any work happens. Used by build when the user typed words after the command, and by fix to check a report before repairing. Decides whether the request is new work, a repair, too vague to size, or a change that needs the masterplan or the fit check first.
---

# Change triage

The user never sorts their own request; you do, and the masterplan is the referee. Read it first, build-path section first.

## Step 1: Understand the request

Compare it with the masterplan, plan.md, parked ideas, the recent changelog,
and existing behaviour where that's cheap to check. Before accepting it as
new work, check: does this already exist under another name? Was it
deliberately parked or rejected before? Is the report actually a
misunderstanding or a setup problem rather than a real gap? Does it contradict
an existing rule in the masterplan?

## Step 2: Classify intent

One of: repair of promised behaviour; new behaviour; clarification or
copy/presentation change; setup or operational task; a decision that needs
grilling; a decision that needs a prototype; a decision that needs source
research; a change that alters the build path or the outside-help scope.

## Step 3: Classify consequence

One of: presentation-only; behaviour; data; access; integration or service;
money; automatic or irreversible action; operational reliance. This
classification is what later decides the evidence, the review, and the save
route; section-builder reads it rather than re-deriving it.

When the request is, or becomes, a plan piece, write the classification into
that row's `Class` column, mapped to the small vocabulary plan.md uses:

| Internal consequence | Plan class |
|---|---|
| presentation-only | visual |
| behaviour | behaviour |
| data, access, money | data/access |
| integration or service | service |
| automatic action, irreversible action, operational reliance | operational |

A later session reads the stored class rather than reclassifying the piece
from scratch.

## Step 4: Route

Route to one of: `/fix`; section-builder directly; grilling; a decision
prototype; a source check; update the masterplan then build; rerun the fit
check; prepare an expert brief; stop at the professional-led boundary. Say
the route and the reason in one line.

Piece-sized and clear (one sitting, a done line you could write now) goes
straight to section-builder. Too vague to size runs grilling first. Bigger
than a piece gets written into the masterplan and cut into pieces on the
plan, order confirmed with the user before building.

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

## Step 5: Record only durable information

Do not add a changelog line for every classification; most triage
conversations leave no trace worth keeping. Record only when: the masterplan
changes, the build path changes, an idea is parked or rejected for a durable
reason, the outside-help scope changes, or work actually lands.

## Done when

The request has exactly one route, the reason is written down, and no work started before the route was chosen.
