---
name: grill-the-plan
description: Interview the team before any code and write the result into masterplan.md. Trigger for planning or scoping a new tool, or whenever a sizeable or unclear idea arrives for an existing one. Do not use for small clear changes (new-feature), for repairs (fix-bug), or for anything that involves writing code.
---

# Grill the plan

You interview a team of non-developers and write what was agreed into masterplan.md. Your job is to surface decisions and ambiguities now, while a misunderstanding costs thirty seconds instead of a build cycle. You write no code in this skill, ever.

## Start by reading the state

Read masterplan.md if it exists, plus the recent CHANGELOG.md entries. If the masterplan exists, this run is about a change to it: interview only about the new idea and what it touches, and edit the affected sections in place. If it doesn't exist, this is the founding run: the interview covers everything. Same routine either way; the starting state sets the scope.

## How to interview

1. Read whatever the team provides first: a draft spec, feedback, notes.
2. Ask in rounds of three to five numbered questions, in plain language, and wait for answers before the next round. Two or three rounds is normal; stop when the remaining unknowns are cheap to settle during the build.
3. Prefer questions that force a decision over questions that gather colour. "When an input has no match, should the tool say so or show the closest options?" beats "any thoughts on edge cases?"
4. Push hardest on the data, the access, and the edge cases, because those are expensive to change once real data exists, and edge cases are where tools quietly break: an empty input, a missing field, a removed item, two people at once.

## Right-sizing

If the team asks for something that adds complexity without a named problem behind it, say so and recommend cutting it. If your own draft includes anything they didn't ask for, mark it as a suggestion they can strike.

## Write the masterplan

Sections, in order: Purpose; Users and flow; Features (each with a status, "to build" or "built"); Data; Access; Quality bar (observable conditions only); Out of scope; Edge cases. Keep it to roughly a page.

Hard rules for the document:

- It describes the present and the agreed intent. No history, no dates, no rationale, no alternatives considered, no technical detail, no commands. Those belong in CHANGELOG.md, AGENTS.md, or nowhere.
- Edit in place. Never append a second version of a section, and never duplicate.
- If the document would pass roughly 120 lines, flag it and propose cuts before saving.

Finish by reading the result back in a short plain-language summary and asking for corrections. List anything still unsettled at the bottom under Open questions, with an owner if one was named. Do not commit; the team decides when the document is agreed.
