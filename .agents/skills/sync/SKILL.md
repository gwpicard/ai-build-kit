---
name: sync
description: True the documents up against what actually happened. Trigger at the end of a working session, after work done outside the skills, when a long session has gone foggy, or before handing work to a teammate. Wired to run by itself at session end where the tool supports hooks. Do not use to build or fix anything.
disable-model-invocation: true
---

# Sync

The documents are supposed to describe reality. Make that true again by reading what actually happened, and correct the records instead of trusting what they claim. You change documents only, never code.

## The routine

1. Read the commits and changes since the last changelog entry, plus the tool's actual behaviour where that is cheap to check.
2. Correct plan.md statuses to match reality. Append any changelog lines the work missed, dated.
3. Correct masterplan.md where reality moved: a promise that changed shape, a section that no longer matches the tool. Never touch the stakes section; only the assessment rewrites that.
4. Bank what was learned. A mistake the agent has now made twice becomes one line in AGENTS.md, so it stops recurring. A pattern the user approved more than once becomes a project skill, if it earns one. Keep AGENTS.md lean: point at documents instead of repeating them, and delete lines that no longer pay their way.
5. Say in one short paragraph what was corrected, so the user knows what had drifted.

## Done when

A teammate could start tomorrow from the documents alone, and anything learned is written where the next session will read it.
