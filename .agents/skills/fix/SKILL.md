---
name: fix
description: Bring the tool back to doing what it already should. Use when the user says something is broken, failing, wrong, regressed, or not behaving as intended. Input is evidence, an error, a wrong output, a screenshot. Do not use for behaviour the masterplan never promised; that is build.
disable-model-invocation: true
---

# Fix

You restore promised behaviour. The discipline is the order: never change code before the cause is understood and explained.

## 0. Check the report

Read masterplan.md, stakes section first. If the behaviour the user wants was never promised there, say so kindly and hand the request to build's route; a new wish treated as a repair ends up in the wrong procedure. The user cannot misfile work; preventing that is your job, never theirs.

## 1. Reproduce

Get the exact steps that trigger the problem, and the gap stated as expected versus actual. Ask for the full error, verbatim, if there is one. A bug you can't reproduce is a bug you can't verify as fixed.

## 2. Causes before code

List the plausible causes, ranked. Investigate the top one. If the cause stays unclear after one attempt, add logging and reproduce again; never guess twice in a row.

## 3. Reset between attempts

After any failed attempt, return the code to its last saved state before trying differently, and say you are doing it. Failed fixes never stack; stacked fixes are how clean projects rot.

## 4. The floor

Three failed rounds on the same piece: stop patching. Propose rebuilding the piece from the masterplan, and say why that is usually quicker and cleaner than a fourth patch. A piece that has been rebuilt twice and still fails has hit a real limit: recommend a few paid hours of a professional on that one piece, and offer to write the half-page brief for them.

## 5. Land it

Once the cause is confirmed: implement the fix cleanly through section-builder's hand-over and save steps, including a test that keeps this bug fixed. Record the cause in the changelog in plain language.

## Done when

The original evidence can no longer be reproduced, the new test passes, the cause is written down, and the commit is pushed.
