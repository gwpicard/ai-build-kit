---
name: merge
description: Take a finished piece to main. The first upload and, by default, each merge wait for a yes. Used by implement, setup-hosting, maintain and founding.
user-invocable: false
---

# Merge

On a live project, merging deploys. The first upload waits for a yes, as
`references/first-upload.md` says. In Codex, if push, fetch or remote check
fails with `unable to get password from user`, run the installed
`setup-ai-build-kit` skill's `templates/foundation/codex-github-check.py`
with python3 and `--message`. Give its sentence and stop without signing in
or retrying.

Upload a later piece with `python3 scripts/upload-piece.py --title "<title>"
--body-file <file>` from the project folder. Exit 3 goes to
`references/first-upload.md`; other stops name their cause. Report that cause;
say the person declined only when they did.

## Merge a finished piece

Merge only on a yes that names it, unless automatic merge is recorded and
the script finds its conditions hold. First say what the person can try and where:
the recipe's preview address or how to try it locally. If the guided check in
`build-piece/references/build-limits.md` is outstanding, ask for merge only
after they confirm the result.

Run `check-sensitive-areas.sh --change <base>` and report each area. For an
accepted area, state its name and the plain date. Exit 1 means the area is
open and holds the merge.

On a live project, make these read-only checks before asking:

- Run `evidence-run` for the piece.
- For a changed area whose caution is done or accepted, check its readiness
  using `fit-check`'s “Rechecks and going live”. Record gaps once in the changelog;
  they are warnings.
- For a database migration, check the live database using the recipe's
  `live-check.sh --only migration`, with the password location per
  `live-copy`. Off-recipe, ask the person. Exit 1 or 2 means not applied. Say
  `/setup-hosting` applies it from this pull request, and ask to merge only
  after it reports success.
- Run any pre-merge local check named by the recipe. Exit 1 holds the merge;
  exit 2 means it could not run, so do not ask to merge without it. Record the
  failure once in the changelog; a repeat is only a pointer.
- Wait for `/setup-hosting` to confirm every `Live side needs:` item is on the
  host. Run `scripts/env-names-added.sh` on the piece's branch; exit 1 names
  new `.env.example` settings to treat the same way, exit 2 is a one-line
  warning.
- If rollback left the live copy on an earlier version, say the merge alone
  will not put this change live; `/setup-hosting` moves it after a yes.

Keep the pull request open and state what it awaits. Read
`gh pr view <number> --json mergeable`. For `CONFLICTING`, explain the two
intentions and offer to merge the newest `main` into the branch on a yes. Never
force-push or rebase. Resolve only when the records make the outcome clear;
otherwise ask. Escalate conflicts involving data, migrations, deployment
settings or risk areas for a fresh yes. Then rerun project checks and the
live checks above. For `UNKNOWN`, read again after a short wait.

## Ask and merge

Name the pull request and what it changes, then ask for a yes that names the
merge. Say that it puts the change live only on a recipe or when the
masterplan says every change to `main` deploys. A clear “merge it” already
counts; do not ask again. A yes to building, saving, uploading, going live,
hosting, or a question asked before naming the merge does not count. A no
leaves the pull request open and live tool unchanged. Red, pending or missing
checks and an unticked `Worth stopping for` box always hold the merge.

One yes covers only named pull requests, or all when clearly asked, such as
“merge both”. A merge does not authorise a conflict fix involving a question,
data, migration, deployment setting or risk area; ask again. A yes given
before a non-blocking issue is noticed still stands; report the issue and offer
it as a piece.

Make an approved merge on the pull request itself. Record the yes with the
`records` skill's `scripts/approval.py`, as `approval.py yes "merge pull
request <number>" --words "<their words>"`, then run
`scripts/merge.py --approved <number>`. Exit 0
merged. Exit 1 means a check, review box, a review of an earlier version or
a risk area holds it; exit 2
means a required read/check could not run or GitHub refused. Say what stopped
it and leave the pull request open. In an unattended run, leave it for review.

After a merge, run the `records` skill's `scripts/piece-labels.sh` with
`merged <number>`, refresh the printout and follow `references/after-merge.md`.

If GitHub did not start its check, the merge waits. Say so and that the person
can re-enable the check or merge on GitHub.
For queues, automatic merge, and conflicts between waiting pieces, follow `references/automatic-merge.md`.

Read `references/automatic-merge.md` before using `--auto`.

An unattended run merges only through `--auto` when the setting is on. It never
merges unattended through another route.
