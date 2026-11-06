---
title: How it differs
description: Compare AI Build Kit with hosted app builders, coding-agent skills and Kiro.
draft: false
---
This comparison uses each tool’s public documentation and repository, read on 20 October 2026.

## At a glance

This page compares AI Build Kit with three kinds of tool:

- **Hosted app builders**, such as Replit, Lovable, Base44, Bolt.new and v0, let you describe an app in chat, then build and host it on their platforms.
- **Skill sets and methods for coding agents**, such as Matt Pocock’s skills, Spec Kit, Superpowers, Addy Osmani’s agent skills and BMad Method, add instructions and tools to agents such as Claude Code or Codex. Most are published on GitHub and intended for developers.
- **Development environments**, represented here by Kiro, include their own coding agent.

AI Build Kit belongs to the skills group. It is designed for people who do not read code and includes steps for setting up and maintaining a live copy.

The kit combines agent instructions with scripts for merging changes and checking launches on a recipe. It also provides a risk record, hosting recipes and a maintenance command, `/maintain`. Its two recipes use Next.js and Supabase, hosted on Vercel or Coolify ([hosting recipes](/ai-build-kit/recipes/)). Every project requires GitHub.

## Hosted app builders

These builders produce a hosted app in a browser, often within minutes and without setup: [Replit](https://docs.replit.com/replitai/agent), [Lovable](https://docs.lovable.dev/introduction/welcome), [Base44](https://docs.base44.com), [Bolt.new](https://support.bolt.new) and [v0](https://v0.app/docs). AI Build Kit takes longer because it requires GitHub, a coding agent and a hosting choice. It provides checks before merge and launch, a risk record, recipes with backup and rollback steps, and maintenance ([checks](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/SKILL.md), [risk record](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/fit-check/SKILL.md), [hosting recipes](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/SKILL.md), [maintenance](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/maintain/SKILL.md)).

The tables compare AI Build Kit with five hosted builders. Documentation gaps, including account ownership and data migration details, are marked unconfirmed.

<div class="comparison-table-wrap" role="region" aria-label="AI Build Kit, Replit, Lovable and Base44 hosted app builder comparison" tabindex="0">

| Question | AI Build Kit | [Replit](https://docs.replit.com/replitai/agent) | [Lovable](https://docs.lovable.dev/introduction/welcome) | [Base44](https://docs.base44.com) |
|---|---|---|---|---|
| How fast to a first app? | More initial setup: the founding interview, GitHub and a hosting choice before the first screen ([setup](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/SKILL.md)). | Minutes; build in the browser ([Agent](https://docs.replit.com/replitai/agent)). | Minutes; build from chat in the browser ([welcome](https://docs.lovable.dev/introduction/welcome)). | Minutes; build in a browser chat ([chat modes](https://docs.base44.com/Building-your-app/AI-chat-modes)). |
| Where does it run, and whose account? | The hosting recipe uses accounts you create and control ([recipe](/ai-build-kit/records/#live-tool-and-recipe)). | Replit deployments; account owner controls it. Cloud provider not confirmed ([deployments](https://docs.replit.com/learn/projects-and-artifacts/replit-deployments)). | Lovable hosts the app and backend; whose account controls hosting is not confirmed ([Cloud](https://docs.lovable.dev/features/cloud)). | Base44 infrastructure; whose account controls hosting is not confirmed ([developer tools](https://docs.base44.com/documentation/building-your-app/developer-tools)). |
| Who owns the code and data? | The code is in your GitHub repository. Hosting and data use accounts you control ([setup](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/SKILL.md), [recipe concept](/ai-build-kit/records/#live-tool-and-recipe)). | You keep rights in your content; data rights are not confirmed ([terms](https://replit.com/terms)). | You own your data and AI output ([terms](https://lovable.dev/terms)). | You own your apps; other data rights are not confirmed ([terms update](https://docs.base44.com/Community-and-support/terms-of-service-update-june-2026)). |
| Can you take it elsewhere? | The code is a standard project in your GitHub account and the data is in your Supabase account. Moving to another hosting recipe is a separate, approved piece of work ([recipes](/ai-build-kit/recipes/)). | Sync with GitHub both ways or download a zip; database migration is not confirmed ([GitHub](https://docs.replit.com/getting-started/quickstarts/import-from-github)). | Git sync works both ways; moving the backend is manual ([Git sync](https://docs.lovable.dev/integrations/git-sync-overview), [self-hosting](https://docs.lovable.dev/tips-tricks/self-hosting)). | Export a zip or sync GitHub on some plans; backend and data stay on Base44 ([developer tools](https://docs.base44.com/documentation/building-your-app/developer-tools)). |
| What is checked before a change goes live? | The merge script checks the project check result. When a live address is set, the launch script blocks its live-address record if backup or rollback conditions are unmet; it cannot stop a host that deploys on merge ([launch script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/scripts/run-recipe.sh)). | Agent tests its work, but a publish gate is not confirmed ([Agent](https://docs.replit.com/replitai/agent)). | Publishing runs [Quick Scan](https://docs.lovable.dev/features/security#quick-scan). An optional block on publishing with critical issues is available on all plans and enabled by default for new Enterprise workspaces ([security settings](https://docs.lovable.dev/features/privacy-and-security-settings#block-publishing-with-critical-issues)). | Security scan is advised before publishing, but a gate is not confirmed ([security scan](https://docs.base44.com/Setting-up-your-app/running-a-security-scan)). |
| Can you undo a change, including the data? | Recipes define application rollback and a separate procedure for restoring database data. Restore has not yet been tried on either recipe ([testing status](/ai-build-kit/recipes/#checks-and-testing-status)). | Rollback can include database contents if selected; production databases need point-in-time restore ([checkpoints](https://docs.replit.com/replitai/checkpoints-and-rollbacks)). | Revert restores code, not database data; no automatic rollback of a published app ([history](https://docs.lovable.dev/features/projects/history), [publish](https://docs.lovable.dev/features/publish)). | Prompt and version undo are available; data backup and restoration depend on the plan ([backup and restore](https://docs.base44.com/Enterprise/backup-and-restore)). |
| What if you outgrow it? | You can change coding agent or developer while retaining the project. Moving to another hosting recipe is a separate, approved piece of work ([recipes](/ai-build-kit/recipes/)). | Move code by GitHub or zip; database migration is not confirmed ([GitHub](https://docs.replit.com/getting-started/quickstarts/import-from-github)). | Sync code to GitHub; move the backend by hand ([Git sync](https://docs.lovable.dev/integrations/git-sync-overview), [self-hosting](https://docs.lovable.dev/tips-tricks/self-hosting)). | Code can be exported, but backend stays on Base44; Base44 does not support self-hosting ([developer tools](https://docs.base44.com/documentation/building-your-app/developer-tools), [backend](https://docs.base44.com/developers/backend/overview/start-from-existing-app)). |

</div>

<div class="comparison-table-wrap" role="region" aria-label="AI Build Kit, Bolt.new and v0 hosted app builder comparison" tabindex="0">

| Question | AI Build Kit | [Bolt.new](https://support.bolt.new) | [v0 by Vercel](https://v0.app/docs) |
|---|---|---|---|
| How fast to a first app? | More initial setup: the founding interview, GitHub and a hosting choice before the first screen ([setup](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/SKILL.md)). | Minutes; make sites and tools in the browser ([Bolt](https://support.bolt.new)). | Minutes; make apps in the browser ([v0 docs](https://v0.app/docs)). |
| Where does it run, and whose account? | The hosting recipe uses accounts you create and control ([recipe](/ai-build-kit/records/#live-tool-and-recipe)). | Bolt handles hosting; location and account details are not confirmed ([hosting](https://support.bolt.new/bolt-cloud/hosting.md)). | Vercel; you need deploy permission on the connected project ([deployments](https://v0.app/docs/deployments)). |
| Who owns the code and data? | The code is in your GitHub repository. Hosting and data use accounts you control ([setup](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/SKILL.md), [recipe concept](/ai-build-kit/records/#live-tool-and-recipe)). | You own code made with Bolt; data terms are not confirmed ([ownership](https://support.bolt.new/account/corporate-commercial.md)). | Vercel does not own generated code; data ownership is not confirmed ([FAQs](https://v0.app/docs/faqs)). |
| Can you take it elsewhere? | The code is a standard project in your GitHub account and the data is in your Supabase account. Moving to another hosting recipe is a separate, approved piece of work ([recipes](/ai-build-kit/recipes/)). | GitHub sync works both ways; you can publish to Netlify ([GitHub](https://support.bolt.new/integrations/git.md), [Netlify](https://support.bolt.new/integrations/netlify.md)). | The connected GitHub repository becomes the source of truth; databases use marketplace integrations ([GitHub](https://v0.app/docs/github), [databases](https://v0.app/docs/databases)). |
| What is checked before a change goes live? | The merge script checks the project check result. When a live address is set, the launch script blocks its live-address record if backup or rollback conditions are unmet; it cannot stop a host that deploys on merge ([launch script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/scripts/run-recipe.sh)). | A security audit is recommended before publishing, but is not a gate ([security](https://support.bolt.new/building/security.md)). | With GitHub, pull requests, CI status and required human reviews apply; without GitHub, this is not confirmed ([GitHub](https://v0.app/docs/github), [deployments](https://v0.app/docs/deployments)). |
| Can you undo a change, including the data? | Recipes define application rollback and a separate procedure for restoring database data. Restore has not yet been tried on either recipe ([testing status](/ai-build-kit/recipes/#checks-and-testing-status)). | Restoring an earlier version does not change Bolt or Supabase databases ([rollback](https://support.bolt.new/managing-projects/rollback-backup.md)). | Roll back through Vercel's deployment inspector; data rollback is not confirmed ([deployments](https://v0.app/docs/deployments)). |
| What if you outgrow it? | You can change coding agent or developer while retaining the project. Moving to another hosting recipe is a separate, approved piece of work ([recipes](/ai-build-kit/recipes/)). | Sync code to GitHub; on some plans you can claim the database into your Supabase account ([GitHub](https://support.bolt.new/integrations/git.md), [database](https://support.bolt.new/bolt-cloud/database/advanced.md)). | The GitHub repository is the source of truth; databases are separate marketplace integrations ([GitHub](https://v0.app/docs/github), [databases](https://v0.app/docs/databases)). |

</div>

### Start with a builder, move to the kit later

[Replit](https://docs.replit.com/getting-started/quickstarts/import-from-github), [Lovable](https://docs.lovable.dev/integrations/git-sync-overview), [Bolt.new](https://support.bolt.new/integrations/git.md) and [v0](https://v0.app/docs/github) sync with GitHub. [Base44](https://docs.base44.com/documentation/building-your-app/developer-tools) syncs with GitHub both ways on the Builder plan and higher. That may provide a repository the kit can adopt, but this route has not been tested for this comparison. Moving the app's data and backend may need separate steps, as the builders' own notes show for [Lovable](https://docs.lovable.dev/tips-tricks/self-hosting) and [Base44](https://docs.base44.com/documentation/building-your-app/developer-tools).

## Skill sets and methods for coding agents

These are instructions and tools for developers who use coding agents. The tables compare who each tool is for, how it guides and checks work, and what help it gives before and after launch.

### Side by side

Tables compare three alternatives; scroll within them on narrow screens. A specification sets required behaviour, a ticket records work, and test-first means a failing test precedes implementation. A gate blocks unmet actions. CI runs checks when code changes; evaluations measure agent behaviour.

<div class="comparison-table-wrap" role="region" aria-label="Comparison of AI Build Kit, Matt Pocock's skills, GitHub Spec Kit and Superpowers" tabindex="0">

| Question | AI Build Kit | [Matt Pocock's skills](https://github.com/mattpocock/skills) | [GitHub Spec Kit](https://github.com/github/spec-kit) | [Superpowers](https://github.com/obra/superpowers) |
|---|---|---|---|---|
| Who is it for? | People who do not read code | Working engineers | Developers | Developers |
| What do you work from? | Agreed pieces of work | Specifications and tickets | Specifications, plans and tasks | Designs and plans |
| Who reviews the work? | Reviewer agent in a fresh context; you decide whether to merge | Two review agents | Model or person | Review agents |
| Testing requirements | The project check must pass before merge | Test-first instructions | Not confirmed | Test-first instructions |
| What can a machine block? | The merge script blocks unmet merge requirements. The launch script blocks its live-address record when backup or rollback conditions are unmet | Optional, unmaintained Claude hook | Missing plan or task files | No user-work gate found |
| Help with deployment? | Two recipes for Next.js and Supabase, on Vercel or Coolify | Manual steps only | Deployment outside its flow | None found |
| Help after launch? | `/maintain` and live checks | None found | None found | None found |
| How does it test itself? | Shell checks and conversation replays | No evaluations or tests found | Cross-platform test suite | Tests and separate evaluations |
| Coding agents supported | Tested: Claude Code; expected to work: Codex; experimental: Cursor, Gemini CLI and GitHub Copilot | Several agents | About 50 integrations | Many agents |
| Licence | [MIT](https://github.com/gwpicard/ai-build-kit/blob/stable/LICENSE) | [MIT](https://github.com/mattpocock/skills/blob/main/LICENSE) | [MIT](https://github.com/github/spec-kit/blob/main/LICENSE) | [MIT](https://github.com/obra/superpowers/blob/main/LICENSE) |

</div>

<div class="comparison-table-wrap" role="region" aria-label="Comparison of AI Build Kit, Addy Osmani's agent skills, BMad Method and Kiro" tabindex="0">

| Question | AI Build Kit | [Addy Osmani's agent skills](https://github.com/addyosmani/agent-skills) | [BMad Method](https://github.com/bmad-code-org/BMAD-METHOD) | [Kiro](https://kiro.dev/docs/) |
|---|---|---|---|---|
| Who is it for? | People who do not read code | Working engineers | People who read agent output | Developers |
| What do you work from? | Agreed pieces of work | Specifications, plans and tasks | Briefs, plans and ticket trees | Specifications and tasks |
| Who reviews the work? | Reviewer agent in a fresh context; you decide whether to merge | Three reviewer roles | Review agents | Person reviews the specification |
| Testing requirements | The project check must pass before merge | Test-first instructions | Optional verification | User-chosen test hooks |
| What can a machine block? | The merge script blocks unmet merge requirements. The launch script blocks its live-address record when backup or rollback conditions are unmet | No project gate found | No project gate found | Hooks and permissions can block tool calls |
| Help with deployment? | Two recipes for Next.js and Supabase, on Vercel or Coolify | Launch guidance | No deploy workflow found | No product hosting found |
| Help after launch? | `/maintain` and live checks | Observability skills | Epic retrospective | Crew tasks; use for upkeep unconfirmed |
| How does it test itself? | Shell checks and conversation replays | CI checks and evaluations run on demand | Pytest tests and a skill evaluation runner | Product tests not public |
| Coding agents supported | Tested: Claude Code; expected to work: Codex; experimental: Cursor, Gemini CLI and GitHub Copilot | Several agents | Skills-capable agents | Kiro's own agent |
| Licence | [MIT](https://github.com/gwpicard/ai-build-kit/blob/stable/LICENSE) | [MIT](https://github.com/addyosmani/agent-skills/blob/main/LICENSE) | [MIT, trademark terms](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/LICENSE) | [Proprietary](https://kiro.dev/license/) |

</div>

### BMad Method review note

This page reviewed the v7 preview alpha, not stable v6 ([BMad Method](https://github.com/bmad-code-org/BMAD-METHOD)).
