---
name: maintain
description: The service visit for AI Build Kit updates, project upkeep, handovers, and retirement. Trigger monthly for the light pass, quarterly or before any handover for the full one, and when a tool is being retired. Composes sync and the evidence run instead of repeating them. Do not use for building, fixing, or planning.
---

# Maintain

Small regular maintenance is what keeps the rare big problem from arriving. Report findings before applying anything beyond routine updates.

## Monthly, light

1. Read this skill's `VERSION` file, which is the version this project holds.
   Then ask for the latest published one with
   `gh api repos/gwpicard/ai-build-kit/releases/latest --jq .tag_name`. Ask
   that endpoint and no other: it is the only one that cannot answer with a
   draft or a prerelease, while `gh release list` puts an unpublished draft in
   its first row for anybody who can see the repository, which would offer an
   update that does not exist yet.

   Say both numbers, every visit, whichever way they compare: "This project
   holds v0.15.0, and the latest published AI Build Kit is v0.16.0." Where they
   differ, say so plainly rather than leaving the person to compare two numbers,
   read the newer version's notes, and add: "A newer AI Build Kit is available.
   It refreshes the installed workflow skills. Your tool, project records, and
   project instructions remain yours." Give a short summary, then wait for
   approval. Where they match, say the project is on the latest published
   release and carry on with the visit.

   Where the call cannot be made at all, because the GitHub tool is missing or
   signed out, say that the version check did not happen. Never say the project
   is up to date on the strength of a call that failed: the whole reason this
   step names one endpoint is that a project was once told it was current while
   holding work that no release had ever contained.
2. Before registering or changing the kit, require the clean checkpoint used by
   the current build path. For a shared skills installation, check whether any
   AI Build Kit skill has local edits. Project-specific rules belong in
   AGENTS.md. If such edits exist, explain them and propose moving the durable
   rule there. Wait for approval rather than replacing an edit silently.
3. Identify how this project receives AI Build Kit. Check whether
   `skills-lock.json` records skills from `gwpicard/ai-build-kit`. Where it
   does, count its entries against the fourteen names and say which are
   missing. A short installation means a skill the kit renamed or added never
   arrived. The version file cannot show this, because the same update that
   drops a skill rewrites the version, so the count is the only sign.
   In Claude Code, also use `claude plugin list --json` to check for the enabled
   `ai-build-kit@ai-build-kit` plugin and note its installation scope. Also
   check for an Agent Plugins installation: a `plugin.json` naming
   `ai-build-kit` beside a `skills` folder, wherever this coding agent keeps
   its plugins. If more than one route is active, stop and ask the person which
   one to keep. Use a plugin when one coding agent runs the project and the
   shared skills installation when the project uses several coding agents.
4. Update only through the route found in step 3:

   - For the Claude plugin, refresh its marketplace with
     `claude plugin marketplace update ai-build-kit`, then run
     `claude plugin update ai-build-kit@ai-build-kit --scope <scope>` using the
     scope reported in step 3.
   - For an Agent Plugins installation, use the coding agent's own plugin
     update command. When the agent has none, download the latest public
     Release and replace the installed `agent-plugin` folder after the same
     approval and clean checkpoint.
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
   version step 1 read from `releases/latest`, and that the count from step 3
   is now fourteen. When the shared installation did not have `screen-check`
   before this visit, confirm that the same `npx skills add` command added it,
   and carry on only once it is there. A matching version
   alone is not proof the installation is whole. For the Claude route, confirm
   that `claude plugin list --json` reports the matching version without the
   leading `v`. Claude loads an updated plugin after `/reload-plugins` or the
   next session, so say that plainly. For an Agent Plugins installation,
   confirm the version in the
   installed `agent-plugin/plugin.json` and in that folder's
   `skills/maintain/VERSION`. Run the project's own check and record the kit
   version in the changelog with the saved change. The foundation created by
   start, including AGENTS.md, README.md, project records, environment files,
   application code, and the project's check, stays project-owned. When this
   update is the one that first brings in `/shape` and `/implement`, run the
   one-time migration in "Migrating a project founded before /shape and
   /implement" below. When the visit finds a `start` skill, or no
   `setup-ai-build-kit` skill, also run "Migrating a project founded before the
   setup-ai-build-kit rename". When it finds a `plan` skill, or no `shape`
   skill, also run "Migrating a project founded before the shape rename". Both
   are decided by what is on disk rather than by which update this is, because
   an update that removed the old skill without adding the new one leaves
   nothing else to say it happened. Whenever the build-path section of
   `masterplan.md` carries a `Required controls:` or `Outside help:` line, or
   a `Path:` value the kit no longer uses, also run "Migrating a masterplan
   written with four build paths" below; that too is decided by what the
   masterplan says rather than by which update this is. On the shared route,
   also run "Tidying a project founded from a whole copy of the kit" below
   whenever the leftovers it names are present.
6. Re-read the capability profile's reach-check engine against what the
   harness and project can use now. Keep the same preference order as
   `.agents/skills/section-builder/references/reach-check.md`, and update the
   profile when a better engine has appeared or the recorded one has gone.
7. Run the sensitive-area check installed during founding. It is silent outside
   Build with care. Where it names a missing path or an unassigned source folder,
   ask which sensitive area it belongs to, or whether it belongs under `none`,
   then update the map only after the person answers.
8. If the normal route is unavailable, use the latest published Release, the
   one step 1 read, as the fallback source. A shared installation may replace
   only the fourteen AI Build Kit skill folders after the same approval and
   clean checkpoint. A Claude
   plugin installation keeps its current enabled version when the marketplace
   cannot be reached. Confirm that version with `claude plugin list --json`,
   tell the person the update did not happen, and retry when the marketplace is
   reachable. Do not create a second installation or claim that the project
   checkpoint can restore Claude's plugin cache. If the plugin is no longer
   enabled, stop and ask the person to reinstall it after the marketplace is
   reachable.
9. Read the masterplan's trued-against mark and count landed changes since it
   using `.agents/skills/setup-ai-build-kit/references/masterplan-changes.md`.
   When data, permissions or connections were touched, report the count and
   offer /sync in one line. An absent or unusable mark gets the same offer
   without a guessed count. Then update project dependencies and check for known
   vulnerabilities. Report what changed; apply on approval.
10. Once live: read the error alerts and the bills. Anything real becomes a piece, for implement to take: open an issue in the shape `.agents/skills/setup-ai-build-kit/references/pieces.md` describes. A finding nobody wrote down is a finding nobody acts on.
11. Verify backups still run where the tool has any. Confirm the named operational owner from the masterplan still holds that role, and that no critical service or credential is tied to someone who has left.
12. Check whether use or reliance has grown enough that the fit check should run again; if it has, run it before anything else this visit.
13. On every build path, count every line in the project's AGENTS.md, including
    blank lines, and read it for a directory layout, dependency list,
    architecture overview or style rule an automatic check could enforce. It
    stays under 200 lines and holds only what the code cannot show: the save
    and review routes, conventions that differ from the default, and pointers
    to the records.

    At 200 lines or more, or with any of the named content even below that
    count, offer a trim in one line, using the measured count and what can
    go: "The standing instructions have reached 240 lines, and 30 of them
    describe the folder layout the code already shows. Shall I trim them?"

    Where length alone triggers the offer, name that alone; never invent
    removable content to fill the example. Cut nothing without the person's
    yes. A no leaves the file intact and the visit carries on. If the file is
    short and carries none of that content, say nothing.
14. Record the visit. In `.ai-build-kit-maintenance` at the project root, put
    today's date on the `last-light-pass` line, written as YYYY-MM-DD. If that
    file is missing, create it with a `founded` line holding the date
    masterplan.md was first saved, then the two pass lines. If the project has
    no `.agents/hooks/session-start.sh`, copy it from the installed start
    skill's `templates/foundation/session-start.sh`. Then say one sentence: "I
    have recorded today's visit, so a session will not remind you again until
    the next one is due." If the project's Claude settings existed before AI
    Build Kit did, add that the reminder cannot appear by itself there, and that
    `/what-now` reports it when asked.

## Migrating a project founded before /shape and /implement

Run this once, on the visit whose update first replaces `/build` with `/shape`
and `/implement`. It brings an existing project's records up to the new model.
It changes labels and, with approval, moves records, so do it only after the
clean checkpoint from step 2. Every part is idempotent: a later visit that finds
the project already migrated does nothing here.

1. Backfill the `ready` label. `/implement` builds only pieces labelled `ready`,
   and a project founded earlier has none, so without this its whole backlog
   goes unbuilt. For every open issue that is already shaped, a `## Done when`
   present and no `needs-clarification`, `needs-prototype`, or `needs-research`
   label, add the `ready` label. Leave anything still carrying a `needs-` label
   alone; that one is `/shape`'s to shape. Say how many pieces were marked ready,
   so the person can see their backlog is still there.

2. Move a `plan.md` into issues. A project founded without the GitHub tool
   signed in kept its pieces in `plan.md`, which nothing reads any more. Where
   that file is on disk, say so plainly and offer to move its rows into issues:
   guide the GitHub setup first if it is not ready
   (`.agents/skills/setup-ai-build-kit/references/manual-setup.md`), open one issue per row in
   the shape `.agents/skills/setup-ai-build-kit/references/pieces.md` describes, carry each
   row's subjects across as labels, label a shaped row `ready`, and label an
   unshaped one with the question it still waits on. Do this on the clean
   checkpoint, name what moved, and only then remove `plan.md`. Where the person
   declines, leave `plan.md` untouched and say its pieces are not picked up until
   they are moved.

3. Point `/build` forward. Say once that the old `/build` command has become
   two: `/shape` to shape a new idea into a ready piece, and `/implement` to build
   one. Nothing the person saved is lost; only the command names changed.

Record the migration in the changelog as a dated line.

## Migrating a project founded before the setup-ai-build-kit rename

Run this on any visit that finds a `start` skill installed, or no
`setup-ai-build-kit` skill. It is idempotent: a visit that finds only
`setup-ai-build-kit` does nothing here.

The founding command was renamed from `/start` to `/setup-ai-build-kit`. Founding
runs once, so a project already founded never types it again, and nothing the
person saved is affected. Two housekeeping steps keep the installation tidy:

1. Remove a stale `start` skill. The shared installer asks whether to remove a
   skill that has gone upstream, and an older installer removed nothing, so
   three states are possible. Where a `setup-ai-build-kit` skill and an old
   `start` skill both exist, offer to remove the `start` one, because it is a
   managed package the kit renamed rather than the person's own work. Where
   neither exists, the update removed the old skill without adding the new
   one: run the add command from the monthly step, then read the skill folder
   back and carry on only once `setup-ai-build-kit` is there. Where only
   `setup-ai-build-kit` exists, there is nothing to do.

2. Point the founding command forward. Rewrite the command list in the
   project's AGENTS.md as "Bringing the project's instructions up to the
   current names" below says, so the person is not left to do it. Then say
   once that the command that founds a project is now `/setup-ai-build-kit`,
   not `/start`, and that any saved command which updates the kit by name uses
   that new first name. The full update command is in the monthly step above.

Record the tidy-up in the changelog as a dated line.

## Migrating a project founded before the shape rename

Run this on any visit that finds a `plan` skill installed, or no `shape`
skill. It is idempotent: a visit that finds only `shape` does nothing here.

The command that turns an idea into a ready piece was renamed from `/plan` to
`/shape`. Some coding agents, Claude Code among them, now carry a `/plan` of
their own, so one name pointed at two different commands. Nothing the person
saved is affected and no record changes, but this command is typed most days, so
the new name is said out loud rather than only tidied away in the files:

1. Remove a stale `plan` skill. The shared installer asks whether to remove a
   skill that has gone upstream, and an older installer removed nothing, so
   three states are possible. Where a `shape` skill and an old `plan` skill
   both exist, offer to remove the `plan` one, because it is a managed package
   the kit renamed rather than the person's own work. Where neither exists,
   the update removed the old skill without adding the new one: run the add
   command from the monthly step, then read the skill folder back and carry on
   only once `shape` is there. Where only `shape` exists, there is nothing to
   do.

2. Point the command forward. Rewrite the command list in the project's
   AGENTS.md as "Bringing the project's instructions up to the current names"
   below says, rather than asking the person to do it. Then say once that
   `/shape` is the command that turns an idea into a ready piece, that it does
   everything `/plan` did, and that a saved note or shortcut typing `/plan`
   still needs changing by hand. The full update command is in the monthly
   step above.

Record the tidy-up in the changelog as a dated line.

## Migrating a masterplan written with four build paths

Run this on any visit that finds, in the build-path section of
`masterplan.md`, a `Required controls:` line, an `Outside help:` line, or a
`Path:` of `Build with expert help` or `Professional-led`. It is idempotent: a
section whose fields are Path, Why, Sensitive areas, Accepted, Recheck when
and Last checked, with a `Path:` of one of the three current names, gets
nothing here, and a second visit after the rewrite finds exactly that.

The kit went from four build paths to three. The two most careful paths asked
who should own the build. The path is now decided by what the work touches,
and a masterplan names each sensitive area with the one caution that has to
happen there. Nothing the person decided is lost: the old fields carry across,
and every accepted risk stays word for word.

1. Work out the new section before saying anything. `Explore privately` and
   `Build and run it` keep their name. `Build with expert help` and
   `Professional-led` become `Build with care`. `Outside help: none`
   contributes nothing. `Outside help: <level>, for <scope>` becomes one line
   under `Sensitive areas`: the scope named as one of the six areas in
   fit-check.md where it plainly is one, what in the tool touches it, the help
   level as its caution, and `not yet done` unless the changelog records that
   it happened. Each `Required controls` entry that protects a place in the
   tool (a review of who can see what, a backup, a rehearsal on a copy, a
   managed provider) becomes a line for the area it protects, or joins the
   line the scope already made where they are the same area. A control that
   names no area (secrets out of code, destructive actions stop for approval,
   a pull request with a check) is a standing rule of the kit and of the save
   route, so it leaves the block; say so in the changelog line. `Accepted`,
   `Recheck when` and `Last checked` are copied word for word, including an
   old line that says the path moved, because they are history and a rewrite
   is not a check.
2. Say this, then show the section as it is and as it would be, one above the
   other: "Your masterplan's build-path section was written when the kit had
   four build paths. It now has three, and the path is decided by what the
   work touches rather than by who owns the build. I can rewrite the section
   to the new shape. Every accepted risk stays exactly as written, and nothing
   else in the masterplan changes. Shall I apply it?"
3. Apply on approval, as part of the visit's saved change. Where a control or
   a help line cannot be matched to one of the six areas, keep its words as
   they are on their own line under `Sensitive areas` and say so, rather than
   guessing; the next fit check tidies it.
4. Where the person declines, leave the section untouched. Say that the kit's
   skills now look for `Sensitive areas`, so a control recorded in the old
   fields may be missed until the section is rewritten, and that the offer
   comes back next visit.

Record the migration in the changelog as a dated line naming the old path,
the new one, and any control that left the block. Where an old `Accepted:`
line says the path moved, the changelog line says that acceptance predates the
rename, so a later reader does not go looking for a path the kit no longer
has.

## Bringing the project's instructions up to the current names

Run this from either rename migration. A project's AGENTS.md is project-owned
and no update touches it. But the line that lists the commands is the kit's own
template text, and a person made to fix it by hand after every rename will stop
updating. So the kit does it for them, with approval:

1. Find the line that lists the commands. In the foundation template it begins
   `- Commands:` and names all nine. Where it names `start`, replace it with
   `setup-ai-build-kit`. Where it names `plan`, replace it with `shape`. Where
   `queue` is missing, add it after `implement`. Where the sentences nearby
   give an older count of commands or skills, make them nine and fourteen.
2. Show the change and apply it on approval. Say what changed in one sentence.
3. Where the file lists the commands in its own words and the line cannot be
   recognised, leave the file alone and say which name needs changing, so the
   person edits one line rather than reads a diff.

Record it in the changelog with the tidy-up that called it.

## Tidying a project founded from a whole copy of the kit

Run this on any visit on the shared route that finds the leftovers below. It
is idempotent: a project that has none of them gets nothing here.

A project founded from a whole copy of the kit brought the kit's own generated
adapters with it: `.claude/commands/<name>.md`, `.cursor/commands/<name>.md`
and `.gemini/commands/<name>.toml`. Only the kit's repository and the Claude
plugin need those. On the shared route the installer's own symlinks under
`.claude/skills/` do their job, and the installer never refreshes them because
it does not know they exist. So every command appears twice in Claude Code, and
a command the kit has renamed lives on in a file nothing will ever remove.
Deleting the files by hand in one project fixes one project, which is why this
is a step here rather than advice:

1. Find the kit's adapters. An adapter is recognised only by the generated
   marker on its first lines, which names `.agents/skills/` and
   `build-adapters.sh`. Never by its name: a command file the person wrote
   themselves has no marker and is never touched. List every file under
   `.claude/commands/`, `.cursor/commands/` and `.gemini/commands/` that
   carries the marker.
2. Find retired skill folders. A folder under `.agents/skills/` counts only
   when it carries one of the kit's former names, `build`, `start` or `plan`,
   and the lockfile does not list it. Any other folder there is the person's
   own and is left alone.
3. Show the list and say what removing it does: each command appears once,
   and the renamed command goes. Remove on approval, and remove the empty
   folders too. Where the files are tracked, the removal is part of the
   visit's saved change.
4. Record a changelog line saying what was removed and why.

## Quarterly, or before a handover

Everything above, plus:

1. Run sync.
2. A hot-spot review, not a general architecture pass. Look first at: areas
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
3. Review project skills for instructions that no longer pay their way and
   offer to remove them. AGENTS.md was already checked in the monthly pass;
   do not repeat its trim offer or cut anything without the person's yes.
4. Run ship's evidence run, scoped by the build path and its sensitive areas.
5. The ownership and graduation check: can the team still explain the main
   flows? Can it verify important changes without reading code? Can it
   identify where data, secrets, service owners, and bills live? Can it
   recover, or use the manual fallback? Has reliability, complexity, or
   reliance grown? Are the named sensitive areas and their cautions still
   accurate? Name a new area when the answers require it. Where an area was
   named or given a boundary since the last full visit, offer the boundary
   rule in `.agents/skills/setup-ai-build-kit/references/boundary-rules.md`,
   and change or remove an existing rule with its area, on a yes. An area comes off
   only when a genuine redesign has removed what put it there; an acceptance
   drops its caution and leaves the area named. Where the person asks for a
   handover, or a caution names a person the team has to find, prepare
   `.agents/skills/ship/templates/handover.md` for the area or the whole
   build.
6. Put today's date on the `last-full-pass` line as well as the
   `last-light-pass` line in `.ai-build-kit-maintenance`.

## When a tool's time is over

Own the ending. Export the data somewhere the team can reach it, in a
documented, usable format, and tell the people who relied on the tool.
Revoke access, rotate or delete credentials, confirm any retention
obligations, remove scheduled jobs and webhooks, switch off the services so
nothing keeps billing quietly, confirm billing has actually stopped, and
archive the repo. An abandoned tool with real data in it is a liability; a
retired one is finished.

## Done when

The findings are reported, the approved changes are applied and recorded, today's visit is written into `.ai-build-kit-maintenance`, and the calendar says when the next visit is due.
