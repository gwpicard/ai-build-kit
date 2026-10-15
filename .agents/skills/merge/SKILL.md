---
name: merge
description: Take a finished piece to main. The first upload waits for the person's yes, and a merge waits for a yes that names it. Used by implement, setup-hosting, maintain and founding.
user-invocable: false
---

# Merge

A finished piece reaches `main` through its pull request, and on a live
project that merge is the deploy. The first upload waits for the person's yes
before any push, and the merge waits for a yes that names it.

In Codex, a push, fetch or remote check that fails with `unable to get password
from user` gets the installed `setup-ai-build-kit` skill's
`templates/foundation/codex-github-check.py`, run with python3 and `--message`.
Give its sentence and stop, without signing in again or retrying.

The project's first push of its code follows `references/first-upload.md`.

## Merging a finished piece

Merge only on a yes that names it. The steps named here are the `build-piece`
skill's.

First, say what the person can try and where: the preview address, on a recipe
whose preview section gives one, or how to try it on this computer. Where step
6 left their own check outstanding, ask for the merge only after they say it
behaves.

**A sensitive area first, on any project.** Run
`check-sensitive-areas.sh --change <base>` and say one line for each area it
names. For an accepted area, say: "This changes <area>, which you accepted on
<date>." Use the plain date the script gives you. Exit 1 means the area is
open and the project check and merge hold.

**Before asking, on a live project.** Where "How it stays running" records a
live address, the merge puts this change live. Check these first, read-only:

- On Build and run it and Build with care, run the `evidence-run` skill,
  scoped to this piece.
- Where the piece touches a named area whose caution is done or accepted, run
  that area's readiness as the `fit-check` skill's "An area going live" says,
  without repeating a notice. A gap is a warning: say it once, record it in
  CHANGELOG.md in this pull request, and carry on.
- Where the change adds a database migration, check whether the live database
  has it. On a recipe, run the recipe's `live-check.sh --only migration`,
  passing the password by its location as the `live-copy` skill's "A
  secret a check needs" says. Off a recipe, ask the person. Exit 1, or exit 2
  (could not read, say why in one line), means not applied. Then say: "This
  change adds to the database, so /setup-hosting applies that first, from this
  pull request. Migrations only add, so the version live now keeps working."
  Ask for the merge only once /setup-hosting reports it applied.
- Where the recipe's Going live section runs a check on this computer before
  the merge, such as the container check, run it now. The exit code decides.
  Exit 1 holds the merge like a red check: say what failed and return to step
  5. Exit 2 means it could not run here: a warning, said once and recorded in
  CHANGELOG.md in this pull request. Do not hold the merge for it, and do not
  ask the person whether to merge without it. Where the changelog already
  holds it, one line pointing to it is the whole answer, in this reply and any
  later one.
- Where the piece has a `Live side needs:` line, ask for the merge only once
  /setup-hosting reports each name present on the host.
- Run `sh` with this skill's `scripts/env-names-added.sh` and the piece's
  branch. Exit 1 prints each setting the branch adds to `.env.example`; treat
  each as a `Live side needs:` name. Exit 2 is a one-line warning.
- Where the live copy is held on an earlier version since a rollback, say in
  the line that asks that the merge alone does not put this change live, and
  that /setup-hosting then moves the live copy on after a yes.

Until then, the pull request stays open and the report says what it waits for.

**Whether it can merge.** Read `gh pr view <number> --json mergeable`. Where it
answers `CONFLICTING`, say so in one line and offer, on a yes, to merge the
newest `main` into the piece's branch here and push it. Never force a push and
never rebase. Settle the conflict as "Merge or rebase conflict"
below says, run the project check again, and ask once it is green. Where it
answers `UNKNOWN`, read it again after a short wait.

**Asking.** Name the pull request in one plain line that says what it changes,
then ask for a yes that names the merge: "Say yes to merge it, which puts it
live." Say the second half only where the merge deploys: on a recipe, or where
the masterplan records that the host builds every change to `main`. Merge only
when the reply plainly covers that merge. Where their own words already named
it, as in "merge it", that is the yes: do not ask again. Something you notice
that none of the checks above holds the merge for, such as a project check
still running the setup placeholder, is said in one line and offered as a
piece; it never takes back a yes the person already gave. A yes to building,
saving, uploading, going live or a hosting step, or to any question asked
before the merge was named, does not cover it. A red, pending or missing
project check, or an unticked box under `Worth stopping for`, always holds
the merge, whatever was said. A no leaves the pull request open and the live
tool as it was.

Where several pieces wait, name each pull request on its own line. A yes
covers only those it names, or all where it plainly says so, as in "merge
both". Where merging one of them leaves another `CONFLICTING`, the same yes
covers bringing `main` into it only when the records settle the conflict
plainly. A conflict that needs a question, or touches data, a migration,
deployment settings or a named sensitive area, takes a new yes that names it.
Once `main` is in, run the check and "Before asking, on a live project" again
for that piece, and merge it once both pass, saying so.

**Merging.** Make an approved merge on the pull request itself through
`python3` with this skill's `scripts/merge.py --approved <pull request
number>`. Claude Code asks before this command runs. Exit 0 means it merged.
Exit 1 means a check, review box or sensitive area holds it. Exit 2 means a
required read or check could not run, or GitHub refused the merge. Say what
stopped it and leave the pull request open.

`--auto` is available only when `Runs on its own:` on `main` records the
person's words and date. It still holds on every red, missing or pending check,
review finding, touched sensitive area, migration, new setting, live
requirement, repair or `(try it)` line. It also requires three earlier merges
with an approved review and a branch that contains the newest `main`. The
person adds this Claude Code allow rule themselves:
`Bash(python3 *merge.py --auto *)`. If a check on `main` or the live check
fails after an automatic merge, pause with
`scripts/merge.py --pause "live check failed"` and wait for the person to turn
it on again before using `scripts/merge.py --resume`.

In an unattended run, report the piece as ready for review and leave the merge
to a person.

After the merge, whoever made it, run the `records` skill's
`scripts/piece-labels.sh` with `merged` and the piece's number, then refresh
the printout. Then follow `references/after-merge.md`.

## A check GitHub did not start

The merge waits. Say in one plain line that GitHub did not run the check, and
that the person can turn the check back on or merge the pull request themselves
on GitHub.

## Merge or rebase conflict

Say which two intentions collided. Resolve it only when the records make the
outcome plain; otherwise keep both sides and ask. A conflict touching data or
deployment is escalated, never guessed.
