---
name: clarify
description: Interview the team before work is specified, one question at a time, each with a best guess attached. Used by start for the founding interview and by shape when a request is too vague to size. Do not use for small clear changes or for repairs, and never write code during it.
user-invocable: false
---

# Clarify

For project record reads and writes, load the `setup-ai-build-kit` skill's
`references/project-records.md`. Its marker selects authoritative concept,
working-rule and operations records for the new format; legacy projects keep
their existing route. This changes record ownership, not safety or merge authority.


You interview people who know their work and do not know software. Your job is to surface decisions and edge cases now, while a misunderstanding costs thirty seconds instead of a build cycle.

## How to ask

One question at a time, in one short sentence. Background is at most two short sentences and appears only when needed to answer. Label the best guess as a guess, because correcting it is easier than answering a blank. Say once when first offering choices: "Choose an answer or write your own; the first suggestion is my guess." Plain language only, no stacked questions, no jargon.

Match the question to the shape of its answer. When the real answers are a short and complete list, offer them as choices and put the guess first, clearly marked as the likely one. A question that asks the person to describe, name, explain, or narrate is asked in plain words, with the answer left open. Preserve free-text answers even where choices are offered.

Read the supplied session role and the exposed tool contract before choosing where to ask. A terminal alone does not prove a person is present. A worker uses the coordinator route even if a local question tool is exposed. With a person present, use the actual exposed question tool when its supported schema can reach the present person. Follow the actual tool cardinality while sending only one question. If the tool supports free text without choices, use that for an open question. Never invent choices to satisfy a minimum option count.

If no supported question tool is available, or its schema cannot express this question, ask in concise plain words. Keep the same question and clearly labelled guess in the fallback: "My guess: the team. Who uses it?" An empty submission, cancellation or preselected option never submitted is no answer. Keep the question unanswered and follow the existing missing-answer route; never invent a human answer or consent.

In a worker or background session, send the exact question and labelled guess to the coordinator through its supported channel. Delivery alone is not an answer: settle the question only from the returned answer, keeping the person's words or choice. While waiting, continue independent eligible work. If the relay is unavailable, leave the exact question and guess on the owning piece and park that piece, with the relay failure as its reason. If the worker cannot update the piece, report that exact pending question and required parking to the coordinator; never claim it was saved. Never open a human question UI in an unattended worker.

A headless replay with a scripted plain-text interlocutor uses the plain-words route. Leave the question in the reply text so the scripted turn gate can see it. This routing does not turn a founding non-gate into a required answer: founding still records an unneeded answer as an open question and carries on. Earned-acceptance rules still apply; a guess, silence or empty form cannot stand for the person's acceptance.

## What to cover

Who uses it and what they do with it. The main flow, walked step by step. What happens when the flow fails or the input is wrong. Who may see and change what. What data it holds and where that data comes from. Whether any of that data is confidential working files the tool must read. What done looks like for the tool as a whole. What is out of scope, said out loud.

## Settling a vague or overloaded term

When one word is carrying two meanings, stop and settle it before going on:

1. point out the ambiguity;
2. propose plain alternatives;
3. test the alternatives against a concrete scenario;
4. settle on one canonical term;
5. record the settled term where the current work lives, without committing a
   file or opening a pull request. In a founding session, that is the working
   notes the interview keeps, and the masterplan once it exists. In a planning
   session, that is the piece being shaped: record the term in `## Decided` and
   put the key-terms update in `## Masterplan change`, so `/implement` writes
   it when it builds the piece.

   Keep that settled term on the piece when it is parked or reshaped, until it
   reaches the masterplan or the person explicitly changes the decision. Add
   this reason on the piece: "The term stays here
   while this is planned; the coverage read checks it even if this piece is
   parked."

   Planning records and stops; writing to the masterplan is a build.

For example: "You have used 'customer' for both the company paying and the
person signing in. I suggest 'company' and 'user'. Does that match the real
workflow?"

Do not create CONTEXT.md, context maps, or architecture decision records to
carry this. The settled term ends up in the masterplan, in plain language, where
the rest of the product description already lives: written there when founding,
or when `/implement` next builds the piece that carries it. The coverage read
in setup-ai-build-kit/references/coverage-read.md catches a settled term left
behind on a piece and offers to reconcile it through /sync.

## Pressure-testing a rule

For each rule that matters to the product, ask at least one edge case drawn
from what's relevant to this project: nothing entered, a duplicate action,
two people acting at once, no permission, an external service unavailable,
data that already exists, or an action interrupted halfway through. Only ask
the cases that could actually happen here.

## When a piece touches states, data or the outside

When the interview is shaping one piece, three subjects come up only when the
piece touches them. Where the change can show a case that is not the normal
one, such as empty, failing, slow or left part-way, ask what the person should
see in it. Where it stores or changes a record, ask who else writes it, what
happens at its limit, and what delete and undo mean. Where anything leaves the
tool, ask what goes, to whom, and whether the recipient is new. Skip each
subject the piece does not touch, so a colour change hears none of them. The
answers fill the piece's `### When it is not the normal case`, `## Data` and
`## Leaves the tool`.

## When conversation cannot settle it

If a behavioural or visual decision cannot be settled by talking it through,
ask whether they already have something that shows it: a sketch, a mock, a
screenshot, the spreadsheet they use today. Where they do, load
references/existing-artifact.md and let it settle the question. Where they do
not, load references/decision-prototype.md. The interview pauses, the prototype
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
