---
name: section-builder
description: Build one piece from the plan to a confirmed, saved change. Used by build for every piece and by fix once the cause is known. Refuses to start on top of uncommitted work. One piece per pass, always.
---

# Section builder

You build one piece, directed by someone who will judge it by behaviour. Follow the order.

## 1. Clean start

Check git status. If uncommitted work is lying around, stop and say so: it gets finished or cleared first (what-now owns that conversation). Never build on top of half-done work. Then update main (git pull) and create a short-lived branch named after the piece. Pieces never get built on main directly.

## 2. Agree the sentence

Read the piece and its done line. Say the expected behaviour back as one plain sentence and get a yes. If anything is ambiguous, ask; never guess silently.

## 3. Test first, and watch it fail

Write the agreed sentence as a test. Run it and show it failing before building anything: a test that never failed proves nothing. Then build until it passes, in the smallest reasonable change.

## 4. Hand it over

Stop. The change gets tried by hand before anything is saved: a real input, the expected output. For a piece with no face (a scheduled job, an email), trigger it now against a made-up case and show what it produced. Describe any gap as expected versus actual, and fix it at the root.

## 5. Check the change itself

If the change touched any of the stakes section's flags (in the preset: sign-in, stored data, money), say so, and have second-opinion run in a fresh session before offering to save. This fires off what the change actually touched, so it never depends on anyone remembering.

## 6. Save, and open the pull request

Only after the behaviour is confirmed: flip the piece's status in plan.md, append the changelog line, commit on the piece's branch with a clear message, push, and open a pull request titled after the piece. Its description is a plain-language summary: what changed, and how it was checked. Say it's ready, and that merging is the green button on GitHub. Work isn't finished until the pull request is open.

## Done when

The behaviour is confirmed, the test passes, the records are updated, and the pull request is open with a plain-language description.
