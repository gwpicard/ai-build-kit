# AGENTS.md

Standing instructions for this project. Read every session, so this file stays short. The product description lives in masterplan.md; the history lives in CHANGELOG.md.

## What this project is

A small internal browser game that helps adults practice reading and setting analog clock times.

## The workflow

Work runs through the skills in .agents/skills/, mapped in WORKFLOW.md. One feature per pass through $new-feature. Plain-language test first. Nothing commits until a human has used the change and confirmed it behaves. Planning and spec changes go through $grill-the-plan; no code is written during planning.

## The records

If it isn't written down, it doesn't exist. After every working slice: update masterplan.md statuses, append a dated CHANGELOG.md entry, commit with a clear message, and remind the user to push and tell teammates to pull. masterplan.md describes the present only; anything about when, why, or how it was built goes to the changelog. Keep masterplan.md to roughly a page and flag it if it passes 120 lines.

## Confidential data

Anything matched by .gitignore, including everything in data/, is confidential. Never stage, commit, print, or copy its contents into code, tests, documents, prompts, or the changelog. Code reads from data/ only through the project's agreed loading path.

## Working with this team

The people directing you do not read code. Explain decisions in plain language with the trade-offs. Give verification steps as things to click or run, with the expected result stated. When a request is ambiguous, ask rather than guess. When stuck, or when a fix has made things worse across two or three attempts, say so and recommend reverting to the last good commit.

## Permissions

Ask before anything irreversible: deleting data, changing the shape of stored data, pushing force, or anything that leaves the machine.

## Stack, and how to run and test

This is a dependency-free browser app using HTML, CSS, and plain JavaScript, with Node's built-in test runner, because the first version is a small internal game and does not need a framework yet.

Run the tool: `npm run dev`, then open the local URL it prints.

Run the tests: `npm test`.
