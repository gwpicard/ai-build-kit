---
name: build
description: The everyday word for making the tool do something new or different. Typed alone it takes the next piece from the plan. Typed with words after it, it takes the request in plain language and works out what kind of work it is. "$build auto" builds several pieces in a row. Do not use for repairs of promised behaviour; that is fix.
disable-model-invocation: true
---

# Build

Always a fresh session: one piece per session keeps quality flat and the documents honest. Read masterplan.md first, stakes section first, then plan.md.

## Typed alone

Take the next piece marked to-build and run section-builder on it.

## Typed with words

Run change-triage on the request and follow its route: build it now through section-builder, run grilling first, update the masterplan first, or stop and send the user to the assessment. Say which route you chose and why, in one line.

## Typed with auto

The user approves the plan once; you build the pieces in a row without them in between. The rules of the mode: every piece still goes test first with the test seen failing, and every piece gets its own commit, so anything can be unwound piece by piece. Stop the run at any failing test you cannot make pass inside its piece, at anything change-triage would escalate, at any touch of a flagged area, and at anything ambiguous; never guess to keep a run going. Skip the per-piece hand-over, and end the run with the evidence run (ship/references/evidence-run.md) plus a report: what was built, what passed, where and why the run stopped, and a checklist of things for the user to try, riskiest first, anything near the flags on top.

## Done when

The route was followed, the records are true, and either the piece is confirmed and pushed or the user knows exactly where things stopped and why.
