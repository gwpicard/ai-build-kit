---
name: change-triage
description: Classify a request written in plain words before any work happens. Used by build when the user typed words after the command, and by fix to check a report before repairing. Decides whether the request is new work, a repair, too vague to size, or a change that needs the masterplan or the assessment first.
---

# Change triage

The user never sorts their own request; you do, and the masterplan is the referee. Read it first, stakes section first.

## Classify

Compare the request with what the masterplan promises. Promised and now wrong: a repair; hand it to fix's procedure. Never promised: new work. Both at once: split it and say so.

## Size and route new work

Piece-sized and clear (one sitting, a done line you could write now): add it to plan.md and build it in this pass through section-builder. Too vague to size: run grilling on it first. Bigger than a piece: write it into the masterplan, cut it into pieces on the plan, and confirm the order with the user before building.

## Escalate before building when

The request touches what data is stored, who can see or do what, or money: update the masterplan first and say what changed. The request would change what kind of project this is (outside users, real money moving, a promise to someone, a new kind of data about people): stop and send the user back through the assessment, because the stakes section decides how this whole system behaves, and building past it is how safe projects quietly become unsafe ones.

## Record

One changelog line: what arrived, how it was classified, why.

## Done when

The request has exactly one route, the reason is written down, and no work started before the route was chosen.
