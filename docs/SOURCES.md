# Sources

AI Build Kit grew from the private `claude-kernel-builder` and its output, `claude-kernel`, then from the private `agentic-dev-skills`, and then into this kit.

This list identifies ideas used in the kit and the files that implement them.

## Records and planning

| Source | Contribution | Where it is in the kit |
|---|---|---|
| [28 Days of Lovable](https://28daysoflovable.com/), by Lazar Jovanovic | A single authoritative project document, with a next step and a named check. | The masterplan and the process for recording work, `.agents/skills/setup-ai-build-kit/templates/masterplan.md`, `.agents/skills/records/SKILL.md`. |
| [Alex Lavaee, the new software lifecycle](https://alexlavaee.me/blog/new-sdlc-agentic-engineering/) | Record decisions in documents, with code implementing the current decisions. | Project records and changes to them, `docs/PHILOSOPHY.md`, `.agents/skills/records/references/masterplan-changes.md`. |
| [Alex Lavaee, from RPI to QRSPI](https://alexlavaee.me/blog/from-rpi-to-qrspi/) | Build complete features in small pieces rather than implementing one technical layer at a time. | Pieces small enough for one session and the shaping process, `.agents/skills/records/references/pieces.md`, `.agents/skills/shape/SKILL.md`. |
| [Dex Horthy, Advanced Context Engineering for Agents](https://www.youtube.com/watch?v=VvkhYWFWaKI) | Build each piece across the parts needed for a working feature, rather than completing one technical layer at a time. | Pieces small enough for one session, `.agents/skills/records/references/pieces.md`, `.agents/skills/shape/SKILL.md`. |
| [Matt Pocock's skills](https://github.com/mattpocock/skills) | Offer a provisional answer with each question; use a small prototype to resolve a decision. | Interview and prototype steps, `.agents/skills/clarify/SKILL.md`, `.agents/skills/clarify/references/decision-prototype.md`. |
| [Matt Pocock's skills](https://github.com/mattpocock/skills) | Reproduce a fault before attempting a repair and choose the workflow according to the type of question. | `.agents/skills/repair/references/reproduce.md`, `.agents/skills/triage/SKILL.md`. |
| [Matt Pocock's skills](https://github.com/mattpocock/skills) | Keep each piece within one session and place implementation detail beneath a plain-language description. | `.agents/skills/build-piece/references/build-limits.md`, `.agents/skills/records/references/pieces.md`. |
| [GitHub Spec Kit](https://github.com/github/spec-kit) | Identify requirements that no piece covers, without changing the records. | The requirements coverage review, `.agents/skills/records/references/coverage-read.md`. |
| [OpenSpec concepts](https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md) | Include proposed changes to project records with each piece and apply them when the work is saved. | `.agents/skills/records/references/masterplan-changes.md`. |
| [Kiro's proposal to record what a spec was checked against](https://github.com/kirodotdev/Kiro/issues/9435) | Record the saved version of the code against which a document was checked. | `.agents/skills/records/scripts/trued-mark.sh`. |
| [Beads](https://github.com/gastownhall/beads/blob/main/docs/reference/faq.md) | Link new work to the build that found it. | The `Found while building` link, `.agents/skills/records/references/pieces.md`. |
| [GitHub Copilot's agentic memory](https://github.blog/ai-and-ml/github-copilot/building-an-agentic-memory-system-for-github-copilot/) | Use concise, sourced facts only after checking them against the current project. | `.agents/agents/researcher.md`, `docs/MAINTAINING.md`. |
| [Damien C. Tanner, how Toyo works](https://x.com/dctanner/status/2034318024673464644) | Judge a change by what it could damage; use a prototype as a brief. | The risk record and fit check, `.agents/skills/fit-check/`, `.agents/skills/setup-ai-build-kit/templates/masterplan.md`. |
| ["Don't read the code"](https://matijacniacki.com/blog/dont-read-the-code) | The person need not read code; check the result against the brief in a fresh context. | `.agents/skills/second-opinion/SKILL.md`, `docs/PHILOSOPHY.md`. |
| [ReqToCode](https://arxiv.org/abs/2603.13999) and [StrictDoc](https://strictdoc.readthedocs.io/en/latest/latest/docs/strictdoc_01_user_guide.html) | Treat an outdated reference between a written requirement and the code as a failure. | `.agents/skills/quality-checks/references/document-read.md`, `.agents/skills/quality-checks/scripts/document-claims.py`. |
| [doc-drift](https://github.com/sunnydachs/doc-drift) and [the trust-allocation study](https://arxiv.org/abs/2604.03447) | Documentation may omit facts but must not invent them; use automated checks to verify names. | `.agents/skills/quality-checks/references/document-read.md`. |
| [GitHub CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) | List the relevant file paths beside each rule. | The risk-area map, `.agents/skills/setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh`. |
| [CCPM](https://github.com/automazeio/ccpm) | Use GitHub issues as the task record. | Pieces are GitHub issues, `.agents/skills/records/references/pieces.md`. |
| [Architecture decision records](https://martinfowler.com/articles/architecture-decision-records.html), as described by Martin Fowler | Record each settled choice with its reason, so a later session does not reopen it. | The `## Decided` section on a piece, `.agents/skills/records/references/pieces.md`. |
| [arc42](https://arc42.org/) and [C4 model](https://c4model.com/) | Diagram the tool and the external systems it connects to. | The system connections diagram in the masterplan, `.agents/skills/setup-ai-build-kit/templates/masterplan.md`, `.agents/skills/records/SKILL.md`. |

## Review and teamwork

| Source | Contribution | Where it is in the kit |
|---|---|---|
| [obra/superpowers](https://github.com/obra/superpowers) | Ask one question at a time; pause after three failed repair attempts to reassess the cause and explain the risk; use a reviewer who did not build the change. | `.agents/skills/clarify/SKILL.md`, `.agents/skills/repair/references/fixing.md`, `.agents/agents/reviewer.md`. |
| [Builder.io on subagents](https://www.builder.io/blog/subagents), [EveryInc compound engineering](https://github.com/EveryInc/compound-engineering-plugin), and [Maxi Contieri's notes](https://dev.to/mcsee/series/34999) | A builder is a poor judge of their own work; independent review needs a separate run. | `.agents/agents/reviewer.md`, `.agents/skills/second-opinion/SKILL.md`. |
| [Cloudflare, AI code review at scale](https://blog.cloudflare.com/ai-code-review/) | Keep the number of review findings small and check each finding again. | `.agents/agents/refuter.md`. |
| [Claude Code subagents](https://code.claude.com/docs/en/sub-agents) | Define each agent in a short file that specifies its tools and skills. | `.agents/agents/*.md`. |
| ["How we vibe code at a FAANG"](https://www.reddit.com/r/vibecoding/comments/1myakhd/how_we_vibe_code_at_a_faang/) | Read a plan closely before building. | Shaping and the requirements coverage review, `.agents/skills/shape/SKILL.md`, `.agents/skills/records/references/coverage-read.md`. |

## Checks and evidence

| Source | Contribution | Where it is in the kit |
|---|---|---|
| [Simon Willison, agentic engineering](https://simonwillison.net/guides/agentic-engineering-patterns/) | A passing test suite is not proof by itself; report what ran and what happened. | `.agents/skills/evidence-run/SKILL.md`. |
| [trailofbits/skills](https://github.com/trailofbits/skills) | A check that inspects nothing must fail. | The starter placeholder check, `.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml`. |
| [TDAD](https://arxiv.org/abs/2603.17973) and [TestPrune](https://arxiv.org/abs/2510.18270) | Identify code affected by a change and run the tests that cover it. | `.agents/skills/quality-checks/references/reach-check.md`, `quality.py reach`. |
| [dependency-cruiser](https://github.com/sverweij/dependency-cruiser) | Use the import graph, a map of dependencies between code files, to identify code affected by a change. | `depcruise`, `.agents/skills/quality-checks/scripts/quality.py`. |
| [StrykerJS incremental testing](https://stryker-mutator.io/docs/stryker-js/incremental/), [mutmut](https://mutmut.readthedocs.io/en/latest/), and [Awesome Testing's field note](https://www.awesome-testing.com/2026/08/mutation-testing-for-agent-written-code) | Deliberately change code to test whether the tests detect the fault. | `.agents/skills/quality-checks/references/test-strength.md`, `quality.py strength`. |
| [Vulture](https://github.com/jendrikseipp/vulture) and [lizard](https://github.com/terryyin/lizard) | Report only what a tool is certain of and use its stated complexity limit. | `.agents/skills/quality-checks/scripts/quality.py`, `.agents/skills/quality-checks/references/trim.md`. |
| [sentrux](https://github.com/sentrux/sentrux), [ArchUnit](https://www.archunit.org/), and [import-linter](https://github.com/seddonym/import-linter/blob/main/docs/contract_types/protected.md) | Enforce rules that restrict which parts of the code may access other parts. | `.agents/skills/quality-checks/references/boundary-rules.md`. |
| [Semantic code clone detection study](https://arxiv.org/abs/2606.25272) | Limit the quarterly duplication check to copied code. | `.agents/skills/quality-checks/references/waste-read.md`. |
| [ESLint ignore files](https://eslint.org/docs/latest/use/configure/ignore) | Exclude installed kit files from project linting, which checks code against style and error rules. | `.agents/skills/quality-checks/references/check-floor.md`. |
| [Agentless](https://dl.acm.org/doi/full/10.1145/3715754), [LLM-guided bisection](https://arxiv.org/abs/2511.18854), [Cursor Debug Mode](https://cursor.com/blog/debug-mode), and [SWE-Doctor](https://arxiv.org/abs/2607.00990) | Reproduce a fault, identify the saved change that caused it, and remove temporary diagnostic code. | `.agents/skills/repair/references/reproduce.md`, `.agents/skills/repair/references/fixing.md`. |
| [OneUptime's structured logging guide](https://oneuptime.com/blog/post/2026-01-25-structured-logging-best-practices/view) | Record each request’s actions in a consistent format, without sensitive content. | The request logging check before launch, `.agents/skills/setup-hosting/scripts/run-recipe.sh`; `.agents/skills/repair/references/reproduce.md` uses those logs. |
| [ImpossibleBench](https://arxiv.org/abs/2510.20270) and [tests written after code inherit its flaws](https://arxiv.org/abs/2410.21136) | Keep existing tests fixed; explain why a test changes. | `.agents/skills/setup-ai-build-kit/templates/foundation/check-tests.sh`. |
| [Martin Fowler and Birgitta Boeckeler, Harness Engineering for Coding Agent Users](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html) | Use automated checks for testable rules and written instructions for decisions requiring judgement. | `docs/PHILOSOPHY.md`, `.agents/skills/quality-checks/SKILL.md`. |

## Skills and standing instructions

| Source | Contribution | Where it is in the kit |
|---|---|---|
| [HumanLayer, Skill Issue: Harness Engineering](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents) | Start with a small set of instructions and review work in separate agent sessions. | `docs/PHILOSOPHY.md`, `.agents/agents/`. |
| [jeffallan/claude-skills](https://github.com/jeffallan/claude-skills) | Keep each skill short and load reference files when needed. | `.agents/skills/*/SKILL.md` and their `references/` folders. |
| [Agent Skills specification](https://agentskills.io/specification) and [Agent Skills best practices](https://agentskills.io/skill-creation/best-practices) | Give each skill one job and load its references only when needed. | The layout of `.agents/skills/*/`. |
| [IFScale](https://arxiv.org/abs/2507.11538) | Evidence that models can miss instructions when too many apply at once. | Short command files and on-demand background skills, `.agents/skills/`, `.agents/tools/check-structure.py`. |
| [ETH Zurich, Evaluating AGENTS.md](https://arxiv.org/abs/2602.11988), [Configuration Smells in AGENTS.md](https://arxiv.org/abs/2606.15828), and [Anthropic's memory guidance](https://code.claude.com/docs/en/memory) | Keep standing instructions focused on practices that the code does not reveal, and remove unnecessary context. | `.agents/skills/maintain/scripts/standing-lines.sh`, `.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md`. |

## Running and release work

| Source | Contribution | Where it is in the kit |
|---|---|---|
| [Geoffrey Huntley's Ralph technique](https://ghuntley.com/ralph/) and [Clayton Farr's Ralph Playbook](https://github.com/ClaytonFarr/ralph-playbook) | When a long run fails, change the instructions and run it again. | `.agents/skills/implement/references/running-longer.md`. |
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | Build several pieces after an explicit decision enabling that workflow, and consult the supplier’s own documentation. | `.agents/skills/implement/references/running-longer.md`, `.agents/skills/research/SKILL.md`. |
| [Agent Flywheel](https://agent-flywheel.com/complete-guide), by Jeffrey Emanuel | List destructive commands and distinguish written prohibitions from enforced restrictions. | `.agents/guard/blocked-commands.md`, `.agents/skills/setup-ai-build-kit/templates/foundation/guard-secrets.py`. |
| [Carsten Jørgensen, harness engineering](https://harness-engineering.carstenj.workers.dev/) | Disable dangerous commands instead of relying on a warning. | `.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json`, `.agents/skills/setup-ai-build-kit/references/blocked-commands.md`. |
| [tw93/waza](https://github.com/tw93/waza) | Keep the command set small and fixed, adding capabilities to existing commands. | `.agents/tools/kit-inventory.txt`, `.agents/tools/validate-kit.sh`. |
| [Husky](https://github.com/typicode/husky/blob/main/index.js) and [Codex non-interactive mode](https://learn.chatgpt.com/docs/non-interactive-mode) | Integrate push protection with the project’s Git hook configuration and run replay conversations through codex exec. | `.agents/skills/setup-ai-build-kit/scripts/use-push-guard.sh`, `.agents/tests/replay/`. |
| [GitHub rulesets and branch protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) and [branch protection API](https://docs.github.com/en/rest/branches/branch-protection) | Require the project check to pass on the main branch, including for administrators. | `.agents/skills/merge/scripts/protect-branch.py`. |
| [GitHub CLI environment](https://cli.github.com/manual/gh_help_environment) and [Codex configuration](https://developers.openai.com/codex/config-reference/) | Give a new Codex process access to the current GitHub sign-in without changing global settings. | `.agents/skills/setup-ai-build-kit/scripts/`, `.agents/skills/setup-ai-build-kit/references/codex-github.md`. |
| [Codex hooks](https://learn.chatgpt.com/docs/hooks) and [Git configuration](https://git-scm.com/docs/git-config#Documentation/git-config.txt-GITCONFIGCOUNT) | Check GitHub access before work begins and give Git access to the session’s sign-in. | `.agents/skills/setup-ai-build-kit/scripts/`, `.agents/skills/setup-ai-build-kit/references/codex-github.md`. |
| [GitHub CLI authentication refresh](https://cli.github.com/manual/gh_auth_refresh), [authentication status](https://cli.github.com/manual/gh_auth_status), and [pull request checks](https://cli.github.com/manual/gh_pr_checks) | Request workflow permission in the person's terminal, check the active account, and treat pending checks as a separate result. | `.agents/skills/setup-ai-build-kit/scripts/workflow-upload-check.py`, `.agents/skills/setup-ai-build-kit/scripts/check-tooling.sh`, `.agents/skills/merge/scripts/merge.py`. |

## Hosting and recovery

| Source | Contribution | Where it is in the kit |
|---|---|---|
| [coolify-devops](https://github.com/KasperHonore/coolify-devops) | Define a hosting request that the person passes to the server administrator. | `.agents/skills/setup-hosting/recipes/nextjs-supabase-on-coolify/hosting-request.md`. |
| [Google's SRE book](https://sre.google/sre-book/table-of-contents/), [DORA delivery metrics](https://dora.dev/guides/dora-metrics/), and [Continuous Delivery](https://continuousdelivery.com/) | Treat recovery as a separate step and check the live tool after a release. | `.agents/skills/live-copy/SKILL.md`, `.agents/skills/merge/scripts/merge.py`. |
| [BoringStack](https://boringstack.xyz/) and [Boring Stack](https://boringstack.org/) | Use a short menu of proven defaults and treat an empty project as a normal start. | `.agents/skills/setup-hosting/recipes/`, `.agents/skills/setup-ai-build-kit/references/completion-report.md`. |
| [Thoughtworks Technology Radar](https://www.thoughtworks.com/radar) | Review tools on a fixed cycle and date each review. | `.agents/maintainer-skills/stack-research/SKILL.md`. |
| [Intercom, The Safety of Speed](https://www.intercom.com/blog/safety-of-speed/) | Plan rollback explicitly and keep changes small. | `.agents/skills/live-copy/SKILL.md`, `.agents/skills/build-piece/references/build-limits.md`. |
| [OpenAI, harness engineering](https://www.infoq.com/news/2026/02/openai-harness-engineering-codex/) | Review documentation for descriptions that no longer match the code. | `.agents/skills/quality-checks/references/document-read.md`. |

## Screen design

The starter copies its components and design variables with the
[shadcn/ui command](https://ui.shadcn.com/docs/cli), using the
[Radix option](https://ui.shadcn.com/docs/changelog/2026-07-base-ui-default).
The copied files live in the starter's `src/components/ui/` folder. The
[current form guide](https://ui.shadcn.com/docs/forms/react-hook-form) pairs
`Field` with react-hook-form and zod.

[better-tailwindcss](https://github.com/schoero/eslint-plugin-better-tailwindcss)
checks colour classes against the design variables. Its
[entryPoint setting](https://github.com/schoero/eslint-plugin-better-tailwindcss/blob/main/docs/settings/settings.md)
points at the Tailwind 4 CSS file. The starter uses the plugin's own
`no-unknown-classes` and `no-conflicting-classes` rules.

[Playwright's axe guide](https://playwright.dev/docs/accessibility-testing)
supplies the sign-in scan in `e2e/accessibility.spec.ts`. A separate assertion
checks that the email label is visible, since axe accepts labels hidden from
sight. Passing these checks does not prove a screen is accessible.

| Source | Contribution | Where it is in the kit |
|---|---|---|
| [Vercel Web Interface Guidelines](https://github.com/vercel-labs/web-interface-guidelines/blob/main/AGENTS.md), [Impeccable craft floor](https://github.com/pbakaus/impeccable/blob/main/skill/reference/craft-floor.md), [GOV.UK Design System](https://design-system.service.gov.uk/), [Nielsen Norman Group](https://www.nngroup.com/articles/ten-usability-heuristics/), [Carbon](https://carbondesignsystem.com/), [Shopify Polaris](https://polaris.shopify.com/), and [WCAG 2.2](https://www.w3.org/WAI/WCAG22/quickref/) | Interface rules for visible labels, errors, keyboard focus, spacing and empty states. | `.agents/skills/screen-check/SKILL.md`. |

### Licence notice

The screen-check skill adapts some interface rules from W3C's "How to Meet WCAG" quick reference, and W3C's licence requires this notice.

Copyright © 2023 W3C®. This software or document includes material copied from or derived from [How to Meet WCAG, Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/).
