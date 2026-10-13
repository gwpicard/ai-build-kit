---
name: implement
description: The everyday command for building a piece that has already been shaped and marked ready. Typed alone it takes the next ready piece from the plan, or, when several are ready, shows what can be built together and what waits on what, and asks which to take. Given an issue number, or a request that matches a ready piece, it builds that one. It shows the result, merges it after the person's yes, and on a live project reads one line of health from the live copy. A request that is not yet a ready piece goes to shape first; implement builds, it does not shape. "/implement auto" builds several ready pieces in a row. A repair is built here too, once shape has reproduced it.
---

# Implement

Use the current session for related, well-bounded work while the context
remains clear. Start fresh after a long, confused, interrupted, or unrelated
session, and whenever an independent review is required. The documents are
the source of truth either way. Read masterplan.md first, build-path section
first, then the project's pieces.

This command builds; it does not shape. It takes a piece that `/shape` has
already shaped and marked ready, and carries it to a confirmed, saved change.
On the pull-request route it then asks the person whether to merge, and merges
only on a yes that names the merge. On a live project that merge is a deploy,
so this is also how a change goes live. `references/merge.md` holds the rules,
and the checks that come before the merge on a live project.
Shaping, sizing, and settling a question all happen in `/shape`, so this command
never has to guess what a piece means. A request that is not yet a ready piece
belongs to `/shape` first.

`sh .agents/tools/plan-refresh.sh` prints the open issues into `plan.local.md`.
Refresh first, then read that, and never sort the pieces by hand in its place.
The `setup-ai-build-kit` skill's `references/pieces.md` describes how the
pieces are kept, and what to run in a project that has no copy of the helper.

Before taking a piece, read whether a kit update is still unfinished. From
the project root, run `python3` with the `maintain` skill's
`scripts/upgrade-check.py`, and keep only its exit code. It reads and changes
nothing. Where it exits 1, say one line: "The kit update is not finished.
/maintain finishes it." Then carry on. The build does not wait for it. Any
other exit says nothing.

When GitHub cannot be reached, say so, say when the printout was last written,
and work from it. The piece already in hand carries on. Anything that would
change what is on the plan waits, because an issue that cannot be updated is
not a record of anything.

In Codex, when a Git push, fetch or remote check fails with
`unable to get password from user`, run the installed `setup-ai-build-kit`
skill's `templates/foundation/codex-github-check.py` with python3 and `--message`.
Give its sentence with the absolute launcher path and stop this session's work.
Do not sign in again or retry the failed command in this session.

## Typed alone

A ready repair comes first: a piece under the printout's `Broken` group marked
`(ready)`, which the printout gives only to a repair nobody is building and
nothing open holds up.
Something that used to work and no longer does outranks anything new, and it
is built with the repair rules, as step 4 below says. Otherwise, where only one
ready piece is free to start, take it: the one nothing open is holding up and
whose class the current build path allows. Where more than one is, show them
as "Taking on several pieces" below says, and let the person choose. In an
unattended run nobody is there to choose, so take the lowest-numbered one.
A ready piece is one `/shape` has finished
shaping: it carries the `ready` label, has a `## Done when` line, and waits on no
open question. The issue list says which are held up, so this needs no digging.

A piece with open parts is a container, not a slice to build directly. Skip it
and take one of its parts, the same way you would take any other ready piece; the
parent closes on its own when its parts all close. The issue list carries the
sub-issue count, so a parent is known without digging, the way a blocker is.

Before building an eligible piece, confirm it's genuinely
unblocked, confirm the current build path allows it, and identify its
evidence and save route from the piece and the build path. Read the piece's
subject labels rather than reclassifying it; the classification was settled in
`/shape`, and the build reads it rather than re-deriving it.

A piece labelled `blocked` needs attention before it counts as buildable again:
one safely prepared and stopped at a recorded condition stays skipped until that
condition is met, or until the person carries on after the risk notice and the
acceptance is recorded; one parked
after repeated failure (references/running-longer.md) needs routing back to
`/shape` first, for another look.

## Taking on several pieces

Somebody taking on several pieces at once needs to see the whole set before
choosing. So when no ready repair is waiting, and the printout holds more than
one piece under `To build` marked `(ready)` that the current build path
allows, show what can be built together and what waits on what, and ask which
to take. The same holds when the person asks for the whole list in plain
words, such as "what can I build in parallel?", and wants no build: show it
and stop there.

A ready repair comes before the list, in both cases. Where one is waiting,
name it first, as "Typed alone" says, since something that used to work
outranks anything new. Typed alone, build it. Asked for the list alone, name
the repair above the two groups and still build nothing.

`/what-now` names one next step and at most three things, because somebody lost
cannot use more. That cap stays. The whole list lives here, at the moment of
building, and never goes back into `/what-now`.

The printout is the only source. Where the project has no copy of the helper,
the `setup-ai-build-kit` skill's `references/pieces.md` says what to run
instead. If GitHub cannot be reached, show the printout as it stands and say
when it was written, because an old list a person can see beats no list at
all.

The printout has already done the sorting. A piece under `Blocked` names the
piece holding it up, and a piece with an open blocker is never under
`To build`, so a ready piece cannot be waiting on another ready piece. Never
work that out again from the issues. Read the masterplan's build-path section
too: a piece the path will not allow is not ready work however the label reads.

Two groups, in this order.

**Build these together now.** Every ready piece. They have no dependency between
them, which is what makes them safe to take on at once. Say the count first, in
one line, then the pieces.

**These wait their turn.** The blocked pieces, one line each, saying which piece
releases it: "deposits cannot start until card payments is built". Where a chain
runs deeper than one, put the piece that unlocks the most first and let the
rest follow it.

Piece names, never issue numbers. The person cannot follow a number, and the
printout carries the name of the blocking piece already.

A piece waiting on a question rather than on another piece is not ready and
not blocked by work. Say which of the three questions it needs and leave it out
of both groups. A piece with a `Waiting on you` step is named as the person's own
to do, and you never ask for a key, a password, or a token in a message.

A piece under `To build` carrying no marker at all has been sized but never
marked ready. Name it with those, and say `/shape` is what marks it ready. This
is the one case where a piece looks buildable in the printout and is not, and it
matters most when that piece is the one holding another up.

Where nothing is blocked, say nothing about it rather than printing an empty
group. Where the ready group is long, say once how many pieces a sitting can
realistically hold, since taking on eight at once is the mess this list exists
to prevent. Do not rank the pieces and do not choose for the person.

Showing the list builds nothing. Wait for the person to name what to take, then
build those pieces one at a time, each as "Building the piece" says.

## A piece already built

A piece whose pull request is open with a green check waits only for its
merge. When the person types this command alone, or asks to put such work
live, follow `references/merge.md` for each such pull request. "Put it live"
names no merge, so ask.

## When a piece waits on the person

A piece carrying a `## Waiting on you` section cannot be built until that step is
done. Do not attempt it, and do not pass it over in silence. Say what the step
is, in the words the piece uses, and that building carries on once it is done.

In an unattended run, name the step, leave the piece where it is, and take the
next ready piece, so the run keeps working and the step is waiting when the
person comes back.

Where the step turns out to be something you can do yourself, do it and carry on
rather than asking. A piece should never hold work up for something the agent
could have gone and done.

## When the next piece is not ready

A piece that still carries `needs-clarification`, `needs-prototype`, or
`needs-research` has a question to settle before its code is written. An issue
with no `## Done when` was typed by hand and never sized. Neither is ready, and
building either one only guesses the answer.

This command does not settle the question. Settling it is planning, and planning
is what `/shape` is for. Say in one sentence what the piece is waiting on, and
point the person at `/shape` to shape it. Then take the next ready piece instead,
so a session that asked to build still builds something. Where nothing else is
ready, say so plainly rather than shaping the waiting piece here.

## Given a specific piece or a request

Typed alone, take the next ready piece as above.

Given an issue number, build that piece if it is ready, and send it to `/shape`
if it is not, saying in one line why it is not ready.

Given a report that the live tool broke, wherever it was typed, follow the
`setup-hosting` skill's "Rolling back" first, so the earlier version can come
back before anything is built.

Given a request in plain words, check whether it already matches a ready piece.
Where it does, build that piece. Where it does not, this is new or unshaped
work: point the person at `/shape`, which shapes a request into a piece. This
command never shapes a typed request itself, and it never builds past an open
question.

## When the pieces contradict each other

The blocked-by link is the truth and the `blocked` label is only a hint, so read
the link. A piece whose blockers have all closed is buildable even with the
label still on it. Say the label looks stale, and leave taking it off to `/maintain`.

When nothing is ready, because everything open is held up, still waiting on a
question, or two pieces hold each other up, say so plainly and name what is
waiting on what. Standing there with nothing to say is the one unhelpful answer.
Two pieces blocking each other is a planning mistake rather than a state to wait
out, so offer to break it in `/shape`.

A piece assigned to somebody else is theirs. Skip it and say who has it. Where
that person is no longer around, offer to take it over and let the person
decide, because reassigning somebody's work is their call.

Two people building the same piece is what claiming a piece exists to prevent,
so say it the moment you see it rather than at the end.

## Building the piece

You build one piece, directed by someone who will judge it by behaviour. One
piece per pass, always. Follow the order.

### 1. Safe start

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
   of a build's two successful outcomes; see step 8.

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

**The first upload.** The project's first push waits for the person's yes.
Before any push, follow "The first upload" in `references/merge.md`.

Replace the piece's `ready` label with `building`, and assign it to whoever is
building it, before changing anything: run this skill's
`scripts/piece-labels.sh` with `start` and the piece's number. That is what
stops two people starting the same piece, and it costs one call. A piece never carries both labels.

### 2. Agree the visible result

Say back what the user will be able to do or see when this piece is done,
what's outside it, and how it will be checked. Get an explicit yes only when
something is still ambiguous; an already-approved, precisely written plan
piece does not need the ceremony repeated.

### 3. Choose evidence

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
run the source check in the `shape` skill's `references/research.md` first.

On Build with care, where a runner exists for the project's language, offer
the optional check in `references/test-strength.md`: break only the changed
code on purpose to see whether its tests notice. Run it after the ordinary
tests pass, if the person wants it. Use that reference's one-line report and
sort the misses on the piece. This offer adds no gate to saving the work.

### 4. Establish the baseline

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

Note the commit the piece starts from. The trim and the structure comparison
read the project as it was there, again from Git history, so nothing is saved.

### 5. Build one vertical slice

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
subject the piece carries, load and follow `references/screen-rules.md`. A screen file is one
that renders a page, view, component, template, style, or native interface.
Apply it before the screen's guided manual check, so the person judges the first
result rather than describing a redo. When this build is a repair, use the
same boundary: a fault on a screen gets the rules and any other fault does not.

When filing a new piece for work this build uncovers, follow the rule for work
found during a build in the `setup-ai-build-kit` skill's `references/pieces.md`.
Put the originating title on the new piece's surface and name the new piece
on the originating record. Say one line such as "Found while building the
invoice list." Keep the current build within its agreed scope.

When the person asks for more during the build, ask one question before
building it: add it to this piece, or make it a new piece. On "this piece",
write it into the piece's `## Done when`, read the new lines back, and build
them, so the piece says what it holds. On "a new piece", file it by the same
rule and keep this build to its scope. Never fold a request into the build
without that answer.

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

### 6. Hand over the behaviour

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
operational.

Give one address to try it on. Before starting a preview, stop any preview this
session started earlier, and use the project's recorded preview address. Where
something else already holds that address, say what holds it, and do not start
a second preview on another address. Never click, type or reload in a browser
tab the person is using. Check the page in a tab of your own. Once the person
has tried the piece, or the pass ends, stop the previews you started and say so
in one line.

The user confirms the behaviour wherever human judgement is
required; for a piece with no face (a scheduled job, an email), trigger it
against a made-up case and show what it produced. Describe any gap as
expected versus actual, and fix it at the root.

### 7. Run required review

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

Compare the structure with the piece's starting commit: run `python3` with
this skill's `scripts/quality.py`, passing `loops --base <that commit>`. Exit 0 means
nothing got worse: say nothing. Exit 1 prints each new loop; say one line:
"This change added a loop between <part> and <part>." When the boundary check
above found a crossing, say "This change crossed the boundary around <area>."
Exit 2 means the comparison could not run; note it in the internal evidence
and carry on. Never show a score. The person can ask to fix either before the
save or leave it; record the choice on the piece and carry on.

Review triggers come from the build path, the change's consequence
classification, or the masterplan's sensitive areas. When
any of those apply, run second-opinion using the best independent method
recorded in the capability profile before offering to save; this fires off
what the change actually touched, so it never depends on anyone remembering.

Where the trigger names who must review, that person is the review. Running
second-opinion instead is a different thing, worth doing and worth saying is not
the named one. Evidence the change works is also not a review: a green check
proves the behaviour, and the review exists for what the check cannot see.

### 8. Save

Before saving on any route, apply the piece's `## Masterplan change` and update
the trued-against mark as
the `setup-ai-build-kit` skill's `references/masterplan-changes.md` describes.
The record changes in step 9 are part of this save, not a later /maintain task.
Read the mark with the `setup-ai-build-kit` skill's `scripts/trued-mark.sh`;
where it exits other than 0, leave the mark as it is, say in one line that
/maintain checks the whole masterplan against the code, and carry on.

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

**A check GitHub did not start.** GitHub can refuse to start the check at
all, for example when the account's billing or spending limit stops it, or
Actions is switched off. The check then ran no step, so it is not red. Read
the reason from the run's own message with `gh run view`, and run the project
check on this computer instead, as AGENTS.md's stack section names it.

- On Explore privately the remote check is optional, so the local result
  decides. Say once, in one line, that GitHub did not start the check and why.
  Record it in CHANGELOG.md with the date in this piece's pull request, and
  carry on to step 10. Where the changelog already holds that line, one line
  pointing to it is enough.
- On Build and run it and Build with care the remote check is required, so the
  merge waits. Say in one line what stops it and where the person fixes it,
  such as GitHub's billing page.

Never switch the check off, change its workflow, or retry it in a loop to get
past this. Switch it off only when the person asks in their own words, and
record in CHANGELOG.md that it is off and the command that turns it back on.
/maintain then names it on every visit until it is back on.

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

### 9. Update the records

Normal completion updates: the piece, a changelog line, the masterplan through
the piece's recorded change, and AGENTS.md only when a durable operating
convention changed. Where the piece added, removed, or changed something outside
the tool that it reaches, update the masterplan's connections picture too, and
say in one line what the tool now reaches, so the person can say whether it
should. A correctly completed build leaves nothing for /maintain to correct.

When the report names what can be built next, refresh the printout first if
this pass has not, and read it off that. A repair under `Broken` marked
`(ready)` comes first, since the printout marks one ready only when nobody is
on it and nothing open holds it up. Otherwise, name only a piece under
`To build` marked `(ready)`, and never the piece just built. Where neither
group holds such a piece, say that nothing is ready to build now, say what the
rest are waiting on, and name no piece as next. Never work the next piece out
from the issue list or its blocked-by links by hand: the printout already keeps
a piece with an open blocker out of `To build`, and a hand reading does not.

Write the changelog line from the piece's own `So that` and `Done when`, in
plain language, dated. Not from its title, and not from the pull request. A
changelog assembled out of titles reads like a list of tasks, and this record
exists so somebody who has not read the code understands what happened to their
project six months later.

### 10. Merge

On the pull-request route, once the check is green and the records are in the
pull request, the person decides whether to merge, always. Load
`references/merge.md` and follow it: what to try first, the checks before the
merge on a live project, asking, merging, and reading one line of health after
it. In an unattended run nobody is there to say yes, so never merge: report
the piece as ready for review, not as done.

## Typed with auto, or handed to a goal mode

Auto is not an ordinary peer to normal building; it is earned, not default.
Before enabling it, require: at least three normal pieces completed cleanly,
no unresolved review or flagged work waiting, clean Git state, evidence a machine can
check for every selected piece, no piece still waiting on a question
(`needs-clarification`, `needs-prototype`, or `needs-research`), no repair
labelled `broken`, every selected
piece self-sufficient enough to build without a person present, meaning its
`Under the hood` notes carry what the build needs, nothing needing
human judgement in the batch,
no pending build-path transition, and the user's explicit approval of the
batch. A project has earned auto mode when its records and checks have
repeatedly predicted successful ordinary builds; the presence of an agent
feature called "goal" or "auto" does not itself make the project eligible.

Once eligible, load references/running-longer.md before starting and follow
it. The shape, so the person knows what they are agreeing to: the plan is
approved once, only ready pieces a machine can prove get taken, a failing piece is
retried three times and then parked, a named sensitive area stops the run,
and it ends through the route required by the build path: normally one pull
request carrying a checklist of things to try before merging, or a confirmed
checkpoint for eligible private exploration.

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

The route was followed and the records are true. Each piece built ends in one
of two outcomes, both complete passes, or the user knows exactly where things
stopped and why:

- Complete: the agreed behaviour has credible evidence, with any available
  machine check run and green, the user-facing result is confirmed where needed,
  required review is satisfied, the records match reality, and the selected save
  route is complete. On the pull-request route, the pull request is merged on
  the person's yes, or left open and ready for review with what it waits for.
- Safely blocked: the piece stopped at its recorded condition, marked
  `blocked`, with the caution recorded on it, unblocked work
  identified, and no claim that the flagged capability is ready or live.
