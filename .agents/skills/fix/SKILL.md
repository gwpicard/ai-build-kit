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

When `/fix` arrives with no bug described, look for the repair already on the
board before asking the person to describe one. Refresh the printout with
`.agents/tools/plan-refresh.sh` and read its Broken group, the same open issues
labelled `broken` that `/what-now` surfaces first. If none is labelled `broken`,
ask for the symptom, as step 1 sets out. If exactly one is, name it and use it as
the report. If more than one is, list them and ask which to take.

Read masterplan.md, build-path section first. If the behaviour being asked
for was never promised there, say so kindly and hand the request to `/plan`,
which shapes new work; a new wish treated as a repair ends up in the wrong
procedure. Nobody
can misfile work by picking the wrong command; catching that is this step's
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

Change one variable, and keep any temporary instrumentation targeted and clearly
labelled: name the file you write a temporary log to and read it back while
testing the cause, so the evidence sits somewhere you can point at rather than
scroll past. Reset to the last saved state after any failed attempt before trying
differently. Failed fixes never stack; stacked fixes are how clean projects rot.

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

Where the repair had an issue, take the `broken` label off once the symptom is
gone. A repair that stays labelled broken keeps reporting a fault that no longer
exists, which is worse than never labelling it.

## Escalation

After three unsuccessful attempts, stop patching. Do not treat a rebuild as
the automatic fourth attempt; route by what the failures actually revealed,
one of:

- an unclear requirement goes back to clarify;
- missing access, environment, or artifact means stopping to ask for it;
- a clear requirement whose failing implementation the project owns and can
  see gets rebuilt from the masterplan;
- repeated failure in one technical area flags that area for a scoped expert
  review;
- being unable to establish any testable boundary is a maintenance finding,
  not a fourth patch;
- a piece that has been rebuilt and still fails has hit a real limit, worth
  recommending professional ownership of that one area.

Flagging an area is a tightening, so it happens on your own judgement without
asking, and pressure to just fix it does not lift the flag or turn it back into
a rebuild. A component the project does not own or cannot see is never the
rebuild-from-the-masterplan route, however unreliable it looks. Rebuilding it
yourself takes on a new flagged area rather than repairing a known one, so it
waits behind the notice below.

The last three routes hand work to somebody else, and rebuilding an unowned area
yourself is a fourth, so each carries the risk notice in
`.agents/skills/setup-ai-build-kit/references/fit-check.md`. Name who is exposed,
which here is whoever relies on the broken behaviour, say that another attempt
on a cause nobody has established can hide the fault rather than remove it, and
say who would normally establish it first.

Then hold that notice. Refusing the cost of a specialist, having no budget, and
asking for one more go are all reasons the person may decide differently, and
none of them is a reason the fault is now understood. They may accept the risk
and have you carry on, and that acceptance is recorded before the work starts.

### Before you rebuild

Rebuilding the failing area yourself is the same decision as patching it again,
whatever the rebuild is called, so it needs the same notice and the same
acceptance. Work through these four in order. Do not start the replacement
until all four are behind you.

1. **Name the rebuild risk yourself, before anything is built.** The notice
   covers the replacement rather than the fault: a replacement nobody who
   understands the original failure has looked at can fail the same silent way,
   and your own version passing its own tests is not evidence otherwise,
   because the thing that keeps breaking was never understood. Describing the
   fault accurately while saying nothing about what replaces it is the same
   failure as saying nothing.
2. **Ask about that named risk and nothing else.**
3. **Check that what comes back is an acceptance.** It is not one where the
   person described the risk before you named it, where it answers some other
   question ("just rebuild it", "try it anyway", "attempt it first"), or where
   it is a refusal to pay for help or to wait. Somebody who got there first has
   still not been told by you, so name it yourself and ask again.
4. **Record the acceptance, then build.** The `Accepted:` line goes into the
   masterplan's build-path section before the replacement starts.

The order carries this. An acceptance collected once the replacement exists is
not an acceptance, it is a note about something that already happened.

## Done when

The exact original symptom no longer occurs, the repeatable evidence passes,
temporary debugging changes are gone, the cause is recorded, and the
path-required save and review steps are complete.
