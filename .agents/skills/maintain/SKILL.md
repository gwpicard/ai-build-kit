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
2. Compare the live copy with `main`, read-only. Where "How it stays running"
   records a live address and AGENTS.md names a recipe, run that recipe's
   `scripts/live-check.sh` from the project root with `--address`, the
   database password's location as the `setup-hosting` skill's "A secret a
   check needs" says, and `--needs` with the names on any open piece's `Live
   side needs:` line. Where the recipe reads its checks from a paste, ask in
   one sentence for the health answer and setting names. Say its lines as
   printed, and nothing more about a read that matches. Exit 0 no gap, 1 a
   gap, 2 a read that could not be made. Off a recipe, say in one line that
   the kit cannot compare the live copy. Without a live address, say nothing.

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
4. Finish a kit update, as below, on every visit. Where the monthly part runs,
   its step 5 runs it instead.
5. In Codex, offer the session-start GitHub check to an older project missing
   it, once the tree is clean. On a yes naming `.codex/hooks.json` and
   `.agents/tools/codex-github-check.py`, run the installed
   `setup-ai-build-kit` skill's `scripts/setup-codex.py --hooks`, explain that
   the person trusts the project and reviews the hook with `/hooks`, then
   restarts, and with approval add the template's check-before-work rule to the
   top of AGENTS.md. Never bypass the review. A hook pointing at a former
   project location is offered the same repair. The marked shell block is
   updated or removed with `--shell-install` or `--shell-remove` only on a yes
   naming the shell file. Never repeat a declined shell offer.

## Monthly, when due

1. From the project root, run `python3` with this skill's
   `scripts/upgrade-check.py --latest --route` and give its `say` lines. Exit
   1: a newer release is out; summarise its notes and wait for approval. Exit
   0: nothing newer. Exit 3: the check did not happen, so never call the
   project up to date. Its `route` lines give the update command.
2. Before changing the kit, require the clean checkpoint. Where an installed
   kit skill has local edits, explain them and propose moving the lasting rule
   into AGENTS.md. Wait for approval.
3. Find how the project receives the kit. Where `skills-lock.json` records
   skills from `gwpicard/ai-build-kit`, count them against the eight names and
   say which are missing. In Claude Code, check `claude plugin list --json`
   for the enabled `ai-build-kit@ai-build-kit` plugin and its scope. Check for
   an Agent Plugins `plugin.json` naming `ai-build-kit` beside a `skills`
   folder. If more than one route is active, ask which to keep: a plugin for
   one coding agent, the shared skills installation for several.
4. Update only through that route, with the command the `route` line names:
   - Claude plugin: `claude plugin marketplace update ai-build-kit`, then
     `claude plugin update ai-build-kit@ai-build-kit --scope <scope>`.
   - For an Agent Plugins installation: the agent's own update command, or replace the
     `agent-plugin` folder from the latest Release after the same approval.
     Read its `skills` folder back: the eight and no former name such as
     `fix`, `queue`, `sync` or `ship`. Offer the Release replacement where an
     old folder remains.
   - Shared skills, or no route found: `npx skills add gwpicard/ai-build-kit`,
     choosing the coding agents the project already uses (`universal` puts the
     folder under `.agents/skills/`). Never `npx skills update`: it drops a
     renamed skill without a word.

   Update nothing unrelated.
5. Confirm the update: the shared route's `VERSION` matches and the count is
   eight; the Claude plugin list shows the version without its `v` (it loads
   after `/reload-plugins` or a new session, so say so); an Agent Plugins
   `plugin.json` and `skills/maintain/VERSION` match. Run the project check,
   record the kit version in the changelog, and run "Finishing a kit update"
   with `--monthly`. The founded files (AGENTS.md, README.md, records,
   environment files, code, the project check) stay the project's.
6. Where that check prints a `planfile` line, read `plan.md`. The person's own
   notes are left alone. The kit's old list gets the `planfile` sentence; on a
   yes, on the clean checkpoint, open one issue per row as pieces.md says,
   with its subjects, `ready` or its question label, then remove `plan.md` and
   add a dated changelog line. A no is not recorded, so the offer returns.
7. Re-read the capability profile's reach-check engine against what is
   available now, by the order in the `implement` skill's
   `references/reach-check.md`, and update it.
8. Run the sensitive-area check installed at founding. Where it names a
   missing path or an unassigned folder, ask which area it belongs to, or
   `none`, and update the map on the answer.
9. Where the normal route is unavailable, the latest Release is the fallback
   for a shared installation, replacing only the eight kit folders after the
   same approval. A Claude plugin keeps its enabled version when the
   marketplace cannot be reached: say the update did not happen and retry
   later. Never create a second installation. If the plugin is no longer
   enabled, ask the person to reinstall it.
10. Update dependencies and check for known vulnerabilities. Report what
    changed; apply on approval.
11. Once live, read the error alerts and the bills. Anything real becomes a
    piece in pieces.md's shape.
12. Backups are checked by /setup-hosting's later run, not here. Where the
    changelog records no backup or restore check in the last month on a live
    project with data, name that gap in one line and offer that run. Confirm
    the named operational owner still holds the role, and that no critical
    service or credential is tied to someone who has left.
13. Where use or reliance has grown, run the fit check again before the rest
    of the monthly part.
14. Run this skill's `scripts/standing-lines.sh` from the project root. Read
    AGENTS.md too for a directory layout, dependency list, architecture
    overview or style rule a check could enforce, and for lines about tools or
    steps the project has dropped. Exit 1, or any such content, earns one
    offer using the measured count and what can go: "The standing instructions
    have reached 240 lines, and 30 of them describe the folder layout the code
    already shows. Shall I trim them?" Never invent removable content. Cut
    nothing without a yes. Otherwise say nothing.
15. Unless the project explores privately, run "Offering a move onto a
    recipe" below.
16. Load `references/stale-branches.md` and run its script. Never remove a
    branch.
17. Record the visit: today's date on the `last-light-pass` line of
    `.ai-build-kit-maintenance`, as YYYY-MM-DD. If the file is missing, create
    it with a `founded` line (the date masterplan.md was first saved) and the
    two pass lines. Where `.agents/hooks/session-start.sh` is missing, copy it
    from the installed setup-ai-build-kit skill's
    `templates/foundation/session-start.sh`, unless the person asked this
    visit to leave kit updates alone. Then say: "I have recorded today's visit,
    so a session will not remind you again until the next one is due." Where
    you skipped the script, say the reminder will not appear by itself and
    /what-now reports it when asked. Say the same where the project's Claude
    settings existed before the kit.

## Finishing a kit update

From the project root, run `python3 <installed maintain skill>/scripts/upgrade-check.py`,
with `--monthly` when the monthly part runs. It changes nothing. Exit 0:
nothing left. Exit 1: a step is left. Exit 2: it could not run; say so and
carry on. Where the harness cannot run it, change nothing by hand, except to
copy the installed `setup-ai-build-kit` skill's
`templates/foundation/plan-refresh.sh` to `.agents/tools/` where it is missing.

Give its `say` lines in one reply, in order, and keep to these rules:

- Ask once. Make the full offer on the first visit that finds a step and on
  monthly visits, then record `upgrade-offered|<installed VERSION>` in
  `.ai-build-kit-maintenance`. On other visits say only: "The kit update is
  not finished. The earlier /maintain offer still stands." Exit 0 with only
  `mention` or `left` sentences: say them and record the same line.
- Copy each `mention` and `left` sentence you say into the visit's changelog
  line, word for word.
- Apply only on a yes, on the clean checkpoint, with `--apply <step>`. The
  `helper` and `ready` steps need no question. A `missing` line is recovered
  with the update command approved this visit, or offered first. An
  `installer` line is removed with the command it names. Never remove a
  skill, file or folder by hand.
- A `commands` line left as written gets an agent edit: propose the lines from
  the installed founding template, keep the person's own sentences, and change
  only those lines on a yes.
- A `settings` line is the offer of the kit's newer safety rules: on a yes run
  `--apply settings`. Never edit the JSON by hand.
- A `fitcheck` line, on a yes, loads `references/four-paths.md`.
- On a no, run the check with `--decline <step>`.

Run the check again after each step and at the end. Record one dated
changelog line saying what was done and what was declined.

## Offering a move onto a recipe

A project with no `Recipe:` line, `Recipe: none`, or a recipe no longer in the
installed setup-hosting skill's `recipes/` folder is off a recipe. Off a
recipe, /setup-hosting can only name what it could not check, so the monthly
visit may offer a move. It is never required. A name written with `.md` means
the folder of that name.

1. On a recipe, or with an open piece already proposing a move, stop here.
2. Read the menu now: each folder in `recipes/` holding a `recipe.md`, and its
   `Build stack:` and `Deploy target:` lines. Take every product name from
   those files.
3. A recipe is close when the project's code and dependency files show the
   same framework and the same data service. A different deploy target, or a
   missing Dockerfile or health route, still counts as close. A self-hosted
   copy of the data service does not, since it lacks the managed backups.
4. Where the person chose their own stack at founding, offer only a close
   recipe that is new since founding (not on the `founding-menu` line in
   `.ai-build-kit-maintenance`; with no such line, every close recipe counts
   once), or one the stack has grown close to since the commit that first
   saved masterplan.md.
5. Where a `recipe-move-declined` line exists, offer again only for a recipe
   it does not list, or after a saved change to the dependency files since its
   date.
6. With nothing left, say nothing. With several, take the best `Build stack:`
   match, or the first by name.
7. Offer once: name the recipe, the launch checks /setup-hosting would then
   run, and what the move would change (such as a Dockerfile and health
   route, a new deploy target, or dashboard-made tables moved into
   migrations). Never quote a price. Say nothing changes on a no.
8. On a yes, open a piece titled as a move onto the recipe, holding its folder
   name and the changes named. Do not make the move this visit. On a no,
   record `recipe-move-declined|<YYYY-MM-DD>|<recipe>|<menu recipes, comma separated>`,
   replacing any earlier line.

## Quarterly, when due

The monthly part as well, plus:

1. A hot-spot review: areas changed repeatedly, behind repeated bugs, with slow
   or unreliable evidence, where one change spreads across many files (count
   the files each landed change touched per area from Git), failing
   integrations, and records that no longer explain reality. On Build and run
   it and Build with care, load `references/waste-read.md`,
   `references/structure-read.md` and `references/document-bloat.md` and run
   their scripts first. Propose at most three simplifications, each with the
   repeated problem, the plain change, what becomes easier to verify or
   recover, the cost, and whether someone outside the team must look. Apply
   on approval.
2. Review project skills for instructions that no longer pay their way, and
   offer to remove them.
3. Run the `setup-hosting` skill's `references/evidence-run.md`, scoped by the
   build path and its areas.
4. The ownership check: can the team still explain the main flows, verify
   important changes without reading code, find where data, secrets, owners
   and bills live, and recover or use the manual fallback? Has reliance
   grown? Are the sensitive areas and cautions still accurate? Name a new
   area when needed. For an area named or given a boundary since the last
   full visit, offer the rule in the `setup-ai-build-kit` skill's
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
