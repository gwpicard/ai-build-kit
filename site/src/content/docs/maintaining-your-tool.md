---
title: Maintenance and retirement
description: Update the kit, review the project and retire a tool.
draft: false
---

## Update the kit

`/maintain` checks for a published kit update and asks before installing it. The update refreshes the kit's skills and leaves your application, records and project checks in place. Updating replaces installed skill files, so keep project-specific rules in `AGENTS.md` rather than editing a kit skill.

The update command depends on how you installed the kit. For the shared installer, run `npx skills add gwpicard/ai-build-kit`. For the Claude Code plugin, update the marketplace and plugin with Claude's plugin commands. An Agent Plugins installation uses that agent's plugin update command. After an update, start a new session or reload the plugin where supported, then run `/maintain` again to finish the update.

## Visit the project

Use `/maintain` after work outside the kit, before a handover or after time away. Every visit checks the project records. Where a live address and a recipe are recorded, it also compares the live copy with the project's main branch; off a recipe, it says it cannot. It reports differences and offers relevant upkeep. Monthly work falls due 30 days after the last monthly pass, and quarterly work 90 days after the last full pass or when you ask for a handover. You can ask for either at any time. The visit does not change the live service.

`/maintain` records the date of each monthly and quarterly pass in `.ai-build-kit-maintenance`, so you can see when the project was last checked.

If a session stopped part-way through, start with `/what-now` to see what remains unfinished.

## Configuration

| What you want to change | Where it belongs |
|---|---|
| Project rules for the coding agent | `AGENTS.md` |
| Keys and passwords | Git-ignored files made from `.env.example`; live values belong in the host's settings |
| Risk record and accepted risks | The risk section of `masterplan.md`; see [project records and risk](/ai-build-kit/records/) |
| Hosting recipe | The `Recipe:` line in the stack section of `AGENTS.md` |
| Commands the agent must not run | The project's blocked-command list and the coding agent's own settings |

Use `/maintain` to update installed kit skills. A kit update replaces those files.

## End a tool

Before retiring a tool, `/maintain` prepares an export and reads it back, then helps you tell users. It takes access, credentials, data retention, scheduled jobs, services, billing and repository archiving one step at a time. Before each step that removes access, deletes a credential, switches off a service or archives the repository, it explains the effect and whether the step can be undone. It requires your approval for that step.

## What remains yours

You decide what the tool should do and whether a change is ready to merge. The code, records, accounts and service terms remain under your control. The kit does not host tools or keep project records for you.
