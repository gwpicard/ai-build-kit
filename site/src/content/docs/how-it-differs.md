---
title: How it differs
description: Compare AI Build Kit with six tools for AI-assisted software work.
draft: false
---
We read each tool's own files on 20 October 2026.

## At a glance

This page compares AI Build Kit with two kinds of tool:

- **Hosted app builders**, such as Replit, Lovable, Base44, Bolt.new and v0. These are websites. You describe an app in chat, and the builder writes it and runs it on its own platform.
- **Skill sets and methods for coding agents**, such as Matt Pocock's skills, Spec Kit, Superpowers, Addy Osmani's agent skills and BMad Method, plus Kiro, an agentic editor. You add these to a coding agent such as Claude Code or Codex. Most are published on GitHub, and most are for developers.

AI Build Kit is in the second group. It differs from the others in that group in two ways. It is for people who do not read code. It also provides setup and maintenance steps for a live tool.

The kit includes a merge script, a launch script, a risk record, supported hosting recipes and `/maintain`. The kit gives agents instructions. Scripts check changes before merge and supported launches. Two recipes cover one software stack. A project also needs GitHub.

### Choose AI Build Kit if

- You can follow technical setup steps but do not read code.
- You want to build and maintain a small tool for a team in accounts you control.
- You want to try each change before a script merges it, and to record project risks.

### Choose another tool if

- You want flexible engineering skills that you can combine yourself. Choose [Matt Pocock's skills](https://github.com/mattpocock/skills).
- You want a detailed written specification, plan and task list. Choose [GitHub Spec Kit](https://github.com/github/spec-kit).
- You want strict test-first development and coding-agent skills. Choose [Superpowers](https://github.com/obra/superpowers).
- You want engineering skills, reviewer roles and a broad skill library. Choose [Addy Osmani's agent skills](https://github.com/addyosmani/agent-skills).
- You want role-based planning, architecture and review workflows. Choose [BMad Method](https://github.com/bmad-code-org/BMAD-METHOD).
- You want a full agentic development environment with specifications and task tracking. Choose [Kiro](https://kiro.dev/docs/).
- You want a first working app fast in your browser and are happy for it to run on the builder's platform. Choose [Replit](https://docs.replit.com/replitai/agent), [Lovable](https://docs.lovable.dev/introduction/welcome), [Base44](https://docs.base44.com), [Bolt.new](https://support.bolt.new) or [v0](https://v0.app/docs).

## Hosted app builders

These builders can get you to a first working, hosted app in minutes, in a browser with no setup: [Replit](https://docs.replit.com/replitai/agent), [Lovable](https://docs.lovable.dev/introduction/welcome), [Base44](https://docs.base44.com), [Bolt.new](https://support.bolt.new) and [v0](https://v0.app/docs). AI Build Kit takes longer to start and needs GitHub, a coding agent and a hosting choice. In exchange, it gives you checks before merge and launch, a risk record, hosting recipes with backup and a way back, and a maintenance process ([checks](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/SKILL.md), [risk record](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/fit-check/SKILL.md), [hosting recipes](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/SKILL.md), [maintenance](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/maintain/SKILL.md)).

The tables compare AI Build Kit with the five builders. Some details, including account ownership and data moves, are not confirmed in the builders' documentation.

<div class="comparison-table-wrap" role="region" aria-label="AI Build Kit, Replit, Lovable and Base44 hosted app builder comparison" tabindex="0">

| Question | AI Build Kit | [Replit](https://docs.replit.com/replitai/agent) | [Lovable](https://docs.lovable.dev/introduction/welcome) | [Base44](https://docs.base44.com) |
|---|---|---|---|---|
| How fast to a first app? | Longer start: founding interview, GitHub and hosting choice before the first screen ([setup](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/SKILL.md)). | Minutes; build in the browser ([Agent](https://docs.replit.com/replitai/agent)). | Minutes; build from chat in the browser ([welcome](https://docs.lovable.dev/introduction/welcome)). | Minutes; build in a browser chat ([chat modes](https://docs.base44.com/Building-your-app/AI-chat-modes)). |
| Where does it run, and whose account? | The hosting recipe uses accounts you create and control ([recipe](./records.md#live-tool-and-recipe)). | Replit deployments; account owner controls it. Cloud provider not confirmed ([deployments](https://docs.replit.com/learn/projects-and-artifacts/replit-deployments)). | Lovable hosts the app and backend; whose account controls hosting is not confirmed ([Cloud](https://docs.lovable.dev/features/cloud)). | Base44 infrastructure; whose account controls hosting is not confirmed ([developer tools](https://docs.base44.com/documentation/building-your-app/developer-tools)). |
| Who owns the code and data? | The code is in your GitHub repository. Hosting and data use accounts you control ([setup](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/SKILL.md), [recipe concept](./records.md#live-tool-and-recipe)). | You keep rights in your content; data rights are not confirmed ([terms](https://replit.com/terms)). | You own your data and AI output ([terms](https://lovable.dev/terms)). | You own your apps; other data rights are not confirmed ([terms update](https://docs.base44.com/Community-and-support/terms-of-service-update-june-2026)). |
| Can you take it elsewhere? | The recipe sets backup and a way back in accounts you control ([recipe](./records.md#live-tool-and-recipe)). | Sync with GitHub both ways or download a zip; database migration is not confirmed ([GitHub](https://docs.replit.com/getting-started/quickstarts/import-from-github)). | Git sync works both ways; moving the backend is manual ([Git sync](https://docs.lovable.dev/integrations/git-sync-overview), [self-hosting](https://docs.lovable.dev/tips-tricks/self-hosting)). | Export a zip or sync GitHub on some plans; backend and data stay on Base44 ([developer tools](https://docs.base44.com/documentation/building-your-app/developer-tools)). |
| What is checked before a change goes live? | The merge script checks project results. The launch script stops a recipe launch without a confirmed backup or rollback ([checks](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/SKILL.md)). | Agent tests its work, but a publish gate is not confirmed ([Agent](https://docs.replit.com/replitai/agent)). | Publishing runs Quick Scan; a hard gate is only described for Enterprise workspaces ([security](https://docs.lovable.dev/features/security)). | Security scan is advised before publishing, but a gate is not confirmed ([security scan](https://docs.base44.com/Setting-up-your-app/running-a-security-scan)). |
| Can you undo a change, including the data? | Hosting recipes include backup and a way back ([hosting](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/SKILL.md)). | Rollback can include database contents if selected; production databases need point-in-time restore ([checkpoints](https://docs.replit.com/replitai/checkpoints-and-rollbacks)). | Revert restores code, not database data; no automatic rollback of a published app ([history](https://docs.lovable.dev/features/projects/history), [publish](https://docs.lovable.dev/features/publish)). | Prompt and version undo are available; data backup and restore depends on the plan ([backup and restore](https://docs.base44.com/Enterprise/backup-and-restore)). |
| What if you outgrow it? | The recipe keeps hosting in your accounts and gives a way back ([hosting](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/SKILL.md)). | Move code by GitHub or zip; database migration is not confirmed ([GitHub](https://docs.replit.com/getting-started/quickstarts/import-from-github)). | Sync code to GitHub; move the backend by hand ([Git sync](https://docs.lovable.dev/integrations/git-sync-overview), [self-hosting](https://docs.lovable.dev/tips-tricks/self-hosting)). | Code can be exported, but backend stays on Base44; self-hosting is not confirmed ([developer tools](https://docs.base44.com/documentation/building-your-app/developer-tools), [backend](https://docs.base44.com/developers/backend/overview/start-from-existing-app)). |

</div>

<div class="comparison-table-wrap" role="region" aria-label="AI Build Kit, Bolt.new and v0 hosted app builder comparison" tabindex="0">

| Question | AI Build Kit | [Bolt.new](https://support.bolt.new) | [v0 by Vercel](https://v0.app/docs) |
|---|---|---|---|
| How fast to a first app? | Longer start: founding interview, GitHub and hosting choice before the first screen ([setup](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/SKILL.md)). | Minutes; make sites and tools in the browser ([Bolt](https://support.bolt.new)). | Minutes; make apps in the browser ([v0 docs](https://v0.app/docs)). |
| Where does it run, and whose account? | The hosting recipe uses accounts you create and control ([recipe](./records.md#live-tool-and-recipe)). | Bolt handles hosting; location and account details are not confirmed ([hosting](https://support.bolt.new/bolt-cloud/hosting.md)). | Vercel; you need deploy permission on the connected project ([deployments](https://v0.app/docs/deployments)). |
| Who owns the code and data? | The code is in your GitHub repository. Hosting and data use accounts you control ([setup](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/SKILL.md), [recipe concept](./records.md#live-tool-and-recipe)). | You own code made with Bolt; data terms are not confirmed ([ownership](https://support.bolt.new/account/corporate-commercial.md)). | Vercel does not own generated code; data ownership is not confirmed ([FAQs](https://v0.app/docs/faqs)). |
| Can you take it elsewhere? | The recipe sets backup and a way back in accounts you control ([recipe](./records.md#live-tool-and-recipe)). | GitHub sync works both ways; you can publish to Netlify ([GitHub](https://support.bolt.new/integrations/git.md), [Netlify](https://support.bolt.new/integrations/netlify.md)). | The connected GitHub repository becomes the source of truth; databases use marketplace integrations ([GitHub](https://v0.app/docs/github), [databases](https://v0.app/docs/databases)). |
| What is checked before a change goes live? | The merge script checks project results. The launch script stops a recipe launch without a confirmed backup or rollback ([checks](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/SKILL.md)). | A security audit is recommended before publishing, but is not a gate ([security](https://support.bolt.new/building/security.md)). | With GitHub, pull requests, CI status and required human reviews apply; without GitHub, this is not confirmed ([GitHub](https://v0.app/docs/github), [deployments](https://v0.app/docs/deployments)). |
| Can you undo a change, including the data? | Hosting recipes include backup and a way back ([hosting](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/SKILL.md)). | Restoring an earlier version does not change Bolt or Supabase databases ([rollback](https://support.bolt.new/managing-projects/rollback-backup.md)). | Roll back through Vercel's deployment inspector; data rollback is not confirmed ([deployments](https://v0.app/docs/deployments)). |
| What if you outgrow it? | The recipe keeps hosting in your accounts and gives a way back ([hosting](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/SKILL.md)). | Sync code to GitHub; on some plans you can claim the database into your Supabase account ([GitHub](https://support.bolt.new/integrations/git.md), [database](https://support.bolt.new/bolt-cloud/database/advanced.md)). | The GitHub repository is the source of truth; databases are separate marketplace integrations ([GitHub](https://v0.app/docs/github), [databases](https://v0.app/docs/databases)). |

</div>

### Start with a builder, move to the kit later

[Replit](https://docs.replit.com/getting-started/quickstarts/import-from-github), [Lovable](https://docs.lovable.dev/integrations/git-sync-overview), [Bolt.new](https://support.bolt.new/integrations/git.md) and [v0](https://v0.app/docs/github) sync with GitHub. [Base44](https://docs.base44.com/documentation/building-your-app/developer-tools) offers GitHub sync on some plans, but the sync direction is not confirmed. That can give the kit a code repository to take over. This page has not tested this route. Moving the app's data and backend may need separate steps, as the builders' own notes show for [Lovable](https://docs.lovable.dev/tips-tricks/self-hosting) and [Base44](https://docs.base44.com/documentation/building-your-app/developer-tools).

### Replit

[Replit Agent](https://docs.replit.com/replitai/agent) turns plain language into an app in a browser. It can build and test the work, and [checkpoints](https://docs.replit.com/replitai/checkpoints-and-rollbacks) can save files and database contents. Its speed and built-in hosting suit a quick first app. You can leave by syncing code to [GitHub](https://docs.replit.com/getting-started/quickstarts/import-from-github) or downloading a zip; database migration is not confirmed.

### Lovable

[Lovable](https://docs.lovable.dev/introduction/welcome) builds web apps with a front end, database and sign-in from chat. Publishing runs a [Quick Scan](https://docs.lovable.dev/features/security), and a version history can [restore code](https://docs.lovable.dev/features/projects/history), but not database data. This makes it a fast route to a hosted app with a managed backend. You can sync code both ways with [GitHub](https://docs.lovable.dev/integrations/git-sync-overview); moving the backend is manual ([guide](https://docs.lovable.dev/tips-tricks/self-hosting)).

### Base44

[Base44](https://docs.base44.com) is a no-code builder with managed data, sign-in and hosting. It has chat modes for building and editing, plus a [security scan](https://docs.base44.com/Setting-up-your-app/running-a-security-scan) to find some common problems. Its managed setup helps you get an app running quickly. You can export a zip or sync GitHub on some plans, but its backend stays on Base44 ([developer tools](https://docs.base44.com/documentation/building-your-app/developer-tools)).

### Bolt.new

[Bolt.new](https://support.bolt.new) builds sites, shops, dashboards and internal tools in a browser, with hosting included. Its [security audit](https://support.bolt.new/building/security.md) checks code and database, but the docs recommend it rather than require it before publishing. You can sync with [GitHub](https://support.bolt.new/integrations/git.md), publish to Netlify, and claim the database into your Supabase account on some plans ([Netlify](https://support.bolt.new/integrations/netlify.md), [database](https://support.bolt.new/bolt-cloud/database/advanced.md)).

### v0 by Vercel

[v0](https://v0.app/docs) makes code and full-stack apps, then deploys them through Vercel. When connected to [GitHub](https://v0.app/docs/github), it works on a branch, opens a pull request, shows CI status and preview deployments, and supports required human review. The repository is the source of truth; databases come from marketplace integrations ([GitHub](https://v0.app/docs/github), [databases](https://v0.app/docs/databases)).

## Skill sets and methods for coding agents

These are instructions and tools for developers who use coding agents. The tables compare who each tool is for, how it guides and checks work, and what help it gives before and after launch.

### Side by side

Each table keeps four products beside AI Build Kit. On a narrow screen, scroll inside the table to compare the columns.

<div class="comparison-table-wrap" role="region" aria-label="Comparison of AI Build Kit, Matt Pocock's skills, GitHub Spec Kit and Superpowers" tabindex="0">

| Question | AI Build Kit | [Matt Pocock's skills](https://github.com/mattpocock/skills) | [GitHub Spec Kit](https://github.com/github/spec-kit) | [Superpowers](https://github.com/obra/superpowers) |
|---|---|---|---|---|
| Who is it for? | People who do not read code | Working engineers | Developers | Developers |
| What do you work from? | Agreed pieces | Specs and tickets | Specs, plans and tasks | Designs and plans |
| Who reviews the work? | Reviewer agent in a fresh context; you decide on merge | Two review agents | Model or person | Review agents |
| What must tests show? | The project check must pass before merge | Test-first instructions | Tests are optional | Test-first instructions |
| What can a machine block? | Merge gates and launch checks for backup and rollback | Optional, unmaintained Claude hook | Missing plan or task files | No user-work gate found |
| Help to put it live? | Two recipes for Next.js and Supabase, on Vercel or Coolify | Manual steps only | Deployment outside its flow | None found |
| Help after launch? | `/maintain` and live checks | None found | None found | None found |
| How does it test itself? | Shell checks and conversation replays | No evals or tests found | Cross-platform test suite | Tests and separate evals |
| Coding agents supported | Tested: Claude Code; expected to work: Codex; experimental: Cursor, Gemini CLI and GitHub Copilot | Several agents | About 50 integrations | Many agents |
| Licence | [MIT](https://github.com/gwpicard/ai-build-kit/blob/stable/LICENSE) | [MIT](https://github.com/mattpocock/skills/blob/main/LICENSE) | [MIT](https://github.com/github/spec-kit/blob/main/LICENSE) | [MIT](https://github.com/obra/superpowers/blob/main/LICENSE) |

</div>

<div class="comparison-table-wrap" role="region" aria-label="Comparison of AI Build Kit, Addy Osmani's agent skills, BMad Method and Kiro" tabindex="0">

| Question | AI Build Kit | [Addy Osmani's agent skills](https://github.com/addyosmani/agent-skills) | [BMad Method](https://github.com/bmad-code-org/BMAD-METHOD) | [Kiro](https://kiro.dev/docs/) |
|---|---|---|---|---|
| Who is it for? | People who do not read code | Working engineers | People who read agent output | Developers |
| What do you work from? | Agreed pieces | Specs, plans and tasks | Briefs, plans and ticket trees | Specs and tasks |
| Who reviews the work? | Reviewer agent in a fresh context; you decide on merge | Three reviewer roles | Review agents | Person reviews the spec |
| What must tests show? | The project check must pass before merge | Test-first instructions | Optional verification | User-chosen test hooks |
| What can a machine block? | Merge gates and launch checks for backup and rollback | No project gate found | No project gate found | Hooks and permissions can block tool calls |
| Help to put it live? | Two recipes for Next.js and Supabase, on Vercel or Coolify | Launch guidance | No deploy workflow found | No product hosting found |
| Help after launch? | `/maintain` and live checks | Observability skills | Epic retrospective | Crew tasks; use for upkeep unconfirmed |
| How does it test itself? | Shell checks and conversation replays | CI checks and on-demand evals | Pytest and skill eval runner | Product tests not public |
| Coding agents supported | Tested: Claude Code; expected to work: Codex; experimental: Cursor, Gemini CLI and GitHub Copilot | Several agents | Skills-capable agents | Kiro's own agent |
| Licence | [MIT](https://github.com/gwpicard/ai-build-kit/blob/stable/LICENSE) | [MIT](https://github.com/addyosmani/agent-skills/blob/main/LICENSE) | [MIT, trademark terms](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/LICENSE) | [Proprietary](https://kiro.dev/license/) |

</div>

### Matt Pocock's skills

[Matt Pocock's skills](https://github.com/mattpocock/skills) are engineering skills for developers, not a fixed process. They guide work from an idea to a specification, tickets and a pull request. The `tdd` skill asks for a failing test first, and two agents review changes. Most steps instruct the model. An optional Claude Code hook can block some Git commands, but it is frozen and outside the plugin. See the [README](https://github.com/mattpocock/skills/blob/main/README.md), [TDD skill](https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md) and [git guardrail](https://github.com/mattpocock/skills/blob/main/skills/misc/git-guardrails-claude-code/SKILL.md).


### GitHub Spec Kit

[GitHub Spec Kit](https://github.com/github/spec-kit) installs a command-line tool, templates and scripts for developers. It guides work through a specification, plan, tasks and implementation. A helper script stops work when required files are missing. Tests are optional, and it has no product hosting flow. The kit is for people who do not read code and includes project checks and maintenance. See the [README](https://github.com/github/spec-kit/blob/main/README.md), [command templates](https://github.com/github/spec-kit/tree/main/templates/commands), [task instructions](https://github.com/github/spec-kit/blob/main/templates/commands/tasks.md) and [prerequisite check](https://github.com/github/spec-kit/blob/main/scripts/bash/check-prerequisites.sh).


### Superpowers

[Superpowers](https://github.com/obra/superpowers) gives developers skills for design, planning, test-first work and agent review. Its startup hook adds instructions but blocks no work. Two helper scripts can record a task after tests pass, if the agent runs them. The kit checks project changes when its merge script runs. See the [README](https://github.com/obra/superpowers/blob/main/README.md), [test-first skill](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md), [session hook](https://github.com/obra/superpowers/blob/main/hooks/hooks.json) and [eval project](https://github.com/prime-radiant-inc/superpowers-evals).


### Addy Osmani's agent skills

[Addy Osmani's agent skills](https://github.com/addyosmani/agent-skills) give developers engineering skills, commands and reviewer roles. `/ship` starts code, security and test reviews. Test-first work instructs the model. The plugin has no project merge gate; some hooks need manual setup. See the [README](https://github.com/addyosmani/agent-skills/blob/main/README.md), [`/ship` setup](https://github.com/addyosmani/agent-skills/blob/main/commands/ship.toml), [test-first skill](https://github.com/addyosmani/agent-skills/blob/main/skills/test-driven-development/SKILL.md) and [eval guide](https://github.com/addyosmani/agent-skills/blob/main/evals/README.md).


### BMad Method

[BMad Method](https://github.com/bmad-code-org/BMAD-METHOD) uses role-based skills for planning and delivery. It suits people who steer an agent and read its output. Its planning covers product, architecture and ticket trees; review agents inspect staged changes. The files reviewed describe model instructions. The kit also provides a merge script and instructions for people who do not read code. This page reviewed the v7 preview alpha, not stable v6. See the [README](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/README.md), [build workflow](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/skills/bmad-build/workflow.md), [review skill](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/skills/bmad-review/SKILL.md) and [planning documents](https://github.com/bmad-code-org/BMAD-METHOD/tree/main/docs/plan).


### Kiro

[Kiro](https://kiro.dev/docs/) is a proprietary development environment with an IDE, command line and other interfaces. Its specifications create requirements, design and task files, which can run in dependency-based groups. People can comment on the specification. Hooks and permissions can block tool calls, though exact exit-code behaviour is unconfirmed. The kit has a separate merge script and a launch script for supported recipes. The files reviewed did not describe product hosting or public product tests. See [specifications](https://kiro.dev/docs/specs/), [hooks](https://kiro.dev/docs/hooks/), [permissions](https://kiro.dev/docs/permissions/) and the [licence](https://kiro.dev/license/).
