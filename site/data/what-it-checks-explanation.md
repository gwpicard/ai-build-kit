## Rules checked in every project

| Rule | Checked by and when | If the check fails | Not covered |
|---|---|---|---|
| By default, each merge needs your recorded approval for its named change. Automatic merging is opt-in. | The [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) checks it. The [Git pre-push hook](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/pre-push) refuses direct pushes to `main`. | The script leaves the pull request open; the hook refuses the push. | Repository members can merge by hand if a private repo lacks GitHub protection. Agents can bypass the hook with `--no-verify`; only Claude Code settings refuse the bypass. |
| Kit-script live changes need recorded approval for the named change. | The [approval script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/records/scripts/approval.py) checks before each live change or merge. | It refuses changes without an unused approval for that action. | Host tools used outside the kit. |
| Secret checks scan commands, output, records and commits. | [Claude Code hooks](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/guard-secrets.sh) check before and after tool calls; push and project checks scan commits. | The hook refuses a command or push; the project check fails. | Tool-call hooks apply to Claude Code. On Codex, Cursor and Gemini CLI, printed secrets reach the agent. A hand-written record is checked only when included in a scanned commit. |
| The project check must pass before merging. | The [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) reads its GitHub result. | The script blocks the merge and leaves the pull request open; a missing result is not a pass. | This checks the result, not every possible defect. |
| A merge uses the reviewed version. | The [project review check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/check-review.sh) and [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) compare the record and current version. | The check fails or the merge script blocks the merge. | If a different GitHub login has not approved that version, the merge script reports the review as unverified. |
| On a recipe, recording a live address requires a confirmed backup and way back. | The [launch script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/scripts/run-recipe.sh) records it only after the backup and rollback conditions pass. | The script blocks the launch record, but cannot stop a host that deploys on merge. | Without a recipe, these checks cannot run. A first launch needs a rollback step; later launches need an earlier build. |
| Accepted risks stay recorded as accepted. | The agent records acceptance; the risk-area check reports it. Maintainer [replay state](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/replay/state-check.sh) and [risk-area tests](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/sensitive-area-map.sh) check temporary projects. | Maintainer tests report a mismatch when state is wrong. | These tests do not run in your project or prevent an agent changing an acceptance to "done". |

## What a result means

The kit's quality, review and merge scripts report one of five results.

| Result | Meaning | Effect on a merge |
|---|---|---|
| Pass | No problem in the checked scope. | No effect on a merge. |
| Fail | The check found a problem. | The result blocks the merge. |
| Not run | The check did not start, or the tool crashed. | The result blocks the merge; it is never shown as a pass. |
| Inconclusive | The check could not reach a conclusion. | Policy asks a person to review before approval. |
| Not applicable | The check does not apply to this change. | No effect on a merge. |

The [result policy](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/scripts/results.py) defines these outcomes. Recipe checks use plain language and report "not checked" when they cannot run.

Checks listed as report-only on a project moved from the kit's older risk record state their limits without claiming a pass. You decide when each becomes enforced, and the date is recorded. This does not allow a failed or unrun required project check to merge.

## How the kit tests itself

- Before release, the maintainer’s [recipe check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tools/check-recipes.sh) confirms all nine sections, including rollback, backup and restore.
- [The test command](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/run-all.sh) checks the kit’s files and rules, then lists failures.
- A [mutation run](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/mutate.sh) breaks safeguards in a temporary copy and reports which checks catch them.
- Replays grade scripted conversations. Each project has a fake secret; the [replay check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/replay/backbone.py) fails if it appears in output or saved records.
- Each release is rebuilt and compared with the reviewed copy. See the [release steps](https://github.com/gwpicard/ai-build-kit/blob/stable/docs/MAINTAINING.md#when-a-release-is-cut).

These checks provide evidence about the kit, but do not establish that a tool built with it is safe.
