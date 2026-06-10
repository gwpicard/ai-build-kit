---
name: new-feature
description: Build one feature through the team's loop, test first, with a human behaviour check before anything commits. Trigger for building any feature from the masterplan, or any small clear change with a one-sentence done condition. Do not use for repairs (fix-bug), for planning (grill-the-plan), or for several features at once.
---

# New feature: the build loop

You build one feature, directed by a non-developer. Follow the steps in order. One feature per pass; the next feature starts a new pass.

## 1. Read the state

masterplan.md, plus the recent CHANGELOG.md entries. If the change touches behaviour that already exists, explore the relevant part of the code first and summarise in two or three plain sentences how it works now and what this change touches, before proposing anything.

## 2. Check the size

The feature needs a done condition the user can say in one sentence. If the request bundles several features or the done condition won't compress to a sentence, stop and propose a split. Build only the first agreed piece.

## 3. Ask before guessing

Anything ambiguous gets asked now, in plain language, with the options and trade-offs. Do not pad the feature with extras nobody asked for. Useful context to request if missing: a real input and the expected output, a screenshot or sketch, the definition of done.

## 4. Test first

Write the expected behaviour as a plain-language test, show the user the sentence form ("when this happens, that should be true"), and wait for their confirmation that it matches what they meant.

## 5. Build until it passes

Implement, run the whole suite including the new test, and keep working until green. Use safe, parameterised approaches for anything that takes user input.

## 6. Stop for the human check

Tell the user exactly what to click or run and what they should see. Then stop. Nothing commits until they confirm the behaviour. If they report a gap, treat their expected-versus-actual description as the bug: fix the root cause rather than a workaround, add a test so the gap cannot reopen, and hand over again.

## 7. Record

After confirmation: if the change touched sign-in, data, or money, run the security-pass skill first and resolve what it finds. Then flip the feature's status to "built" in masterplan.md (and update any masterplan section the change made untrue, editing in place), append a dated CHANGELOG.md entry with the why where it isn't obvious, update AGENTS.md only if a convention changed, and commit with a clear message. Remind the user to push, and that teammates need to pull.

## Hard rules

- Nothing matched by .gitignore is ever staged, committed, printed, or copied into code, tests, documents, or prompts. Confidential data is read only through the project's agreed loading path.
- If a fix has made things worse across two or three attempts, say so, recommend reverting to the last good commit, and propose a different approach.
- The masterplan stays about a page and describes the present; history goes to the changelog.
