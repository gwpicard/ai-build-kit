---
name: maintain
description: The service visit for AI Build Kit updates, project upkeep, handovers, and retirement. Trigger monthly for the light pass, quarterly or before any handover for the full one, and when a tool is being retired. Composes sync and the evidence run instead of repeating them. Do not use for building, fixing, or planning.
disable-model-invocation: true
---

# Maintain

Small regular maintenance is what keeps the rare big problem from arriving. Report findings before applying anything beyond routine updates.

## Monthly, light

1. Check the project's `.ai-build-kit-version` against the latest stable release
   from `gwpicard/ai-build-kit-maintainer`. If a newer version exists, read its
   release notes and say: "A newer AI Build Kit is available. This updates the
   kit around your tool, not the tool itself." Do not update silently.
2. To prepare an approved kit update, download the official starter archives
   for both the project's current version and the new version into new temporary
   folders outside the project. Run `.agents/tools/update-kit.sh plan` with
   those two unpacked folders. It updates only the paths declared in the
   releases' `.ai-build-kit-managed` records; project code, project records,
   AGENTS.md, README.md, environment files, and the project's check stay owned
   by the project.
3. Report the version, the release-note summary, and the updater's plain change
   counts. Apply only after approval, on the save route the build path requires,
   with no other unsaved work present. Run `.agents/tools/update-kit.sh apply`,
   then the regenerated adapter check and the project's own check. Record the
   kit version in the changelog with the saved change.
4. A conflict or a path redirected outside the project stops before anything
   changes. After an unexpected failure while applying, the updater restores
   the clean starting state when the computer still permits restoration. If it
   cannot finish restoring, stop and direct recovery from the required clean
   checkpoint. Explain which kit behaviour needs attention and what the new
   release changes there. Propose one resolution and wait for approval; never
   choose a side by file age or replace the whole project with the starter. If
   either official release archive is unavailable, stop and report that the
   update cannot be verified.
5. Update project dependencies and check for known vulnerabilities. Report what changed; apply on approval.
6. Once live: read the error alerts and the bills. Anything real becomes a piece on plan.md, for build to take.
7. Verify backups still run where the tool has any. Confirm the named operational owner from the masterplan still holds that role, and that no critical service or credential is tied to someone who has left.
8. Check whether use or reliance has grown enough that the fit check should run again; if it has, run it before anything else this visit.

## Quarterly, or before a handover

Everything above, plus:

1. Run sync.
2. A hot-spot review, not a general architecture pass. Look first at: areas
   changed repeatedly, areas behind repeated bugs, areas whose evidence is
   slow or unreliable, areas where one change spreads across many files,
   integrations that fail often, and records that no longer explain reality.
   Propose no more than three simplifications; for each, state the repeated
   problem, the plain-language change, what becomes easier to verify or
   recover, the cost, and whether it needs expert help. Apply on approval.
   Do not run a broad architecture programme merely because the quarter
   changed.
3. Prune the instruction layer: AGENTS.md lines and project skills that no longer pay their way. Those accumulate debt the same way code does.
4. Run ship's evidence run, scoped by the build path's required controls.
5. The ownership and graduation check: can the team still explain the main
   flows? Can it verify important changes without reading code? Can it
   identify where data, secrets, service owners, and bills live? Can it
   recover, or use the manual fallback? Has reliability, complexity, or
   reliance grown? Are the expert gates still accurate? Move the build path
   upward when the answers require it, and downward when a genuine redesign
   has removed the risk that put it there.

## When a tool's time is over

Own the ending. Export the data somewhere the team can reach it, in a
documented, usable format, and tell the people who relied on the tool.
Revoke access, rotate or delete credentials, confirm any retention
obligations, remove scheduled jobs and webhooks, switch off the services so
nothing keeps billing quietly, confirm billing has actually stopped, and
archive the repo. An abandoned tool with real data in it is a liability; a
retired one is finished.

## Done when

The findings are reported, the approved changes are applied and recorded, and the calendar says when the next visit is due.
