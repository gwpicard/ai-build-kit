# Truing the records

Every `/maintain` visit runs this first, whenever it runs. The documents are
supposed to describe reality. Make that true again by reading what actually
happened, and correct the records instead of trusting what they claim. Propose
the document changes before making anything large or ambiguous. The truing
changes documents only, never code; the single piece of machinery it keeps in
step is the check's own file, in step 6.

## Why every visit

Normal completion of /shape, /implement and /setup-hosting already updates the
pieces, the changelog and the masterplan directly, so a correctly finished
piece leaves little here to do. The truing catches what normal completion
missed: a session that was interrupted mid-piece, work done outside the skills
entirely, an imported branch or outside contribution, a long session whose
context became unclear, an optional automation that failed to run, or a
handover coming up. Running it on every visit means the person never has to
know which of those happened.

/what-now owns recovery after an interrupted session: it finds uncommitted
work and offers the person what to do with it. The truing only reports that
work and leaves it alone.

## The routine

1. Bring the shared `main` branch up to date, then read the commits and changes since the last changelog entry, plus the tool's actual behaviour where that is cheap to check, and compare them against the records and the current Git state. Uncommitted work found here is the first finding, not an obstacle: say what it is and whose it seems to be, leave it exactly where it is, and never sweep it into a commit of your own or discard it to get a clean tree. Say once that /what-now offers the ways to continue it, save it or clear it. Where `main` cannot be reached, work from the local copy and say so in one plain line.
2. Check for stale pieces before correcting their records. On every build
   path, read the open pieces' last-updated times from GitHub.
   List pieces untouched for at least 30 days once, in one short list by title.
   Ask once: "For each of these, is it still wanted, should it be parked, or is
   it done?" Change nothing on that list without a yes to the proposed action
   for that piece.

   Silence leaves it as it is, and the visit carries on without asking again. Age
   alone never closes or relabels a piece. If the dates cannot be read, say the
   stale-piece check could not be made; do not guess from the local printout.

   Correct the pieces to match reality, and append any changelog lines the work missed, dated. On a project with issues there is usually little to do, because a merged pull request saying `Closes #<number>` closes its own piece. Look for the exceptions: a piece marked `building` that nobody is building, a piece still open whose work plainly landed, a `blocked` label whose blocker has gone. Say what you found rather than correcting it quietly. Closing a piece is the person's decision, and a stale `blocked` label is worth offering to remove, since the blocked-by link already decides what `/implement` does. Whatever somebody did on GitHub by hand stands, as the `setup-ai-build-kit` skill's `references/pieces.md` describes. Refresh the printout afterwards.

3. Correct masterplan.md where reality moved. Load the `setup-ai-build-kit` skill's `references/masterplan-changes.md`. Read the gap first, as its "Read the gap at each visit" says, before anything moves the mark. Then merge each landed piece's `## Masterplan change` that has not yet been applied, and move the trued-against mark to the saved state you checked. Read from the older of that mark and the last changelog entry, so an up-to-date history cannot hide a stale page. Never rewrite the build-path section directly; if the project's character has changed, rerun the fit check instead and let it produce the new section.

   Re-read every "rests on" clause in the masterplan against what it names,
   following the decision rules in the `setup-ai-build-kit` skill's
   `references/pieces.md`. When its support has gone, say in one line which decision lost its
   ground: "The rule that a job closes once rested on a test that no longer
   exists." Keep the decision on the page and ask what should settle it;
   never quietly remove a rule because its evidence went missing.

4. Check the plan still covers the page. Load the `setup-ai-build-kit` skill's `references/coverage-read.md` and compare the masterplan's promises against the pieces. Reconciling after an interruption or an outside contribution is exactly when a promise quietly loses its piece.

   On every build path, count the words in the masterplan's core sections.
   Leave out `Build path`, the optional `Key terms` and `How it stays running`
   sections, headings, comments and diagram source. More than 1,000 words is the
   working measure for roughly two pages. Above that, give one line once in this run:
   "The masterplan is longer than roughly two pages. Shall I move the detail
   about individual pieces onto those pieces?" Move detail only with a yes,
   keeping every present promise and decision on the masterplan. Otherwise,
   leave it intact and carry on. At or below the measure, say nothing.

   Then read the project's own documents against it. Load
   the `maintain` skill's `references/document-read.md` and check the README
   and every document AGENTS.md points at for a file, link, command or setting that no longer
   exists. Offer to correct only the stale name, or to file it as a piece.
   Retired-command guidance in AGENTS.md and masterplan.md belongs only to
   maintain's "Finishing a kit update" step. Leave it for that step's exact
   template rewrite or own-guidance report, rather than correcting it here.
   This is the visit's one read for stale names. The quarterly read for
   documents that repeat each other leaves those names to it.
5. Identify anything left open: an unresolved recheck trigger from the build-path section, flagged work still waiting, or interrupted manual setup. Say what's open rather than closing it quietly. Where flagged work was built during the period being reconciled, check the build-path section carries an `Accepted:` line for it; if the work happened and the line is missing, say so rather than writing one now, because an acceptance recorded after the fact is a record of nothing.
6. Keep the check on the pull request honest. If the way the project installs or tests has moved, update `.github/workflows/checks.yml` so `jobs.project-check` runs the project's real commands, the same ones AGENTS.md's stack section names. Touch only that job. An older project may still carry a separate source-validation job and repository conditions; leave those unchanged. A check still running the placeholder, or the wrong commands, is worse than no check at all because people believe the green tick.
7. Bank what was learned. A mistake the agent has now made twice becomes one line in AGENTS.md, so it stops recurring. A pattern the user approved more than once becomes a project skill, if it earns one. Point at documents instead of repeating them. The file's length and the lines that no longer pay their way belong to the monthly trim offer, which is their one home, so do not trim AGENTS.md here.
8. Save the corrections the way a piece is saved, as soon as the truing is done and before the rest of the visit changes a file. The truing changes documents only, but the documents are shared, so the corrections take the save route the build path already requires: the three routes section-builder names, with no fourth for records. A monthly or quarterly part that runs afterwards starts its clean checkpoint from this save, and saves its own changes the same way on top of it.

   On the checkpoint route, commit on the current branch and state the saved checkpoint. On the pull-request route, cut a short-lived branch from the up-to-date `main`, stage only the files the truing itself changed, commit, push, open a pull request titled after the reconciliation, and run the project check. The person's own uncommitted work stays out of that commit, as step 1 says. The paragraph from step 9 is the body of that pull request. It is the proposal step 1 asks for, put where the person can read it and say yes.

   Never merge it, and do not delete the branch: a person decides whether to merge, always. A correction committed straight onto `main`, or left uncommitted, is a second kind of drift, since the records now disagree with what is saved. The project's first upload waits for the yes section-builder's "The first upload" describes. Where GitHub cannot be reached, save on the branch and note the step that did not happen in one plain line; a missing step is not a hazard and earns no warning. A label changed on GitHub itself in step 2 is not a file and needs no branch.
9. Say in one short paragraph what was corrected, so the user knows what had drifted. Where nothing had drifted, say so in one line.

## Done when

A teammate could start tomorrow from the documents alone, anything learned is written where the next session will read it, and nothing was closed quietly that should have stayed visible.
