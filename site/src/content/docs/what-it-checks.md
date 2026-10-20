---
title: Rules and checks
description: Rules that apply in every project and how the kit tests them.
draft: false
---

## When the agent stops and when you decide

The agent stops when a script finds a problem that you cannot judge from outside, such as a review of an earlier version. The agent warns when you can judge a risk. You decide what to do, and the agent records your answer. See [records and risk](./records.md).

## Rules checked in every project

Each rule says who checks it, when the check runs, what happens if it fails and what it does not cover.

| Rule | Checked by and when | If the check fails | Not covered |
|---|---|---|---|
| A change merges only after you give one named yes, unless automatic merge is enabled. | The [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) checks when it runs. The [Git pre-push hook](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/pre-push) refuses direct pushes to `main`. | The script leaves the pull request open. The hook refuses the push. | Someone with repository access can merge by hand if GitHub does not protect the private repository. |
| The agent changes a live service only after you give a yes for that named change. | The [approval script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/records/scripts/approval.py) checks before each approved live change and merge. | The script refuses the change when no unused approval names it. | A host tool used outside the kit. Claude Code also asks before certain approval commands. |
| Scripts check secrets in commands, output, records and commits. | [Claude Code hooks](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/guard-secrets.sh) check before and after tool calls. Push and project checks scan commits. | The hook refuses a command or push, or the project check fails. | These tool hooks apply to Claude Code. A person-written record is checked at the next scan. |
| The project check must pass before a merge. | The [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) reads the GitHub check result when it runs. | The script stops and leaves the pull request open. A missing result does not count as a pass. | This rule covers the check result, not every possible defect in the tool. |
| A merge uses the exact saved version that the reviewer read. | The [project review check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/check-review.sh) and [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) compare the review record with the current version. | The check fails or the merge script stops. | A second GitHub login may not have approved the review. The merge then reports the review as unverified. |
| A launch on a supported recipe needs a confirmed backup and rollback step. | The [launch script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/scripts/run-recipe.sh) checks before each launch. | The script stops the launch. | Outside a supported recipe, the script says it checks nothing. A first launch has no earlier build to restore. |
| An accepted risk remains recorded as accepted. | Project records retain the acceptance. The [state check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/replay/state-check.sh) and [risk-area check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/sensitive-area-map.sh) check project state. | The check reports a mismatch. | An agent may edit a record by hand; the state checks cover recorded project state. |

## What a result means

Every check that can stop a merge reports one of five results.

| Result | Meaning | Effect on a merge |
|---|---|---|
| Pass | The check found no problem in what it checked. | None. The result is only reported. |
| Fail | The check found a problem. | The merge stops. |
| Not run | The check did not start, or the tool crashed. | The merge stops. The kit never shows it as a pass. |
| Inconclusive | The check could not decide. | The kit asks for a review. |
| Not applicable | The check does not apply to this change. | None. The result is only reported. |

The [results table](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/scripts/results.py) lists these meanings. The hosting recipe checks use plain words instead. A hosting check that did not run says "not checked".

A check that the project cannot run yet says "report-only". It never shows a false pass. You decide when it becomes a hard rule. The kit records the date.

## How the kit tests itself

- Scripts check the kit's own files and rules. [One command](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/run-all.sh) runs them all and names each one that failed.
- A [mutation run](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/mutate.sh) removes one safeguard at a time. It confirms that a check notices.
- Recorded conversations are replayed and graded on what the agent did. Each test project contains a fake secret. A [replay fails](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/replay/backbone.py) if the fake secret appears.
- Each release is rebuilt and compared with the reviewed copy. The [release steps](https://github.com/gwpicard/ai-build-kit/blob/stable/docs/MAINTAINING.md#when-a-release-is-cut) say how.

These checks give evidence about the kit. They do not prove that a tool built with the kit is safe.
