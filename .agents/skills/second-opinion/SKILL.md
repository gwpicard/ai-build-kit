---
name: second-opinion
description: Review work using the best independent method available to the current harness and build path. Used on a drafted masterplan during start, on the diff of any change the build path or the change's consequence flags for review during a build, and on the whole build during ship when the current build path calls for a launch review. Report first, in plain behavioural language, sorted into worth-stopping-for and worth-knowing; change nothing without approval.
user-invocable: false
---

# Second opinion

Act as fresh eyes. Prefer a reviewer that did not produce the work. When Explore privately permits a same-session fallback, label it as non-independent and review only from the written agreement and evidence.

You review on two axes internally, and report the findings under the same two
user-facing headings regardless of which axis surfaced them.

## Axis 1: Agreement

Does the result do what the masterplan or the agreed piece says? Is any
requested behaviour missing or partial? Was behaviour added that nobody
asked for? Does the evidence actually cover the promised result, or does it
prove something narrower? Does the documentation now match what was really
built?

## Axis 2: Risk

Ask only what applies to the build path and the change in front of you:
access and permission boundaries, secret or personal-data exposure, data
loss, duplication, or corruption, double actions, failure and recovery,
migration or rollback safety, autonomous actions, unnecessary complexity
that would make future changes materially harder, and any violation of the
build path or an expert boundary.

Check the classics by trying them rather than assuming. Can someone without
an account see anything? Can one user reach another's things by editing an
address or an id? Do keys or personal details appear anywhere they should
not, including anything sent to the browser? Can money move twice from one
click?

## On a masterplan

Hunt for gaps and contradictions: two sections that disagree, a failure path
with no answer, a who-can-do-this question with no rule, a piece of data
with no stated home. Report what you found as questions the team can answer,
ordered by how expensive each would be to discover later. Note in the
changelog that the review ran.

## On a change, or a whole build

Read the work against the masterplan's build-path section. For a change,
review the diff against main and only the diff: a bounded change
concentrates the review, and wandering the whole repository dilutes it. On
the paths where ship runs a launch review, the whole tool gets read exactly
once, at that point.

## Report format

```md
## Worth stopping for

- Agreement: <plain finding, what was tried, what happened>
- Risk: <plain finding, what was tried, what happened>

## Worth knowing

- Agreement: ...
- Risk: ...

## Review limits

- <what this review did not prove>
```

Every finding states what you tried, what happened, and whether that seems
intended: "Someone with the link can see the board without signing in.
Expected?" The person's decision should collapse to one question: is the
first list empty?

Do not expose code-smell vocabulary. Raise a maintainability concern only
when it affects reliability, the ability to test something, a repeated bug,
future ownership, or the project's build path; state it in those terms, not
as an abstraction critique.

## Independence fallback

Use, in order: an independent subagent, a clean separate session, or a
user-opened clean chat with a prepared instruction. A same-session fallback
is permitted only for Explore privately and must be labelled as
non-independent.

This fallback covers a review that asks only for eyes other than the builder's.
It does not cover a review whose reviewer is named. Where the build path or a
risk notice asks for a particular person, such as the owner of a failing
component or a specialist in one area, that person is the review, and no
session of any kind stands in for them. Neither does a passing test suite, a
check the project already runs, or the person having a look themselves. Say the
named review has not happened, and let them accept that on the record if they
want the work anyway.

## The rule

Report first. Fix only what the user approves, and never widen into a general tidy-up.

## Done when

Every finding was tried rather than assumed, the report is in plain language, and the user has decided what happens next.
