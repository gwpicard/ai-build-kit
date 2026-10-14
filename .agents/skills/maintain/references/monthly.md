# Monthly, when due

1. From the project root, run `python3` with this skill's
   `scripts/upgrade-check.py --latest --route` and give its `say` lines. Exit
   1: a newer release is out; summarise its notes and wait for approval. Exit
   0: nothing newer. Exit 3: the check did not happen, so never call the
   project up to date. Its `route` lines give the update command.
2. Before changing the kit, require the clean checkpoint. Where an installed
   kit skill has local edits, explain them and propose moving the lasting rule
   into AGENTS.md. Wait for approval.
3. Find how the project receives the kit. Where `skills-lock.json` records
   skills from `gwpicard/ai-build-kit`, count them against the kit's skills
   and say which are missing, as the update check's `missing` lines name them. In Claude Code, check `claude plugin list --json`
   for the enabled `ai-build-kit@ai-build-kit` plugin and its scope. Check for
   an Agent Plugins `plugin.json` naming `ai-build-kit` beside a `skills`
   folder. If more than one route is active, ask which to keep: a plugin for
   one coding agent, the shared skills installation for several.
4. Update only through that route, with the command the `route` line names:
   - Claude plugin: `claude plugin marketplace update ai-build-kit`, then
     `claude plugin update ai-build-kit@ai-build-kit --scope <scope>`.
   - For an Agent Plugins installation: the agent's own update command, or replace the
     `agent-plugin` folder from the latest Release after the same approval.
     Read its `skills` folder back: every kit skill and no former name such as
     `fix`, `queue`, `sync` or `ship`. Offer the Release replacement where an
     old folder remains.
   - Shared skills, or no route found: `npx skills add gwpicard/ai-build-kit`,
     choosing the coding agents the project already uses (`universal` puts the
     folder under `.agents/skills/`). Never `npx skills update`: it drops a
     renamed skill without a word.

   Update nothing unrelated.
5. Confirm the update: the shared route's `VERSION` matches and no kit skill
   is missing; the Claude plugin list shows the version without its `v` (it loads
   after `/reload-plugins` or a new session, so say so); an Agent Plugins
   `plugin.json` and `skills/maintain/VERSION` match. Run the project check,
   record the kit version in the changelog, and run "Finishing a kit update"
   in `kit-update.md` beside this file, with `--monthly`. The founded files (AGENTS.md, README.md, records,
   environment files, code, the project check) stay the project's.
6. Where that check prints a `planfile` line, read `plan.md`. The person's own
   notes are left alone. The kit's old list gets the `planfile` sentence; on a
   yes, on the clean checkpoint, open one issue per row as pieces.md says,
   with its subjects, `ready` or its question label, then remove `plan.md` and
   add a dated changelog line. A no is not recorded, so the offer returns.
7. Re-read the capability profile's reach-check engine against what is
   available now, by the order in the `quality-checks` skill's
   `references/reach-check.md`, and update it.
8. Run the sensitive-area check installed at founding. Where it names a
   missing path or an unassigned folder, ask which area it belongs to, or
   `none`, and update the map on the answer.
9. Where the normal route is unavailable, the latest Release is the fallback
   for a shared installation, replacing only the kit's own folders after the
   same approval. A Claude plugin keeps its enabled version when the
   marketplace cannot be reached: say the update did not happen and retry
   later. Never create a second installation. If the plugin is no longer
   enabled, ask the person to reinstall it.
10. Update dependencies and check for known vulnerabilities. Report what
    changed; apply on approval.
11. Once live, read the error alerts and the bills. Anything real becomes a
    piece: sort it with the `triage` skill and write it in the `records` skill's
    piece shape.
12. Backups are checked by /setup-hosting's later run, not here. Where the
    changelog records no backup or restore check in the last month on a live
    project with data, name that gap in one line and offer that run. Confirm
    the named operational owner still holds the role, and that no critical
    service or credential is tied to someone who has left.
13. Where use or reliance has grown, run the `fit-check` skill again before the rest
    of the monthly part.
14. Run the maintain skill's `scripts/standing-lines.sh` from the project root. Read
    AGENTS.md too for a directory layout, dependency list, architecture
    overview or style rule a check could enforce, and for lines about tools or
    steps the project has dropped. Exit 1, or any such content, earns one
    offer using the measured count and what can go: "The standing instructions
    have reached 240 lines, and 30 of them describe the folder layout the code
    already shows. Shall I trim them?" Never invent removable content. Cut
    nothing without a yes. Otherwise say nothing.
15. Unless the project explores privately, run "Offering a move onto a
    recipe" in `recipe-move.md` beside this file.
16. Load the `quality-checks` skill's `references/stale-branches.md` and run its script. Never remove a
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
