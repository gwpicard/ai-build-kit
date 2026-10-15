---
name: build-piece
description: Build one ready piece to a confirmed, saved change, from the safe start to the updated records. Used by implement for every piece, a repair included, and by the builder agent. Refuses to start on top of uncommitted work. One piece per pass, always.
user-invocable: false
---

# Build a piece

One piece per pass, always, directed by someone who judges it by behaviour.

## 1. Safe start

Read the piece in full, its `Under the hood` notes, the build-path section, and
anything in the masterplan or AGENTS.md's stack section it points to. Check git
status: uncommitted work stops the build, and /what-now owns that
conversation. Bring `main` up to date and start from it on every
save route including the checkpoint route. Where `main` cannot be reached,
start from the local copy and say so in one line.

Choose the save route before changing anything:

1. **Checkpoint route.** Private or disposable exploration, with no shared or
   live reliance and no change to data, access, integrations, money,
   autonomy, or operations.
2. **Pull-request route.** Shared or live use, a behavioural change, data or
   permissions, an outside service, an operational change, or whatever the
   build path requires.
3. **Flagged route.** The work touches a named sensitive area whose caution
   is neither done nor accepted. Before building inside the area, give the
   risk notice once, in full, as the `fit-check` skill describes. If the
   person carries on after it, run the `records` skill's
   `scripts/piece-labels.sh` with `start`, write and read back `Accepted:` with
   their words and date, then build and save by pull request in that reply,
   with no further question. A lock that
   only waits for this caution opens with the acceptance unless they ask to keep
   it. If they do not carry on, build only up to the recorded condition. In an
   unattended run never write an acceptance: stop at the condition, which is a
   successful outcome (step 8).

The pull-request and flagged routes work on a short-lived branch from the
up-to-date `main`. Where GitHub cannot be reached, build and save on the
branch, and note the missing pull request in one plain line on the piece. A
step a service could not do is a note, never a warning or a risk.

The first push waits for the person's yes, as the `merge` skill's
`references/first-upload.md` says.

Elsewhere, run `scripts/piece-labels.sh start <number>` before changing
anything. The `records` skill owns this script. It swaps `ready` for `building`
and assigns the piece.

## 2. Agree the visible result

Say back what the person will be able to do or see, what is outside it, and
how it will be checked. Ask for a yes only when something is still ambiguous.

## 3. Choose evidence

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

For a change inside a mapped sensitive area, `quality.py tests` runs the
strength check after the tests pass. A repair runs it on the regression test.

## 4. Write the tests

For a repair, load the `repair` skill's `references/fixing.md` and follow
"Building a repair" from here.

Before coding, follow `quality-checks/references/tests-prove-change.md`: new
tests fail on the old behaviour, and refactor tests pass before the change.
Never write a meaningless test. For a visual change, describe the current
screen first.

## 5. Build one vertical slice

Build only the agreed behaviour, end to end, in the smallest reasonable change,
with focused checks as you go. Prefer managed services and the project's
conventions, and avoid speculative abstraction. Groundwork is allowed only as
its own vertical slice, or an
expand-then-contract sequence that keeps the checks green throughout, ordered
ahead as its own piece. Stop and say so if the change grows past what was
agreed.

After the build, run `quality.py tests --base <start commit> --piece <number>`
once and act on its exit code.
Put each strength miss in the review packet. If the strength check could not
run, say so plainly. Strength misses are reported, never a fail.

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

Work the build uncovers becomes a new piece, filed by the `records` skill's
`references/pieces.md` with its subjects from the `triage` skill, and
one line such as "Found while building the invoice list." When the person asks
for more mid-build, ask once: this piece, or a new one? On "this piece", add it
to `## Done when`, read it back, and build it. Never fold a request in without
that answer.

A test that passes only on a retry is unreliable evidence: repair or replace it
before saving.

## 6. Hand over the behaviour

Run the tests, and the type check and linter AGENTS.md's stack section names.
Fix any failure at the root. Then, on Build and run it and Build with care, run
the trim in the `quality-checks` skill's `references/trim.md` and give its
one line.

Give the exact action to try, the expected result, any known limitation, and
the kind of evidence behind it. Give one address: stop any preview this
session started, use the project's recorded preview address, and where
something else holds it, say what. Never act in a browser tab the person is
using; use your own. Stop the previews you started once they have tried it.

The person confirms behaviour wherever judgement is needed. A piece with no
face, such as a scheduled job, is triggered against a made-up case and its
output shown. Describe a gap as expected versus actual, and fix it at the root.

## 7. Run required review

Run the reach check, with the tests it names, as the `quality-checks` skill's
`references/reach-check.md` says. Run the boundary check and the loops read as
its "During a build" section says. On Build with care, run
`check-sensitive-areas.sh --change <base>` and say one line for each area it
names. Exit 1 means an area is still open and the project check will hold the
pull request.

When the build path, the subjects, or a sensitive area call for review, run
the `second-opinion` skill by the best independent method in the capability
profile before saving. Where the trigger names a person, that person is the
review; a second-opinion run or a green check is not.

## 8. Save

Before saving, apply the piece's `## Masterplan change` and move the
trued-against mark as the `records` skill's
`references/masterplan-changes.md` says. Where its `scripts/trued-mark.sh`
exits other than 0, leave the mark, say in one line that /maintain checks the
whole masterplan against the code, and carry on.

Checkpoint route: update the records, commit, and state the checkpoint.

Pull-request route: update the records, commit, push, open a pull request
titled after the piece with a plain summary and `Closes #<number>`, and run the
project checks. Put each unsettled finding worth stopping for under `Worth
stopping for` in the pull request body as an unticked `- [ ]` box. Keep settled
findings and tick their boxes. Never present it as
ready until the check is green. If it goes red, say so, read the failure
yourself, fix it, and push again. Never merge in this skill, and never on a red
check: the merge is the caller's next step, by the `merge` skill.

If GitHub did not start the check, the merge waits. Say in one plain line that
GitHub did not run the check, and that the person can turn it back on or merge
the pull request themselves on GitHub.

Flagged route without an acceptance: take the pull-request route up to the
condition, then record the exact condition and that /maintain prepares a
handover on request, label the piece `blocked`, name the work that can
continue, and say plainly the flagged capability is not ready or live. That is
a completed pass.

## 9. Update the records

Update the records as the `records` skill's "After a build" says.

Keep these limits in view: see `references/build-limits.md`.
