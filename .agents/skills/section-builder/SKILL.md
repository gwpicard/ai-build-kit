---
name: section-builder
description: Build one piece from the plan to a confirmed, saved change. Used by implement for every piece, a repair included. Refuses to start on top of uncommitted work. One piece per pass, always.
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
   Stopping there, safely prepared and correctly recorded as blocked, is one
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

Label the piece `building` and assign it to whoever is building it before
changing anything. That is what stops two people starting the same piece, and it
costs one call.

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

A piece labelled `broken` is a repair. Load `references/repair.md` and follow
its "Building a repair" part from here: the check the piece records is the
baseline, the cause comes before any code, and its escalation holds after
three failed attempts.

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

On a live project, /setup-hosting applies a migration to the live database
before the merge, as step 10 says, so a build never applies one itself.

When the piece carries `visual`, or the change touches a screen file whatever
subject the piece carries, load and follow `screen-check`. A screen file is one
that renders a page, view, component, template, style, or native interface.
Apply it before the screen's guided manual check, so the person judges the first
result rather than describing a redo. When this build is a repair, use the
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
The record changes in step 9 are part of this save, not a later /maintain task.

Checkpoint route: update the records, commit, and state the saved checkpoint.

Pull-request route: update the records, commit, push, open a pull request
titled after the piece with a plain-language summary, and run the project
checks. The project's first upload waits for the yes in step 1. Where the
piece is an issue, write `Closes #<number>` in the pull request body, so
merging it closes the piece rather than leaving somebody to remember. Never present it as ready until the check is green; if it goes red,
say so plainly, pull the failing output yourself, fix through the normal
steps, and push again.

Once the check is green the piece is ready for review, and step 10 asks the
person whether to merge it. Never merge before that step, and never on a red
check.

Flagged route: where the person carried on and the acceptance is recorded,
this is the pull-request route and nothing below applies. Otherwise do the
pull-request route for everything up to the condition, then:

- record the exact condition that must be met, and say that /maintain
  prepares a handover for the area on request;
- label the piece `blocked`;
- name what unblocked work may still continue;
- state plainly that the flagged capability is not ready or live, with no
  softer wording that could be read otherwise.

A piece that ends here, with all five done, is safely prepared and correctly
blocked. Report it as a completed pass, and leave it alone until the
condition is met or the person carries on after the notice and the acceptance
is recorded.

## 9. Update the records

Normal completion updates: the piece, a changelog line, the masterplan through
the piece's recorded change, and AGENTS.md only when a durable operating
convention changed. Where the piece added, removed, or changed something outside
the tool that it reaches, update the masterplan's connections picture too, and
say in one line what the tool now reaches, so the person can say whether it
should. A correctly completed build leaves nothing for /maintain to correct.

When the report names a next piece, refresh the printout first if this pass has
not. A ready repair comes first: name a piece under its `Broken` group marked
`(ready)`, which the printout marks only when nobody is on it and nothing open
holds it up. Otherwise, name only a piece under its `To build` group marked
`(ready)`. Where there is neither, say nothing is ready to build now and name
no piece. Never work the next piece out from the issue list by hand.

Write the changelog line from the piece's own `So that` and `Done when`, in
plain language, dated. Not from its title, and not from the pull request. A
changelog assembled out of titles reads like a list of tasks, and this record
exists so somebody who has not read the code understands what happened to their
project six months later.

## 10. Merge

On the pull-request route, once the check is green and the records are in the
pull request, the person decides whether to merge, always. Merge only on a yes
that names it. On a project that is live, the merge is a deploy, so this step
is also how the change goes live.

First, say what the person can try and where: the preview address, on a recipe
whose preview section gives one, or how to try it on this computer.

**A sensitive area first, on any project.** Where the piece touches a named
sensitive area, the merge takes that area a step nearer live, so check it
before anything else, live or not. Ask for the merge only when the area's
caution is done or accepted on the record, as the flagged route already
requires. A piece stopped at its condition is never offered for a merge. This
comes first so that nothing is applied to the live side for a piece that may
not merge.

**Before asking, on a live project.** Read the masterplan's "How it stays
running" section. Where it records a live address, the merge puts this change
live, so check these first, read-only, and change nothing live:

- On Build and run it and Build with care, run the evidence run in the
  `setup-hosting` skill's `references/evidence-run.md`, scoped to what this
  piece changed.
- Where the piece touches a named area whose caution is done or accepted,
  run that area's operational readiness as the `setup-hosting` skill's Build
  with care step 5 says, with the request record and monitoring rules of its
  Build and run it step 3. Do not repeat a notice already given. A gap there
  is a warning, as it is in /setup-hosting: say it once, record it in
  CHANGELOG.md with the date in this piece's pull request, and carry on.
- Where the change adds a database migration, check whether the live database
  already has it, with the recipe's own dry run where it has one. Off a recipe,
  ask the person. Where the dry run needs the database password, follow the
  `setup-hosting` skill's "A secret a check needs": read where it is kept from
  the masterplan, ask once when nobody recorded it, and never say it is
  absent. Where the live database cannot be read, treat the migration as not
  applied, and say why in one line. If it is not applied, say in one line:
  "This change adds to the database, so /setup-hosting applies that first,
  from this pull request. Migrations only add, so the version live now keeps
  working." Ask for the merge only once /setup-hosting reports it applied.
- Where the recipe's going-live section runs a check on this computer before
  the merge, such as building the app the way the host will and reading its
  health, run it now, so the build that goes live has already answered here.
- Where the piece carries a `Live side needs:` line, ask for the merge only
  once /setup-hosting reports each name on it present on the host. Say so in
  one line, naming what is missing.
- Where "How it stays running" records that the live copy is held on an
  earlier version since a rollback, the merge alone does not put this change
  live. Say so in the line that asks for the merge, and that /setup-hosting
  then moves the live copy on to it after a yes, as its "Rolling back" says.

Until then, the pull request stays open and ready for review, and the report
says what it waits for.

**Asking.** Name the pull request in one plain line that says what it changes.
Then ask for a yes that names the merge, for example: "Say yes to merge it,
which puts it live." Say the second half only where the project is live and
the merge does deploy: on a recipe, or where the masterplan records that the
host builds every change to `main`. Merge only
when the person's reply plainly covers that merge. Where their own words
already named the merge, as in "merge it", that is the yes: do not ask again.
A yes to building, saving, uploading, going live or a hosting step, or to any
question asked before the merge was named, does not cover it: ask again, and merge nothing
until they answer. A no leaves the pull request open, ready for review, and the
live tool as it was.

Where more than one piece waits on its merge, name each pull request in its
own line. A yes covers only the pull requests it names, or all of them where
it plainly says so, as in "merge both".

**Merging.** Make an approved merge on the pull request itself, such as with
`gh pr merge`. Never merge the branch on this computer and push `main`. Where
GitHub cannot be reached, the merge waits: say in one line that the person can
merge it on GitHub themselves. Where the session runs in Claude Code, the
project's settings show a confirmation box before the merge runs, so say in
one line just before it that the box will ask them to allow the merge. Under
another coding agent, say nothing about a box. Leave the branch to GitHub, which removes it once merged.

In an unattended run nobody is there to say yes, so never merge. Report the
piece as ready for review, not as done, and leave the merge to a person.

The merge closes the issue, so there is no status to set by hand. After the
merge, whoever made it, remove the `building` label and refresh the printout
with `sh .agents/tools/plan-refresh.sh` so the person's list matches what just
happened.

**After the merge, on a project held after a rollback.** Where "How it stays
running" records that the live copy is held on an earlier version since a
rollback, the merge does not go live until /setup-hosting promotes it, after
its own named yes. Say so in one line, close to: "This is merged. The live
copy stays on the earlier version until /setup-hosting puts this change
live." Do not read the health line as "did not update", and suggest no
redeploy.

**After the merge, on a project live on a recipe.** Once the host has had
time to build, read one line of health from the live copy, read-only, as the
recipe's going-live check and Health section say. Where the check is the kit's
own, run it. Where a companion or the person runs it, ask in one sentence for
the live address's health answer and read what they paste. Where it reports the
merge, say: "The live copy now runs this change." Where it does not, read the
host's own list of deployments where the recipe names a command for it, or
ask for it to be read. Where the list shows the build still running, say so,
wait a short while, and read the health line again. Never suggest a second
deploy for a build in progress. Only where the build failed or is missing,
say: "The live copy did not update," with the next step, which is
/setup-hosting to compare the live copy with `main`. Off a recipe, say in one
line that the merged change reaches the live copy the way the project's hosting
works, and claim no more than you saw.

Change nothing live after the merge: no deploy, no rollback, and no second
push to `main`, since a host that builds `main` would build it again. Where
the person asks to put the change out again, read the health line again first
and say what it shows. A further deploy belongs to /setup-hosting and its
rules, never to this step. Where they ask whether they can go back to the
earlier version, say what the recipe's rollback section offers, that a
rollback has not been tried, and run none in this step. Nothing here changes
the live copy unasked. Where they report that the live tool broke after this
merge, that is a live break: the `change-triage` skill's "A live break after a
recent merge" makes the offer, and a rollback runs only on the yes it asks
for, by the `setup-hosting` skill's "Rolling back".

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
  route is complete. On the pull-request route, the pull request is merged on
  the person's yes, or left open and ready for review with what it waits for.
- Safely blocked: the piece stopped at its recorded condition, marked
  `blocked`, with the caution recorded on it, unblocked work
  identified, and no claim that the flagged capability is ready or live.
