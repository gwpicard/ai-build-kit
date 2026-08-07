---
name: build
description: The everyday word for making the tool do something new or different. Typed alone it takes the next piece from the plan. Typed with words after it, it takes the request in plain language and works out what kind of work it is. "/build auto" builds several pieces in a row. Do not use for repairs of promised behaviour; that is fix.
disable-model-invocation: true
---

# Build

Use the current session for related, well-bounded work while the context
remains clear. Start fresh after a long, confused, interrupted, or unrelated
session, and whenever an independent review is required. The documents are
the source of truth either way. Read masterplan.md first, build-path section
first, then plan.md.

## Typed alone

Take the next piece marked to-build. A piece marked `blocked` needs attention
before it counts as buildable again: one safely prepared and stopped at a
recorded expert gate stays skipped until that gate condition is met; one
parked after repeated failure (running-longer.md) needs routing onward
first, to grilling, a source check, or a build-path reassessment.

Before handing an eligible piece to section-builder, confirm it's genuinely
unblocked, confirm the current build path allows it, and identify its
evidence and save route from the plan and the build path. Read the piece's
stored `Class` rather than reclassifying it; reclassify only when the row
predates the column, the request materially changed, or the class
contradicts the masterplan.

## Typed with words

Run change-triage on the request and follow its route: build it now through
section-builder, run grilling first, run a decision prototype, run a source
check, update the masterplan first, or stop and rerun the fit check. Say
which route you chose and why, in one line.

## Typed with auto, or handed to a goal mode

Auto is not an ordinary peer to normal build; it is earned, not default.
Before enabling it, require: at least three normal pieces completed cleanly,
no unresolved review or expert gate, clean Git state, evidence a machine can
check for every selected piece, nothing needing human judgement in the batch,
no pending build-path transition, and the user's explicit approval of the
batch. A project has earned auto mode when its records and checks have
repeatedly predicted successful ordinary builds; the presence of an agent
feature called "goal" or "auto" does not itself make the project eligible.

Once eligible, load references/running-longer.md before starting and follow
it. The shape, so the person knows what they are agreeing to: the plan is
approved once, only pieces a machine can prove get taken, a failing piece is
retried three times and then parked, flags and expert scopes stop the run,
and it ends through the route required by the build path: normally one pull
request carrying a checklist of things to try before merging, or a confirmed
checkpoint for eligible private exploration.

## Done when

The route was followed, the records are true, and the piece is confirmed and saved through the required route, safely blocked at a recorded expert gate, or the user knows exactly where things stopped and why.
