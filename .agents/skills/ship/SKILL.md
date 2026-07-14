---
name: ship
description: Take checked work to the copy of the tool the team actually uses. The only skill that touches that copy. Use when the user thinks the tool, or a batch of work on it, is ready for people to rely on. Checks everything first, and declines politely when the project's own stakes section says it should stay private.
disable-model-invocation: true
---

# Ship

Everything build and fix make lives on the draft copy until this word moves it over. Read masterplan.md, stakes section first.

## 0. Read the verdict

If the stakes section says the project is practice, or records a fit-check outcome of fix-the-design-first, decline: say "not yet", say the project stays on the draft copy, and say exactly what changes the answer: the redesign the stakes section names, or a fresh run of the fit check. This refusal exists because the moment before launch is exactly when checks get skipped.

## 1. The evidence run

Run references/evidence-run.md in full. No claims without fresh output.

## 2. Fresh eyes on the whole

Have second-opinion run in a new session across the build, scoped by the stakes section's flags.

## 3. What the stakes section directs

No flags: continue to step 4. A get-it-checked flag: write the reviewer's brief now, one page: what the tool is, what data it holds, the specific parts to examine (taken from the flags), how to run it, and what the review should try to break. Stop until the review comes back and its findings are fixed. A handover flag: instead of launching, assemble the handover folder: the masterplan, the plan, the changelog, the repo with its tests, an honest list of what's unfinished or was deferred, and a one-page orientation covering how to run it and where things live. Rotate every key first, so none travels with the package.

## 4. Go live, one connection at a time

Take the harmless parts live first; anything a flag names waits for its own check. Before the team is told: error alerts point at an inbox someone reads, a backup exists and has been restored once, the way back is written in the changelog, and test data is gone. If hosting uses a preview address, this is the moment work moves to the team's address. That move is what /ship means.

## After the first launch

Lighter: re-run the evidence for what changed since the last ship, and move that over.

## Done when

The team can rely on the copy they use, the alerts and backups are real, and the changelog says what went live and when.
