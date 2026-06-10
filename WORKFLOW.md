# WORKFLOW.md: how this project is built

The reference card for the whole system. When in doubt about what to run, start here. Skills are invoked in Codex by typing $ and the name, or by asking for them by name.

## Three documents, one job each

| Document | Job | Read | Written |
|---|---|---|---|
| masterplan.md | What the tool is: purpose, users and flow, features with a status each, data, access, quality bar, out of scope, edge cases. About a page, describing the present. | At the start of any piece of work | Created by $grill-the-plan; statuses flipped by the loop; kept true by $capture-state |
| CHANGELOG.md | What happened, dated, in plain language | When something breaks, or when returning after time away | Appended every loop |
| AGENTS.md | How we work here: stack, commands, conventions, rules | Automatically, every session | By $setup-project once; touched only when a convention changes |

The dividing rule: the masterplan describes the present. The moment a sentence is about when, why, or how something was built, it belongs in the changelog or the code.

## Day one, once per project

1. `$grill-the-plan` — the agent interviews the team and writes masterplan.md.
2. `$split-features` — cuts the masterplan's features into right-sized pieces, ordered, each with a one-sentence done condition, marked "to build".
3. `$setup-project` — fills in AGENTS.md, stands up the test harness with one passing test, commits, pushes. Runs once, never again.

## Every feature: $new-feature

One skill, with a human gate in the middle:

1. Reads AGENTS.md (automatic), the masterplan, and the relevant code if changing something that exists.
2. Checks the feature is small enough (a one-sentence done condition); proposes a split if it isn't. Asks about anything ambiguous instead of guessing.
3. Writes the expected behaviour as a plain-language test, confirms the sentence with you, then builds until it passes.
4. Stops and hands over: you use the tool. Nothing commits until you confirm it behaves. Gaps get described as expected versus actual, and fixed at the root.
5. Records: flips the feature to "built", appends the changelog, commits. If the change touched sign-in, data, or money, $security-pass runs before the commit.

## Routing: what to run when something arrives

- A sizeable or unclear idea: `$grill-the-plan` first (it reads the masterplan and asks only about the new thing), then `$split-features`, then the loop.
- A small, clear change, with a done condition you can say in one sentence and no change to data, access, or scope: straight to `$new-feature`.
- Something broken: `$fix-bug`.

## Guards, outside the loop

- `$security-pass` — after any change touching sign-in, data, or money, and before the tool goes in front of anyone. Reports first, fixes only on approval.
- `$capture-state` — at the end of a working session, after work done outside the skills, or before handing work to a teammate. Reconciles the documents backward against what's actually in the repo.
- `$health-check` — quarterly, or before a handoff. Updates dependencies and checks vulnerabilities, runs a simplify pass for invisible debt, and calls $capture-state and $security-pass rather than repeating them.

## The cadence

- After every change: handled inside $new-feature (docs, changelog, commit, confirmed by using it). Touched sign-in, data, or money: $security-pass.
- Every month or so: $health-check, light (dependencies, vulnerabilities; once live, error alerts and spend).
- Quarterly, or before a handoff: $health-check, full.

## What is never delegated

Two things stay human in every loop: giving real context going in (a real input and the output you expect, a screenshot, a definition of done), and checking by behaviour before anything commits. The system automates the routine, never the judgement.

## Git, day to day

Everyone on main for now. Pull before you start, commit when a slice works, push so others can pull it. Conflicts go to the agent to walk through. Branches, pull requests, and worktrees arrive once the loop is habit.
