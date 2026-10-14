---
name: implement
description: The everyday command for building a piece that has already been shaped and marked ready. Typed alone it takes the next ready piece from the plan, or, when several are ready, shows what can be built together and what waits on what, and asks which to take. Given an issue number, or a request that matches a ready piece, it builds that one. It shows the result, merges it after the person's yes, and on a live project reads one line of health from the live copy. A request that is not yet a ready piece goes to shape first; implement builds, it does not shape. "/implement auto" builds several ready pieces in a row. A repair is built here too, once shape has reproduced it.
---

# Implement

This command builds; it does not shape. It carries a ready piece to a
confirmed, saved change, and on the pull-request route merges it only on a yes
that names the merge. On a live project that merge is a deploy.
The `merge` skill holds the first upload and the merge.

Read masterplan.md first, build-path section first. Refresh the printout with
`sh .agents/tools/plan-refresh.sh` and read `plan.local.md`; never sort the
pieces by hand. The `records` skill's `references/pieces.md`
describes the pieces, their labels, and what to do when GitHub is unreachable.

Before taking a piece, run `python3` with the `maintain` skill's
`scripts/upgrade-check.py` from the project root and keep only its exit code.
Where it exits 1, say: "The kit update is not finished. /maintain finishes
it." Then carry on.

In Codex, when a Git push, fetch or remote check fails with `unable to get
password from user`, run the installed `setup-ai-build-kit` skill's
`templates/foundation/codex-github-check.py` with python3 and `--message`. Give
its sentence and stop this session's work, without signing in again or
retrying.

## Choosing the piece

Typed alone, a ready repair comes first: a piece under the printout's `Broken`
group marked `(ready)`. Otherwise, where one ready piece under `To build` is
free and the build path allows it, take it. Where several are, show the list
below and let the person choose; in an unattended run take the lowest-numbered.

A ready piece carries `ready`, has a `## Done when`, and waits on no question.
A piece with open parts is a container, not a slice to build directly: take
one of its parts.

Given an issue number, build that piece if it is ready, or send it to `/shape`
with one line on why not. Given a request in plain words, build the ready piece
it matches; otherwise point at `/shape`. Given a report that the live tool
broke, follow the `live-copy` skill's "Rolling back" first.

A piece still carrying a `needs-` label, or with no `## Done when`, is not
ready. This command does not settle the question: say what it waits on, point
at `/shape`, and take the next ready piece instead.

A piece with `## Waiting on you` is not attempted. Say the step in the piece's
words; in an unattended run leave it and take the next. Where you can do the
step yourself, do it.

A piece labelled `blocked` at a recorded condition stays skipped until the
condition is met or the person carries on after the risk notice. One parked
after repeated failure goes back to `/shape`. The blocked-by link decides, not
the label: a piece whose blockers have closed is buildable, and you say the
label looks stale. Two pieces holding each other up is a planning mistake to
break in `/shape`. A piece assigned to somebody else is theirs: skip it, say
who has it, and offer to take it over only if they are gone.

When nothing is ready, say so and name what is waiting on what.

### Taking on several pieces

Where several ready pieces are free, or the person asks what can be built in
parallel, show two groups from the printout, after any ready repair:

**Build these together now.** The count, then every ready piece. None waits on
another.

**These wait their turn.** Each blocked piece in one line naming what releases
it: "deposits cannot start until card payments is built".

Piece names, never issue numbers. Leave out pieces waiting on a question, and
name a sized piece with no marker as one `/shape` still has to mark ready.
Where the ready group is long, say how many a sitting can hold. Do not rank or
choose. Showing the list builds nothing; build the chosen pieces one at a time.

### A piece already built

A piece whose pull request is open with a green check waits only for its
merge. Typed alone, or asked to put such work live, follow
the `merge` skill for each. "Put it live" names no merge, so ask.

## Building the piece

One piece per pass, always, directed by someone who judges it by behaviour.

### 1. Safe start

Read the piece in full, its `Under the hood` notes, the build-path section, and
anything in the masterplan or AGENTS.md's stack section it points to. Check git
status: uncommitted work stops the build, and /what-now owns that
conversation. Bring `main` up to date and start from it on every save route including the checkpoint route. Where `main` cannot be reached, start from
the local copy and say so in one line.

Choose the save route before changing anything:

1. **Checkpoint route.** Private or disposable exploration, with no shared or
   live reliance and no change to data, access, integrations, money,
   autonomy, or operations.
2. **Pull-request route.** Shared or live use, a behavioural change, data or
   permissions, an outside service, an operational change, or whatever the
   build path requires.
3. **Flagged route.** The work touches a named sensitive area whose caution
   is neither done nor accepted. Before building inside the area, give the
   risk notice once, in full, as the `fit-check` skill describes. If the person carries on after it,
   write the `Accepted:` line with their words and the date, read it back,
   and build and save on the pull-request route, in the reply that answers
   them, with no further question. A lock that only waits for this caution
   opens with the acceptance unless they ask to keep it. If they do not carry
   on, build only up to the recorded condition. In an unattended run never
   write an acceptance: stop at the condition, which is a successful outcome
   (step 8).

The pull-request and flagged routes work on a short-lived branch from the
up-to-date `main`. Where GitHub cannot be reached, build and save on the
branch, and note the missing pull request in one plain line on the piece. A
step a service could not do is a note, never a warning or a risk.

The project's first push waits for the person's yes, as "The first upload" in
the `merge` skill's `references/merge.md` says.

Run the `records` skill's `scripts/piece-labels.sh` with `start` and the piece's number
before changing anything. It swaps `ready` for `building` and assigns the
piece.

### 2. Agree the visible result

Say back what the person will be able to do or see, what is outside it, and
how it will be checked. Ask for a yes only when something is still ambiguous.

### 3. Choose evidence

Pick the smallest credible evidence for every subject the piece carries. A
piece with two subjects needs what both demand, and the stricter save route.

Where a machine can check the piece, that check runs and must pass. A screen
that looks right is never a substitute for a check that was available and skipped.

- An automated behaviour test is required for rules, calculations,
  permissions, data changes, integrations, background behaviour, bugs, and any
  done line a machine can judge.
- A guided manual check is enough for copy, layout, colour, exploratory
  interaction, usability, and throwaway prototypes.
- An operational rehearsal is required for backups, restores, migrations,
  rollback, alerts, deployment, and failure recovery. Adding a field takes a
  test; changing records people already have takes a rehearsal on a copy.
- An outside fact runs the source check in the `research` skill first.

On Build with care, offer the optional check in the `quality-checks` skill's `references/test-strength.md`
once the tests pass. It adds no gate.

### 4. Establish the baseline

A piece labelled `broken` is a repair: load the `repair` skill's `references/fixing.md` and follow
"Building a repair" from here.

Otherwise show the new check fails before the behaviour exists, or establish
the passing baseline before a refactor, or describe the current screen before a
visual change. Never write a meaningless test to have one. Note the commit the
piece starts from; the trim and the structure check read from it.

### 5. Build one vertical slice

Build only the agreed behaviour, end to end, in the smallest reasonable change,
with focused checks as you go. Prefer managed services and the project's
conventions, and avoid speculative abstraction. Groundwork is allowed only as
its own vertical slice, or an expand-then-contract sequence that keeps the checks green throughout, ordered ahead as its own piece. Stop and say so if
the change grows past what was agreed.

A build that reaches an outside service follows AGENTS.md's Secrets rule. A
command that changes a live service's settings or data, other than saving code
through the save route, waits for a yes that names every setting or record it
will change, from the command's own preview where it has one, and says
whether it can be undone. Ask before, never after. In an unattended run leave
it unrun and say so on the piece. On a live project a build never applies a
migration itself; /setup-hosting does that before the merge.

When the piece carries `visual`, or the change touches a file that renders a
page, view, component, template, style or native interface, load
the `screen-check` skill before the guided check.

Work the build uncovers becomes a new piece, filed by pieces.md's rule, with
one line such as "Found while building the invoice list." When the person asks
for more mid-build, ask once: this piece, or a new one? On "this piece", add it
to `## Done when`, read it back, and build it. Never fold a request in without
that answer.

A test that passes only on a retry is unreliable evidence: repair or replace it
before saving. Keep engineering vocabulary out of what the person sees.

### 6. Hand over the behaviour

Run the tests, and the type check and linter AGENTS.md's stack section names.
Fix any failure at the root. Then, on Build and run it and Build with care, run
the trim in the `quality-checks` skill's `references/trim.md` and give its one line.

Give the exact action to try, the expected result, any known limitation, and
the kind of evidence behind it. Give one address: stop any preview this
session started, use the project's recorded preview address, and where
something else holds it, say what. Never act in a browser tab the person is
using; use your own. Stop the previews you started once they have tried it.

The person confirms behaviour wherever judgement is needed. A piece with no
face, such as a scheduled job, is triggered against a made-up case and its
output shown. Describe a gap as expected versus actual, and fix it at the root.

### 7. Run required review

Run the reach check in the `quality-checks` skill's `references/reach-check.md` and the tests it names. On
Build with care, compare what the change reaches with the sensitive-area map; a
match starts the review and you say: "This change reaches <area>, so a review
is running." Check a boundary with sentrux or dependency-cruiser where present,
or by reading the changed imports. Update the map in the same save as any code
move.

Run `python3` with the `quality-checks` skill's `scripts/quality.py`, passing
`loops --base <start commit>`. Exit 0: say nothing. Exit 1: say "This change added a loop between
<part> and <part>." A boundary crossing gets "This change crossed the boundary
around <area>." Exit 2: note it internally. Never show a score. The person may
fix it or leave it; record the choice on the piece.

When the build path, the subjects, or a sensitive area call for review, run
second-opinion by the best independent method in the capability profile before
saving. Where the trigger names a person, that person is the review; a
second-opinion run or a green check is not.

### 8. Save

Before saving, apply the piece's `## Masterplan change` and move the
trued-against mark as the `records` skill's
`references/masterplan-changes.md` says. Where its `scripts/trued-mark.sh`
exits other than 0, leave the mark, say in one line that /maintain checks the
whole masterplan against the code, and carry on.

Checkpoint route: update the records, commit, and state the checkpoint.

Pull-request route: update the records, commit, push, open a pull request
titled after the piece with a plain summary and `Closes #<number>`, and run the
project checks. List any unsettled finding worth stopping for under `Worth
stopping for` in the body, and remove it once settled. Never present it as
ready until the check is green. If it goes red, say so, read the failure
yourself, fix it, and push again. Never merge before step 10, and never on a
red check.

Where GitHub did not start the check at all, such as for billing or Actions
switched off, read the reason with `gh run view` and run the project check
here. On Explore privately the local result decides: say why in one line and
record it in CHANGELOG.md in this pull request (one line pointing to an
existing entry is enough). On the other paths the merge waits: say what stops
it and where the person fixes it. Never switch the check off, edit its
workflow, or retry it in a loop. Switch it off only when the person asks in
their own words, and record in CHANGELOG.md how to turn it back on.

Flagged route without an acceptance: take the pull-request route up to the
condition, then record the exact condition and that /maintain prepares a
handover on request, label the piece `blocked`, name the work that can
continue, and say plainly the flagged capability is not ready or live. That is
a completed pass.

### 9. Update the records

Update the piece, a dated changelog line written from its `So that` and `Done
when` in plain words, the masterplan through its recorded change, and AGENTS.md
only for a lasting convention. Where the tool now reaches something new outside
itself, update the connections picture and say what it reaches. A finished
build leaves nothing for /maintain to correct.

When naming what comes next, read it from a refreshed printout, by pieces.md's
rule, and never name the piece just built.

### 10. Merge

Once the check is green and the records are in the pull request, load
the `merge` skill and follow it. In an unattended run nobody is there to say yes, so never merge: report the piece as ready for review.

## Typed with auto, or handed to a goal mode

Auto is earned. Before it runs, require: three ordinary pieces completed
cleanly, no unsettled review finding worth stopping for, no flagged work
waiting, a clean tree, evidence a machine can check for every selected piece,
no piece waiting on a question, no repair, every piece
self-sufficient enough to build without a person present through its
`Under the hood` notes, nothing needing human judgement in the batch, no
pending build-path change, and the person's yes to the batch. Then load `references/running-longer.md` and follow it.

## Excuses that don't hold

- Urgency does not remove the need for evidence.
- Small does not permit hidden scope.
- Visual work does not need a fake automated test.
- Private exploration does not need pull-request ceremony.
- Shared or risky work is not downgraded because setup is inconvenient.
- A review finding does not authorise unrelated cleanup, and the trim does not
  authorise a restructure.

## Done when

The route was followed and the records are true. Each piece built ends in one
of two outcomes, both complete passes, or the person knows exactly where it
stopped and why:

- Complete: credible evidence, with any available machine check run and green,
  the result confirmed where needed, required review satisfied, the records
  true, and the save route complete. On the pull-request route, the pull
  request is merged on the person's yes, or left open and ready with what it
  waits for.
- Safely blocked: stopped at its recorded condition, labelled `blocked`, the
  caution recorded, unblocked work named, and no claim that the flagged
  capability is ready or live.
