# Truing the records

Every `/maintain` visit runs this first. Read what actually happened and
correct the records to match, rather than trusting what they claim. It catches
what normal completion missed: an interrupted session, work done outside the
skills, an outside contribution, a failed automation. Propose large or
ambiguous changes before making them. The truing changes documents only, and
the project check's file in step 6.

## The routine

1. Bring `main` up to date, then read the commits and changes since the last
   changelog entry, and the tool's behaviour where that is cheap, against the
   records and the Git state. Where `main` cannot be reached, work from the
   local copy and say so in one line.

   Uncommitted work is the first finding, not an obstacle. Say what it is and
   whose it seems to be, leave it exactly where it is, and never sweep it into
   a commit or discard it to get a clean tree. Say once that /what-now offers
   to continue it, save it or clear it.
2. Read the open pieces' last-updated times from GitHub. List those untouched
   for 30 days or more, by title, and ask once: "For each of these, is it
   still wanted, should it be parked, or is it done?" Change nothing on that
   list without a yes for that piece. Age alone never closes or relabels a
   piece. Where the dates cannot be read, say the check could not be made.

   Correct the pieces to match reality, and add any changelog lines the work
   missed, dated. Look for a piece marked `building` nobody is building, a
   piece still open whose work plainly landed, and a `blocked` label whose
   blocker has gone. Say what you found; closing a piece is the person's
   decision, and a stale `blocked` label is offered for removal. What somebody
   did on GitHub by hand stands, as pieces.md says. Refresh the printout.

   Where CHANGELOG.md records that the project check on GitHub was switched
   off, read `gh workflow list --all`. While it is off, say in one line that
   GitHub is not checking pull requests, with the recorded command to turn it
   back on. Turn it on only on a yes.
3. Correct masterplan.md where reality moved, by the
   `setup-ai-build-kit` skill's `references/masterplan-changes.md`: read the gap first, then apply
   each landed piece's unapplied `## Masterplan change`, and move the mark to
   the saved state you checked. Read from the older of the mark and the last
   changelog entry. Never rewrite the build-path section; if the project's
   character changed, rerun the fit check.

   Re-read every "rests on" clause by pieces.md's rule. Where support has gone,
   say which decision lost it, keep the decision, and ask what should settle
   it.
4. Load the `setup-ai-build-kit` skill's `references/coverage-read.md` and
   compare the masterplan's promises with the pieces.

   Count the words in the masterplan's core sections, leaving out `Build
   path`, `Key terms`, `How it stays running`, headings, comments and diagram
   source. Above 1,000, ask once: "The masterplan is longer than roughly two
   pages. Shall I move the detail about individual pieces onto those
   pieces?" Move detail only on a yes, keeping every present promise and
   decision.

   Then load the `maintain` skill's `references/document-read.md` and run its read for
   stale names. Retired-command guidance in AGENTS.md and masterplan.md is
   left to "Finishing a kit update".
5. Name anything left open: a recheck trigger, flagged work waiting,
   interrupted manual setup. Where flagged work was built in the period and
   the build-path section has no `Accepted:` line for it, say so, and never
   write one after the fact.
6. Keep the pull-request check honest. Where the install or test commands have
   moved, update only `jobs.project-check` in `.github/workflows/checks.yml` to
   the commands AGENTS.md's stack section names. Leave an older separate
   source-validation job and its conditions alone.

   Then run `python3 <installed setup-ai-build-kit skill>/scripts/place-trim-check.py`.
   Exit 0: say nothing. Exit 1: offer once: "Your project's check does not yet
   go red when a tidy-up step changes a test. I can add that step, which
   changes only the check file and adds one script beside it." On a yes run it
   with `--apply` and save it with the corrections; on a no, `--decline`. Exit
   2: say in one line it could not be placed.
7. A mistake the agent has made twice becomes one line in AGENTS.md. A pattern
   the person approved more than once may become a project skill. The length
   of AGENTS.md belongs to the monthly trim offer.
8. Save the corrections as soon as the truing is done, by the save route the
   build path requires, before the rest of the visit changes a file.

   On the checkpoint route, commit on the current branch and state the
   checkpoint. On the pull-request route, cut a short-lived branch from the
   up-to-date `main`, commit only the files the truing changed with the
   `implement` skill's `scripts/save-records.sh`, naming each file, push, open
   a pull request titled after the reconciliation with step 9's paragraph as
   its body, and run the project check. The person's uncommitted work stays out
   of it.

   Never merge it and never delete the branch: a person decides. Never commit a
   correction straight onto `main` or leave it uncommitted. The first upload
   waits for its yes, as the `implement` skill's `references/merge.md` says.
   Where GitHub cannot be reached, save on the branch and note the missing step
   in one line. A label changed on GitHub needs no branch.
9. Say in one short paragraph what was corrected, or in one line that nothing
   had drifted.

## Done when

A teammate could start tomorrow from the documents alone, anything learned is written where the next session will read it, and nothing was closed quietly that should have stayed visible.
