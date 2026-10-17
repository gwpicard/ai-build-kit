# Promises and what holds them

| Promise | What holds it | Where it applies |
|---|---|---|
| Commands, background skills and their references stay within their word budgets. | `.agents/tools/check-structure.py` | Every agent |
| Named checks and replay scenarios stay present in this list. | `.agents/tests/promises-list.sh`; `.agents/tests/promises-list-rehearsal.sh` | Every agent |
| Adapters match the canonical skills. | `.agents/tools/validate-kit.sh` | Every agent |
| Project bootstrap does not overwrite existing files or follow links outside the project. | `.agents/tests/starter-rehearsal.sh` | Every agent |
| A project check holds while a stopping finding is unticked. | `.agents/tests/review-gate.sh`; `.agents/tests/merge-gate.sh` | Every agent |
| Merge waits for project checks, a settled review, and an accepted sensitive area. | `.agents/tests/merge-gate.sh` | Every agent |
| Secrets stay out of committed files, command output, and logs. | `.agents/tests/secrets-gates.sh`; `.agents/tests/push-guard.sh` | Every agent |
| A changed test cannot weaken the test that caught the fault. | `.agents/tests/tests-prove-change.sh` | Every agent |
| A quality check that tried nothing reports that it could not run. | `.agents/tests/test-strength-rehearsal.sh` | Every agent |
| A starter release contains only the declared files. | `.agents/tests/release-builder.sh`; `.agents/tools/validate-kit.sh` | Every agent |
| Maintainer files stay out of the released starter. | `.agents/tests/release-builder.sh` | Every agent |
| The plugin manifest and installed skills follow the published shape. | `.agents/tests/agent-plugin.sh` | Every agent |
| Session reminders appear only when a project check-up is due. | `.agents/tests/session-start.sh` | Every agent |
| A review finding needs evidence before it reaches the pull request. | `.agents/tests/review-gate.sh` | Every agent |
| A project's first upload waits for a yes and recognises shared history. | `.agents/tests/first-upload.sh` | Every agent |
| A release draft can be prepared without publishing it or pushing a tree. | `.agents/tests/release-publication.sh` | Every agent |
| A release upgrade carries existing project work forward. | `.agents/tests/upgrade-rehearsal.sh` | Every agent |
| A project check uses its shared review-box reader. | `.agents/tests/review-gate.sh`; `.agents/tests/merge-gate.sh` | Every agent |
| The Claude Code read guard refuses environment files. | `.agents/tests/secrets-gates.sh`; `.claude/settings.json` | Claude Code only |
| Claude Code reads its project settings and session hook. | `.agents/tests/session-start.sh`; `.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json` | Claude Code only |
| The kit names risks before sensitive work and records the person's choice. | `.agents/tests/scenarios.md`, replay scenarios 3, 4, 5 and 6 | Every agent |
| The agent asks only for answers that change the result. | `.agents/tests/scenarios.md`, replay scenarios 9 and 10 | Every agent |
| The agent does not claim a review or result that did not happen. | `.agents/tests/scenarios.md`, replay scenarios 2 and 46 | Every agent |
| The agent asks before changing a live service or online access. | `.agents/tests/push-to-main-rules.sh` checks Claude Code settings; words only for other agents, could be a script for named operations | Every agent; Claude Code checked |
| The agent makes the work understandable without asking the person to read code. | Words only; needs judgement | Every agent |
| The agent says when a command runs and does not start one the person did not ask for. | `.agents/tests/scenarios.md`, replay scenario 44 | Every agent |
