---
name: build
description: The everyday word for making the tool do something new or different. Typed alone it takes the next piece from the plan. Typed with words after it, it takes the request in plain language and works out what kind of work it is. "/build auto" builds several pieces in a row. Do not use for repairs of promised behaviour; that is fix.
disable-model-invocation: true
---

# Build

Always a fresh session, and fresh session means exactly that: close the chat, open a new one, type the command. One piece per session keeps quality flat and the documents honest. Read masterplan.md first, stakes section first, then plan.md.

## Typed alone

Take the next piece marked to-build and run section-builder on it.

## Typed with words

Run change-triage on the request and follow its route: build it now through section-builder, run grilling first, update the masterplan first, or stop and run the fit check. Say which route you chose and why, in one line.

## Typed with auto

The plan gets approved once; the pieces then run in a row with nobody in between. The rules of the mode: every piece still goes test first with the test seen failing, and every piece gets its own commit, so anything can be unwound piece by piece.

Which pieces the run may take: only those whose done line a machine can prove, meaning it names a test or a command with a checkable result. A piece whose done line needs human eyes ("you see it in the browser", "you check it by hand") gets skipped and left marked to-build; say so in the report. The plan sorts itself: the how-to-check phrase on each done line is the eligibility rule.

When a piece fails: retry within the piece, up to three attempts, the same number fix uses. After the third, park it: mark it stuck in plan.md with one line on what kept failing, and move to the next piece. Never let one piece consume the run. Stop the whole run at anything change-triage would escalate, at any touch of a flagged area, and at anything ambiguous; never guess to keep a run going.

The whole run happens on one branch and ends as one pull request. Skip the per-piece hand-over; end the run with the evidence run (ship/references/evidence-run.md), and write the pull request's description as the report: what was parked and why first, then what was built, what passed, what was skipped as eyes-only, and a checklist of things to try before merging, riskiest first, anything near the flags on top.

When a run disappoints, the fix is the documents, never the code by hand: sharpen the done lines that let weak work through, add the missing rule to the masterplan, then run it again. Hand-editing what a run wrote is how a readable project becomes a mystery.

## Goal modes

Some tools ship a /goal feature: state a condition and the agent keeps going until a separate model judges it met. Treat it as this mode wearing the tool's clothes, under the same rules: the condition comes from a done line or a plan area's done lines, read aloud; flagged areas stay stop conditions the goal may not cross; the three-attempt parking rule still applies per piece; and the result still lands as a pull request, because merging belongs to a human however long the machine ran.

## Done when

The route was followed, the records are true, and either the piece is confirmed and pushed or the user knows exactly where things stopped and why.
