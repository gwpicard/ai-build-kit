---
name: section-builder
description: Build one piece from the plan to a confirmed, saved change. Used by build for every piece and by fix once the cause is known. Refuses to start on top of uncommitted work. One piece per pass, always.
user-invocable: false
---

# Section builder

You build one piece, directed by someone who will judge it by behaviour. Follow the order.

## 1. Safe start

Read the masterplan's build-path section. Check git status; if uncommitted
work is lying around, stop and say so: it gets finished or cleared first
(what-now owns that conversation). Never build on top of half-done work.
Update from the shared branch when the save route will need it.

Choose the save route before changing anything:

1. **Checkpoint route.** Private or disposable exploration, with no shared or
   live reliance and no change to data, access, integrations, money,
   autonomy, or operations.
2. **Pull-request route.** Shared or live use, a behavioural change, data or
   permissions, an external integration or service, an operational change, or
   any change the build path requires it for.
3. **Flagged route.** The work touches a named expert scope. Build may
   prepare or implement only up to the recorded condition; that condition
   must be met before merge or live activation. Stopping there, safely
   prepared and correctly recorded as blocked, is one of section-builder's
   two successful outcomes; see step 8.

Pull-request and flagged routes work on a short-lived branch. The
checkpoint route may use the current branch once its state is confirmed
clean.

Where the piece is an issue, label it `building` and assign it to whoever is
building it before changing anything. That is what stops two people starting the
same piece, and it costs one call.

## 2. Agree the visible result

Say back what the user will be able to do or see when this piece is done,
what's outside it, and how it will be checked. Get an explicit yes only when
something is still ambiguous; an already-approved, precisely written plan
piece does not need the ceremony repeated.

## 3. Choose evidence

Pick the smallest evidence that would actually be credible. Use every subject
the piece stores as an input to that choice and to the save route, from its
labels on an issue or its `Subjects` column on a plan; do not silently downgrade
any of them. A piece carrying two subjects needs what both demand, and its save
route is the stricter of the two.

An automated behaviour test is required for: business rules, calculations,
permissions, data transformations, integrations, scheduled or background
behaviour, bugs, previously broken behaviour, and any acceptance criteria a
machine can judge.

A guided manual check is acceptable for: copy, layout, colour, exploratory
interaction, subjective usability, and disposable prototype work.

An operational rehearsal is required for: backups, restores, migrations,
rollback, alerts, deployment, and failure recovery. Under `data`, that turns on
what the change does to records that already exist. Adding a new field takes a
test; changing or moving records people already have takes a rehearsal on a copy.

Source evidence is required when correctness depends on an external fact;
run change-triage's source check first.

## 4. Establish the baseline

For automated behaviour: write or identify the check, and show it fails
before the behaviour exists or before the bug is fixed. For adopted
behaviour or a refactor: establish the current passing baseline before
changing it. For visual work: capture or describe the current state and say
what visible difference to expect. Do not write a meaningless automated test
merely to have one.

## 5. Build one vertical slice

Implement only the agreed behaviour, end to end and visible, in the smallest
reasonable change. Run focused checks as you go. Avoid speculative
abstraction; prefer managed services and the project's existing conventions.
Stop and say so if the change is expanding past what was agreed.

Internal engineering judgement, about interfaces, locality, or what makes a
boundary testable, can guide the work, but none of that vocabulary belongs in
what the user sees.

## 6. Hand over the behaviour

Stop. Give the exact action, the expected result, any known limitation, and
whether the evidence behind it is automated, manual, source-backed, or
operational. The user confirms the behaviour wherever human judgement is
required; for a piece with no face (a scheduled job, an email), trigger it
against a made-up case and show what it produced. Describe any gap as
expected versus actual, and fix it at the root.

## 7. Run required review

Review triggers come from the build path, the change's consequence
classification, the masterplan's required controls, or an expert scope. When
any of those apply, run second-opinion using the best independent method
recorded in the capability profile before offering to save; this fires off
what the change actually touched, so it never depends on anyone remembering.

Where the trigger names who must review, that person is the review. Running
second-opinion instead is a different thing, worth doing and worth saying is not
the named one. Evidence the change works is also not a review: a green check
proves the behaviour, and the review exists for what the check cannot see.

## 8. Save

Checkpoint route: update the records, commit, and state the saved checkpoint.

Pull-request route: update the records, commit, push, open a pull request
titled after the piece with a plain-language summary, and run the project
checks. Where the piece is an issue, write `Closes #<number>` in the pull
request body, so merging it closes the piece rather than leaving somebody to
remember. Never present it as ready until the check is green; if it goes red,
say so plainly, pull the failing output yourself, fix through the normal
steps, and push again.

Flagged route: do the pull-request route for everything up to the condition,
then:

- attach or generate the expert brief;
- record the exact condition that must be met;
- label the piece `blocked`, or set its plan status to `blocked` on a project
  with no issues;
- name what unblocked work may still continue;
- state plainly that the flagged capability is not ready or live, with no
  softer wording that could be read otherwise.

A piece that ends here, with all five done, is safely prepared and correctly
blocked. Report it as a completed pass, and leave it alone until the
condition is met or the person accepts the risk instead.

## 9. Sync the records

Normal completion updates: the piece, a changelog line, the masterplan when the
present behaviour changed, and AGENTS.md only when a durable operating
convention changed. A correctly completed build does not need /sync afterward.

Where the piece is an issue, the merged pull request closes it, so there is no
status to set by hand. Remove the `building` label, and refresh the printout
with `.agents/tools/plan-refresh.sh` so the person's list matches what just
happened. On a project with no issues, set the row's status in plan.md instead.

Write the changelog line from the piece's own `So that` and `Done when`, in
plain language, dated. Not from its title, and not from the pull request. A
changelog assembled out of titles reads like a list of tasks, and this record
exists so somebody who cannot read code understands what happened to their
project six months later.

## Excuses that don't hold

- Urgency does not remove the need for evidence.
- Small does not permit hidden scope.
- Visual work does not need a fake automated test to look rigorous.
- Private exploration does not need pull-request ceremony it doesn't need.
- Shared or risky work does not get downgraded because setup is inconvenient.
- A review finding does not authorise unrelated cleanup.

## Done when

One of two outcomes, both complete passes:

- Complete: the agreed behaviour has credible evidence, the user-facing
  result is confirmed where needed, required review is satisfied, the
  records match reality, and the selected save route is complete.
- Safely blocked: the piece stopped at its recorded condition, marked
  `blocked`, with an expert brief carrying that condition, unblocked work
  identified, and no claim that the flagged capability is ready or live.
