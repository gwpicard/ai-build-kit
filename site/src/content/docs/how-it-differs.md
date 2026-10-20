---
title: How it differs
description: Compare AI Build Kit with six tools for AI-assisted software work.
draft: false
---

AI Build Kit helps a person who does not read code build and run a small shared tool through GitHub. Its workflow combines model instructions with scripts that check named steps, plus hosting recipes for one software stack. It needs GitHub and is not a quick hosted app builder.

## Choose AI Build Kit if

- You can follow technical setup steps but do not read code.
- You want to build and maintain a small tool for a team in accounts you control.
- You want a person to approve each merge, checks at named boundaries, and a record of project risks.

## Choose another tool if

- You want flexible engineering skills that you can combine yourself. Choose [Matt Pocock's skills](https://github.com/mattpocock/skills).
- You want a detailed written specification, plan and task list. Choose [GitHub Spec Kit](https://github.com/github/spec-kit).
- You want strict test-first development and coding-agent skills. Choose [Superpowers](https://github.com/obra/superpowers).
- You want engineering skills, reviewer roles and a broad skill library. Choose [Addy Osmani's agent skills](https://github.com/addyosmani/agent-skills).
- You want role-based planning, architecture and review workflows. Choose [BMad Method](https://github.com/bmad-code-org/BMAD-METHOD).
- You want a full agentic development environment with specifications and task tracking. Choose [Kiro](https://kiro.dev/docs/).

## Side by side

Each table keeps four products beside AI Build Kit. On a narrow screen, scroll inside the table to compare the columns.

<div class="comparison-table-wrap" role="region" aria-label="Comparison of AI Build Kit, Matt Pocock's skills, GitHub Spec Kit and Superpowers" tabindex="0">

| Question | AI Build Kit | [Matt Pocock's skills](https://github.com/mattpocock/skills) | [GitHub Spec Kit](https://github.com/github/spec-kit) | [Superpowers](https://github.com/obra/superpowers) |
|---|---|---|---|---|
| Who is it for? | People who do not read code | Working engineers | Developers | Developers |
| What do you work from? | Agreed pieces | Specs and tickets | Specs, plans and tasks | Designs and plans |
| Who reviews the work? | Person; recorded review | Two review agents | Model or person | Review agents |
| What must tests show? | Named checks must pass at gates | Test-first instructions | Tests are optional | Test-first instructions |
| What can a machine block? | Merge gates; launch checks report | Optional, unmaintained Claude hook | Missing plan or task files | No user-work gate found |
| Help to put it live? | Two proven recipes, one stack | Manual steps only | Deployment outside its flow | None found |
| Help after launch? | `/maintain` and live checks | None found | None found | None found |
| How does it test itself? | Shell checks and conversation replays | No evals or tests found | Cross-platform test suite | Tests and separate evals |
| Coding agents supported | Claude, Codex, Cursor, Gemini, others | Several agents | About 50 integrations | Many agents |
| Licence | [MIT](https://github.com/gwpicard/ai-build-kit/blob/stable/LICENSE) | [MIT](https://github.com/mattpocock/skills/blob/main/LICENSE) | [MIT](https://github.com/github/spec-kit/blob/main/LICENSE) | [MIT](https://github.com/obra/superpowers/blob/main/LICENSE) |

</div>

<div class="comparison-table-wrap" role="region" aria-label="Comparison of AI Build Kit, Addy Osmani's agent skills, BMad Method and Kiro" tabindex="0">

| Question | AI Build Kit | [Addy Osmani's agent skills](https://github.com/addyosmani/agent-skills) | [BMad Method](https://github.com/bmad-code-org/BMAD-METHOD) | [Kiro](https://kiro.dev/docs/) |
|---|---|---|---|---|
| Who is it for? | People who do not read code | Working engineers | People who read agent output | Developers |
| What do you work from? | Agreed pieces | Specs, plans and tasks | Briefs, plans and ticket trees | Specs and tasks |
| Who reviews the work? | Person; recorded review | Three reviewer roles | Review agents | Person reviews the spec |
| What must tests show? | Named checks must pass at gates | Test-first instructions | Optional verification | User-chosen test hooks |
| What can a machine block? | Merge gates; launch checks report | No project gate found | No project gate found | Hooks and permissions can block tool calls |
| Help to put it live? | Two proven recipes, one stack | Launch guidance | No deploy workflow found | No product hosting found |
| Help after launch? | `/maintain` and live checks | Observability skills | Epic retrospective | Crew tasks; use for upkeep unconfirmed |
| How does it test itself? | Shell checks and conversation replays | CI checks and on-demand evals | Pytest and skill eval runner | Product tests not public |
| Coding agents supported | Claude, Codex, Cursor, Gemini, others | Several agents | Skills-capable agents | Kiro's own agent |
| Licence | [MIT](https://github.com/gwpicard/ai-build-kit/blob/stable/LICENSE) | [MIT](https://github.com/addyosmani/agent-skills/blob/main/LICENSE) | [MIT, trademark terms](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/LICENSE) | [Proprietary](https://kiro.dev/license/) |

</div>

## Matt Pocock's skills

[Matt Pocock's skills](https://github.com/mattpocock/skills) are engineering skills for developers, not a fixed process. They guide work from an idea to a specification, tickets and a pull request. The `tdd` skill asks for a failing test first, and two agents review changes. Most steps instruct the model. An optional Claude Code hook can block some Git commands, but it is frozen and outside the plugin. The kit adds merge gates, launch checks, risk records and `/maintain`. Combining them is untested. See the [README](https://github.com/mattpocock/skills/blob/main/README.md), [TDD skill](https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md) and [git guardrail](https://github.com/mattpocock/skills/blob/main/skills/misc/git-guardrails-claude-code/SKILL.md).

Read on 20 October 2026 at commit `5beb35b`.

## GitHub Spec Kit

[GitHub Spec Kit](https://github.com/github/spec-kit) installs a command-line tool, templates and scripts for developers. It guides work through a specification, plan, tasks and implementation. A helper script stops work when required files are missing. Tests are optional, and it has no product hosting flow. The kit adds a route for people who do not read code, merge gates, launch checks, risk records, hosting recipes and maintenance. Using both for planning and delivery is possible, but untested; their commands may overlap. See the [README](https://github.com/github/spec-kit/blob/main/README.md), [command templates](https://github.com/github/spec-kit/tree/main/templates/commands), [task instructions](https://github.com/github/spec-kit/blob/main/templates/commands/tasks.md) and [prerequisite check](https://github.com/github/spec-kit/blob/main/scripts/bash/check-prerequisites.sh).

Read on 20 October 2026 at commit `f68ffca`.

## Superpowers

[Superpowers](https://github.com/obra/superpowers) gives developers skills for design, planning, test-first work and agent review. Its startup hook adds instructions but blocks no work. Two helper scripts can record a task after tests pass, if the agent runs them. The kit adds merge gates, launch checks, risk records, hosting recipes and `/maintain`. Using its debugging or test-first skill inside a kit task may work, but this has not been tried. See the [README](https://github.com/obra/superpowers/blob/main/README.md), [test-first skill](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md), [session hook](https://github.com/obra/superpowers/blob/main/hooks/hooks.json) and [eval project](https://github.com/prime-radiant-inc/superpowers-evals).

Read on 20 October 2026 at commit `bb92a77`.

## Addy Osmani's agent skills

[Addy Osmani's agent skills](https://github.com/addyosmani/agent-skills) give developers engineering skills, commands and reviewer roles. `/ship` starts code, security and test reviews. Test-first work instructs the model. The plugin has no project merge gate; some hooks need manual setup. The kit adds merge gates, launch checks, risk records, hosting recipes and `/maintain`. Using its review skills beside the kit is untested, and their planning steps may compete. See the [README](https://github.com/addyosmani/agent-skills/blob/main/README.md), [`/ship` setup](https://github.com/addyosmani/agent-skills/blob/main/commands/ship.toml), [test-first skill](https://github.com/addyosmani/agent-skills/blob/main/skills/test-driven-development/SKILL.md) and [eval guide](https://github.com/addyosmani/agent-skills/blob/main/evals/README.md).

Read on 20 October 2026 at commit `aeac41d`.

## BMad Method

[BMad Method](https://github.com/bmad-code-org/BMAD-METHOD) uses role-based skills for planning and delivery. It suits people who steer an agent and read its output. Its planning covers product, architecture and ticket trees; review agents inspect staged changes. These are model instructions, and the report found no gate on a user's project. The kit adds merge gates, launch checks, risk records, hosting recipes, `/maintain` and guidance for people who do not read code. BMad planning could feed a kit piece, but the workflows have not been tried together. This report read the v7 preview alpha, not stable v6. See the [README](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/README.md), [build workflow](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/skills/bmad-build/workflow.md), [review skill](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/skills/bmad-review/SKILL.md) and [planning documents](https://github.com/bmad-code-org/BMAD-METHOD/tree/main/docs/plan).

Read on 20 October 2026 at commit `61e01f8`.

## Kiro

[Kiro](https://kiro.dev/docs/) is a proprietary development environment with an IDE, command line and other interfaces. Its specifications create requirements, design and task files, which can run in dependency-based groups. People can comment on the specification. Hooks and permissions can block tool calls, though exact exit-code behaviour is unconfirmed. The kit adds merge gates, launch checks with plain-word results, risk records, hosting recipes and `/maintain`. Kiro skills may be able to run the kit, but this has not been tried. The report found no product hosting feature or public product tests. See [specifications](https://kiro.dev/docs/specs/), [hooks](https://kiro.dev/docs/hooks/), [permissions](https://kiro.dev/docs/permissions/) and the [licence](https://kiro.dev/license/).

Read on 20 October 2026 at commit `bfe7ff3`.
