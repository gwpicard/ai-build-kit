# Sources

AI Build Kit grew from the private `claude-kernel-builder` and its output, `claude-kernel`, then from the private `agentic-dev-skills`, and then into this kit.

This list names ideas used in the kit and where they appear.

## Records and planning

| Source | What it gave | Where it is in the kit |
|---|---|---|
| [28 Days of Lovable](https://28daysoflovable.com/), by Lazar Jovanovic | One master document as the source of truth, with a next item and a named check. | The project record and work rhythm, `.agents/skills/setup-ai-build-kit/templates/masterplan.md`, `.agents/skills/records/SKILL.md`. |
| [Alex Lavaee, the new software lifecycle](https://alexlavaee.me/blog/new-sdlc-agentic-engineering/) | Documents hold the decisions; code is their current form. | Project records and changes to them, `docs/PHILOSOPHY.md`, `.agents/skills/records/references/masterplan-changes.md`. |
| [Alex Lavaee, from RPI to QRSPI](https://alexlavaee.me/blog/from-rpi-to-qrspi/) | Build vertical slices instead of layers. | One-sitting pieces and shaping, `.agents/skills/records/references/pieces.md`, `.agents/skills/shape/SKILL.md`. |
| [Dex Horthy, Advanced Context Engineering for Agents](https://www.youtube.com/watch?v=VvkhYWFWaKI) | Build each piece through the whole tool, not one layer at a time. | One-sitting pieces, `.agents/skills/records/references/pieces.md`, `.agents/skills/shape/SKILL.md`. |
| [Matt Pocock's skills](https://github.com/mattpocock/skills) | Attach a best guess to each question; use a small prototype to settle a choice. | Interview and prototype steps, `.agents/skills/clarify/SKILL.md`, `.agents/skills/clarify/references/decision-prototype.md`. |
| [Matt Pocock's skills](https://github.com/mattpocock/skills) | Reproduce a fault before repair and route work by question type. | `.agents/skills/repair/references/reproduce.md`, `.agents/skills/triage/SKILL.md`. |
| [Matt Pocock's skills](https://github.com/mattpocock/skills) | Size a piece for one fresh session and keep dense build detail under a plain surface. | `.agents/skills/build-piece/references/build-limits.md`, `.agents/skills/records/references/pieces.md`. |
| [GitHub Spec Kit](https://github.com/github/spec-kit) | A read-only analysis that lists promises without a plan. | The coverage read, `.agents/skills/records/references/coverage-read.md`. |
| [OpenSpec concepts](https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md) | Carry a proposed record change with the piece and apply it when the work lands. | `.agents/skills/records/references/masterplan-changes.md`. |
| [Kiro's proposal to record what a spec was checked against](https://github.com/kirodotdev/Kiro/issues/9435) | Mark which saved code state a record was checked against. | `.agents/skills/records/scripts/trued-mark.sh`. |
| [Beads](https://github.com/gastownhall/beads/blob/main/docs/reference/faq.md) | Link new work to the build that found it. | The `Found while building` link, `.agents/skills/records/references/pieces.md`. |
| [GitHub Copilot's agentic memory](https://github.blog/ai-and-ml/github-copilot/building-an-agentic-memory-system-for-github-copilot/) | Use small cited facts only after checking them against the current project. | `.agents/agents/researcher.md`, `docs/MAINTAINING.md`. |
| [Damien C. Tanner, how Toyo works](https://x.com/dctanner/status/2034318024673464644) | Judge a change by what it could damage; use a prototype as a brief. | The risk record and fit check, `.agents/skills/fit-check/`, `.agents/skills/setup-ai-build-kit/templates/masterplan.md`. |
| ["Don't read the code"](https://matijacniacki.com/blog/dont-read-the-code) | The person need not read code; check the result against the brief in a fresh context. | `.agents/skills/second-opinion/SKILL.md`, `docs/PHILOSOPHY.md`. |
| [ReqToCode](https://arxiv.org/abs/2603.13999) and [StrictDoc](https://strictdoc.readthedocs.io/en/latest/latest/docs/strictdoc_01_user_guide.html) | A stale link between a written requirement and code is a failure. | `.agents/skills/quality-checks/references/document-read.md`, `.agents/skills/quality-checks/scripts/document-claims.py`. |
| [doc-drift](https://github.com/sunnydachs/doc-drift) and [the trust-allocation study](https://arxiv.org/abs/2604.03447) | Documents may omit facts but must not invent them; check names mechanically. | `.agents/skills/quality-checks/references/document-read.md`. |
| [GitHub CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) | Put a short path list beside the rule it applies to. | The risk-area map, `.agents/skills/setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh`. |
| [CCPM](https://github.com/automazeio/ccpm) | Use GitHub issues as the task record. | Pieces are GitHub issues, `.agents/skills/records/references/pieces.md`. |
| [Architecture decision records](https://martinfowler.com/articles/architecture-decision-records.html), as described by Martin Fowler | Record each settled choice with its reason, so a later session does not reopen it. | The `## Decided` section on a piece, `.agents/skills/records/references/pieces.md`. |
| [arc42](https://arc42.org/) and [C4 model](https://c4model.com/) | Show the tool and the systems it reaches. | The connections picture in the masterplan, `.agents/skills/setup-ai-build-kit/templates/masterplan.md`, `.agents/skills/records/SKILL.md`. |

## Review and teamwork

| Source | What it gave | Where it is in the kit |
|---|---|---|
| [obra/superpowers](https://github.com/obra/superpowers) | Ask one question at a time; stop after three failed repairs; use a reviewer who did not build the change. | `.agents/skills/clarify/SKILL.md`, `.agents/skills/repair/references/fixing.md`, `.agents/agents/reviewer.md`. |
| [Builder.io on subagents](https://www.builder.io/blog/subagents), [EveryInc compound engineering](https://github.com/EveryInc/compound-engineering-plugin), and [Maxi Contieri's notes](https://dev.to/mcsee/series/34999) | A builder is a poor judge of their own work; independent review needs a separate run. | `.agents/agents/reviewer.md`, `.agents/skills/second-opinion/SKILL.md`. |
| [Cloudflare, AI code review at scale](https://blog.cloudflare.com/ai-code-review/) | Keep review findings few and check each finding again. | `.agents/agents/refuter.md`. |
| [Claude Code subagents](https://code.claude.com/docs/en/sub-agents) | Define an agent in a short file with its tools and skills. | `.agents/agents/*.md`. |
| ["How we vibe code at a FAANG"](https://www.reddit.com/r/vibecoding/comments/1myakhd/how_we_vibe_code_at_a_faang/) | Read a plan closely before building. | Shaping and the coverage read, `.agents/skills/shape/SKILL.md`, `.agents/skills/records/references/coverage-read.md`. |

## Checks and evidence

| Source | What it gave | Where it is in the kit |
|---|---|---|
| [Simon Willison, agentic engineering](https://simonwillison.net/guides/agentic-engineering-patterns/) | A passing test suite is not proof by itself; report what ran and what happened. | `.agents/skills/evidence-run/SKILL.md`. |
| [trailofbits/skills](https://github.com/trailofbits/skills) | A check that inspects nothing must fail. | The starter placeholder check, `.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml`. |
| [TDAD](https://arxiv.org/abs/2603.17973) and [TestPrune](https://arxiv.org/abs/2510.18270) | Find which code a change reaches and run the tests that cover it. | `.agents/skills/quality-checks/references/reach-check.md`, `quality.py reach`. |
| [dependency-cruiser](https://github.com/sverweij/dependency-cruiser) | Read the import graph when checking which code a change reaches. | `depcruise`, `.agents/skills/quality-checks/scripts/quality.py`. |
| [StrykerJS incremental testing](https://stryker-mutator.io/docs/stryker-js/incremental/), [mutmut](https://mutmut.readthedocs.io/en/latest/), and [Awesome Testing's field note](https://www.awesome-testing.com/2026/08/mutation-testing-for-agent-written-code) | Change code on purpose and see whether tests catch it. | `.agents/skills/quality-checks/references/test-strength.md`, `quality.py strength`. |
| [Vulture](https://github.com/jendrikseipp/vulture) and [lizard](https://github.com/terryyin/lizard) | Report only what a tool is certain of and use its stated complexity limit. | `.agents/skills/quality-checks/scripts/quality.py`, `.agents/skills/quality-checks/references/trim.md`. |
| [sentrux](https://github.com/sentrux/sentrux), [ArchUnit](https://www.archunit.org/), and [import-linter](https://github.com/seddonym/import-linter/blob/main/docs/contract_types/protected.md) | Make rules about which code can reach other code pass or fail. | `.agents/skills/quality-checks/references/boundary-rules.md`. |
| [Semantic code clone detection study](https://arxiv.org/abs/2606.25272) | Limit the quarterly copy check to copied code. | `.agents/skills/quality-checks/references/waste-read.md`. |
| [ESLint ignore files](https://eslint.org/docs/latest/use/configure/ignore) | Keep installed kit files out of project lint checks. | `.agents/skills/quality-checks/references/check-floor.md`. |
| [Agentless](https://dl.acm.org/doi/full/10.1145/3715754), [LLM-guided bisection](https://arxiv.org/abs/2511.18854), [Cursor Debug Mode](https://cursor.com/blog/debug-mode), and [SWE-Doctor](https://arxiv.org/abs/2607.00990) | Reproduce a fault, find the saved change that caused it, and remove temporary instrumentation. | `.agents/skills/repair/references/reproduce.md`, `.agents/skills/repair/references/fixing.md`. |
| [OneUptime's structured logging guide](https://oneuptime.com/blog/post/2026-01-25-structured-logging-best-practices/view) | Record what each request did, in one consistent form, without sensitive contents. | The request record check before a tool goes live, `.agents/skills/setup-hosting/scripts/run-recipe.sh`; `.agents/skills/repair/references/reproduce.md` reads that record. |
| [ImpossibleBench](https://arxiv.org/abs/2510.20270) and [tests written after code inherit its flaws](https://arxiv.org/abs/2410.21136) | Keep existing tests fixed; explain why a test changes. | `.agents/skills/setup-ai-build-kit/templates/foundation/check-tests.sh`. |
| [Martin Fowler and Birgitta Boeckeler, Harness Engineering for Coding Agent Users](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html) | Use machine checks for rules a machine can judge, and prose for human judgement. | `docs/PHILOSOPHY.md`, `.agents/skills/quality-checks/SKILL.md`. |

## Skills and standing instructions

| Source | What it gave | Where it is in the kit |
|---|---|---|
| [HumanLayer, Skill Issue: Harness Engineering](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents) | Start with few instructions and use separate contexts for review. | `docs/PHILOSOPHY.md`, `.agents/agents/`. |
| [jeffallan/claude-skills](https://github.com/jeffallan/claude-skills) | Keep each skill short and load reference files when needed. | `.agents/skills/*/SKILL.md` and their `references/` folders. |
| [Agent Skills specification](https://agentskills.io/specification) and [Agent Skills best practices](https://agentskills.io/skill-creation/best-practices) | Give each skill one job and load its references only when needed. | The layout of `.agents/skills/*/`. |
| [IFScale](https://arxiv.org/abs/2507.11538) | Evidence that models can miss instructions when too many are active. | Short command files and on-demand background skills, `.agents/skills/`, `.agents/tools/check-structure.py`. |
| [ETH Zurich, Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988), [Configuration Smells in AGENTS.md](https://arxiv.org/abs/2606.15828), and [Anthropic's memory guidance](https://code.claude.com/docs/en/memory) | Keep standing instructions to practices that code cannot show and trim excess context. | `.agents/skills/maintain/scripts/standing-lines.sh`, `.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md`. |

## Running and release work

| Source | What it gave | Where it is in the kit |
|---|---|---|
| [Geoffrey Huntley's Ralph technique](https://ghuntley.com/ralph/) and [Clayton Farr's Ralph Playbook](https://github.com/ClaytonFarr/ralph-playbook) | When a long run fails, change the instructions and run it again. | `.agents/skills/implement/references/running-longer.md`. |
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | Run several pieces after one approval and check a supplier's own documentation. | `.agents/skills/implement/references/running-longer.md`, `.agents/skills/research/SKILL.md`. |
| [Agent Flywheel](https://agent-flywheel.com/complete-guide), by Jeffrey Emanuel | List commands that can destroy work; a written rule is not enforced by itself. | `.agents/guard/blocked-commands.md`, `.agents/skills/setup-ai-build-kit/templates/foundation/guard-secrets.py`. |
| [Carsten Jørgensen, harness engineering](https://harness-engineering.carstenj.workers.dev/) | Disable dangerous commands instead of relying on a warning. | `.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json`, `.agents/skills/setup-ai-build-kit/references/blocked-commands.md`. |
| [tw93/waza](https://github.com/tw93/waza) | Keep a small fixed number of commands and add abilities to existing commands. | `.agents/tools/kit-inventory.txt`, `.agents/tools/validate-kit.sh`. |
| [Husky](https://github.com/typicode/husky/blob/main/index.js) and [Codex non-interactive mode](https://learn.chatgpt.com/docs/non-interactive-mode) | Keep the push guard in the person's hook; run replay conversations through `codex exec`. | `.agents/skills/setup-ai-build-kit/scripts/use-push-guard.sh`, `.agents/tests/replay/`. |
| [GitHub rulesets and branch protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) and [branch protection API](https://docs.github.com/en/rest/branches/branch-protection) | Require the project check on the main branch, including for administrators. | `.agents/skills/merge/scripts/protect-branch.py`. |
| [GitHub CLI environment](https://cli.github.com/manual/gh_help_environment) and [Codex configuration](https://developers.openai.com/codex/config-reference/) | Pass the current GitHub login into a fresh Codex process without changing global settings. | `.agents/skills/setup-ai-build-kit/scripts/`, `.agents/skills/setup-ai-build-kit/references/codex-github.md`. |
| [Codex hooks](https://learn.chatgpt.com/docs/hooks) and [Git configuration](https://git-scm.com/docs/git-config#Documentation/git-config.txt-GITCONFIGCOUNT) | Check GitHub access before work and share the session login with Git. | `.agents/skills/setup-ai-build-kit/scripts/`, `.agents/skills/setup-ai-build-kit/references/codex-github.md`. |
| [GitHub CLI authentication refresh](https://cli.github.com/manual/gh_auth_refresh), [authentication status](https://cli.github.com/manual/gh_auth_status), and [pull request checks](https://cli.github.com/manual/gh_pr_checks) | Request workflow permission in the person's terminal, check the active account, and treat pending checks as a separate result. | `.agents/skills/setup-ai-build-kit/scripts/workflow-upload-check.py`, `.agents/skills/setup-ai-build-kit/scripts/check-tooling.sh`, `.agents/skills/merge/scripts/merge.py`. |

## Hosting and recovery

| Source | What it gave | Where it is in the kit |
|---|---|---|
| [coolify-devops](https://github.com/KasperHonore/coolify-devops) | The fields for a hosting request and a person carrying it to the server. | `.agents/skills/setup-hosting/recipes/nextjs-supabase-on-coolify/hosting-request.md`. |
| [Google's SRE book](https://sre.google/sre-book/table-of-contents/), [DORA delivery metrics](https://dora.dev/guides/dora-metrics/), and [Continuous Delivery](https://continuousdelivery.com/) | Make recovery its own step; check the live copy after a release. | `.agents/skills/live-copy/SKILL.md`, `.agents/skills/merge/scripts/merge.py`. |
| [BoringStack](https://boringstack.xyz/) and [Boring Stack](https://boringstack.org/) | Use a short menu of proven defaults and treat an empty project as a normal start. | `.agents/skills/setup-hosting/recipes/`, `.agents/skills/setup-ai-build-kit/references/completion-report.md`. |
| [Thoughtworks Technology Radar](https://www.thoughtworks.com/radar) | Review tools on a fixed cycle and date each review. | `.agents/maintainer-skills/stack-research/SKILL.md`. |
| [Intercom, The Safety of Speed](https://www.intercom.com/blog/safety-of-speed/) | Make rollback a planned step and keep changes small. | `.agents/skills/live-copy/SKILL.md`, `.agents/skills/build-piece/references/build-limits.md`. |
| [OpenAI, harness engineering](https://www.infoq.com/news/2026/02/openai-harness-engineering-codex/) | Review documents for changes that no longer match the code. | `.agents/skills/quality-checks/references/document-read.md`. |

## Screen design

| Source | What it gave | Where it is in the kit |
|---|---|---|
| [Vercel Web Interface Guidelines](https://github.com/vercel-labs/web-interface-guidelines/blob/main/AGENTS.md), [Impeccable craft floor](https://github.com/pbakaus/impeccable/blob/main/skill/reference/craft-floor.md), [GOV.UK Design System](https://design-system.service.gov.uk/), [Nielsen Norman Group](https://www.nngroup.com/articles/ten-usability-heuristics/), [Carbon](https://carbondesignsystem.com/), [Shopify Polaris](https://polaris.shopify.com/), and [WCAG 2.2](https://www.w3.org/WAI/WCAG22/quickref/) | Screen rules for visible labels, errors, focus, spacing and empty states. | `.agents/skills/screen-check/SKILL.md`. |

Copyright © 2023 W3C®. This software or document includes material copied from or derived from [How to Meet WCAG, Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/).
