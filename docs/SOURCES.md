# Sources

AI Build Kit grew from the private `claude-kernel-builder` and its output, `claude-kernel`, then from the private `agentic-dev-skills`, and then into this kit.

This list names ideas used in the kit and where they appear.

## Records and planning

- [28 Days of Lovable](https://28daysoflovable.com/), by Lazar Jovanovic.
  - **Contributed:** one master document as the source of truth, with a next item and a named check. **In the kit:** the project record and work rhythm, `.agents/skills/setup-ai-build-kit/templates/masterplan.md`, `.agents/skills/records/SKILL.md`.
- [Alex Lavaee, the new software lifecycle](https://alexlavaee.me/blog/new-sdlc-agentic-engineering/).
  - **Contributed:** documents hold the decisions; code is their current form. **In the kit:** project records and changes to them, `docs/PHILOSOPHY.md`, `.agents/skills/records/references/masterplan-changes.md`.
- [Alex Lavaee, from RPI to QRSPI](https://alexlavaee.me/blog/from-rpi-to-qrspi/).
  - **Contributed:** build vertical slices instead of layers. **In the kit:** one-sitting pieces and shaping, `.agents/skills/records/references/pieces.md`, `.agents/skills/shape/SKILL.md`.
- [Dex Horthy, Advanced Context Engineering for Agents](https://www.youtube.com/watch?v=VvkhYWFWaKI).
  - **Contributed:** a workflow should not depend on special phrasing. **In the kit:** shaping names the piece and its next step, `.agents/skills/shape/SKILL.md`. The link to this specific idea needs maintainer confirmation.
- [Matt Pocock's skills](https://github.com/mattpocock/skills).
  - **Contributed:** attach a best guess to each question; use a small prototype to settle a choice. **In the kit:** interview and prototype steps, `.agents/skills/clarify/SKILL.md`, `.agents/skills/clarify/references/decision-prototype.md`.
  - **Contributed:** reproduce a fault before repair and route work by question type. **In the kit:** `.agents/skills/repair/references/reproduce.md`, `.agents/skills/triage/SKILL.md`.
  - **Contributed:** size a piece for one fresh session and keep dense build detail under a plain surface. **In the kit:** `.agents/skills/build-piece/references/build-limits.md`, `.agents/skills/records/references/pieces.md`.
- [GitHub Spec Kit](https://github.com/github/spec-kit).
  - **Contributed:** a read-only analysis that lists promises without a plan. **In the kit:** the coverage read, `.agents/skills/records/references/coverage-read.md`.
- [OpenSpec concepts](https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md).
  - **Contributed:** carry a proposed record change with the piece and apply it when the work lands. **In the kit:** `.agents/skills/records/references/masterplan-changes.md`.
- [Kiro's proposal to record what a spec was checked against](https://github.com/kirodotdev/Kiro/issues/9435).
  - **Contributed:** mark which saved code state a record was checked against. **In the kit:** `.agents/skills/records/scripts/trued-mark.sh`.
- [Beads](https://github.com/gastownhall/beads/blob/main/docs/reference/faq.md).
  - **Contributed:** link new work to the build that found it. **In the kit:** the `Found while building` link, `.agents/skills/records/references/pieces.md`.
- [GitHub Copilot's agentic memory](https://github.blog/ai-and-ml/github-copilot/building-an-agentic-memory-system-for-github-copilot/).
  - **Contributed:** use small cited facts only after checking them against the current project. **In the kit:** `.agents/agents/researcher.md`, `docs/MAINTAINING.md`.
- [Damien C. Tanner, how Toyo works](https://x.com/dctanner/status/2034318024673464644).
  - **Contributed:** judge a change by what it could damage; use a prototype as a brief. **In the kit:** the risk record and fit check, `.agents/skills/fit-check/`, `.agents/skills/setup-ai-build-kit/templates/masterplan.md`.
- ["Don't read the code"](https://matijacniacki.com/blog/dont-read-the-code).
  - **Contributed:** the person need not read code; check the result against the brief in a fresh context. **In the kit:** `.agents/skills/second-opinion/SKILL.md`, `docs/PHILOSOPHY.md`.
- [ReqToCode](https://arxiv.org/abs/2603.13999) and [StrictDoc](https://strictdoc.readthedocs.io/en/latest/latest/docs/strictdoc_01_user_guide.html).
  - **Contributed:** a stale link between a written requirement and code is a failure. **In the kit:** `.agents/skills/quality-checks/references/document-read.md`, `.agents/skills/quality-checks/scripts/document-claims.py`.
- [doc-drift](https://github.com/sunnydachs/doc-drift) and [the trust-allocation study](https://arxiv.org/abs/2604.03447).
  - **Contributed:** documents may omit facts but must not invent them; check names mechanically. **In the kit:** `.agents/skills/quality-checks/references/document-read.md`.
- [GitHub CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners).
  - **Contributed:** put a short path list beside the rule it applies to. **In the kit:** the risk-area map, `.agents/skills/setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh`.
- [CCPM](https://github.com/automazeio/ccpm).
  - **Contributed:** use GitHub issues as the task record. **In the kit:** pieces are GitHub issues, `.agents/skills/records/references/pieces.md`.
- [Martin Fowler, architecture decision records](https://martinfowler.com/articles/architecture-decision-records.html) and [O'Reilly, "Coding agents love decision records"](https://www.oreilly.com/radar/coding-agents-love-decision-records/).
  - **Contributed:** record the reason for a settled choice. **In the kit:** the `## Decided` section on a piece, `.agents/skills/records/references/pieces.md`. The source link needs maintainer confirmation.
- [arc42](https://arc42.org/) and [C4 model](https://c4model.com/).
  - **Contributed:** show the tool and the systems it reaches. **In the kit:** the connections picture in the masterplan, `.agents/skills/setup-ai-build-kit/templates/masterplan.md`, `.agents/skills/records/SKILL.md`.

## Review and teamwork

- [obra/superpowers](https://github.com/obra/superpowers).
  - **Contributed:** ask one question at a time; stop after three failed repairs; use a reviewer who did not build the change. **In the kit:** `.agents/skills/clarify/SKILL.md`, `.agents/skills/repair/references/fixing.md`, `.agents/agents/reviewer.md`.
- [Builder.io on subagents](https://www.builder.io/blog/subagents), [EveryInc compound engineering](https://github.com/EveryInc/compound-engineering-plugin), and [Maxi Contieri's notes](https://dev.to/mcsee/series/34999).
  - **Contributed:** a builder is a poor judge of their own work; independent review needs a separate run. **In the kit:** `.agents/agents/reviewer.md`, `.agents/skills/second-opinion/SKILL.md`.
- [Cloudflare, AI code review at scale](https://blog.cloudflare.com/ai-code-review/).
  - **Contributed:** keep review findings few and check each finding again. **In the kit:** `.agents/agents/refuter.md`.
- [Claude Code subagents](https://code.claude.com/docs/en/sub-agents).
  - **Contributed:** define an agent in a short file with its tools and skills. **In the kit:** `.agents/agents/*.md`.
- [Anthropic's Claude Code review plugin and Code Review docs](https://code.claude.com/docs/en/code-review).
  - **Contributed:** use narrow review passes, a confidence filter and repository review rules. **In the kit:** review design, `.agents/skills/second-opinion/SKILL.md`. The link to this specific influence needs maintainer confirmation.
- ["How we vibe code at a FAANG"](https://www.reddit.com/r/vibecoding/comments/1myakhd/how_we_vibe_code_at_a_faang/).
  - **Contributed:** read a plan closely before building. **In the kit:** shaping and the coverage read, `.agents/skills/shape/SKILL.md`, `.agents/skills/records/references/coverage-read.md`. The link to this specific influence needs maintainer confirmation.

## Checks and evidence

- [Simon Willison, agentic engineering](https://simonwillison.net/guides/agentic-engineering-patterns/).
  - **Contributed:** a passing test suite is not proof by itself; report what ran and what happened. **In the kit:** `.agents/skills/evidence-run/SKILL.md`.
- [trailofbits/skills](https://github.com/trailofbits/skills).
  - **Contributed:** a check that inspects nothing must fail. **In the kit:** the starter placeholder check, `.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml`.
- [TDAD](https://arxiv.org/abs/2603.17973) and [TestPrune](https://arxiv.org/abs/2510.18270).
  - **Contributed:** find which code a change reaches and run the tests that cover it. **In the kit:** `.agents/skills/quality-checks/references/reach-check.md`, `quality.py reach`.
- [dependency-cruiser](https://github.com/sverweij/dependency-cruiser).
  - **Contributed:** read the import graph when checking which code a change reaches. **In the kit:** `depcruise`, `.agents/skills/quality-checks/scripts/quality.py`.
- [StrykerJS incremental testing](https://stryker-mutator.io/docs/stryker-js/incremental/), [mutmut](https://mutmut.readthedocs.io/en/latest/), and [Awesome Testing's field note](https://www.awesome-testing.com/2026/08/mutation-testing-for-agent-written-code).
  - **Contributed:** change code on purpose and see whether tests catch it. **In the kit:** `.agents/skills/quality-checks/references/test-strength.md`, `quality.py strength`.
- [Vulture](https://github.com/jendrikseipp/vulture) and [lizard](https://github.com/terryyin/lizard).
  - **Contributed:** report only what a tool is certain of and use its stated complexity limit. **In the kit:** `.agents/skills/quality-checks/scripts/quality.py`, `.agents/skills/quality-checks/references/trim.md`.
- [sentrux](https://github.com/sentrux/sentrux), [ArchUnit](https://www.archunit.org/), and [import-linter](https://github.com/seddonym/import-linter/blob/main/docs/contract_types/protected.md).
  - **Contributed:** make rules about which code can reach other code pass or fail. **In the kit:** `.agents/skills/quality-checks/references/boundary-rules.md`.
- [Semantic code clone detection study](https://arxiv.org/abs/2606.25272).
  - **Contributed:** limit the quarterly copy check to copied code. **In the kit:** `.agents/skills/quality-checks/references/waste-read.md`.
- [ESLint ignore files](https://eslint.org/docs/latest/use/configure/ignore).
  - **Contributed:** keep installed kit files out of project lint checks. **In the kit:** `.agents/skills/quality-checks/references/check-floor.md`.
- [Agentless](https://dl.acm.org/doi/full/10.1145/3715754), [LLM-guided bisection](https://arxiv.org/abs/2511.18854), [Cursor Debug Mode](https://cursor.com/blog/debug-mode), and [SWE-Doctor](https://arxiv.org/abs/2607.00990).
  - **Contributed:** reproduce a fault, find the saved change that caused it, and remove temporary instrumentation. **In the kit:** `.agents/skills/repair/references/reproduce.md`, `.agents/skills/repair/references/fixing.md`.
- [OneUptime's structured logging guide](https://oneuptime.com/blog/post/2026-01-25-structured-logging-best-practices/view).
  - **Contributed:** use evidence from a running tool to reproduce a fault. **In the kit:** `.agents/skills/repair/references/reproduce.md` reads the project's request record. A shared request identifier is not confirmed, so this credit needs maintainer review.
- [ImpossibleBench](https://arxiv.org/abs/2510.20270) and [tests written after code inherit its flaws](https://arxiv.org/abs/2410.21136).
  - **Contributed:** keep existing tests fixed; explain why a test changes. **In the kit:** `.agents/skills/setup-ai-build-kit/templates/foundation/check-tests.sh`. The ImpossibleBench link needs maintainer confirmation.
- [Martin Fowler and Birgitta Boeckeler, Harness Engineering for Coding Agent Users](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html).
  - **Contributed:** use machine checks for rules a machine can judge, and prose for human judgement. **In the kit:** `docs/PHILOSOPHY.md`, `.agents/skills/quality-checks/SKILL.md`.
## Skills and standing instructions

- [HumanLayer, Skill Issue: Harness Engineering](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents).
  - **Contributed:** start with few instructions and use separate contexts for review. **In the kit:** `docs/PHILOSOPHY.md`, `.agents/agents/`.
- [jeffallan/claude-skills](https://github.com/jeffallan/claude-skills).
  - **Contributed:** keep each skill short and load reference files when needed. **In the kit:** `.agents/skills/*/SKILL.md` and their `references/` folders.
- [Agent Skills specification](https://agentskills.io/specification) and [Agent Skills best practices](https://agentskills.io/skill-creation/best-practices).
  - **Contributed:** give each skill one job and load its references only when needed. **In the kit:** the layout of `.agents/skills/*/`.
- [IFScale](https://arxiv.org/abs/2507.11538).
  - **Contributed:** evidence that models can miss instructions when too many are active. **In the kit:** short command files and on-demand background skills, `.agents/skills/`, `.agents/tools/check-structure.py`.
- [ETH Zurich, Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988), [Configuration Smells in AGENTS.md](https://arxiv.org/abs/2606.15828), and [Anthropic's memory guidance](https://code.claude.com/docs/en/memory).
  - **Contributed:** keep standing instructions to practices that code cannot show and trim excess context. **In the kit:** `.agents/skills/maintain/scripts/standing-lines.sh`, `.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md`.
## Running and release work

- [Geoffrey Huntley's Ralph technique](https://ghuntley.com/ralph/) and [Clayton Farr's Ralph Playbook](https://github.com/ClaytonFarr/ralph-playbook).
  - **Contributed:** when a long run fails, change the instructions and run it again. **In the kit:** `.agents/skills/implement/references/running-longer.md`.
- [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills).
  - **Contributed:** run several pieces after one approval and check a supplier's own documentation. **In the kit:** `.agents/skills/implement/references/running-longer.md`, `.agents/skills/research/SKILL.md`.
- [Agent Flywheel](https://agent-flywheel.com/complete-guide), by Jeffrey Emanuel.
  - **Contributed:** list commands that can destroy work; a written rule is not enforced by itself. **In the kit:** `.agents/guard/blocked-commands.md`, `.agents/skills/setup-ai-build-kit/templates/foundation/guard-secrets.py`.
- [Carsten Jørgensen, harness engineering](https://harness-engineering.carstenj.workers.dev/).
  - **Contributed:** disable dangerous commands instead of relying on a warning. **In the kit:** `.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json`, `.agents/skills/setup-ai-build-kit/references/blocked-commands.md`.
- [tw93/waza](https://github.com/tw93/waza).
  - **Contributed:** keep a small fixed number of commands and add abilities to existing commands. **In the kit:** `.agents/tools/kit-inventory.txt`, `.agents/tools/validate-kit.sh`.
- [Husky](https://github.com/typicode/husky/blob/main/index.js) and [Codex non-interactive mode](https://learn.chatgpt.com/docs/non-interactive-mode).
  - **Contributed:** keep the push guard in the person's hook; run replay conversations through `codex exec`. **In the kit:** `.agents/skills/setup-ai-build-kit/scripts/use-push-guard.sh`, `.agents/tests/replay/`.
- [GitHub rulesets and branch protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) and [branch protection API](https://docs.github.com/en/rest/branches/branch-protection).
  - **Contributed:** require the project check on the main branch, including for administrators. **In the kit:** `.agents/skills/merge/scripts/protect-branch.py`.
- [GitHub CLI environment](https://cli.github.com/manual/gh_help_environment) and [Codex configuration](https://developers.openai.com/codex/config-reference/).
  - **Contributed:** pass the current GitHub login into a fresh Codex process without changing global settings. **In the kit:** `.agents/skills/setup-ai-build-kit/scripts/`, `.agents/skills/setup-ai-build-kit/references/codex-github.md`.
- [Codex hooks](https://learn.chatgpt.com/docs/hooks) and [Git configuration](https://git-scm.com/docs/git-config#Documentation/git-config.txt-GITCONFIGCOUNT).
  - **Contributed:** check GitHub access before work and share the session login with Git. **In the kit:** `.agents/skills/setup-ai-build-kit/scripts/`, `.agents/skills/setup-ai-build-kit/references/codex-github.md`.
- [GitHub CLI authentication refresh](https://cli.github.com/manual/gh_auth_refresh), [authentication status](https://cli.github.com/manual/gh_auth_status), and [pull request checks](https://cli.github.com/manual/gh_pr_checks).
  - **Contributed:** request workflow permission in the person's terminal, check the active account, and treat pending checks as a separate result. **In the kit:** `.agents/skills/setup-ai-build-kit/scripts/workflow-upload-check.py`, `.agents/skills/setup-ai-build-kit/scripts/check-tooling.sh`, `.agents/skills/merge/scripts/merge.py`.

## Hosting and recovery

- [coolify-devops](https://github.com/KasperHonore/coolify-devops).
  - **Contributed:** the fields for a hosting request and a person carrying it to the server. **In the kit:** `.agents/skills/setup-hosting/recipes/nextjs-supabase-on-coolify/hosting-request.md`.
- [Google's SRE book](https://sre.google/sre-book/table-of-contents/), [DORA delivery metrics](https://dora.dev/guides/dora-metrics/), and [Continuous Delivery](https://continuousdelivery.com/).
  - **Contributed:** make recovery its own step; check the live copy after a release. **In the kit:** `.agents/skills/live-copy/SKILL.md`, `.agents/skills/merge/scripts/merge.py`.
- [BoringStack](https://boringstack.xyz/) and [Boring Stack](https://boringstack.org/).
  - **Contributed:** use a short menu of proven defaults and treat an empty project as a normal start. **In the kit:** `.agents/skills/setup-hosting/recipes/`, `.agents/skills/setup-ai-build-kit/references/completion-report.md`.
- [Thoughtworks Technology Radar](https://www.thoughtworks.com/radar).
  - **Contributed:** review tools on a fixed cycle and date each review. **In the kit:** `.agents/maintainer-skills/stack-research/SKILL.md`.
- [Intercom, The Safety of Speed](https://www.intercom.com/blog/safety-of-speed/).
  - **Contributed:** make rollback a planned step and keep changes small. **In the kit:** `.agents/skills/live-copy/SKILL.md`, `.agents/skills/build-piece/references/build-limits.md`.
- [OpenAI, harness engineering](https://www.infoq.com/news/2026/02/openai-harness-engineering-codex/).
  - **Contributed:** review documents for changes that no longer match the code. **In the kit:** `.agents/skills/quality-checks/references/document-read.md`.

## Screen design

- [Vercel Web Interface Guidelines](https://github.com/vercel-labs/web-interface-guidelines/blob/main/AGENTS.md), [Impeccable craft floor](https://github.com/pbakaus/impeccable/blob/main/skill/reference/craft-floor.md), [GOV.UK Design System](https://design-system.service.gov.uk/), [Nielsen Norman Group](https://www.nngroup.com/articles/ten-usability-heuristics/), [Carbon](https://carbondesignsystem.com/), [Shopify Polaris](https://polaris.shopify.com/), and [WCAG 2.2](https://www.w3.org/WAI/WCAG22/quickref/).
  - **Contributed:** screen rules for visible labels, errors, focus, spacing and empty states. **In the kit:** `.agents/skills/screen-check/SKILL.md`.

Copyright © 2023 W3C®. This software or document includes material copied from or derived from [How to Meet WCAG, Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/).
