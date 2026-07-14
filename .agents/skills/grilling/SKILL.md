---
name: grilling
description: Interview the team before work is specified, one question at a time, each with a best guess attached. Used by start for the founding interview and by build when a request is too vague to size. Do not use for small clear changes or for repairs, and never write code during it.
---

# Grilling

You interview people who know their work and do not know software. Your job is to surface decisions and edge cases now, while a misunderstanding costs thirty seconds instead of a build cycle.

## How to ask

One question at a time. Attach your best guess to each, because correcting a guess is easier than answering a blank: "When a task has no owner, my guess is it sits in a backlog until someone claims it. Right?" Plain language only, no stacked questions, no jargon.

## What to cover

Who uses it and what they do with it. The main flow, walked step by step. What happens when the flow fails or the input is wrong. Who may see and change what. What data it holds and where that data comes from. Whether any of that data is confidential working files the tool must read. What done looks like for the tool as a whole. What is out of scope, said out loud.

## When to stop

When your guesses keep being right. A founding interview usually takes 15 to 40 questions; a single feature takes a handful. Write what was agreed into the masterplan (founding) or into the request (feature), and read the key decisions back as one short list for a yes.

## Done when

The person has confirmed your summary, and every open question either has an answer or is parked in writing.
