---
name: maintain
description: The service visit for AI Build Kit updates, project upkeep, handovers, and retirement. Trigger monthly for the light pass, quarterly or before any handover for the full one, and when a tool is being retired. Composes sync and the evidence run instead of repeating them. Do not use for building, fixing, or planning. Type this command when you want it; it never starts on its own.
disable-model-invocation: true
---

# Maintain

Small regular maintenance is what keeps the rare big problem from arriving. Report findings before applying anything beyond routine updates.

## Monthly, light

1. Read this skill's `VERSION` file and compare it with the latest stable public
   Release at `gwpicard/ai-build-kit`. If a newer version exists, read its notes
   and say: "A newer AI Build Kit is available. It refreshes the installed
   workflow skills. Your tool, project records, and project instructions remain
   yours." Give the version and a short summary, then wait for approval.
2. Before registering or changing the kit, require the clean checkpoint used by
   the current build path. For a shared skills installation, check whether any
   AI Build Kit skill has local edits. Project-specific rules belong in
   AGENTS.md. If such edits exist, explain them and propose moving the durable
   rule there. Wait for approval rather than replacing an edit silently.
3. Identify how this project receives AI Build Kit. Check whether
   `skills-lock.json` records the eleven skills from `gwpicard/ai-build-kit`.
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
     `npx skills update start build fix ship sync maintain what-now grilling change-triage section-builder second-opinion -p`.
   - When no route is present, this is an older installation. After
     approval, run `npx skills add gwpicard/ai-build-kit` and let the person
     choose the coding agents they use. This registers and refreshes the
     existing skills, so do not run a second update on the same visit.

   Do not update unrelated plugins, project skills, or global skills.
5. For the shared route, confirm that this skill's `VERSION` matches the public
   Release. For the Claude route, confirm that `claude plugin list --json`
   reports the matching version without the leading `v`. Claude loads an
   updated plugin after `/reload-plugins` or the next session, so say that
   plainly. For an Agent Plugins installation, confirm the version in the
   installed `agent-plugin/plugin.json` and in that folder's
   `skills/maintain/VERSION`. Run the project's own check and record the kit
   version in the changelog with the saved change. The foundation created by
   start, including AGENTS.md, README.md, project records, environment files,
   application code, and the project's check, stays project-owned.
6. If the normal route is unavailable, use the latest public Release as the
   fallback source. A shared installation may replace only the eleven AI Build
   Kit skill folders after the same approval and clean checkpoint. A Claude
   plugin installation keeps its current enabled version when the marketplace
   cannot be reached. Confirm that version with `claude plugin list --json`,
   tell the person the update did not happen, and retry when the marketplace is
   reachable. Do not create a second installation or claim that the project
   checkpoint can restore Claude's plugin cache. If the plugin is no longer
   enabled, stop and ask the person to reinstall it after the marketplace is
   reachable.
7. Update project dependencies and check for known vulnerabilities. Report what changed; apply on approval.
8. Once live: read the error alerts and the bills. Anything real becomes a piece on plan.md, for build to take.
9. Verify backups still run where the tool has any. Confirm the named operational owner from the masterplan still holds that role, and that no critical service or credential is tied to someone who has left.
10. Check whether use or reliance has grown enough that the fit check should run again; if it has, run it before anything else this visit.
11. Record the visit. In `.ai-build-kit-maintenance` at the project root, put
    today's date on the `last-light-pass` line, written as YYYY-MM-DD. If that
    file is missing, create it with a `founded` line holding the date
    masterplan.md was first saved, then the two pass lines. If the project has
    no `.agents/hooks/session-start.sh`, copy it from the installed start
    skill's `templates/foundation/session-start.sh`. Then say one sentence: "I
    have recorded today's visit, so a session will not remind you again until
    the next one is due." If the project's Claude settings existed before AI
    Build Kit did, add that the reminder cannot appear by itself there, and that
    `/what-now` reports it when asked.

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
