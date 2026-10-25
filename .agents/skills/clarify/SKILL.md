---
name: clarify
description: Interview the team before work is specified, one question at a time, each with a best guess attached. Used by setup-ai-build-kit for the founding interview and by shape when a request is too vague to size. Do not use for small clear changes or for repairs, and never write code during it.
user-invocable: false
---

# Clarify

You interview people who know their work and do not know software. Surface decisions and edge cases now, while a misunderstanding costs thirty seconds instead of a build.

## How to ask

One question at a time, each with your best guess attached: "When a task has no owner, my guess is it sits in a backlog until someone claims it. Right?" Do not stack questions. Use the person's own terms and the established term where it is the right word; define a new term once.

Match the question to the shape of its answer. Where the real answers are a short and complete list, offer them as choices with your guess marked. A question that asks the person to describe, name, explain, or narrate is asked in plain words, with the answer left open. If the list would need "something else", the question is open. Most questions are open.

## What to cover

Who uses it and what they do with it. The main flow, step by step. What happens when the flow fails or the input is wrong. Who may see and change what. What data it holds and where it comes from, including confidential working files the tool must read. What done looks like. What is out of scope, said out loud.

## Settling a vague or overloaded term

When one word carries two meanings, stop: point out the ambiguity, propose plain alternatives, test them against a concrete case, and settle one term. For example: "You have used 'customer' for both the company paying and the person signing in. I suggest 'company' and 'user'. Does that match the real workflow?"

Record the settled term where the current work lives, without committing a file or opening a pull request. In founding, that is the working notes, then the masterplan. In planning, it is the piece: the term in `## Decided`, and the key-terms update in `## Masterplan change`, so `/implement` writes it when it builds. Planning records and stops; writing to the masterplan is a build.

Keep the term on the piece when it is parked or reshaped, until it reaches the masterplan or the person changes it, with this note: "The term stays here while this is planned; the coverage read checks it even if this piece is parked." Never create a separate glossary, context map or decision record for it.

## Pressure-testing a rule

For each rule that matters, ask at least one edge case that could really happen here: nothing entered, a duplicate action, two people at once, no permission, an outside service down, data that already exists, an action interrupted halfway.

## When conversation cannot settle it

For a behavioural or visual decision talk cannot settle, ask whether they already have something that shows it: a sketch, a mock, a screenshot, today's spreadsheet. Where they do, load references/existing-artifact.md. Where they do not, load references/decision-prototype.md. The decision goes back into the masterplan or the request before the interview continues.

An answer that depends on an outside fact runs the source check in the `research` skill.

## When to stop

When your guesses keep being right, the main flow, failure and permissions are clear, the fit check's questions can be answered, and every remaining unknown is parked, researched or prototyped rather than assumed. Write what was agreed into the masterplan (founding) or the request, and read the key decisions back as one short list for approval.

## Done when

The person has confirmed your summary, and every open question either has an answer or is parked in writing.
