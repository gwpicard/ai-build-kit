# Monthly, when due

1. Finish the kit update as `kit-update.md` directs, with `--monthly`. It owns
   the route, approval, version and project-check steps. Do not replace the
   project's own files.
   Before replacing skills, follow `latest-release.md`'s local-edit check and
   require its file-specific approval where needed.
   Use `claude plugin marketplace update ai-build-kit` then
   `claude plugin update ai-build-kit@ai-build-kit --scope <scope>` for Claude.
   For an Agent Plugins installation, use its update command or offer the
   approved Release folder replacement. For shared skills, run
   `npx skills add gwpicard/ai-build-kit`; never `npx skills update`, which
   drops a renamed skill without warning.
2. Where the check prints a `planfile` line, read `plan.md`. The person's own
   notes are left alone. The kit's old list gets the `planfile` sentence; with
   approval, on the clean checkpoint, open one issue per row as pieces.md says,
   with its subjects, `ready` or its question label, then remove `plan.md` and
   add a dated changelog line. A no is not recorded, so the offer returns.
3. Re-read the reach check and note whether
   dependency-cruiser or the built-in import reader is available.
4. Run the risk-area check installed at founding. Where it names a
   missing path or an unassigned folder, ask which area it belongs to, or
   `none`, and update the map on the answer.
5. Update dependencies and check for known vulnerabilities. Report what
    changed; apply with approval.
6. Once live, read the error alerts and bills. Anything real becomes a
    piece: sort it with the `triage` skill and write it in the `records` skill's
    piece shape.
7. Backups are checked by `/setup-hosting`'s later run, not here. Where the
    changelog records no backup or restore check in the last month on a live
    project with data, name that gap in one line and offer that run. Confirm
    the named operational owner still holds the role, and that no critical
    service or credential is tied to someone who has left.
8. Where use or reliance has grown, run `fit-check` again before the rest
    of the monthly part.
9. Run `scripts/standing-lines.sh` from the project root. Read
    AGENTS.md too for a directory layout, dependency list, architecture
    overview or style rule a check could enforce, and for lines about tools or
    steps the project has dropped. Exit 1, or any such content, earns one
    offer using the measured count and what can go: "The standing instructions
    have reached 240 lines, and 30 of them describe the folder layout the code
    already shows. Shall I trim them?" Never invent removable content. Cut
    nothing without approval. Otherwise say nothing.
10. Run "Offering a move onto a
    recipe" in `recipe-move.md` beside this file.
11. Load the `quality-checks` skill's `references/stale-branches.md` and run its script. Never remove a
    branch.
12. Record the visit: today's date on `last-light-pass` in
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
