---
name: second-opinion
description: Review a piece from its review packet or the founding masterplan in a fresh context. Judge the agreed result, what the change may have broken, and whether the evidence is real.
user-invocable: false
---

# Second opinion

Report first. Fix only what the person approves.

For a piece, run the `quality-checks` skill's
`scripts/gate.py` with `brief --base <start commit> --piece <number>` and act on its exit
code. Review the packet it writes. It is the
full brief for this review, including the change, `project-check` and, where
reported, `recipe-check` evidence for type and lint checks.
Gemini reviewers have no shell, so include the packet text in the prompt.
Exit 2 means an input is missing. Continue the review and carry the packet's
`Review limits` into the result.

At founding, review `masterplan.md` against the agreed scope and setup notes,
using the questions below for the proposed work. No piece, base commit or
pull request is needed. Put findings and review limits in the completion
report instead of running `gate.py record`.

Use the reviewer agent in a fresh context. If its brief is not installed,
start an ordinary fresh subagent, tell it to load this `second-opinion` skill,
and give it the packet, or the masterplan and setup notes. Tell it to return
only JSON findings, change no files and start no agents. For refutation, use
a separate fresh subagent loading this skill with the packet and one finding;
ask it only to disprove that finding and return `refuted` and an explanation.
Where subagents cannot start, run the same brief and inputs headless with
`claude -p`, `codex exec` or `gemini -p`. If none can run, give the person an
instruction naming the installed skill and inputs to paste into a clean chat.
Never present a same-session pass as independent.

Ask only:

- Does the change do what the title, `So that` and `Done when` agreed?
- Did it break behaviour that worked before: can anyone now read or change records or actions they could not before, through row rules, roles, sign-in or another user's data?
- Does the evidence prove the promised result, using real data where an
  outside service is involved?

Do not judge risk to people. Founding settles that. Do not review screens,
settings or the whole project in this review.

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
to refute it. Mark a refuted finding `refuted` in the JSON. For a piece, run
`gate.py record --pr <number>` with the findings and act on its exit code.
Exit 1 means stopping findings were recorded as open boxes, or the pull
request moved on after the packet; exit 0 means none remain. The record names
the commit the packet read, so a later push needs a new review. Say in one line
what was reviewed and the result, with the record's `Review independence`
words. Never call an unverified review independent.
