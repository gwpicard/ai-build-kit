# Decision prototype

A prototype answers one decision that conversation cannot settle.

## Start with the question

Write one sentence:

"This prototype exists to decide whether <question>."

If more than one question appears, split them or return to grilling.

## Rules

- Use fake or disposable data.
- Do not use production credentials.
- Do not connect to live systems unless the question cannot be answered otherwise
  and the build path explicitly allows it.
- Make it trivial to run.
- Show relevant state after actions.
- Skip production error handling, abstractions, and polish.
- Do not treat prototype code as production code.
- Let the user try alternatives where the decision is visual or behavioural.

## Finish

Record:

- question;
- what was tried;
- decision;
- rejected alternative and why, when useful;
- what the production build must preserve.

Delete the prototype or isolate it clearly. Keep it only when it remains useful
evidence, and never let it silently become the production implementation.
