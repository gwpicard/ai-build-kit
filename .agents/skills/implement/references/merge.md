# Merge

A finished piece reaches `main` through its pull request, and on a live
project that merge is the deploy. The first upload waits for the person's yes
before any push, and the merge waits for a yes that names it.

In Codex, a push, fetch or remote check that fails with `unable to get password
from user` gets the installed `setup-ai-build-kit` skill's
`templates/foundation/codex-github-check.py`, run with python3 and `--message`.
Give its sentence and stop, without signing in again or retrying.

## The first upload

Founding told the person nothing would be uploaded, so the first push of the
project's code waits for their yes. Where `origin` is the kit's own
repository, `gwpicard/ai-build-kit`, push nothing: say the project still
points at the kit's repository, and ask for their own.

Run `python3` with this skill's `scripts/first-upload.py` from the project
root. Its `state` line and exit code give the answer:

- Exit 2: the repository has no branch. Nothing is online yet, and this push
  is the first upload.
- Exit 0 with a remote branch sharing history with local `main` (after `git
  fetch origin`, `git merge-base` finds a shared commit): the code is already
  online. Push without asking. The question is asked once per project.
- Branches, but none sharing history with `main`: push nothing. Name
  `owner/name`, say it holds something else, and ask what to do.
- State `no-main`, exit 9: an earlier first upload pushed a branch but did not
  create `main`. Ask for a yes to create it, then run the script with
  `--approved`. It creates `main` and pushes nothing.
- Any other exit: the listing could not be read (no `origin`, GitHub
  unreachable, or not signed in). Keep the work local with a one-line note.
  Never treat it as an empty repository.

Before asking, run the installed `setup-ai-build-kit` skill's
`scripts/workflow-upload-check.py` with python3, adding `--codex` in Codex.
Exit 1 gives the exact line to say: the person runs `gh auth refresh -h
github.com -s workflow` in their own terminal, which opens the browser once.
Save locally and leave the upload waiting for that step. Where a push is
refused for the `workflow` permission, run the helper with `--refused`, give
its line, and keep the work local. Never refresh the login for them or retry
in a Codex session holding the old login. Their yes still stands when they
return.

Build and check the piece first; only the push waits. In the reply that
reports the piece, ask for a yes that names the upload: the repository as
`owner/name` and whether it is public or private, from the script's
`repository` and `visibility` lines, or `unknown` where it says so. Close to:
"This is the first time your project's code goes online. It goes to
owner/name, which is private. Shall I upload it?"

On a yes, run the script with `--approved` from the piece's branch. It pushes
the branch, creates `main` on GitHub at the commit the branch was cut from,
and makes it the default branch. Run the push as a command of its own, with
nothing chained to it: the project's settings refuse a chained command that
names `main`. Where a command is refused that way, run its parts one at a
time; the yes still stands. Open the pull request, and say in one clause that
GitHub now starts from their project's main copy. On a no, keep the piece on
its branch on this computer with a one-line note; the next push asks again.
In an unattended run never upload: keep the work local and note it on the
piece.

## Merging a finished piece

Merge only on a yes that names it. The steps named here are SKILL.md's.

First, say what the person can try and where: the preview address, on a recipe
whose preview section gives one, or how to try it on this computer. Where step
6 left their own check outstanding, ask for the merge only after they say it
behaves.

**A sensitive area first, on any project.** Where the piece touches a named
sensitive area, ask for the merge only when its caution is done or accepted on
the record. A piece stopped at its condition is never offered for a merge.

**Before asking, on a live project.** Where "How it stays running" records a
live address, the merge puts this change live. Check these first, read-only:

- On Build and run it and Build with care, run the `setup-hosting` skill's
  `references/evidence-run.md`, scoped to this piece.
- Where the piece touches a named area whose caution is done or accepted, run
  that area's readiness as the `setup-hosting` skill's "Build with care" says,
  without repeating a notice. A gap is a warning: say it once, record it in
  CHANGELOG.md in this pull request, and carry on.
- Where the change adds a database migration, check whether the live database
  has it. On a recipe, run the recipe's `live-check.sh --only migration`,
  passing the password by its location as the `setup-hosting` skill's "A
  secret a check needs" says. Off a recipe, ask the person. Exit 1, or exit 2
  (could not read, say why in one line), means not applied. Then say: "This
  change adds to the database, so /setup-hosting applies that first, from this
  pull request. Migrations only add, so the version live now keeps working."
  Ask for the merge only once /setup-hosting reports it applied.
- Where the recipe's Going live section runs a check on this computer before
  the merge, such as the container check, run it now. The exit code decides.
  Exit 1 holds the merge like a red check: say what failed and return to step
  5. Exit 2 means it could not run here: a warning, said once and recorded in
  CHANGELOG.md in this pull request, and the merge is not held for it. Where
  the changelog already holds it, one line pointing to it is the whole
  answer, in this reply and any later one.
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
never rebase. Settle the conflict as the `what-now` skill's "Merge or rebase
conflict" says, run the project check again, and ask once it is green. Where it
answers `UNKNOWN`, read it again after a short wait.

**Asking.** Name the pull request in one plain line that says what it changes,
then ask for a yes that names the merge: "Say yes to merge it, which puts it
live." Say the second half only where the merge deploys: on a recipe, or where
the masterplan records that the host builds every change to `main`. Merge only
when the reply plainly covers that merge. Where their own words already named
it, as in "merge it", that is the yes: do not ask again. A yes to building,
saving, uploading, going live or a hosting step, or to any question asked
before the merge was named, does not cover it. A no leaves the pull request
open and the live tool as it was.

Where several pieces wait, name each pull request on its own line. A yes
covers only those it names, or all where it plainly says so, as in "merge
both". Where merging one of them leaves another `CONFLICTING`, the same yes
covers bringing `main` into it, as above: settle it, run the check, and merge
it once green, saying so. Do not ask again.

**Merging.** Make an approved merge on the pull request itself, always with
`gh pr merge --merge`, never `--squash` or `--rebase`, so the masterplan's mark
stays on `main`. Never merge on this computer and push `main`. Where GitHub
cannot be reached, the merge waits, and the person can merge it on GitHub.

In Claude Code, run `python3` with the `maintain` skill's
`scripts/settings-rules.py` with `--merge-box` first. Exit 0 means a confirmation box
will ask them to allow the merge: say so in one line. Any other exit means no
box: say the merge runs on their yes in this chat, and that /maintain can add
the question. Under another coding agent, say nothing about a box.

In an unattended run, report the piece as ready for review and leave the merge
to a person.

After the merge, whoever made it, run this skill's `scripts/piece-labels.sh`
with `merged` and the piece's number, then refresh the printout.

**After the merge, held after a rollback.** Say: "This is merged. The live
copy stays on the earlier version until /setup-hosting puts this change live."
Suggest no redeploy.

**After the merge, live on a recipe.** Once the host has had time to build,
read the live copy with the recipe's `live-check.sh --only commit` and
`--address` set to the recorded live address. Where the recipe reads health
from a paste, ask for the live address's health answer and pass it with
`--pasted-health`. Exit 0: "The live copy now runs this change." Otherwise read
the host's list of deployments where the recipe names a command, or ask for it.
A build still running: say so, wait, and read again; never suggest a second
deploy. Only where the build failed or is missing, say "The live copy did not
update," and point at /setup-hosting to compare the live copy with `main`. Off
a recipe, say the change reaches the live copy the way the project's hosting
works, and claim no more than you saw.

Change nothing live after the merge: no deploy, no rollback, no second push to
`main`. Asked to put the change out again, read the health line again and say
what it shows; a further deploy belongs to /setup-hosting. Asked whether they
can go back, say what the recipe's rollback section offers, that a rollback
has not been tried, and run none here. A live break after this merge goes to
the `setup-hosting` skill's "Rolling back", which asks its own yes.
