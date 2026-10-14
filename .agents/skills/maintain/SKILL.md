---
name: maintain
description: Make the project true and healthy, at any time. Every visit trues the records against what actually happened and compares the live copy with main without changing it. The monthly and quarterly upkeep run only when due, and the visit also holds handovers and retirement. Trigger when it has been a while, after work done outside the skills, before a handover, and when a tool is being retired. A session that died part-way goes to what-now first. Do not use for building, repairing, or planning.
---

# Maintain

Every visit makes the project true again. The monthly and quarterly parts run
only when due. Report findings before applying anything beyond routine updates.

In Codex, when a Git push, fetch or remote check fails with `unable to get
password from user`, run the installed `setup-ai-build-kit` skill's
`templates/foundation/codex-github-check.py` with python3 and `--message`, give
its sentence, and stop this session's work.

## Every visit

1. Make the records true: load `references/truing.md` and follow it. It saves
   its corrections before the rest of the visit changes a file.

   The person's own uncommitted work stays out of every commit the visit
   makes. Report it in one line and name /what-now, which offers to continue,
   save or clear it. While it is there, every step that needs the clean
   checkpoint waits, the kit update included: say so in one line. Steps that
   only read carry on.
2. Compare the live copy with `main`, read-only, as the `live-copy` skill's
   "Comparing the live copy with main" says.

   Change nothing live and write nothing to the changelog here. Backups,
   restores, previews and the rest of the recipe's checks belong to a later
   /setup-hosting run: offer it in one line with any gap found. Never apply a
   migration, deploy, promote or roll back from this visit.
3. Decide what else is due from `.ai-build-kit-maintenance`. Monthly: 30 days
   after `last-light-pass`, or after founding when none is recorded.
   Quarterly: 90 days after `last-full-pass`, or after founding, and whenever
   a handover is asked for. Either is due when the person asks. A
   records-only visit runs only the every-visit steps. Say in one line when a
   part not due falls due. A part that runs saves its own changes the same way
   at its end.
4. Finish a kit update by `references/kit-update.md`, on every visit. Where
   the monthly part runs, its step 5 runs it instead.
5. In Codex, offer the session-start GitHub check as
   `references/kit-update.md`'s "The Codex start check" says.

## Monthly, when due

Load `references/monthly.md` and work through it in order.

## Quarterly, when due

The monthly part as well, plus:

1. A hot-spot review: areas changed repeatedly, behind repeated bugs, with slow
   or unreliable evidence, where one change spreads across many files (count
   the files each landed change touched per area from Git), failing
   integrations, and records that no longer explain reality. On Build and run
   it and Build with care, run the waste, structure and document-bloat reads in
   the `quality-checks` skill first. Propose at most three simplifications,
   each with the repeated problem, the plain change, what becomes easier to
   verify or recover, the cost, and whether someone outside the team must look.
   Apply on approval.
2. Review project skills for instructions that no longer pay their way, and
   offer to remove them.
3. Run the `evidence-run` skill, scoped by the
   build path and its areas.
4. The ownership check: can the team still explain the main flows, verify
   important changes without reading code, find where data, secrets, owners
   and bills live, and recover or use the manual fallback? Has reliance
   grown? Are the sensitive areas and cautions still accurate? Name a new
   area when needed. For an area named or given a boundary since the last
   full visit, offer the rule in the `quality-checks` skill's
   `references/boundary-rules.md`. An area comes off only when a redesign
   removed what put it there. Where a handover is asked for, or a caution
   names a person the team must find, prepare one.
5. Date the `last-full-pass` and `last-light-pass` lines.

## A handover

A handover gives somebody outside the team one sensitive area, or the whole
build, to look at or take on. Prepare it only on a yes, from this skill's
`templates/handover.md`, in plain words, with no secret in it: say where access
is granted. Work outside the area carries on. Where preparing it changes the
build path or names a new area, record what changed and why, each new area and
its caution, and which work continues or waits. It is done when it is complete
and says what it does not cover.

## When a tool's time is over

Export the data in a usable format and read the export back before anything is
switched off. Tell the people who relied on it. Then revoke access, rotate or
delete credentials, confirm retention duties, remove scheduled jobs and
webhooks, switch off the services, confirm billing stopped, and archive the
repository. Each of those steps waits for a yes naming it, after you say what
it changes and whether it can be undone. A yes covers only that step. A no
leaves that part running, listed as still open.

## Done when

The records match what happened, the upgrade check has run and anything it still finds is said, any gap between the live copy and `main` is reported, the findings are reported, the approved changes are applied and saved through the build path's route, a monthly or quarterly part that ran is written into `.ai-build-kit-maintenance`, and the person knows when the next one is due.
