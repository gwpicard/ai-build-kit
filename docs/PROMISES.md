# Promises and what enforces them

## Kit source and structure

| Promise | Enforced by |
|---|---|
| Commands, background skills and their references stay within their word budgets. | `.agents/tools/check-structure.py` |
| Named checks and replay scenarios stay present in this list. | `.agents/tests/promises-list.sh`; `.agents/tests/promises-list-rehearsal.sh` |
| Adapters match the canonical skills. | `.agents/tools/validate-kit.sh` |
| Project bootstrap does not overwrite existing files or follow links outside the project. | `.agents/tests/starter-rehearsal.sh` |

## Project checks and records

| Promise | Enforced by |
|---|---|
| A project check blocks the merge while a finding marked worth stopping for is unticked. | `.agents/tests/review-gate.sh`; `.agents/tests/merge-gate.sh` |
| Merge waits for project checks, a settled review, and a risk area whose caution is done or accepted. | `.agents/tests/merge-gate.sh` |
| Secrets stay out of committed files, command output, and logs. | `.agents/tests/secrets-gates.sh`; `.agents/tests/push-guard.sh` |
| A secret never reaches the kit's saved records, and the refusal names the record, never the value. The kit's scripts apply across agents; Claude Code also checks records it writes by hand. | `.agents/tests/record-secrets.sh` |
| A review record is valid only for the commit it read, and a hand edit to it blocks the merge. | `.agents/tests/review-gate.sh`; `.agents/tests/merge-gate.sh` |
| A review without approval from a second login is labelled unverified. | `.agents/tests/review-gate.sh`; `.agents/tests/merge-gate.sh` |
| A check that did not run, has no runner or crashed reports `NOT_RUN`, never `PASS`. | `.agents/tests/result-vocabulary.sh` |
| A live recipe launch is blocked if it has no rollback or no backup. | `.agents/tests/run-recipe.sh` |
| With no recipe the kit gives one notice that nothing is guaranteed, records the person's words and the date, and never refuses. | `.agents/tests/run-recipe.sh` |
| Each command is tested by what it should do, and each test reads its result from disk as well as from the transcript. | `.agents/tests/replay-behaviour.sh`; `.agents/tests/replay-behaviour-cases.sh`; `.agents/tests/scenarios.md`, replay scenarios 64 to 81 |
| A run interrupted by a broken replay harness counts as could not run, never as a pass or a fail. | `.agents/tests/replay-preflight.sh` |
| A changed test cannot weaken the test that caught the fault. | `.agents/tests/tests-prove-change.sh` |
| A quality check that tried nothing reports that it could not run. | `.agents/tests/test-strength-rehearsal.sh` |
| A starter release contains only the declared files. | `.agents/tests/release-builder.sh`; `.agents/tools/validate-kit.sh` |
| Maintainer files stay out of the released starter. | `.agents/tests/release-builder.sh` |
| The plugin manifest and installed skills follow the published shape. | `.agents/tests/agent-plugin.sh` |
| Session reminders appear only when a project check-up is due. | `.agents/tests/session-start.sh` |
| A review finding needs evidence before it reaches the pull request. | `.agents/tests/review-gate.sh` |
| Confirmed missing working conditions stop setup. Unreadable checks are reported separately; private repositories on GitHub Free may use the recorded branch-protection exception. | `.agents/tests/check-tooling.sh` |
| A project's first upload requires approval and recognises shared history. | `.agents/tests/first-upload.sh` |
| A release draft can be prepared without publishing it or pushing a tree. | `.agents/tests/release-publication.sh` |
| A release upgrade carries existing project work forward. | `.agents/tests/upgrade-rehearsal.sh` |
| An older path record moves to the risk record with approval, keeping every risk area, acceptance, date and word; declining leaves project records unchanged and records the refusal in maintenance notes. | `.agents/tests/risk-move-rehearsal.sh` |
| A project check uses its shared review-box reader. | `.agents/tests/review-gate.sh`; `.agents/tests/merge-gate.sh` |
| The Claude Code read guard refuses environment files. | `.agents/tests/secrets-gates.sh`; `.claude/settings.json` |
| Claude Code reads its project settings and session hook. | `.agents/tests/session-start.sh`; `.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json` |

## Behaviour and judgement

| Promise | Enforced by |
|---|---|
| The agent makes the work understandable without asking the person to read code. | Words only; needs judgement |
| The kit names risks before work in a risk area and records the person's choice. | `.agents/tests/scenarios.md`, replay scenario 5; manual scenarios, not yet replayed: scenarios 3, 4 and 6 |
| The agent asks only questions whose answers would change the outcome. | `.agents/tests/scenarios.md`, replay scenarios 9 and 10 |
| The agent checks a decision against the test it rests on before relying on it. | `.agents/tests/scenarios.md`, manual scenario, not yet replayed: scenario 46 checks that a removed supporting test is noticed before the decision is reused |
| The agent asks before changing a live service or online access. The kit's scripts apply across agents; Claude Code settings check other commands. | `.agents/tests/approval-gate.sh`, `.agents/tests/merge-gate.sh` and `.agents/tests/recipe-nextjs-supabase-on-vercel.sh` prove the kit's scripts refuse without the person's recorded approval; `.agents/tests/push-to-main-rules.sh` checks Claude Code settings |
| The agent reports which command is running and does not start one the person did not ask for. | `.agents/tests/scenarios.md`, manual scenario, not yet replayed: scenario 44 |
