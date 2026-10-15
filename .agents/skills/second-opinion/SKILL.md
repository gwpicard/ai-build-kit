---
name: second-opinion
description: Review work using the best independent method available to the current harness and build path. Used on a drafted masterplan during setup-ai-build-kit, on the diff of any change the build path or the change's consequence flags for review during a build, and on the whole build during setup-hosting when the current build path calls for a launch review. Report first, in plain behavioural language, sorted into worth-stopping-for and worth-knowing; change nothing without approval.
user-invocable: false
---

# Second opinion

Act as fresh eyes. Report every finding under the two report headings below,
whichever axis found it.

## Axis 1: Agreement

Does the result do what the masterplan or the agreed piece says? Is requested
behaviour missing or partial, or was unrequested behaviour added? Does the
evidence cover the promised result, or something narrower? Do the documents
match what was built?

## Axis 2: Risk

Ask only what applies to this build path and change: access and permission
boundaries, secret or personal-data exposure, data loss, duplication or
corruption, double actions, failure and recovery, migration or rollback
safety, autonomous actions, complexity that would make later changes much
harder, and any breach of the build path or a sensitive area's caution.

Try the classics rather than assuming. Can someone without an account see
anything? Can one user reach another's things by editing an address or an id?
Do keys or personal details appear where they should not, including in what
is sent to the browser? Can money move twice from one click?

Before a finding asks the person to look up a setting of a service the tool
uses, read it yourself where you can: a public address, a command-line tool
already signed in here through its own commands, or the project's files. On a
recipe, run the script its `Settings the kit can read` section names and report
its lines. Use only a key the project already sends to the browser. Ask the
person only for what you cannot read that way, and say why. AGENTS.md's
Secrets rule holds throughout.

## Axis 3: Screen

During a build review, when the piece carries `visual` or the diff touches a
screen file, load and follow the `screen-check` skill. Say which rules were
applied, which could not be checked, and what a person still has to try. This
axis does not run on a masterplan review or the whole-build review.

## On a masterplan

Hunt for gaps and contradictions: two sections that disagree, a failure path
with no answer, a who-can-do-this question with no rule, data with no stated
home. Report them as questions the team can answer, most expensive to find
later first. Note in the changelog that the review ran.

## On a change, or a whole build

Read the work against the build-path section. For a change, review the diff
against main and only the diff. The whole tool is read once, at the launch
review /setup-hosting runs.

## Report format

Write every finding under `Worth stopping for` as an unticked box. For a
masterplan review, put findings in the completion report. For a change or
whole-build review, put them in the pull request body. Keep a settled finding
as a ticked box; do not remove it.

```md
## Worth stopping for

- [ ] Agreement: <plain finding, what was tried, what happened>
- [ ] Risk: <plain finding, what was tried, what happened>

## Worth knowing

- Agreement: ...
- Risk: ...
- Review limits: <what this review did not prove>
```

Every finding says what you tried, what happened, and whether that seems
intended: "Someone with the link can see the board without signing in.
Expected?" The person's decision should come down to one question: is any box
under `Worth stopping for` unticked? Keep code-smell vocabulary out. Raise
maintainability only where it affects reliability, testing, a repeated bug,
ownership or the build path, in those terms.

## Independence fallback

Use, in order: the `reviewer` agent where the coding agent has one, or another
fresh subagent told to load this skill; the same brief run headless with
`claude -p`, `codex exec` or `gemini -p`; a clean separate session; or a clean
chat the person opens with a prepared instruction. A same-session review is
allowed only on Explore privately, labelled as not independent and reading only
the written agreement and evidence.

A reviewer that works in this project folder only reads. Before you start it,
run this skill's `scripts/review-guard.sh snapshot` with the files under
review: masterplan.md at founding, and the files the change touches for a
piece. When it returns, run `scripts/review-guard.sh check`. Exit 1: it put
back what the review changed and named anything else it found changed; tell
the person in one line, and that their work is as it was. Exit 2: say in one
line that the review could not be checked for changes.

This covers a review that asks only for eyes other than the builder's. Where
the build path or a risk notice names a person, such as the owner of a failing
component or a specialist, that person is the review. No session, passing test
suite, existing check, or the person's own look stands in for them. Say the
named review has not happened, and let them accept that on the record if they
want the work anyway.

## The rule

Report first. Fix only what the person approves, and never widen into a
general tidy-up.

## Done when

Every finding was tried rather than assumed, the report is in plain language, and the user has decided what happens next.
