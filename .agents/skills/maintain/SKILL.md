---
name: maintain
description: Make the project true and healthy, at any time. Every visit trues the records against what actually happened and compares the live copy with main without changing it. The monthly and quarterly upkeep run only when due, and the visit also holds handovers and retirement. Trigger when it has been a while, after work done outside the skills, before a handover, and when a tool is being retired. A session that died part-way goes to what-now first. Do not use for building, repairing, or planning.
---

# Maintain

Small regular maintenance is what keeps the rare big problem from arriving. Report findings before applying anything beyond routine updates.

This command can run at any time. Every visit makes the project true again.
The monthly and quarterly parts run only when they are due.

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
   with the truing's summary and step 4. A monthly or quarterly part that runs
   saves its own changes the same way at its end, on top of the truing's save.
4. Finish a kit update, as "Finishing a kit update" below says. This runs on
   every visit, a records-only one included, since the visit that ran the
   update was still following the release it replaced. Where the monthly part
   runs on this visit, its step 5 runs this after the update; do not run it
   twice on the same visit.

## Monthly, when due

1. Read this skill's `VERSION` file, which is the version this project holds.
   Then ask for the latest published one with
   `gh api repos/gwpicard/ai-build-kit/releases/latest --jq .tag_name`. Ask
   that endpoint and no other: it is the only one that cannot answer with a
   draft or a prerelease, while `gh release list` puts an unpublished draft in
   its first row for anybody who can see the repository, which would offer an
   update that does not exist yet.

   Say both numbers, every monthly visit, whichever way they compare: "This project
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
   does, count its entries against the eleven names and say which are
   missing. A short installation means a skill the kit renamed or added never
   arrived. The version file cannot show this, because the same update that
   drops a skill rewrites the version, so the count is the only sign.
   An entry under one of the kit's former names, such as `fix`, `queue`,
   `sync` or `ship`, is an old skill the installer kept. "Migrating a project
   installed before the six commands" below removes it.
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
   version step 1 read from `releases/latest`, and that the count from step 3
   is now eleven. When the shared installation did not have `screen-check`
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
   nothing else to say it happened. Then run "Finishing a kit update" below,
   with `--monthly`; it finds what the six commands left, on disk too.
   Whenever the build-path section of
   `masterplan.md` carries a `Required controls:` or `Outside help:` line, or
   a `Path:` value the kit no longer uses, also run "Migrating a masterplan
   written with four build paths" below; that too is decided by what the
   masterplan says rather than by which update this is. Whenever a `plan.md`
   is at the project root, run "Moving a plan.md into issues" below. That is
   decided by what is on disk, so a project that missed the update which
   first needed it still gets it.
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
   clean checkpoint. That leaves the folder of a skill the kit has since
   retired, so run "Tidying a project founded from a whole copy of the kit"
   afterwards too. A Claude
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

An update refreshes the kit's skills and nothing else. The visit that runs it
is still following the maintain text of the release it replaces, which knows
nothing of what the new release changed. So what an update leaves behind is
finished here, on the next visit, whatever day it falls on. It never waits for
the monthly part.

1. Read what is left. From the project root, run `python3 <installed maintain
   skill>/scripts/upgrade-check.py`, with `--monthly` added when the monthly
   part runs on this visit. It changes nothing. It prints one line for each
   thing left, and its exit code decides. Exit 0 means no step is left. Then
   offer nothing; step 2 still names unseen informational lines. Say nothing
   else about the update, except one line for each `declined` step
   below. On a monthly visit, also say in one line how many `pointer` lines
   end in `left as written:`, and in which file. Exit 1 means at least one
   step is left, and the rest of this section runs. Exit 2 means the check could not run: say so in one line and
   carry on with the visit.
2. Make the full offer only on the first visit that finds a leftover and on
   monthly visits. Read `upgrade-offered|<installed VERSION>` in
   `.ai-build-kit-maintenance`. After showing the offers, record that line,
   keeping the other lines. On other visits with the same version, say only:
   "The kit update is not finished. The earlier /maintain offer still stands."
   Apply nothing until the person answers that offer. The automatic helper
   step still runs after the checkpoint. Do not repeat `mention` or `left`
   lines on those visits. When exit 0 has only those lines, name them once
   and record the same line too, so a project with no actionable step still
   hears about its own guidance.

   Say once, in the reply that makes the offers below, where a line names a
   retired skill or command, or `setup-hosting` as missing: "The kit now has
   six commands. /fix and /queue are part of /shape and /implement, /sync is
   part of /maintain, and /ship is now /setup-hosting. Nothing you built has
   changed." Add that a saved note or shortcut typing an old command still
   needs changing by hand.
3. Put the helper in place. A `helper` line is the kit's own machinery, so it
   needs no question: on the clean checkpoint the truing's save leaves, run
   the check with `--apply helper`, as "Adding the plan printout helper" below
   says.
4. Make every other offer in one reply, each in plain words, and change
   nothing without a yes to that offer, except recovery of an already approved
   update:
   - `installer` lines: the installer's own removal, as "Migrating a project
     installed before the six commands" below says.
   - `missing` lines: recover with the add command from the monthly part's
     update step after the update approval already given. Do not ask again
     for that recovery. Where no update was approved, offer the add first.
   - `folder`, `adapter`, `kitcopy` and `hook` lines: `--apply remove`, as
     "Tidying a project founded from a whole copy of the kit" below says.
   - `commands` and `pointer` lines that show a new form: `--apply commands`
     and `--apply pointers`, each shown old and new, as "Bringing the
     project's instructions up to the current names" and "Pointing the records
     at a skill by name" below say.
   - `commands` lines ending in `left as written:`: propose and apply an agent
     edit as "Bringing the project's instructions up to the current names"
     says. A linked file stays untouched.
   - `settings` lines: `--apply settings`, as "Adding the kit's newer safety
     rules" below says.
   - a `template` line: `--apply template`. It rewrites one sentence the kit
     itself wrote into the masterplan's "How it stays running" comment, which
     still names the old launch command, and nothing else in the file.
5. After each step, run the check again, and carry on only once that step's
   lines are gone. Where they remain, say so in one line and carry on with the
   other steps. Every step that changes a file waits for the clean checkpoint.
   While the person's own uncommitted work is there, make the offers and say
   that they wait, as "Every visit" says.
6. Lines starting `mention` name a line of the person's own in AGENTS.md or
   masterplan.md that still names a retired command, such as a note of when
   they run one. Those lines guide later sessions, so they are not history.
   Name each one once, in the reply that makes the offers, as the person's to
   change, and never rewrite one. Name `left` lines once in the same reply.
   Keep the named lines in the visit's changelog record. Before naming one,
   read that record: do not repeat a line already named, even on a monthly
   visit, unless its text has changed.
   The changelog is the only history, and the check never reads it.
7. Where the person says no to an offer, run the check with `--decline` and
   that step's name, such as `--decline installer` or `--decline
   commands,template`. It records the no. On a later visit without
   `--monthly`, that step prints as a `declined` line: say it in one line,
   such as "The old skills are still installed, as you chose; the next monthly
   visit offers their removal again." Make the full offer again only on a
   monthly visit. A declined safety rule follows the rule in "Adding the kit's
   newer safety rules" instead.
8. Record one dated changelog line that says what was done and what was
   declined. Save it with the visit's other changes, through the save route.
9. Run the check once more at the end of the visit. Exit 0 ends the update,
   and a later visit says nothing about it. Exit 1 means a step is still left:
   say which in one line, and that the next visit finishes it.

Where the harness cannot run the check, say so in one line and follow the
sections below by hand, each as it says.

## Adding the plan printout helper

`plan.local.md` is written by `.agents/tools/plan-refresh.sh` in the project.
That helper ships inside the setup-ai-build-kit skill and founding copies it
in. A project founded before that has no copy, unless it came from a whole copy
of the kit, and then its copy may be older. An update refreshes skills and
nothing else, so the helper would never arrive.

"Finishing a kit update" runs this on any visit whose check prints a `helper`
line, on the clean checkpoint the truing's save leaves, and after the update
where the person approved one. Its `--apply helper` runs `sh <installed
setup-ai-build-kit skill>/scripts/place-plan-helper.sh` from the project root.
That adds the helper when it is missing, replaces a copy that differs from the
installed one, and changes nothing when the copy is current, so it is safe on
every visit.

Where it added the helper, say one sentence: "I have added the helper that
prints your list of pieces, so /what-now and /implement read what is
ready from it rather than from the issues by hand." Where it replaced one, say
that the helper was brought up to date, and that any change made to the old
copy by hand was replaced too and is kept in the checkpoint saved first. Where
it made the helper runnable again, say so, since that is a change to save. Save either change with the visit's
other changes and add a dated changelog line. When it changed nothing, say
nothing. Where the harness cannot run the script and the project has no
helper, copy the installed skill's `templates/foundation/plan-refresh.sh` to
`.agents/tools/plan-refresh.sh` by hand.

## Adding the kit's newer safety rules

Founding copies the kit's Claude Code settings into `.claude/settings.json`
once, and no update touches that file again. A project founded before the kit
learned a new way to write a dangerous command keeps the older rules, and a
command the older rules miss goes through with nothing to stop it. The same
holds for the question Claude Code asks before a merge. So the visit offers
the missing rules, once.

The script `<installed maintain skill>/scripts/settings-rules.py` makes the
comparison, so nobody edits the JSON by hand. The check in "Finishing a kit
update" runs it on every visit, and its `settings` lines are what it found.

1. Where the project has no `.claude/settings.json`, this step ends. Otherwise
   the script reads its `permissions.deny` and `permissions.ask` lists, and
   the ones in the installed setup-ai-build-kit skill's
   `templates/foundation/claude-settings.json`. Take the rules from that file,
   never from memory.
2. It lists each rule the template holds and the project lacks, in three
   groups. It leaves out a group when its condition does not hold, since the
   person may have removed a rule on purpose. When no rule is left, say
   nothing.
   - A rule in `deny` that names both `git push` and `main`. Always offered.
   - A rule in `deny` that stops a force push or a forced delete. Offered only
     while the project still holds `Bash(git push --force:*)` for a force
     push, or `Bash(rm -rf:*)` for a forced delete.
   - A rule in `ask`, which makes Claude Code ask before a merge. Always
     offered.
3. It reads the `push-rules-declined` line in `.ai-build-kit-maintenance`, if
   there is one. Where it already lists every missing rule, the earlier no
   stands, the rules print as `declined`, and you say nothing more than the
   one line "Finishing a kit update" gives a declined step.
4. Offer the change once, in one reply. Name the rules it adds, and say in
   plain words what they stop: a push to `main` written with an option before
   the remote, such as `-q`, or as `HEAD:refs/heads/main`; a force push with
   the option at the end; a forced delete written as `rm -fr`; a merge with no
   click from the person. Say that it adds lines to those lists and changes
   nothing else in the file. Say too that the `setup-ai-build-kit` skill's
   `references/blocked-commands.md` lists the spellings the rules still cannot
   catch. Ask for a yes.
5. On a yes, run the check with `--apply settings`. It adds only the missing
   rules to the end of the list each came from. It keeps every other entry
   and setting as it is, even an older rule the new ones cover, and it writes
   nothing unless the file still reads as valid JSON with every earlier entry
   in it. Save it with the visit's other changes and add a dated changelog
   line.
6. On a no, change nothing. Run the check with `--decline settings`, which
   records the no as one line in `.ai-build-kit-maintenance`, replacing any
   earlier one:
   `push-rules-declined|<YYYY-MM-DD>|<the rules offered, separated by " ; ">`.
   A later visit offers again only when a new release adds a rule that line
   does not list.

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

2. Move a `plan.md` into issues, as "Moving a plan.md into issues" below says.

3. Point `/build` forward. Say once that the old `/build` command has become
   two: `/shape` to shape a new idea into a ready piece, and `/implement` to build
   one. Nothing the person saved is lost; only the command names changed.

Record the migration in the changelog as a dated line.

## Moving a plan.md into issues

Run this on any monthly visit that finds a `plan.md` at the project root, for as long
as it is there. It used to run only on the visit that first brought in
`/shape` and `/implement`, and a project that missed that visit kept its
`plan.md` for good, with nothing to say its pieces were never picked up.

A project founded without the GitHub tool signed in kept its pieces in
`plan.md`, which nothing reads any more. Where the file is plainly something
else of the person's, such as their own notes, leave it and say nothing.
Otherwise say so plainly and offer to move its rows into issues: guide the
GitHub setup first if it is not ready (the `setup-ai-build-kit` skill's
`references/manual-setup.md`), open one issue per row in the shape the
`setup-ai-build-kit` skill's `references/pieces.md` describes, carry each
row's subjects across as labels, label a shaped row `ready`, and label an
unshaped one with the question it still waits on. Do this on the clean
checkpoint, name what moved, and only then remove `plan.md`. Record the move
in the changelog as a dated line.

Where the person declines, leave `plan.md` untouched and say its pieces are not
picked up until they are moved. Nothing records the no, so the offer comes back
on the next visit that still finds the file. Say that too, in the same reply.

## Pointing the records at a skill by name

"Finishing a kit update" runs this on every visit, through its check's
`pointer` lines. A project founded before the kit named its pointers
by skill carries lines in AGENTS.md and masterplan.md that name a skill's file
by its place in the project's `.agents/skills/` folder. A project installed
for Claude Code alone, or through a plugin, has no such folder, so the line
opens nothing. The current form names the skill and the path inside it: the
`setup-ai-build-kit` skill's `references/pieces.md`. An update refreshes the
skills and never touches these two files, so the old lines stay until the
visit changes them.

1. The check runs `python3 <installed maintain
   skill>/scripts/old-skill-pointers.py` from the project root, and prints
   each of its lines with `pointer` in front. The script reads only those two
   files and prints one line for each old pointer it finds, and nothing when
   there is none. It finds a pointer into one of the kit's skills under today's name
   or one it had before, such as `start` for `setup-ai-build-kit`. It also
   finds a pointer that already names its skill, where that skill is one the
   kit has retired. A pointer to the handover template in `ship` now names
   the `maintain` skill, since handovers moved there. A project's
   own skill, a placeholder such as `<name>`, and a mention of the folder
   itself are never found. When it prints nothing, say nothing.
2. A line ending in the new form is one the script can rewrite: the pointer
   stands alone, as a whole code span or a bare path, and the skill still has
   the file. A line ending in `left as written:` gives the reason it cannot,
   such as a pointer inside a code block, a command or a link, where a
   rewrite would break the line. Those are never rewritten. A rewrite changes
   the pointers and nothing else in the file, line endings included.
3. Offer the rewrite once, in one reply: say how many lines in which file, that
   each keeps its sentence and only the pointer changes, and show one line
   before and after. Name each line left as written, with its reason, as one
   the person may want to change by hand. Wait for the person's yes. Where the
   script finds only lines left as written, offer nothing: say in one line how
   many there are and in which file, since they come back on every monthly visit
   until the person changes them.
4. On a yes, run the check with `--apply pointers`, which runs the script
   with `--apply`. Then run it again without, and carry on only once no line
   it prints ends in a new form. Save the change with the visit's other
   changes and add a dated changelog line.
5. Where the person says no, leave both files as they are, and record the no
   as "Finishing a kit update" says. The offer comes back in full on the next
   monthly visit that still finds an old pointer.

Where the harness cannot run the script, leave the files as they are and say
that the check did not run. A rewrite by hand cannot tell a pointer that stands
alone from one inside a command, and getting that wrong breaks the person's
line.

## Migrating a project founded before the setup-ai-build-kit rename

Run this on any monthly visit that finds a `start` skill installed, or no
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

Run this on any monthly visit that finds a `plan` skill installed, or no `shape`
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

## Migrating a project installed before the six commands

"Finishing a kit update" runs this on any visit whose check finds a `fix`,
`queue`, `sync` or `ship` skill installed, no `setup-hosting` skill, or a
command list in AGENTS.md that names one of the four. It is idempotent: a
visit that finds the six commands and the list already current does nothing
here and says nothing.

The kit cut its commands from nine to six. `/fix` folded into `/shape` and
`/implement`, `/queue` into `/implement`, and `/sync` into `/maintain`. `/ship`
was renamed `/setup-hosting`. Every rule moved with its job, so nothing the
person built or saved changes. An update brings the new skills, but the shared
installer keeps an old skill it still lists, and nothing updates the project's
AGENTS.md. So the old commands stay on offer until this step runs.

1. Read what is left. The check in "Finishing a kit update" runs `python3
   <installed maintain skill>/scripts/kit-leftovers.py` from the project root
   and prints its lines. It prints one line for each thing left behind, and
   nothing when nothing is.
2. Remove the old skills the installer still lists. A line starting
   `installer` names a skill under a former name that `skills-lock.json` lists
   as the kit's. It is a managed package the kit retired, not the person's own
   work, so offer to remove it with the installer, naming each one in a single
   command such as `npx skills remove fix queue sync ship`. The installer
   removes the folder, every link to it, and its lockfile entry. On a yes, run
   it, then run the check again and carry on only once no `installer` line
   is left and the lockfile lists the eleven kit skills and none of the former
   ones. A lockfile may list other people's skills too, so its length proves
   nothing. Never delete one of these folders
   by hand, since the lockfile would still list it.
3. Recover a missing new skill. A line starting `missing` names one of the
   eleven that is not installed, such as `setup-hosting` after an update that
   removed `ship` without adding its new name. Run the add command from the
   monthly step, then run the check again and carry on only once no
   `missing` line is left.
4. Lines starting `folder` or `adapter` are leftovers the lockfile does not
   list. "Tidying a project founded from a whole copy of the kit" below
   removes them, after its own approval. A line starting `left` names
   something that looks like a leftover but is never removed: a folder not
   recognised as the kit's, or one whose real place is outside the project.
   Name it once, beside a removal the visit offers, as the person's to keep or
   remove.
5. Rewrite the command list in the project's AGENTS.md as "Bringing the
   project's instructions up to the current names" below says. Lines starting
   `commands` show the change.
6. On the Claude Code plugin route, the plugin update itself replaces the
   commands: the new release offers the six and nothing else, and no old skill
   is left in the project. Steps 2 to 4 find nothing there. The AGENTS.md list
   still needs step 5.
7. A mention of `/fix`, `/queue`, `/sync` or `/ship` in `CHANGELOG.md` is
   history. It says what happened at the time, so leave it. The changelog is
   never rewritten. A line in AGENTS.md or masterplan.md is different: it
   guides later sessions. The kit's own sentence there is the check's
   `template` line, and a line of the person's own is a `mention` line, named
   once and never rewritten. A pointer to a retired skill's file is a
   different thing again, because it opens nothing now. "Pointing the records
   at a skill by name" below finds those and follows each rule to its new
   home.

Where the person says no to a removal, leave it. Say that the old command
stays on offer beside the new one until it is removed, and record the no as
"Finishing a kit update" says, so the next monthly visit offers it again.
Where the harness cannot run the script, read
the lockfile and the two skill folders by hand for the four names, and leave
the AGENTS.md list for the person, naming each word to change.

Record what changed in the changelog as one dated line.

## Migrating a masterplan written with four build paths

Run this on any monthly visit that finds, in the build-path section of
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

Run this from any rename migration. A project's AGENTS.md is project-owned
and no update touches it. But the line that lists the commands is the kit's own
template text, and a person made to fix it by hand after every rename will stop
updating. So the kit does it for them, with approval:

1. Find the line that lists the commands. In the foundation template it begins
   `- Commands:` and names all six. Where it names `start`, replace it with
   `setup-ai-build-kit`. Where it names `plan`, replace it with `shape`. Where
   it names `ship`, replace it with `setup-hosting`. Where it names `fix`,
   `queue` or `sync`, take the name out, since its command folded into
   another. Bring the `- Background skills:` line to the five the template
   names. Where the sentences nearby give an older count of commands or
   skills, make them six and eleven.
2. The script `<installed maintain skill>/scripts/kit-leftovers.py` does this
   from the template that came with the update. Its `commands` lines show each
   change, old and new. It rewrites a list only when it holds the kit's names
   and nothing else, in the template's shape. A line ending in `left as
   written:` is one it will not change, with the reason and the suggested
   line: a name in the list that is not one of the kit's, or words of the
   person's own inside it. When the commands line is left as written, the
   counts above it are left too.
3. Show the change and apply it on approval, by running the script with
   `--rewrite-commands`, which the check's `--apply commands` does. It
   changes those lines and nothing else in the file,
   line endings included. Run it again without, and carry on only once no
   `commands` line offers a change. Say what changed in one sentence.
4. When the script cannot rewrite a command list, show the old lines and a
   proposed replacement. Name the six commands and the five background skills,
   eleven in all, using the installed founding template. Keep the rest of the
   paragraph's meaning and the person's own sentences. Say: "The command list
   still names old commands. Shall I replace it with this wording?" On a yes,
   apply the replacement as an agent edit to those lines only, then run the
   check again. Never ask the person to edit the command list by hand. A linked
   file stays untouched. Where the harness cannot run the script, use the
   same proposal and approval before editing.
5. On a no, record `--decline commands` as "Finishing a kit update" says.
   Name the declined command-list lines once and keep them in the visit's
   changelog record, using the same rule as a `mention` line. The update stays
   unfinished while a command list names a retired command, unless the person
   declined it, even when the installed version already matches the release.

Record it in the changelog with the tidy-up that called it.

## Tidying a project founded from a whole copy of the kit

"Finishing a kit update" runs this on any visit, on the shared route or after
a manual update, whose check finds the leftovers below. It is idempotent: a
project that has none of them gets nothing here.

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
   carries the marker, and every generated skill folder for a name the kit
   no longer has, such as a `grilling` folder in Claude's skills folder.
2. Find retired skill folders. Look in both `.agents/skills/` and
   `.claude/skills/`, since an installation for Claude Code alone keeps its
   skills only in the second. A folder there counts only
   when it carries one of the kit's former names, `build`, `start`, `plan`,
   `grilling`, `fix`, `queue`, `sync` or `ship`, and the lockfile does not
   list it under any source, and its `SKILL.md` carries that name and a
   description one of the kit's releases gave it. Any other folder there is
   the person's own and is left alone, a skill of theirs under one of those
   names included. A former name the lockfile lists as the kit's is the
   installer's to remove, in "Migrating a project installed before the six
   commands" above.
   A recognised name and description identify a possible leftover. Removal
   also requires that every remaining file in it matches a released copy for
   that skill. A changed file or a personal addition keeps the whole folder,
   reported as `left`. The script checks that again before removal.

3. Run `python3 <installed maintain skill>/scripts/kit-leftovers.py` from the
   project root. Its `adapter` and `folder` lines are the two lists above,
   found by these rules. A generated skill folder under `.claude/skills/`,
   `.cursor/skills/` or `.gemini/skills/` is an adapter too, when its
   `SKILL.md` carries the marker and its name is one the kit no longer has.
   Nothing whose real place is outside the project is listed for removal, and
   a link is never followed: at most the link itself goes. A generated command file for a retired command is
   listed on every route, since it opens nothing. One for a current command
   is listed only on the shared route, where the installer already reaches
   that command.
4. Find the kit's own files a whole copy brought. When the project's
   `.ai-build-kit-version` names an older release than this skill's `VERSION`,
   the copy's kit files are from that older release, and no update refreshes
   them. The script lists each of `agent-plugin/`, `.claude-plugin/`,
   `WORKFLOW.md`, `.agents/guard/blocked-commands.md`,
   `.agents/tools/build-adapters.sh` and `.ai-build-kit-version` as a
   `kitcopy` line only when every byte matches a copy a release shipped at the
   same path, read from `kit-released-copies.json` beside it. A changed one
   gets a `left` line and stays: it may hold the person's own words. The
   kit's README from a whole copy is only ever named, as the person's to
   replace with one about their tool.
5. A whole copy also brought `.agents/hooks/session-end-sync.sh`. A `hook`
   line means it matches an older copy a release shipped, so the one this
   release ships replaces it on `--remove`. One that was changed by hand and
   still names a retired command gets a `left` line: say once that
   `/what-now` and `/maintain` do that job now, and leave the file as it is.
6. Show the list and say what removing it does: each command appears once,
   the renamed or folded command goes, and the kit's own files stop
   describing an older kit. Remove on approval, by running the check with
   `--apply remove`, which runs the script with `--remove`. That removes only
   what it listed and any folder that leaves empty, and checks each kit file
   byte for byte again first. Run the check again, and carry on only once it
   lists none of these kinds. Where the files are tracked, the removal is part
   of the visit's saved change. Where the harness cannot run the script,
   apply only the generated-marker rule for adapters by hand. Leave retired
   folders, the kit's files and the hook as they are, since their released
   bytes cannot be checked by reading their names.
7. Record a changelog line saying what was removed and why.

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
