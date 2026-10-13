# Merge

A finished piece reaches `main` through its pull request, and on a live
project that merge is the deploy. This file holds the first upload, which
waits for the person's yes before any push, and the merge, which waits for a
yes that names it.

## The first upload

Founding told the person nothing would be uploaded, so
the first push of the project's code waits for their yes. Before any push,
check where `origin` points. Where it is the kit's own repository,
`gwpicard/ai-build-kit`, push nothing: say plainly that the project still
points at the kit's repository, and ask for their own. Never push a project
there.

Then run `python3` with this skill's `scripts/first-upload.py` from the
project root. It runs `git ls-remote --exit-code --heads origin` and reads the
exit code as below; its `state` line and its own exit code give the answer.
In Codex, a push, fetch or remote check that reports `unable to get password
from user` gets the installed `setup-ai-build-kit` skill's
`templates/foundation/codex-github-check.py`, run with python3 and `--message`.
Give that restart sentence and stop work in this session, without signing in
again or retrying the command. It names the launcher by its absolute path.
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

The script names the repository from `origin`, never from the GitHub tool's
own default. It says `unknown` when the tool is signed out or cannot write
there, so nothing goes up that could leave a branch online with no `main`.
State `no-main`, exit 9, means an earlier first upload pushed the branch but
did not create `main`. Ask for a yes to create it, then run the script with
`--approved`. It creates `main` and pushes nothing.

Before asking for the first-upload yes, run the installed
`setup-ai-build-kit` skill's `scripts/workflow-upload-check.py` with python3.
In Codex, add `--codex`. Exit 1 gives the exact line to say: run
`gh auth refresh -h github.com -s workflow` in the person's own terminal,
which opens the browser once. In Codex it also names the absolute launcher
command to use after quitting, because this session keeps the login it
started with. Build and save locally first, then leave the upload waiting
for that step before asking for its yes. Exit 0 means no missing permission
was found; an SSH push or unreadable permissions remain unknown, and the
upload question carries on.

Where a push is refused because adding or changing a workflow needs the
`workflow` permission, run the same helper with `--refused` (and `--codex`
in Codex), give its line, and leave the saved work local. Never ask the
person to "update the credential", never refresh the login for them, and
never retry in a Codex session holding the old login. Their upload yes
still stands when they return after fixing the permission.

Build and check the piece first. Only the push waits. In the reply that
reports the piece, ask for a yes that names the upload: the repository as
`owner/name`, and whether it is public or private, from the script's
`repository` and `visibility` lines. Where it says `unknown`, say so rather
than guess. Close to: "This is the first time your project's code goes
online. It goes to owner/name, which is private. Shall I upload it?"

On a yes, run the same script with `--approved`, from the piece's branch. It
pushes the piece's branch, then creates `main` on GitHub at the commit
the branch was cut from, `git merge-base main <piece branch>`, with
`gh api repos/<owner>/<name>/git/refs -f ref=refs/heads/main -f sha=<commit>`.
Run the push as a command of its own, with nothing chained to it. In Claude
Code, the project's settings refuse a push that names `main`, and they can read a
chained command as one, so a `main` later in the same line refuses the push.
Where a command is refused that way, run its parts one at a time. The
person's yes still stands, so do not ask for it again.
The script also makes it the default branch with
`gh repo edit --default-branch main`. Open the pull request, and tell the person in one clause that GitHub now starts
from their project's main copy. This is the one time `main` is written other
than by a merge. It holds only what the person already has, so it changes
nothing anybody relies on. On a no, keep the piece on its own branch on this
computer. That is the route the project cannot perform right now, with its
one-line note, and the next piece that pushes asks again. In an unattended
run nobody is there to say yes, so never upload on the person's behalf: keep
the work local and note it on the piece.

## Merging a finished piece

Merge only on a yes that names it. On a project that is live, the merge is a
deploy, so this step is also how the change goes live. The steps named here
are the build steps in SKILL.md.

First, say what the person can try and where: the preview address, on a recipe
whose preview section gives one, or how to try it on this computer.

Where step 6 left the person's own check outstanding, because the piece's
evidence names a guided check or a result only they can judge, ask for the
merge only after they say it behaves. Until then, the pull request stays open
and the report says it waits for them to try it.

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
  run that area's readiness as the `setup-hosting` skill's "Build with care"
  says, without repeating a notice already given. A gap there is a warning,
  as it is in /setup-hosting: say it once, record it in CHANGELOG.md with the
  date in this piece's pull request, and carry on.
- Where the change adds a database migration, check whether the live database
  already has it. On a recipe, run the recipe's `live-check.sh` with
  `--only migration`, passing the database password by its location as the
  `setup-hosting` skill's "A secret a check needs" says. Off a recipe, ask the
  person. Exit 1 means it is not applied; exit 2 means the live database
  could not be read, which counts as not applied: say why in one line. If it
  is not applied, say in one line: "This change adds to the database, so
  /setup-hosting applies that first, from this pull request. Migrations only
  add, so the version live now keeps working." Ask for the merge only once
  /setup-hosting reports it applied.
- Where the recipe's Going live section runs a check on this computer before
  the merge, such as the Health part's container check, run that script now
  from the project root, so the build that goes live has already answered
  here. The exit code decides, never a reading of the output. Exit 0 means it
  passed.
  - Exit 2 means it could not run here, for example because no container engine
    is running. Then it is a warning, as a check not done is in /setup-hosting.
    Say it once, record it in CHANGELOG.md with the date in this piece's pull
    request, and carry on. Do not hold the merge for it, and do not ask the
    person to choose to merge without it. Where the changelog already holds
    that warning, one line pointing to it is enough. In that case say only
    that line, in this reply and any later one: not what the check does, why
    it could not run, or what it would have caught.
  - Exit 1 means the check ran and failed, and that holds the merge as a red
    project check does. Say so in one line, naming what failed in plain words.
    The piece goes back to its build, from step 5, to fix the cause, and the
    merge is not asked for until the check passes.
- Where the piece carries a `Live side needs:` line, ask for the merge only
  once /setup-hosting reports each name on it present on the host. Say so in
  one line, naming what is missing.
- Where the piece's branch adds a setting to `.env.example`, the live copy
  needs it too, with or without that line, since a piece shaped before the
  line existed has none. From the project root, run `sh` with this skill's
  `scripts/env-names-added.sh` and the piece's branch. The exit code decides.
  Exit 1 prints each name the branch adds: treat each one as a name on a
  `Live side needs:` line, so the merge waits until /setup-hosting reports it
  present on the host. Exit 0 means the branch adds none. Exit 2 means it
  could not tell: say so in one line, as a warning, and carry on.
- Where "How it stays running" records that the live copy is held on an
  earlier version since a rollback, the merge alone does not put this change
  live. Say so in the line that asks for the merge, and that /setup-hosting
  then moves the live copy on to it after a yes, as its "Rolling back" says.

Until then, the pull request stays open and ready for review, and the report
says what it waits for.

**Whether it can merge.** Before asking, read whether GitHub can merge the
pull request, with `gh pr view <number> --json mergeable`. Where it answers
`CONFLICTING`, another change has landed in the same place since this piece
began. Say so in one line, and offer to bring the newest `main` into the
piece's branch: merge `main` into it on this computer and push the branch.
Never force a push and never rebase. Do it only on a yes. Settle the conflict
as the `what-now` skill's "Merge or rebase conflict" says, keeping both sides
and asking where the records do not make the outcome plain. Then run the
project check again, and ask for the merge only once it is green. Where GitHub
answers `UNKNOWN`, it is still working the answer out: read it again after a
short wait.

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

**Merging.** Make an approved merge on the pull request itself, always with
`gh pr merge --merge`, never `--squash` or `--rebase`. A merge commit keeps the
piece's commits, so the masterplan's trued-against mark still names a commit
on `main`. Never merge the branch on this computer and push `main`. Where
GitHub cannot be reached, the merge waits: say in one line that the person can
merge it on GitHub themselves. Where the session runs in Claude Code, read
first whether the project's settings show a confirmation box before the merge
runs: from the project root, run `python3` with the `maintain` skill's
`scripts/settings-rules.py` and `--merge-box`. Exit 0 means they do, so say
in one line just before it that the box will ask them to allow the merge. Any
other exit means a project founded before the kit added that question has no
box, so promise none. Say in one line that the merge runs on their yes in this
chat, and that /maintain can add the question. Under another coding agent,
say nothing about a box. Leave the branch to GitHub, which removes it once merged.

In an unattended run, report the piece as ready for review, not as done, and
leave the merge to a person.

The merge closes the issue, so there is no status to set by hand. After the
merge, whoever made it, remove the `building` label and any `ready` still on
the piece: run this skill's `scripts/piece-labels.sh` with `merged` and the
piece's number, which reads the labels back and repeats the removal until
neither is there. Then refresh the printout with
`sh .agents/tools/plan-refresh.sh` so the person's list matches what just
happened.

**After the merge, on a project held after a rollback.** Where "How it stays
running" records that the live copy is held on an earlier version since a
rollback, the merge does not go live until /setup-hosting promotes it, after
its own named yes. Say so in one line, close to: "This is merged. The live
copy stays on the earlier version until /setup-hosting puts this change
live." Do not read the health line as "did not update", and suggest no
redeploy.

**After the merge, on a project live on a recipe.** Once the host has had
time to build, read the live copy, read-only, with the recipe's `live-check.sh`,
`--only commit` and `--address` set to the live address "How it stays
running" records. Where the recipe's Going live section is read back from
a paste, ask in one sentence for the live address's health answer and pass
what they paste with `--pasted-health`. Exit 0 means it runs the merge: say
"The live copy now runs this change." Otherwise read the host's own list of
deployments where the recipe names a command for it, or ask for it to be read. Where the list shows the build still running, say so,
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
merge, that is a live break: the `setup-hosting` skill's "Rolling back" makes
the offer, and a rollback runs only on the yes it asks for.
