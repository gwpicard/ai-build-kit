---
title: What the kit checks
description: The checks the kit runs at each step, what they stop, and what they do not cover.
draft: false
---

The kit uses scripts to check the work at each step. Some checks stop the work. Others warn you once and let you decide.

## When the kit stops, and when it warns

The kit stops when you could not see the problem yourself. Examples: a review of code that changed after the review, or a launch with no backup.

The kit warns when you can judge the risk. Example: the tool will hold personal data. You hear the warning once. The kit records your answer and the date, then builds.

## What the kit always holds

These rules hold in every project. Each row names the script that holds the rule. The last column says what the script does not cover.

| What holds | How | Not covered |
|---|---|---|
| A change joins the project only after your yes, unless you turned on automatic merge. | The [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) needs your recorded yes. With automatic merge on, it merges only when the recorded option and every hold allow it. A [push guard](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/pre-push) blocks a push straight to the main project. Tests: [merge gate](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/merge-gate.sh), [push guard](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/push-guard.sh). | A private repository on the GitHub free plan has no GitHub protection. Someone with access can merge by hand. |
| Nothing goes live without your yes. | One [approval step](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/records/scripts/approval.py) covers each deploy, database change, secret and access change. Test: [approval gate](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/approval-gate.sh). | A host's own tool used outside the kit. Only Claude Code's own rules ask first. |
| Secrets are never shown. | Guards check commits, command output and saved records. Scripts: [guard](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/guard-secrets.sh), [redact](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/redact-secrets.sh), [scan](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/scan-secrets.sh). Tests: [secrets](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/secrets-gates.sh), [records](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/record-secrets.sh). | An agent that writes a record by hand. The scan catches it when you push. |
| Checks pass before a merge. | The [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) reads the project's check results. Test: [merge gate](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/merge-gate.sh). | Nothing known. |
| The review matches the code. | The review record names the exact version it read. If the code changes, the merge stops. Scripts: [merge](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py), [review check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/check-review.sh). Test: [review gate](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/review-gate.sh). | A review that no second person approved is marked "unverified". The merge says so in plain words. |
| A launch has a backup and a way back. | On a recipe, the launch stops without a confirmed backup or without a way back. Script: [run-recipe](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/scripts/run-recipe.sh). Tests: [run-recipe](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/run-recipe.sh), [recipe check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tools/check-recipes.sh). | Off a recipe, nothing is checked, and the kit says so. A first launch has no earlier build, so its way back is not tried. |
| An accepted risk stays "accepted". | Records never show it as fixed. Tests: [state check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/replay/state-check.sh), [risk areas](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/sensitive-area-map.sh). | An agent that edits a record by hand. |

## Checks at each step

Each line names one check and links to it. A project holds only the checks that fit its recipe and its risk areas.

### Found a project

- The [tooling check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/scripts/check-tooling.sh) says which tool is not ready before the kit builds anything.
- The [push guard](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/scripts/use-push-guard.sh) is turned on, so no push goes straight to the main project.
- The [branch rule](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/protect-branch.py) requires the project check on GitHub, where your plan allows it.
- The [first upload](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/first-upload.py) waits for your yes.
- The [project check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml) starts as a placeholder that fails. It cannot show a pass until the project has real tests.

### Shape a piece

- The [ready mark](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/records/scripts/mark-ready.sh) goes on only when the piece has a "Done when" section, waits on no question, and names its risk areas.
- The [reach check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/scripts/quality.py) lists the files the piece is likely to touch.
- The [risk warning](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/fit-check/SKILL.md) comes once. The kit records your answer and the date.

### Implement a piece

- The [test freeze](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/check-tests.sh) fails a change that edits an existing test without a stated reason.
- The [tests check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/scripts/quality.py) reports a test that already passed before the change, and a "Done when" line with no test.
- The [structure check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/scripts/quality.py) reports a new loop between parts, or a crossed boundary.
- The [trim commit](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/scripts/trim-commit.sh) refuses a clean-up that touched a test.
- The [secret guards](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/guard-secrets.sh) stop a command that would show a secret.
- The [repair reset](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/repair/scripts/reset-attempt.sh) undoes a failed repair before the next one, so failed fixes do not stack.

### Review the change

- The [review packet](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/scripts/gate.py) gives the reviewer the change and the evidence. The review record names the version it read.
- The [review guard](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/second-opinion/scripts/review-guard.sh) puts back any file the reviewer changed.
- The [review check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/check-review.sh) holds the project check while a finding is open, or while the record names another version.
- A review that no second person approved is marked "unverified" in the pull request.

### Merge the change

- The [merge script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/merge.py) needs your recorded yes, unless you turned on automatic merge. It merges only the version that was checked.
- It stops when the project check is missing, failed or did not run.
- It stops when a review finding is open, or when the review names another version.
- The [risk-area check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-ai-build-kit/templates/foundation/check-sensitive-areas.sh) reports each risk area the change touches, and holds while a decision is open.
- On a live project, the [settings check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/merge/scripts/env-names-added.sh) holds the merge until the host has each new setting.

### Set up or check the live tool

- The [launch script](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/scripts/run-recipe.sh) holds a launch with no confirmed backup or no way back. With no recipe, it says once that nothing is checked.
- The [approval step](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/records/scripts/approval.py) asks for your yes before each live change.
- The live check compares the live tool with the main project, on [Vercel](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/scripts/live-check.sh) or [Coolify](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-coolify/scripts/live-check.sh). It changes nothing.
- The [recipe check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tools/check-recipes.sh) fails a recipe with no rollback, backup or restore section.

### Maintain the project

- The [live check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/scripts/live-check.sh) runs again at each visit.
- The [update check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/maintain/scripts/upgrade-check.py) lists what a kit update left for the visit to finish.
- The [recipe age check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/maintain/scripts/recipe-freshness.py) reports a recipe that is old or has an old name.
- The [branch list](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/scripts/stale-branches.py) names branches whose work already reached the main project. It removes nothing.
- The [instruction length check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/maintain/scripts/standing-lines.sh) reports when the standing instructions grow too long.
- The [safety rules check](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/maintain/scripts/settings-rules.py) offers newer safety rules and applies them only on your yes.

## What a result means

Every check that can stop a merge reports one of five results.

| Result | Meaning | Effect on a merge |
|---|---|---|
| Pass | The check found no problem in what it checked. | None. The result is only reported. |
| Fail | The check found a problem. | The merge stops. |
| Not run | The check did not start, or the tool crashed. | The merge stops. The kit never shows it as a pass. |
| Inconclusive | The check could not decide. | The kit asks for a review. |
| Not applicable | The check does not apply to this change. | None. The result is only reported. |

[One table](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/quality-checks/scripts/results.py) holds these rules. The hosting recipe checks use plain words instead. A hosting check that did not run says "not checked".

A check that the project cannot run yet says "report-only". It never shows a false pass. You decide when it becomes a hard rule. The kit records the date.

## How the kit tests itself

- Scripts check the kit's own files and rules. [One command](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/run-all.sh) runs them all and names each one that failed.
- A [mutation run](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/mutate.sh) removes one safeguard at a time. It confirms that a check notices.
- Recorded conversations are replayed and graded on what the agent did. Each test project holds a fake secret. A [replay fails](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/tests/replay/backbone.py) if the fake secret appears.
- Each release is rebuilt and compared with the reviewed copy. The [release steps](https://github.com/gwpicard/ai-build-kit/blob/stable/docs/MAINTAINING.md#when-a-release-is-cut) say how.

These checks give evidence about the kit. They do not prove that a tool built with the kit is safe.
