---
name: section-builder
description: Build one piece from the plan to a confirmed, saved change. Used by implement for every piece and by fix once the cause is known. Refuses to start on top of uncommitted work. One piece per pass, always.
user-invocable: false
---

# Section builder

You build one piece, directed by someone who will judge it by behaviour. Follow the order.

## 1. Safe start

Read the piece in full, including its `Under the hood` notes, the masterplan's
build-path section, and any whole-product decision in the masterplan or
whole-codebase convention in AGENTS.md's stack section that the piece points to.
The under-the-hood notes carry the build context so this does not have to be
worked out from nothing. Check git status; if uncommitted
work is lying around, stop and say so: it gets finished or cleared first
(what-now owns that conversation). Never build on top of half-done work.
Bring the shared `main` branch up to date and start the piece from it, on every
save route including the checkpoint route, so no piece begins from a stale copy.
Where `main` cannot be reached, start from the local copy and note that in one
plain line.

Choose the save route before changing anything:

1. **Checkpoint route.** Private or disposable exploration, with no shared or
   live reliance and no change to data, access, integrations, money,
   autonomy, or operations.
2. **Pull-request route.** Shared or live use, a behavioural change, data or
   permissions, an external integration or service, an operational change, or
   any change the build path requires it for.
3. **Flagged route.** The work touches a named sensitive area whose caution
   is neither done nor accepted. Before building inside the area, give the
   risk notice once, in full, as
   the `setup-ai-build-kit` skill's `references/fit-check.md` describes. If
   the person carries on after it, write the `Accepted:` line with their
   words and the date, read it back, and build and save the piece on the
   pull-request route. Do this in the reply that answers them, and do not
   ask a further question before the build. A lock whose only purpose is to
   wait for this caution opens with the acceptance, unless the person asks
   to keep it. If they do not carry on, build only up to the recorded
   condition. In an unattended run nobody is there to carry on, so never
   write an acceptance on the person's behalf: stop at the condition.
   Stopping there, safely prepared and correctly recorded as parked, is one
   of section-builder's two successful outcomes; see step 8.

Pull-request and flagged routes work on a short-lived branch cut from the
up-to-date `main`. The checkpoint route may commit on the current branch once
its state is confirmed clean, but it too starts the piece from the up-to-date
`main` rather than continuing an older branch, so each piece is independent.

A route the project cannot perform right now does not stop the work. Where the
pull-request route is the right one and GitHub cannot be reached, so there is no
way to open a pull request, build the piece and save it on its own branch. Note
the step that did not happen in one plain line where the piece lives, the way you
would note any other fact.

That line is a note, not a warning. A step that cannot be performed because a
service is temporarily unreachable is missing, not dangerous, so it earns no risk
notice, no acceptance, and no recorded exception. Treating it as a hazard tells
the person their working project is broken, which is both untrue and the fastest
way to make them distrust the record they are relying on. Open the pull request
once GitHub is reachable again.

**The first upload.** Founding told the person nothing would be uploaded, so
the first push of the project's code waits for their yes. Before any push,
check where `origin` points. Where it is the kit's own repository,
`gwpicard/ai-build-kit`, push nothing: say plainly that the project still
points at the kit's repository, and ask for their own. Never push a project
there.

Then run `git ls-remote --exit-code --heads origin` and read its exit code.
Exit 2 means the repository has no branch: nothing from this project is
online yet, and this push is the first upload. Any exit other than 0 or 2
means the listing could not be read, because there is no `origin`, GitHub
cannot be reached, or the tool is not signed in. That is the route the
project cannot perform right now, with its one-line note, and never an empty
repository. Exit 0 means it has branches. Run `git fetch origin`: the code is
already online only when a remote branch shares history with the local
`main`, so that `git merge-base` finds a commit they share. Then push without
asking. That is how you know the question was answered: it is asked once for
each project, and no record is kept. A remote with nothing on it has no
`main` to bring up to date, and that needs no note.

Where the repository has branches but none shares history with `main`, push
nothing. It may hold a first commit GitHub made itself, or other work. Name
`owner/name`, say it holds something else, and ask the person what to do.

Build and check the piece first. Only the push waits. In the reply that
reports the piece, ask for a yes that names the upload: the repository as
`owner/name`, and whether it is public or private, read with
`gh repo view --json visibility`. Where you cannot read that, say so rather
than guess. Close to: "This is the first time your project's code goes
online. It goes to owner/name, which is private. Shall I upload it?"

On a yes, push the piece's branch, then create `main` on GitHub at the commit
the branch was cut from, `git merge-base main <piece branch>`, with
`gh api repos/<owner>/<name>/git/refs -f ref=refs/heads/main -f sha=<commit>`.
Make it the default branch with `gh repo edit --default-branch main`, open
the pull request, and tell the person in one clause that GitHub now starts
from their project's main copy. This is the one time `main` is written other
than by a merge. It holds only what the person already has, so it changes
nothing anybody relies on. On a no, keep the piece on its own branch on this
computer. That is the route the project cannot perform right now, with its
one-line note, and the next piece that pushes asks again. In an unattended
run nobody is there to say yes, so never upload on the person's behalf: keep
the work local and note it on the piece.

Claim the piece before changing anything. Label the piece `building` and assign
it to whoever is building it, in one step,
`gh issue edit <number> --add-label building --remove-label ready --add-assignee <login>`.
Whatever state it carried comes off in that step, such as `parked` for a piece
whose condition is now met. That is what stops two people starting the same
piece, and it costs one call. Where GitHub cannot be reached, the claim fails:
say so, and do not start the piece. A piece already claimed carries on if
GitHub drops out later, as the route note above says.

## 2. Agree the visible result

Say back what the user will be able to do or see when this piece is done,
what's outside it, and how it will be checked. Get an explicit yes only when
something is still ambiguous; an already-approved, precisely written plan
piece does not need the ceremony repeated.

## 3. Choose evidence

Pick the smallest evidence that would actually be credible. Use every subject
the piece stores as an input to that choice and to the save route, from its
labels; do not silently downgrade
any of them. A piece carrying two subjects needs what both demand, and its save
route is the stricter of the two.

Where a machine can check the piece, that check is run and must pass before the
piece is called done. The softer proofs below are for the claims a machine
cannot judge, not a way around one it could. A screen that looks right is never
a substitute for a check that was available and skipped.

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

On Build with care, where a runner exists for the project's language, offer
the optional check in `references/test-strength.md`: break only the changed
code on purpose to see whether its tests notice. Run it after the ordinary
tests pass, if the person wants it. Use that reference's one-line report and
sort the misses on the piece. This offer adds no gate to saving the work.

## 4. Establish the baseline

For automated behaviour: write or identify the check, and show it fails
before the behaviour exists or before the bug is fixed. For adopted
behaviour or a refactor: establish the current passing baseline before
changing it. For visual work: capture or describe the current state and say
what visible difference to expect. Do not write a meaningless automated test
merely to have one.

Load `references/reach-check.md` and use its current engine to take a small
structure baseline before code changes. Record only the relationships needed
for comparison: imports between the parts being changed, and any declared
sensitive-area boundary. Where no engine is present, read those imports
directly. Do not save the baseline as a project file or turn it into a score.

## 5. Build one vertical slice

Implement only the agreed behaviour, end to end and visible, in the smallest
reasonable change. Run focused checks as you go. Avoid speculative
abstraction; prefer managed services and the project's existing conventions.
Stop and say so if the change is expanding past what was agreed.

A piece whose build fails three attempts stops there: move it from `building`
to `parked` in one step, `gh issue edit <number> --add-label parked --remove-label building`,
with one line on what kept failing, and route it as `/fix`'s escalation says.
Never let a fourth attempt run on the same guess.

A build may reach a service the tool uses, for example to read its keys or set
it up. Use only what a tool offers through its own commands, and the keys the
tool already sends to the browser. Never read a stored login, token or
password out of the keychain, a credential store, or another tool's own files,
such as its settings or sign-in file, and never call a service's management API
with one. When you cannot read or change something that way, say so truthfully
and ask the person, naming the page where it lives. Once you have said you
cannot read something, never read it another way. A key the person gave this
project, kept where the masterplan records it, belongs to the project.

A command that changes a live service's settings or data, other than saving
code through the save route, waits for a yes that names the change and says
whether it can be undone, or that you do not know. Name every setting or
record the command will change, not only the one you meant to change, taken
from the command's own preview where it has one. Pushing a whole local
settings file changes everything in it that differs from the live project.
Applying migrations to the live project needs the yes too, and so does
changing its sign-in settings. Ask before you run it, never after. In an
unattended run nobody is there to say yes, so leave it unrun and say so on the
piece. A secret key is never written to a shared temporary folder such as
`/tmp`. Write what the build needs straight into the git-ignored file that
uses it. A secret key read through a tool's own commands is piped straight
into that file and never shown.

When the piece carries `visual`, or the change touches a screen file whatever
subject the piece carries, load and follow `screen-check`. A screen file is one
that renders a page, view, component, template, style, or native interface.
Apply it before the screen's guided manual check, so the person judges the first
result rather than describing a redo. When this build came from `/fix`, use the
same boundary: a fault on a screen gets the rules and any other fault does not.

When filing a new piece for work this build uncovers, follow the rule for work
found during a build in the `setup-ai-build-kit` skill's `references/pieces.md`.
Put the originating title on the new piece's surface and name the new piece
on the originating record. Say one line such as "Found while building the
invoice list." Keep the current build within its agreed scope.

A test that passes only on a retry is a fault in the test, never a passing
result. Report it as unreliable evidence and repair or replace it before the
piece can be saved.

Groundwork that makes the change easier is allowed only when it is itself a
vertical slice, or an expand-then-contract sequence that keeps the checks green
throughout, and it is ordered ahead as its own piece. It is never a horizontal
"refactor the data layer first" step, because that is the speculative
abstraction the paragraph above rules out and the layer split `/setup-ai-build-kit` forbids.

Internal engineering judgement, about interfaces, locality, or what makes a
boundary testable, can guide the work, but none of that vocabulary belongs in
what the user sees.

## 6. Hand over the behaviour

Before handing over, run the type check and linter that AGENTS.md's stack
section names, alongside the tests. A failure is a gap like any other: describe
it as expected versus actual and fix it at the root. Where the stack section
records none for the language, there is nothing to run.

Once those pass, on Build and run it and Build with care, load
`references/trim.md` and run its single pass. It takes out what this change
added that the behaviour does not need, and it only removes or folds, so the
person tries the piece as it will be saved. Give its one line at hand-over, or
nothing when it found nothing.

Stop. Give the exact action, the expected result, any known limitation, and
whether the evidence behind it is automated, manual, source-backed, or
operational. The user confirms the behaviour wherever human judgement is
required; for a piece with no face (a scheduled job, an email), trigger it
against a made-up case and show what it produced. Describe any gap as
expected versus actual, and fix it at the root.

## 7. Run required review

Before deciding which review applies, load `references/reach-check.md`. Check
what else the finished change reaches and which existing tests cover it, then
run those tests first. Use what the change actually reaches when applying the
review triggers below. On Build with care, compare the reached paths and crossed
boundaries with the sensitive-area map in the masterplan. A match starts the
review and says exactly: "This change reaches <area>, so a review is running."
Check a boundary with sentrux or dependency-cruiser where either is already
present, and by reading the changed imports where neither is present.
Update that map in the same save as any code move that changes it. Keep the full
project check for the pull-request gate.

Compare the finished structure with the baseline from step 4, using the same
engine. Say one line only when it got worse: "This change added a loop between
<part> and <part>." On Build with care, use "This change crossed the boundary
around <area>." Never show a score. When nothing worsened, say nothing. If it
did, the person can ask to fix it before the save or leave it; record the choice
on the piece and carry on.

Review triggers come from the build path, the change's consequence
classification, or the masterplan's sensitive areas. When
any of those apply, run second-opinion using the best independent method
recorded in the capability profile before offering to save; this fires off
what the change actually touched, so it never depends on anyone remembering.

Where the trigger names who must review, that person is the review. Running
second-opinion instead is a different thing, worth doing and worth saying is not
the named one. Evidence the change works is also not a review: a green check
proves the behaviour, and the review exists for what the check cannot see.

## 8. Save

Before saving on any route, apply the piece's `## Masterplan change` and update
the trued-against mark as
the `setup-ai-build-kit` skill's `references/masterplan-changes.md` describes.
The record changes in step 9 are part of this save, not a later /sync task.

Checkpoint route: update the records, commit, and state the saved checkpoint.
There is no pull request to wait on, and the person confirmed the behaviour in
step 6, so close the issue and take `building` off it in the same step.

Pull-request route: update the records, commit, push, open a pull request
titled after the piece with a plain-language summary, and run the project
checks. The project's first upload waits for the yes in step 1. Where the
piece is an issue, write `Closes #<number>` in the pull request body, so
merging it closes the piece rather than leaving somebody to remember. When the
pull request opens, move the piece from `building` to `to check` in the same
step, `gh issue edit <number> --add-label "to check" --remove-label building`,
since it now waits for the person to try it or merge it. Never present it as ready until the check is green; if it goes red,
say so plainly, pull the failing output yourself, fix through the normal
steps, and push again.

Once the check is green the piece is ready for review, and the run stops
there. Do not merge the pull request, and do not delete the branch. A person
decides whether to merge, always. Report the piece as ready for review, not as
done, and leave the merge to them.

Flagged route: where the person carried on and the acceptance is recorded,
this is the pull-request route and nothing below applies. Otherwise do the
pull-request route for everything up to the condition, then:

- record the exact condition that must be met, and say that /ship prepares a
  handover for the area on request;
- move the piece from `building` to `parked` in one step, with the condition
  written on it, `gh issue edit <number> --add-label parked --remove-label building`;
- name what other work may still continue;
- state plainly that the flagged capability is not ready or live, with no
  softer wording that could be read otherwise.

A piece that ends here, with all five done, is safely prepared and correctly
parked. Report it as a completed pass, and leave it alone until the
condition is met or the person carries on after the notice and the acceptance
is recorded.

## 9. Sync the records

Normal completion updates: the piece, a changelog line, the masterplan through
the piece's recorded change, and AGENTS.md only when a durable operating
convention changed. Where the piece added, removed, or changed something outside
the tool that it reaches, update the masterplan's connections picture too, and
say in one line what the tool now reaches, so the person can say whether it
should. A correctly completed build does not need /sync afterward.

Once a person merges the pull request it closes the issue, so there is no
status to set by hand. After that merge, take `to check` off the closed issue,
since a closed issue is done and carries no state, and refresh
the printout with `sh .agents/tools/plan-refresh.sh` so the person's list matches
what just happened.

When the report names a next piece, refresh the printout first if this pass has
not, and name only a piece under its `To build` group marked `(ready)`. Where
there is none, say nothing is ready to build now and name no piece. Never work
the next piece out from the issue list by hand.

Write the changelog line from the piece's own `So that` and `Done when`, in
plain language, dated. Not from its title, and not from the pull request. A
changelog assembled out of titles reads like a list of tasks, and this record
exists so somebody who has not read the code understands what happened to their
project six months later.

## Excuses that don't hold

- Urgency does not remove the need for evidence.
- Small does not permit hidden scope.
- Visual work does not need a fake automated test to look rigorous.
- Private exploration does not need pull-request ceremony it doesn't need.
- Shared or risky work does not get downgraded because setup is inconvenient.
- A review finding does not authorise unrelated cleanup.
- The trim does not authorise a restructure. It removes and folds, and reports
  the rest.

## Done when

One of two outcomes, both complete passes:

- Complete: the agreed behaviour has credible evidence, with any available
  machine check run and green, the user-facing result is confirmed where needed,
  required review is satisfied, the records match reality, and the selected save
  route is complete.
- Safely parked: the piece stopped at its recorded condition, moved from
  `building` to `parked`, with the caution recorded on it, work that can go on
  identified, and no claim that the flagged capability is ready or live.
