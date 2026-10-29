## Rules checked in every project

Each rule says who checks it, when the check runs, what happens if it fails and what it does not cover.

| Rule | Checked by and when | If the check fails | Not covered |
|---|---|---|---|
| A merge requires your recorded approval for the named change, unless automatic merging is enabled. | The [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) checks when it runs. The [Git pre-push hook](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/pre-push) refuses direct pushes to `main`. | The script leaves the pull request open. The hook refuses the push. | Someone with repository access can merge by hand if GitHub does not protect the private repository. An agent can bypass the hook with `--no-verify`; only Claude Code settings refuse that bypass. |
| Live changes made through the kit’s scripts require your recorded approval for the named change. | The [approval script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/records/scripts/approval.py) checks before each approved live change and merge. | The script refuses the change if it cannot find an unused approval for that exact action. | A host tool used outside the kit. |
| Secret checks scan commands, output, records and commits. | [Claude Code hooks](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/guard-secrets.sh) check before and after tool calls. Push and project checks scan commits. | The hook refuses a command or push, or the project check fails. | Tool-call hooks apply to Claude Code. On Codex, Cursor and Gemini CLI, a secret printed by a tool reaches the agent. A record written manually is checked only if it falls within a later scan. |
| The project check must pass before a merge. | The [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) reads the GitHub check result when it runs. | The script stops and leaves the pull request open. A missing result does not count as a pass. | This rule covers the check result, not every possible defect in the tool. |
| A merge uses the exact saved version that was reviewed. | The [project review check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/check-review.sh) and [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) compare the review record with the current version. | The check fails or the merge script stops. | If a different GitHub login has not approved the version reviewed, the merge script reports the review as unverified. |
| On a supported recipe, the launch flow requires a confirmed backup and a way back when a live address is set. | The [launch script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/scripts/run-recipe.sh) records the live address only after applying its hold conditions. | The script holds the launch flow and does not record the address as live. It cannot stop a host that deploys on merge. | Without a recipe, the script cannot run the recipe checks. A first launch needs a defined rollback step; later launches need an earlier build. |
| An accepted risk remains recorded as accepted. | The agent retains the acceptance in project records. The project risk-area check reports accepted areas. Maintainer tests, including the [replay state check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/replay/state-check.sh) and [risk-area test](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/sensitive-area-map.sh), test this behaviour in temporary projects. | Maintainer tests report a mismatch when the tested state is incorrect. | The maintainer tests do not run in your project. They do not prevent an agent from manually changing an acceptance to “done”. |

## What a result means

The kit's quality, review and merge scripts report one of five results.

| Result | Meaning | Effect on a merge |
|---|---|---|
| Pass | The check found no problem in what it checked. | None. The result is only reported. |
| Fail | The check found a problem. | The merge stops. |
| Not run | The check did not start, or the tool crashed. | The merge stops. The kit never shows it as a pass. |
| Inconclusive | The check could not reach a conclusion. | The result policy calls for a person to review it before approving the merge. |
| Not applicable | The check does not apply to this change. | None. The result is only reported. |

The [result policy](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/scripts/results.py) defines these outcomes and their effect on merging. Hosting recipe checks report in plain language instead; when a check cannot run, it reports “not checked”.

When a project moved from the kit's older risk record cannot yet run a check, that check can be listed as report-only. It reports its limits without claiming a pass. You decide when to make it enforced, and the decision is recorded with the date. This does not turn a required project check that failed or did not run into permission to merge.

## How the kit tests itself

- Before a release, the maintainer's [recipe check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tools/check-recipes.sh) confirms that each recipe describes all nine checks, including rollback, backup and restore.
- Scripts check the kit’s own files and rules. [One command](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/run-all.sh) runs the suite and identifies each failing check.
- A [mutation run](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/mutate.sh) deliberately breaks one safeguard at a time in a temporary copy and reports which checks detect it.
- Replays run scripted conversations and grade the agent’s behaviour. Each test project contains a fake secret, and the [replay check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/replay/backbone.py) fails the run if that secret appears in its output or saved records.
- Each release is rebuilt and compared with the reviewed copy. The [release steps](https://github.com/gwpicard/ai-build-kit/blob/stable/docs/MAINTAINING.md#when-a-release-is-cut) say how.

These checks provide evidence about the kit, but do not establish that a tool built with it is safe.
