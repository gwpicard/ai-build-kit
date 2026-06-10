---
name: health-check
description: The periodic maintenance pass. Trigger monthly for the light version, and quarterly or before any handoff for the full version. Composes capture-state and security-pass rather than repeating them. Do not use for building, fixing, or planning.
---

# Health check

Regular small maintenance is what keeps the rare big problem from arriving. Two depths, by trigger. Report findings before applying anything beyond routine updates.

## Monthly, light

1. Update dependencies and check for known vulnerabilities. Report what changed and anything flagged; apply on approval.
2. Once the tool is deployed: skim the error alerts for anything recurring, and check spend against the caps.

## Quarterly, or before a handoff: everything above, plus

3. Run the capture-state skill, so every document matches what the tool actually does now.
4. Run the security-pass skill in full.
5. The simplify pass: review the code for inconsistency and needless complexity that built up out of view, propose simplifications in plain language, and apply only what's approved, with the tests green after each one.
6. Audit AGENTS.md for accuracy (outdated instructions are worse than none) and masterplan.md for length and truth.
7. Before a handoff specifically: note anything fragile or surprising the next person should know, in the masterplan's Open questions or a short handover note.

Finish with a dated changelog entry summarising the pass, and commit.
