---
name: section-builder
description: Build one piece from the plan to a confirmed, saved change. Used by build for every piece and by fix once the cause is known. Refuses to start on top of uncommitted work. One piece per pass, always.
---

# Section builder

You build one piece, directed by someone who will judge it by behaviour. Follow the order.

## 1. Clean start

Check git status. If uncommitted work is lying around, stop and say so: it gets finished or cleared first (what-now owns that conversation). Never build on top of half-done work.

## 2. Agree the sentence

Read the piece and its done line. Say the expected behaviour back as one plain sentence and get a yes. If anything is ambiguous, ask; never guess silently.

## 3. Test first, and watch it fail

Write the agreed sentence as a test. Run it and show it failing before building anything: a test that never failed proves nothing. Then build until it passes, in the smallest reasonable change.

## 4. Hand it over

Stop, and ask the user to try it: a real input, the output they expected. For a piece with no face (a scheduled job, an email), trigger it now against a made-up case and show what it produced. Describe any gap as expected versus actual, and fix it at the root.

## 5. Check the change itself

If the change touched sign-in, stored data, or money, say so, and have second-opinion run in a fresh session before offering to save. This fires off what the change actually touched, so it never depends on anyone remembering.

## 6. Save

Only after the user confirms the behaviour: flip the piece's status in plan.md, append the changelog line, commit with a clear message, push. Work is not finished until the push succeeds.

## Done when

The user confirmed the behaviour, the test passes, the records are updated, and the commit is pushed.
