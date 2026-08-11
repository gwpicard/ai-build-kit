---
name: fix
description: Bring the tool back to doing what it already should. Use when the user says something is broken, failing, wrong, regressed, or not behaving as intended. Input is evidence, an error, a wrong output, a screenshot. Do not use for behaviour the masterplan never promised; that is build. Type this command when you want it; it never starts on its own.
disable-model-invocation: true
---

# Fix

You restore promised behaviour. The discipline is the order: never change
code before the problem repeats reliably and the cause is understood and
explained.

## 0. Check the report

Read masterplan.md, build-path section first. If the behaviour being asked
for was never promised there, say so kindly and hand the request to build's
route; a new wish treated as a repair ends up in the wrong procedure. Nobody
can misfile work by picking the wrong word; catching that is this step's
whole job.

## 1. Define the symptom

Record the exact steps that trigger it, the expected result, the actual
result, the error text or artifact verbatim if there is one, the environment
it happened in, and whether it's intermittent. A bug you can't describe this
precisely is a bug you can't verify as fixed.

## 2. Build the tightest feedback loop available

Find one repeatable check that catches the exact symptom. Prefer, in order:
an existing failing test; a new focused automated test; a request or command
script; browser automation; replayed input; a small throwaway harness;
structured human-in-the-loop steps, when nothing else can reach the bug.

The user never needs to know which technique this was. The report states how
the bug is triggered, what result marks failure, how long the check takes,
and whether it's reliable.

When no loop can be built, stop and ask for the missing artifact, access, or
permission. Do not begin speculative patching without one.

## 3. Reproduce and minimise

Run the check, confirm it actually catches the user's bug, then remove
irrelevant steps or inputs one at a time until only the smallest case that
still fails remains.

## 4. Rank causes

List two to five plausible causes internally, each with a falsifiable
prediction. Show the list to the user only when their domain knowledge could
change the ranking; otherwise it stays internal.

## 5. Test one cause at a time

Change one variable, add targeted and clearly labelled temporary
instrumentation, and reset to the last saved state after any failed attempt
before trying differently. Failed fixes never stack; stacked fixes are how
clean projects rot.

## 6. Fix and lock it down

Create the regression evidence at the highest credible user-facing boundary,
watch it fail, apply the smallest fix that addresses the actual cause, watch
it pass, then rerun the original, unminimised case. When no credible
automated boundary exists, record that as a maintainability finding and use
the strongest manual or operational evidence available instead.

## 7. Cleanup

Remove temporary logs and harnesses, confirm the original symptom is gone and
the regression evidence passes, record the cause in the changelog in plain
language, update the other records, and use section-builder's save and
review route for the change itself.

## Escalation

After three unsuccessful attempts, stop patching. Do not treat a rebuild as
the automatic fourth attempt; route by what the failures actually revealed,
one of:

- an unclear requirement goes back to grilling;
- missing access, environment, or artifact means stopping to ask for it;
- a clear requirement but an implementation that keeps failing unreliably
  gets rebuilt from the masterplan;
- repeated failure in one technical area means a scoped expert review;
- being unable to establish any testable boundary is a maintenance finding,
  not a fourth patch;
- a piece that has been rebuilt and still fails has hit a real limit, worth
  recommending professional ownership of that one area.

## Done when

The exact original symptom no longer occurs, the repeatable evidence passes,
temporary debugging changes are gone, the cause is recorded, and the
path-required save and review steps are complete.
