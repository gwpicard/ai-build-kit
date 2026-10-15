---
name: second-opinion
description: Review a piece from its review packet in a fresh context. Judge the agreed result, what the change may have broken, and whether the evidence is real.
user-invocable: false
---

# Second opinion

Run `gate.py brief --base <start commit> --piece <number>` and act on its exit
code. Review the packet it writes. It is the
full brief for this review, including the change and the available evidence.
Gemini reviewers have no shell, so include the packet text in the prompt.
Exit 2 means an input is missing. Continue the review and carry the packet's
`Review limits` into the result.
Use the reviewer agent in a fresh context. If the coding agent cannot start
agents, run `.agents/agents/reviewer.md` headless with the packet text in its
prompt. Use the refuter agent the same way for its separate pass.

Ask only:

- Does the change do what the title, `So that` and `Done when` agreed?
- Did it break behaviour that worked before?
- Does the evidence prove the promised result, using real data where an
  outside service is involved?

Do not judge risk to people. Founding settles that. Do not review screens,
settings, the whole project or a masterplan in this review.

Return findings as JSON for `gate.py record`, with one object per finding:

```json
{
  "mark": "reproduced or reasoned",
  "finding": "What failed, in plain language",
  "command": "Command that reproduced it",
  "output": "Relevant output",
  "failing_test": "Test name, if a test reproduced it",
  "scenario": "Who does what and what goes wrong",
  "worth_stopping_for": true
}
```

For a reproduced finding, include a command and its output, or name a failing
test. For a reasoned finding, give a concrete scenario that says who does
what and what goes wrong. The script drops findings without either form of
evidence. Mark whether each supported finding is worth stopping for.

For each finding marked worth stopping for, ask a second fresh reviewer to try
to refute it. Mark a refuted finding `refuted` in the JSON. Then run
`gate.py record --pr <number>` with the findings and act on its exit code.
Exit 1 means stopping findings were recorded as open boxes; exit 0 means none
remain. Say in one line what was reviewed and the result.
