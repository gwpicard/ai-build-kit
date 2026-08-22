---
name: sync
description: True the documents up against what actually happened. Use for an interrupted session, work done outside the skills, an imported branch or contribution, a long session whose context went foggy, or reconciliation before a handover. Normal completion of /plan, /implement, /fix, /ship, and /maintain already updates the records; sync is the recovery and reconciliation route, not a routine step after every piece. Type this command when you want it; it never starts on its own.
disable-model-invocation: true
---

# Sync

The documents are supposed to describe reality. Make that true again by reading what actually happened, and correct the records instead of trusting what they claim. Propose the document changes before making anything large or ambiguous. You change documents only, never code; the single piece of machinery you keep in step is the check's own file, in step 6.

## When to run this

Normal completion of /plan, /implement, /fix, /ship, and /maintain already updates the
pieces, the changelog, and the masterplan directly; a correctly finished
piece of work doesn't need sync afterward. Reach for sync instead for: a
session that was interrupted mid-piece, work done outside the skills
entirely, an imported branch or outside contribution, a long session whose
context became unclear, reconciliation before handing the project to someone
else, or recovering after an optional automation failed to run.

## The routine

1. Read the commits and changes since the last changelog entry, plus the tool's actual behaviour where that is cheap to check, and compare them against the records and the current Git state.
2. Correct the pieces to match reality, and append any changelog lines the work missed, dated. On a project with issues there is usually little to do, because a merged pull request saying `Closes #<number>` closes its own piece. Look for the exceptions: a piece marked `building` that nobody is building, a piece still open whose work plainly landed, a `blocked` label whose blocker has gone. Say what you found rather than correcting it quietly. Closing a piece is the person's decision, and a stale `blocked` label is worth offering to remove, since the blocked-by link already decides what `/implement` does. Whatever somebody did on GitHub by hand stands, as `.agents/skills/setup-ai-build-kit/references/pieces.md` describes. Refresh the printout afterwards.
3. Correct masterplan.md where reality moved: a promise that changed shape, a section that no longer matches the tool. Never rewrite the build-path section directly; if the project's character has changed, rerun the fit check instead and let it produce the new section.
4. Check the plan still covers the page. Load `.agents/skills/setup-ai-build-kit/references/coverage-read.md` and compare the masterplan's promises against the pieces. Reconciling after an interruption or an outside contribution is exactly when a promise quietly loses its piece.
5. Identify anything left open: an unresolved recheck trigger from the build-path section, flagged work still waiting, or interrupted manual setup. Say what's open rather than closing it quietly. Where flagged work was built during the period being reconciled, check the build-path section carries an `Accepted:` line for it; if the work happened and the line is missing, say so rather than writing one now, because an acceptance recorded after the fact is a record of nothing.
6. Keep the check on the pull request honest. If the way the project installs or tests has moved, update `.github/workflows/checks.yml` so `jobs.project-check` runs the project's real commands, the same ones AGENTS.md's stack section names. Touch only that job. An older project may still carry a separate source-validation job and repository conditions; leave those unchanged. A check still running the placeholder, or the wrong commands, is worse than no check at all because people believe the green tick.
7. Bank what was learned. A mistake the agent has now made twice becomes one line in AGENTS.md, so it stops recurring. A pattern the user approved more than once becomes a project skill, if it earns one. Keep AGENTS.md lean: point at documents instead of repeating them, and delete lines that no longer pay their way.
8. Say in one short paragraph what was corrected, so the user knows what had drifted.

## Done when

A teammate could start tomorrow from the documents alone, anything learned is written where the next session will read it, and nothing was closed quietly that should have stayed visible.
