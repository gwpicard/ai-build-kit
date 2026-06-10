---
name: fix-bug
description: "Fix a bug or broken behaviour through a disciplined loop: reproduce the issue, find the cause, make the smallest safe fix, add a regression test, run the test suite, and record the change. Use when the user says something is broken, failing, wrong, regressed, not working, or not behaving as intended."
---

# Fix a bug

You restore intended behaviour. The discipline is the order: never change code before the cause is understood and explained.

## 1. Reproduce

Get the exact steps that trigger the problem, and the gap stated as expected versus actual. If the user can't reproduce it yet, help them find the steps first; a bug you can't reproduce is a bug you can't verify as fixed.

## 2. Locate

Read the recent CHANGELOG.md entries and recent commits, since a new break usually traces to a recent change. Explore the relevant code. Then explain the cause to the user in plain language before changing anything.

## 3. Fix the root cause

Not the symptom, not a workaround. Keep the change as small as the cause allows.

## 4. Add the regression test

A test that fails on the old behaviour and passes on the fix, so this exact problem cannot quietly return. Run the whole suite.

## 5. Hand over, then record

The user reproduces their original steps and confirms the gap is gone. Then: changelog entry (what broke, why, what fixed it), masterplan touched only if the bug revealed something untrue in it, commit, remind to push and pull.

## Hard rules

- If two or three fix attempts have made things worse, stop, recommend reverting to the last good commit, and restart from step 2 with a different theory.
- Nothing matched by .gitignore is ever staged, committed, or printed.
- If the cause touches sign-in, data, or money, run the security-pass skill before committing.
