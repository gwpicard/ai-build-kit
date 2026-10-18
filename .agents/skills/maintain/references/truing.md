# Truing the records

Every `/maintain` visit starts here. Compare events with records and propose
large or ambiguous corrections. Step 6 may also change the project check.

## The routine

1. Update `main`; compare changes since the last changelog entry, tool
   behaviour where cheap, the records and Git state. If offline, use the local
   copy and say so.

   Uncommitted work is the first finding, not an obstacle. Say what it is and
   whose it seems to be, leave it exactly where it is, and never sweep it into
   a commit or discard it to get a clean tree. Say once that /what-now offers
   to continue it, save it or clear it.
2. Read the open pieces' last-updated times from GitHub. List those untouched
   for 30 days or more, by title, and ask once: "For each of these, is it
   still wanted, should it be parked, or is it done?" Change nothing on that
   list without a yes for that piece. Age alone never closes or relabels a
   piece. Where the dates cannot be read, say the check could not be made.

   Use `records/references/pieces.md` to correct stale states and add missed,
   dated changelog lines. Report findings; closing a piece is the person's
   decision. Keep manual GitHub changes and refresh the printout.

   Where CHANGELOG.md records that the project check on GitHub was switched
   off, read `gh workflow list --all`. While it is off, say in one line that
   GitHub is not checking pull requests, with the recorded command to turn it
   back on. Turn it on only on a yes.
3. Correct the masterplan using `records/references/masterplan-changes.md`,
   reading from the older of the saved mark and last changelog entry. Never
   rewrite its risk record; rerun `fit-check` if the project's
   character changed. Re-read each `rests on` clause using
   `records/references/pieces.md`; report unsupported decisions and ask what
   should settle them.
4. Load `records/references/coverage-read.md` and compare promises with
   pieces. Above 1,000 words in the core sections (excluding the risk record, key
   terms, live-running notes, headings, comments and diagram source), ask
   whether to move piece detail onto pieces. Move only on a yes, preserving
   promises and decisions. Run `quality-checks/references/document-read.md`
   for stale names. Kit-update handles retired-command guidance.
5. Name anything left open: a recheck trigger, flagged work waiting,
   interrupted manual setup. Where flagged work was built in the period and
   the risk record has no `Accepted:` line for it, say so, and never
   write one after the fact.
6. Keep `.github/workflows/checks.yml` aligned with AGENTS.md's install and
   test commands: change only `jobs.project-check`, not a separate source
   validation job. Run the installed
   `setup-ai-build-kit/scripts/place-trim-check.py`. Exit 0: say nothing.
   Exit 1: make its offer once; on yes run `--apply` and save with the
   corrections, on no run `--decline`. Exit 2: say it could not be placed.
7. A mistake the agent has made twice becomes one line in AGENTS.md. A pattern
   the person approved more than once may become a project skill. The length
   of AGENTS.md belongs to the monthly trim offer.
8. Save corrections before the visit changes other files. On a checkpoint
   route, commit on the current branch. On a pull-request route, use
   `merge/scripts/save-records.sh` on a short-lived branch from current `main`,
   including only changed files. Open a pull request with step 9's paragraph
   and run the project check. Keep uncommitted work out. Never merge, delete
   the branch, commit to `main` or leave corrections uncommitted. The first
   upload needs a yes. If GitHub is unreachable, save the branch and report
   the missing step. A GitHub label change needs no branch.
9. Say in one short paragraph what was corrected, or in one line that nothing
   had drifted.
