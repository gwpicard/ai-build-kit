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

## Settling a vague or overloaded term

When one word is carrying two meanings, stop and settle it before going on:

1. point out the ambiguity;
2. propose plain alternatives;
3. test the alternatives against a concrete scenario;
4. settle on one canonical term;
5. update masterplan.md immediately if the term affects the whole product.

For example: "You have used 'customer' for both the company paying and the
person signing in. I suggest 'company' and 'user'. Does that match the real
workflow?"

Do not create CONTEXT.md, context maps, or architecture decision records to
carry this. The settled term lives in the masterplan, in plain language,
where the rest of the product description already lives.

## Pressure-testing a rule

For each rule that matters to the product, ask at least one edge case drawn
from what's relevant to this project: nothing entered, a duplicate action,
two people acting at once, no permission, an external service unavailable,
data that already exists, or an action interrupted halfway through. Only ask
the cases that could actually happen here.

## When conversation cannot settle it

If a behavioural or visual decision cannot be settled by talking it through,
load references/decision-prototype.md. The interview pauses, the prototype
answers the one question it exists to answer, and the decision gets written
back into the masterplan or the request before the interview continues.

If an answer instead depends on an external fact, such as what a provider's
API actually supports, load change-triage/references/source-check.md rather
than guessing.

## When to stop

When your guesses keep being right, and: the main flow is clear, failure and
permissions are clear, the fit check's questions can be answered, and every
remaining unknown is explicitly parked, researched, or prototyped rather than
quietly assumed. Write what was agreed into the masterplan (founding) or into
the request (feature), and read the key decisions back as one short list for
a yes.

## Done when

The person has confirmed your summary, and every open question either has an answer or is parked in writing.
