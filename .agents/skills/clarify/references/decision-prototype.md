# Decision prototype

A prototype answers one decision that conversation cannot settle. First check
whether the person already has something that answers it, and follow
existing-artifact.md where they do.

## Start with the question

Write one sentence: "This prototype exists to decide whether <question>." If
more than one question appears, split them or return to clarify.

## Which kind of question is it

Say which of these you are answering, and why, before building anything:

- **Does this behave the way I meant?** They need something to press and
  watch, driven by them. Follow prototype-behaviour.md.
- **What shape should this take?** They need different arrangements side by
  side. Follow prototype-structure.md.

A question that sounds like both is two questions. Answer the behaviour one
first.

## Rules

- Use fake or disposable data, and no production credentials.
- Do not connect to live systems unless the question cannot be answered
  otherwise and the person approves.
- Make it trivial to run, and show the relevant state after each action.
- Skip production error handling, abstractions and polish.
- Build the visible thing to look like what it is testing, not like a labelled
  prototype. A tax calculator's screen is titled "Tax Calculator", not "Tax
  Calculator prototype".
- Let the person try alternatives where the decision is visual or behavioural.

## Finish

Record the question, what was tried, the decision, any rejected alternative and
why, and what the production build must preserve. Delete the prototype or
isolate it clearly, and never let it silently become the production build.
