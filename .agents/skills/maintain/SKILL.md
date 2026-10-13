---
name: maintain
description: Make the project true and healthy, at any time. Every visit trues the records against what actually happened and compares the live copy with main without changing it. The monthly and quarterly upkeep run only when due, and the visit also holds handovers and retirement. Trigger when it has been a while, after work done outside the skills, before a handover, and when a tool is being retired. A session that died part-way goes to what-now first. Do not use for building, repairing, or planning.
---

# Maintain

Small regular maintenance is what keeps the rare big problem from arriving. Report findings before applying anything beyond routine updates.

This command can run at any time. Every visit makes the project true again.
The monthly and quarterly parts run only when they are due.

In Codex, when a Git push, fetch or remote check fails with
`unable to get password from user`, run the installed `setup-ai-build-kit`
skill's `templates/foundation/codex-github-check.py` with python3 and `--message`.
Give its sentence with the absolute launcher path and stop this session's work.
Do not sign in again or retry the failed command in this session.

## Every visit

1. Make the records true. Load `references/truing.md` and follow it. Its
   save step saves the corrections through the save route as soon as the
   truing is done, before the rest of the visit changes a file. The monthly
   part's clean checkpoint starts from that save.

   The person's own uncommitted work stays out of every commit the visit
   makes. Report it in one line and name /what-now, which offers to continue
   it, save it or clear it. While it is there, the tree is not clean, so the
   kit update and every other step that needs the clean checkpoint waits, as
   it always has: say so in one line. Steps that only read carry on.
2. Compare the live copy with `main`, read-only. Where the masterplan's "How
   it stays running" section records a live address, make only these reads,
   each as the `setup-hosting` skill's "A later run" describes it:

   - whether the live copy runs the latest merge on `main`, from its health
     route or the host's list of deployments;
   - whether the live copy is still held on an earlier version since a
     rollback;
   - whether `main` holds a database migration the live database does not
     have, read with the recipe's own dry run where it has one, its secret
     passed by its location as "A secret a check needs" in that skill says;
   - whether each secret name the tool needs is present on the host, by name
     only;
   - whether health answers.

   Report each gap in one plain line, and change nothing. Say nothing more
   about a part that matches, and say in one line when a read could not be
   made. Write nothing to the changelog here, and do not rerun the fit check
   from this step.

   The backup, the restore, the preview and the rest of the recipe's checks
   stay in /setup-hosting's later run. They can stop the local database, copy
   the live one, or need the person, so a visit nobody asked to touch the
   live side never runs them. Offer that later run in one line, with any gap
   found, since each repair there waits for its own yes. Never apply a
   migration, deploy, promote or roll back from this visit. Without a
   recorded live address, skip this step and say nothing.
3. Decide what else is due. Read `.ai-build-kit-maintenance`. The monthly part
   is due 30 days after its `last-light-pass` date, or 30 days after founding
   when no visit is recorded. The quarterly part is due 90 days after its
   `last-full-pass` date, or 90 days after founding when no full visit is
   recorded, and whenever the person asks for a handover. The person may ask
   for either part at any time, and then it is due. A records-only visit,
   where the person asks only for the records to be checked, runs only the
   every-visit steps. Run what is due. Where a part is not due, say so in one
   line with the date it falls due. When nothing more is due, the visit ends
   with the truing's summary and steps 4 and 5. A monthly or quarterly part that runs
   saves its own changes the same way at its end, on top of the truing's save.
4. Finish a kit update, as "Finishing a kit update" below says, on every
   visit, a records-only one included. Where the monthly part runs, its step
   5 runs it after the update instead; do not run it twice.
5. In Codex, offer the session-start GitHub check to an older project missing
   it. Wait for the clean checkpoint before changing a project file. On a yes
   naming `.codex/hooks.json` and `.agents/tools/codex-github-check.py`, run
   `python3` with the installed `setup-ai-build-kit` skill's
   `scripts/setup-codex.py`, passing `--hooks`. It preserves other hooks and records the
   installed skill's path for plugin installations. Explain that the person
   trusts the project and reviews the hook with `/hooks`, then restarts;
   never bypass that review. With approval, add the template's short
   check-before-work rule to the top of the project's AGENTS.md, preserving
   its other instructions and line ceiling. Save these changes through the
   project's save route. The check also runs while the hook is untrusted or
   disabled. A no leaves the files alone and the visit carries on.

   On a later visit, a hook whose command points at a former project location
   is offered for the same repair. Refresh a changed kit helper or plugin path
   only on the same named yes. For the marked shell block, a requested update
   or removal runs that installed skill's `scripts/setup-codex.py` with
   `--shell-install` or `--shell-remove`, only on a yes naming the shell file. Never repeat
   founding's declined shell offer.

## Monthly, when due

1. From the project root, run `python3` with this skill's
   `scripts/upgrade-check.py --latest --route`. It asks only GitHub's
   `releases/latest`, the one endpoint that never answers with a draft. Give
   its `say` lines on every monthly visit. Where the versions differ, read the
   newer version's notes, give a short summary, and wait for approval. Exit 3
   means the check did not happen: never call the project up to date then.
   Its `route` lines give step 4's update command.
2. Before registering or changing the kit, require the clean checkpoint used by
   the current build path. For a shared skills installation, check whether any
   AI Build Kit skill has local edits. Project-specific rules belong in
   AGENTS.md. If such edits exist, explain them and propose moving the durable
   rule there. Wait for approval rather than replacing an edit silently.
3. Identify how this project receives AI Build Kit. Check whether
   `skills-lock.json` records skills from `gwpicard/ai-build-kit`. Where it
   does, count its entries against the eleven names and say which are
   missing. A short installation means a skill the kit renamed or added never
   arrived. The version file cannot show this, because the same update that
   drops a skill rewrites the version, so the count is the only sign.
   An entry under a former name is an old skill the installer kept, which
   "Finishing a kit update" names.
   In Claude Code, also use `claude plugin list --json` to check for the enabled
   `ai-build-kit@ai-build-kit` plugin and note its installation scope. Also
   check for an Agent Plugins installation: a `plugin.json` naming
   `ai-build-kit` beside a `skills` folder, wherever this coding agent keeps
   its plugins. If more than one route is active, stop and ask the person which
   one to keep. Use a plugin when one coding agent runs the project and the
   shared skills installation when the project uses several coding agents.
4. Update only through the route found in step 3, with the command its
   `route` line from step 1 names:

   - For the Claude plugin, refresh its marketplace with
     `claude plugin marketplace update ai-build-kit`, then run
     `claude plugin update ai-build-kit@ai-build-kit --scope <scope>` using the
     scope reported in step 3.
   - For an Agent Plugins installation, use the coding agent's own plugin
     update command. When the agent has none, download the latest public
     Release and replace the installed `agent-plugin` folder after the same
     approval and clean checkpoint. Afterwards, read the installed folder's
     `skills` folder back. It holds the eleven and no folder under a former
     name such as `fix`, `queue`, `sync` or `ship`. Where an old folder is
     still there, the agent's command did not replace the folder whole. Say
     so, and offer the replacement from the Release after the same approval.
   - For a shared skills installation, run
     `npx skills add gwpicard/ai-build-kit` and let the person choose the same
     coding agents the project already uses. Choosing `universal` is what puts
     the real folder under `.agents/skills/`. This command refreshes a skill
     that is installed and adds one that is missing. Do not use
     `npx skills update` for the kit: it refreshes only what the lockfile
     already lists and drops any other name without a word, so it cannot
     carry a project across a rename.
   - When no route is present, this is an older installation. After
     approval, run the same `npx skills add gwpicard/ai-build-kit`. This
     registers and refreshes the existing skills, so do not run a second
     update on the same visit.

   Do not update unrelated plugins, project skills, or global skills.
5. For the shared route, confirm that this skill's `VERSION` now matches the
   version step 1 read, and that the count from step 3 is now eleven. A
   matching version alone is not proof the installation is whole. For the
   Claude route, confirm that `claude plugin list --json` reports the matching
   version without the leading `v`. Claude loads an updated plugin after
   `/reload-plugins` or the next session, so say that plainly. For an Agent
   Plugins installation, confirm the version in the installed
   `agent-plugin/plugin.json` and in that folder's `skills/maintain/VERSION`.
   Run the project's own check and record the kit version in the changelog
   with the saved change. The foundation that founding created, including
   AGENTS.md, README.md, project records, environment files, application code,
   and the project's check, stays project-owned. Then run "Finishing a kit
   update" below, with `--monthly`.

   Where a `plan.md` at the project root is the kit's old list of pieces
   rather than the person's own notes, offer to open one issue per row as the
   `setup-ai-build-kit` skill's `references/pieces.md` describes, and remove
   the file only after the move.
6. Re-read the capability profile's reach-check engine against what the
   harness and project can use now. Keep the same preference order as
   the `section-builder` skill's `references/reach-check.md`, and update the
   profile when a better engine has appeared or the recorded one has gone.
7. Run the sensitive-area check installed during founding. It is silent outside
   Build with care. Where it names a missing path or an unassigned source folder,
   ask which sensitive area it belongs to, or whether it belongs under `none`,
   then update the map only after the person answers.
8. If the normal route is unavailable, use the latest published Release, the
   one step 1 read, as the fallback source. A shared installation may replace
   only the eleven AI Build Kit skill folders after the same approval and
   clean checkpoint. The check in "Finishing a kit update" then finds the
   folder of any skill the kit has since retired. A Claude
   plugin installation keeps its current enabled version when the marketplace
   cannot be reached. Confirm that version with `claude plugin list --json`,
   tell the person the update did not happen, and retry when the marketplace is
   reachable. Do not create a second installation or claim that the project
   checkpoint can restore Claude's plugin cache. If the plugin is no longer
   enabled, stop and ask the person to reinstall it after the marketplace is
   reachable.
9. Update project dependencies and check for known vulnerabilities. Report
   what changed; apply on approval. The masterplan's gap since its
   trued-against mark was already read in the truing, on every visit.
10. Once live: read the error alerts and the bills. Anything real becomes a piece, for implement to take: open an issue in the shape the `setup-ai-build-kit` skill's `references/pieces.md` describes. A finding nobody wrote down is a finding nobody acts on.
11. Verify backups still run where the tool has any. A check that needs a secret reads where it lives from the masterplan first, asks once when that is unknown, and never calls the secret absent. Confirm the named operational owner from the masterplan still holds that role, and that no critical service or credential is tied to someone who has left.
12. Check whether use or reliance has grown enough that the fit check should run again; if it has, run it before the rest of the monthly part.
13. On every build path, count every line in the project's AGENTS.md, including
    blank lines, and read it for a directory layout, dependency list,
    architecture overview or style rule an automatic check could enforce, and
    for lines that no longer pay their way, such as a rule about a tool or a
    step the project has dropped. It
    stays under 200 lines and holds only what the code cannot show: the save
    and review routes, conventions that differ from the default, and pointers
    to the records.

    At 200 lines or more, or with any of the named content or such a line
    even below that count, offer a trim in one line, using the measured count and what can
    go: "The standing instructions have reached 240 lines, and 30 of them
    describe the folder layout the code already shows. Shall I trim them?"

    Where length alone triggers the offer, name that alone; never invent
    removable content to fill the example. Cut nothing without the person's
    yes. A no leaves the file intact and the visit carries on. If the file is
    short and carries none of that content, say nothing.
14. Unless the project explores privately, run "Offering a move onto a
    recipe" below. When no recipe on the menu is close to the project's stack,
    it says nothing.
15. On every build path, load `references/stale-branches.md` and list the
    branches whose work is already in the default branch, each with the
    command that removes it. List this computer and GitHub separately. Keep
    the ones Git confirms apart from the ones only GitHub records as merged.
    Never remove a branch. When no branch qualifies, say nothing.
16. Record the visit. In `.ai-build-kit-maintenance` at the project root, put
    today's date on the `last-light-pass` line, written as YYYY-MM-DD. If that
    file is missing, create it with a `founded` line holding the date
    masterplan.md was first saved, then the two pass lines. If the project has
    no `.agents/hooks/session-start.sh`, copy it from the installed
    setup-ai-build-kit skill's `templates/foundation/session-start.sh`, unless
    the person asked during this visit to leave kit updates alone. That script
    comes from the kit, and it changes what the project does later. Read what
    they asked, not a fixed phrase. Then say one sentence: "I have recorded
    today's visit, so a session will not remind you again until the next one is
    due." Where you skipped the script, say instead: "I have recorded today's
    visit. I left out the script that reminds a session when a visit is due,
    since you asked for no kit updates, so that reminder will not appear by
    itself; /what-now still reports it when asked." If the project's Claude
    settings existed before AI Build Kit did, add that the reminder cannot
    appear by itself there, and that `/what-now` reports it when asked.

## Finishing a kit update

An update refreshes the kit's skills and nothing else, so the next visit
finishes what it left, whatever day it falls on. From the project root, run
`python3 <installed maintain skill>/scripts/upgrade-check.py`, with
`--monthly` when the monthly part runs on this visit. It changes nothing.
Exit 0 means nothing is left, exit 1 means a step is, and exit 2 means it
could not run: say so in one line and carry on. Where the harness cannot run
it, say the check did not happen and change nothing by hand.

Its `say` lines hold the words the person hears for each finding. Give them
in one reply, in the order printed, and keep to these rules:

- An `older` line comes first. When there is one, make only that offer.
- Ask once. Make the full offer on the first visit that finds a step and on
  monthly visits, then record `upgrade-offered|<installed VERSION>` in
  `.ai-build-kit-maintenance`. On other visits say only: "The kit update is
  not finished. The earlier /maintain offer still stands." Name `mention` and
  `left` lines once, and not again where the changelog already names them.
- Apply only on a yes to that offer, on the clean checkpoint, with
  `--apply <step>`. The `helper` step needs no question. A `missing` line is
  recovered with the update command already approved. An `installer` line is
  removed with the installer command it names. Never remove a skill, file or
  folder by hand.
- A `commands` line the script leaves as written gets an agent edit: propose
  the lines from the installed founding template, keep the person's own
  sentences, and change only those lines on a yes. Never ask the person to
  edit the list by hand.
- A `fitcheck` line, on a yes, runs the full fit check in the
  `setup-ai-build-kit` skill's `references/fit-check.md`.
- On a no, run the check with `--decline <step>`.

Run the check again after each step, and once more at the end of the visit.
Record one dated changelog line saying what was done and what was declined,
saved with the visit's other changes.

## Adding the kit's newer safety rules

Founding copies the safety rules into `.claude/settings.json` once, and no
update touches that file. Any release can add a rule, so this step stays. The
check's `settings` lines and their `say` line are the offer. Never edit the
JSON by hand: on a yes run `--apply settings`, and on a no `--decline
settings`. A no stands until a release adds a rule it did not cover.

## Offering a move onto a recipe

A project founded before the kit had recipes has no `Recipe:` line in its
AGENTS.md. A project whose person chose their own stack has `Recipe: none`.
Either one can be built much like a recipe on the menu without anybody
noticing. On a recipe, /setup-hosting checks the launch steps. Off one, it can only
name what it could not check. So the monthly visit makes the offer, and the
person decides. The move is never required.

Skip this on Explore privately. Nothing there goes live, so the launch checks
would gain nothing.

1. Read the `Recipe:` line in the stack section of the project's AGENTS.md.
   Where it names a file that is in the installed setup-hosting skill's `recipes/`
   folder, the project is on a recipe, and this step ends. `Recipe: none`, no
   line at all, or a file that is no longer there counts as off a recipe.
2. Look at the project's open pieces. Where an open piece already proposes a
   move onto a recipe, the person said yes on an earlier visit and the move is
   waiting to be built, so this step ends. Filing it again would make a copy.
3. Read the menu at this moment: each file directly in the installed setup-hosting
   skill's `recipes/` folder, not the `parts/` folder inside it. Read each
   file's `Build stack:` and `Deploy target:` lines. Take every product name
   from those files, and never write one into this skill.
4. Compare each recipe's `Build stack:` line with what the project is built
   with. Read that from the project's code and dependency files, not from
   memory. A recipe is close when the build stack matches in substance: the
   same framework and the same data service. It stays close when the project
   deploys somewhere else, or lacks something the recipe adds, such as its
   Dockerfile or its health route. A different framework or a different data
   service is not close. A copy of the data service that the project runs on
   its own server is not the same data service, because it lacks the managed
   backups that the recipe's checks rely on. Keep every close recipe for
   now, and do not pick one yet. Steps 5 and 6 drop the ones they do not
   allow, so a close recipe that is new never hides behind an older one that
   matches a little better.
5. Where the person chose their own stack at founding, offer the move only
   when the stack has become close since, or when the close recipe is new
   since founding. Read the stack at founding from the commit that first
   saved masterplan.md. Read the `founding-menu` line in
   `.ai-build-kit-maintenance`: it lists the recipe files on the menu
   founding showed. A close recipe that line does not list joined the menu
   later, so the person never had the chance to choose it. Offer it once,
   even if the stack has not changed. A project with no `founding-menu` line
   was founded before founding kept one, so every close recipe counts as new
   for it, once. Where a close recipe was on that menu and the stack was
   already that close then, their choice stands. After a no, step 6 decides
   whether the offer comes back.
6. Read the `recipe-move-declined` line in `.ai-build-kit-maintenance`, if
   there is one. It holds the date of an earlier no, the recipe file that was
   offered, and the recipe files on the menu that day. Offer again only when
   the menu or the project's stack has changed since that no: a recipe file on
   the menu now that the line does not list, or a saved change to the
   project's dependency files after that date. Where only the menu changed,
   allow only the close recipes the line does not list, and the ones it lists
   stay declined. Otherwise the earlier no stands.
7. When no recipe is close, or an earlier no stands, say nothing. Compare
   only the close recipes that steps 5 and 6 still allow. Where several are
   left, take the one whose `Build stack:` line matches the most, or the
   first by file name.
8. Offer the move once, in one reply. Name the recipe from its file. Say what
   it gains in plain words: the launch checks /setup-hosting would then run, one for
   each section the recipe checks, such as preview, rollback, backup and
   restore. Say what it would change, from the differences step 4 found: for
   example, add the recipe's shared Dockerfile and health route, move the tool
   to the recipe's deploy target, or, where the recipe expects tables made by
   migrations and the project's tables are made only in the data service's
   dashboard, move those tables into migrations. Never quote a price. Say that
   the project keeps working as it is if they say no. For example: "This
   project is built much like the [recipe name] recipe. On that recipe, /setup-hosting
   would check the preview, rollback, backup and restore for you. The move
   would add a Dockerfile and a health route, and move the tool to [deploy
   target]. Shall I file it as a piece? Nothing changes if you say no."
9. Change nothing without approval. On a yes, open an issue in the shape
   the `setup-ai-build-kit` skill's `references/pieces.md` describes, titled
   as a move onto the recipe. It holds the recipe's file name and the changes
   the offer named. Leave it for /shape and /implement like any other piece.
   Do not make the move during the visit. The `Recipe:` line changes only
   when that piece lands.
10. On a no, leave the project alone and do not ask again this visit. Record
    the no in `.ai-build-kit-maintenance` as one line, replacing any earlier
    one: `recipe-move-declined|<YYYY-MM-DD>|<recipe file>|<menu files, comma
    separated>`. Step 6 reads it on later visits.

## Quarterly, when due

The monthly part as well, plus:

1. A hot-spot review, not a general architecture pass. Look first at: areas
   changed repeatedly, areas behind repeated bugs, areas whose evidence is
   slow or unreliable, areas where one change spreads across many files,
   integrations that fail often, and records that no longer explain reality.
   For spread, read the quarter's landed changes from Git and count the files
   each change touched in each area. Use that count to name the widest-spreading
   areas rather than judging them from memory. This is a comparison, not a
   health score.
   On Build and run it and Build with care, load `references/waste-read.md`
   and gather copied code, unused code and unused dependencies before
   proposing anything. Load `references/structure-read.md` too, and compare
   the structure with the last full visit. Then load
   `references/document-bloat.md` and look for documents that repeat each
   other or are no longer needed.
   Propose no more than three simplifications; for each, state the repeated
   problem, the plain-language change, what becomes easier to verify or
   recover, the cost, and whether a person outside the team has to look.
   Apply on approval.
   Do not run a broad architecture programme merely because the quarter
   changed.
2. Review project skills for instructions that no longer pay their way and
   offer to remove them. AGENTS.md was already checked in the monthly pass;
   do not repeat its trim offer or cut anything without the person's yes.
3. Run the evidence run in the `setup-hosting` skill's
   `references/evidence-run.md`, scoped by the build path and its sensitive
   areas.
4. The ownership and graduation check: can the team still explain the main
   flows? Can it verify important changes without reading code? Can it
   identify where data, secrets, service owners, and bills live? Can it
   recover, or use the manual fallback? Has reliability, complexity, or
   reliance grown? Are the named sensitive areas and their cautions still
   accurate? Name a new area when the answers require it. Where an area was
   named or given a boundary since the last full visit, offer the boundary
   rule in the `setup-ai-build-kit` skill's `references/boundary-rules.md`,
   and change or remove an existing rule with its area, on a yes. An area comes off
   only when a genuine redesign has removed what put it there; an acceptance
   drops its caution and leaves the area named. Where the person asks for a
   handover, or a caution names a person the team has to find, prepare
   one for the area or the whole build, as "A handover" below says.
5. Put today's date on the `last-full-pass` line as well as the
   `last-light-pass` line in `.ai-build-kit-maintenance`.

## A handover

A handover is what the team gives somebody outside it to look at one
sensitive area, or to take the whole build on. This section is its one home.
/setup-hosting offers one on Build with care where a caution is a person the
team has nobody to ask, and a flagged piece that stops at its condition names
it too.

A handover is a document the person asks for, not a stop. Prepare it only on
a yes, from this skill's `templates/handover.md`, filled in for that area or
for the whole build, in plain words for the reader outside the project. Never
put a secret in it: say where access is granted. Carry on with everything
outside the area either way.

Where preparing it changes the build path or names a new sensitive area,
record what changed, why the previous path no longer fits, each new area and
its caution, which work may continue, and which work waits.

It is done when it is complete and says what it does not cover.

## When a tool's time is over

Own the ending. Export the data somewhere the team can reach it, in a
documented, usable format, and tell the people who relied on the tool.
Revoke access, rotate or delete credentials, confirm any retention
obligations, remove scheduled jobs and webhooks, switch off the services so
nothing keeps billing quietly, confirm billing has actually stopped, and
archive the repo. An abandoned tool with real data in it is a liability; a
retired one is finished.

Export first, and read the export back before anything is switched off. Each
step that revokes access, deletes a credential, removes a scheduled job or
webhook, switches a service off or archives the repository waits for a yes
that names that step. Before asking, say what it changes and whether it can
be undone: a deleted credential or database cannot be brought back, while an
archived repository can be unarchived. A yes to one step covers only that
step. A no leaves that part running, and the ending lists it as still open.

## Done when

The records match what happened, the upgrade check has run and anything it still finds is said, any gap between the live copy and `main` is reported, the findings are reported, the approved changes are applied and saved through the build path's route, a monthly or quarterly part that ran is written into `.ai-build-kit-maintenance`, and the person knows when the next one is due.
