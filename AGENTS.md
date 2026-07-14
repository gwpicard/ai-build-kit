# AGENTS.md

Standing instructions for this project. Read every session, so this file stays short: it points at the documents rather than repeating them. The product lives in masterplan.md, what's left lives in plan.md, the history lives in CHANGELOG.md.

## What this project is

(One line, written by $start.)

## Before any work

Read masterplan.md, stakes section first. Its flags are stop conditions, never suggestions. Then read plan.md if the work touches it.

## The workflow

Work runs through the skills in .agents/skills/, mapped in WORKFLOW.md. One piece per pass through $build. Test first, and show the test failing before building: a test that never failed proves nothing. Nothing is saved until a human has used the change and confirmed it behaves. Requests arrive in plain language through $build; classify them with change-triage instead of trusting the label the user picked.

## The records

If it isn't written down, it doesn't exist. After every working piece: update plan.md statuses, append a dated CHANGELOG.md entry, commit on the piece's branch with a clear message, and open the pull request. Merging belongs to a human, always; after a merge, everyone pulls main. masterplan.md describes the present only. Keep it to roughly a page and flag it if it passes 120 lines.

## Working with this team

The people directing you do not read code. Explain decisions in plain language with the trade-offs. Give verification steps as things to click or run, with the expected result stated. When a request is ambiguous, ask rather than guess. When stuck, or when a fix has made things worse across two or three attempts, say so and recommend going back to the last good snapshot.

## Secrets

Keys, passwords, and tokens live in .env and nowhere else. Never print, commit, or echo one; never paste one into a document, a test, or the changelog. A key that has appeared anywhere it shouldn't gets rotated straight away, and you say so.

## Confidential files

If the project works from confidential files, their folder and handling rules are recorded here by $start. Never stage, commit, print, or copy their contents into code, tests, documents, or the changelog.

(Filled in by $start if the project needs it.)

## Dangerous commands

The list in .agents/guard/blocked-commands.md is off limits. Commit before anything sweeping. Ask before anything irreversible: deleting data, changing the shape of stored data, or anything that leaves this machine.

## Stop and ask when

Work would touch a flagged area outside the current piece. A piece needs more than three new files. A dependency would be added or upgraded. The masterplan is silent on a decision that matters.

## Stack, and how to run and test

(Filled in by $start.)
