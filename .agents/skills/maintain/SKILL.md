---
name: maintain
description: The service visit. Trigger monthly for the light pass, quarterly or before any handover for the full one, and when a tool is being retired. Composes sync and the evidence run instead of repeating them. Do not use for building, fixing, or planning.
disable-model-invocation: true
---

# Maintain

Small regular maintenance is what keeps the rare big problem from arriving. Report findings before applying anything beyond routine updates.

## Monthly, light

1. Update dependencies and check for known vulnerabilities. Report what changed; apply on approval.
2. Once live: read the error alerts and the bills. Anything real becomes a piece on plan.md, for build to take.

## Quarterly, or before a handover

Everything above, plus:

1. Run sync.
2. A simplify pass: name the parts that have grown tangled even though nothing is wrong, and propose the two or three cheapest tidy-ups. Apply on approval.
3. Prune the instruction layer: AGENTS.md lines and project skills that no longer pay their way. Those accumulate debt the same way code does.
4. Run ship's evidence run, scoped by the stakes section's flags.

## When a tool's time is over

Own the ending. Export the data somewhere the team can reach it, tell the people who relied on the tool, switch off the services so nothing keeps billing quietly, and archive the repo. An abandoned tool with real data in it is a liability; a retired one is finished.

## Done when

The findings are reported, the approved changes are applied and recorded, and the calendar says when the next visit is due.
