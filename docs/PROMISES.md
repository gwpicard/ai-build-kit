# Promises and what holds them

| Promise | What holds it | Where it applies |
|---|---|---|
| Commands, background skills and their references stay within their word budgets. | `.agents/tools/check-structure.py` | Every agent |
| Named checks and replay scenarios stay present in this list. | `.agents/tests/promises-list.sh`; `.agents/tests/promises-list-rehearsal.sh` | Every agent |
| Adapters match the canonical skills. | `.agents/tools/validate-kit.sh` | Every agent |
| Project bootstrap does not overwrite existing files or follow links outside the project. | `.agents/tests/starter-rehearsal.sh` | Every agent |
| A project check holds while a stopping finding is unticked. | `.agents/tests/review-gate.sh`; `.agents/tests/merge-gate.sh` | Every agent |
| Merge waits for project checks, a settled review, and an accepted risk area. | `.agents/tests/merge-gate.sh` | Every agent |
| Secrets stay out of committed files, command output, and logs. | `.agents/tests/secrets-gates.sh`; `.agents/tests/push-guard.sh` | Every agent |
| A secret never reaches the kit's saved records, and the refusal names the record, never the value. | `.agents/tests/record-secrets.sh` | Every agent for the kit's scripts; Claude Code for records it writes by hand |
| A review record holds only for the commit it read, and a hand edit to it holds the merge. | `.agents/tests/review-gate.sh`; `.agents/tests/merge-gate.sh` | Every agent |
| A review no second login approved is labelled unverified. | `.agents/tests/review-gate.sh`; `.agents/tests/merge-gate.sh` | Every agent |
| A check that never ran, lost its runner or crashed reports `NOT_RUN`, never `PASS`. | `.agents/tests/result-vocabulary.sh` | Every agent |
| A live recipe launch with no way back or no backup is held. | `.agents/tests/run-recipe.sh` | Every agent |
| With no recipe the kit gives one notice that nothing is guaranteed, records the person's words and the date, and never refuses. | `.agents/tests/run-recipe.sh` | Every agent |
| Each command is tested by what it should do, and each test reads its result from disk as well as from the transcript. | `.agents/tests/replay-behaviour.sh`; `.agents/tests/replay-behaviour-cases.sh`; `.agents/tests/scenarios.md`, replay scenarios 64 to 81 | Every agent |
| A replay run the harness breaks counts as could not run, never as a pass or a fail. | `.agents/tests/replay-preflight.sh` | Every agent |
| A changed test cannot weaken the test that caught the fault. | `.agents/tests/tests-prove-change.sh` | Every agent |
| A quality check that tried nothing reports that it could not run. | `.agents/tests/test-strength-rehearsal.sh` | Every agent |
| A starter release contains only the declared files. | `.agents/tests/release-builder.sh`; `.agents/tools/validate-kit.sh` | Every agent |
| Maintainer files stay out of the released starter. | `.agents/tests/release-builder.sh` | Every agent |
| The plugin manifest and installed skills follow the published shape. | `.agents/tests/agent-plugin.sh` | Every agent |
| Session reminders appear only when a project check-up is due. | `.agents/tests/session-start.sh` | Every agent |
| A review finding needs evidence before it reaches the pull request. | `.agents/tests/review-gate.sh` | Every agent |
| Confirmed missing working conditions stop setup. Unreadable checks are reported separately; private repositories on GitHub Free may use the recorded branch-protection exception. | `.agents/tests/check-tooling.sh` | Every agent |
| A project's first upload requires approval and recognises shared history. | `.agents/tests/first-upload.sh` | Every agent |
| A release draft can be prepared without publishing it or pushing a tree. | `.agents/tests/release-publication.sh` | Every agent |
| A release upgrade carries existing project work forward. | `.agents/tests/upgrade-rehearsal.sh` | Every agent |
| An older path record moves to the risk record with approval, keeps every risk area, acceptance, date and word, and a no changes nothing. | `.agents/tests/risk-move-rehearsal.sh` | Every agent |
| A project check uses its shared review-box reader. | `.agents/tests/review-gate.sh`; `.agents/tests/merge-gate.sh` | Every agent |
| The Claude Code read guard refuses environment files. | `.agents/tests/secrets-gates.sh`; `.claude/settings.json` | Claude Code only |
| Claude Code reads its project settings and session hook. | `.agents/tests/session-start.sh`; `.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json` | Claude Code only |
| The kit names risks before work in a risk area and records the person's choice. | `.agents/tests/scenarios.md`, replay scenarios 3, 4, 5 and 6 | Every agent |
| The agent asks only for answers that change the result. | `.agents/tests/scenarios.md`, replay scenarios 9 and 10 | Every agent |
| The agent checks a decision against the test it rests on before relying on it. | `.agents/tests/scenarios.md`, replay scenario 46 checks that a removed supporting test is noticed before the decision is reused | Every agent |
| The agent asks before changing a live service or online access. | `.agents/tests/approval-gate.sh`, `.agents/tests/merge-gate.sh` and `.agents/tests/recipe-nextjs-supabase-on-vercel.sh` prove the kit's scripts refuse without the person's recorded yes; `.agents/tests/push-to-main-rules.sh` checks Claude Code settings | Every agent for the kit's scripts; Claude Code for other commands |
| The agent makes the work understandable without asking the person to read code. | Words only; needs judgement | Every agent |
| The agent says when a command runs and does not start one the person did not ask for. | `.agents/tests/scenarios.md`, replay scenario 44 | Every agent |
