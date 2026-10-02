# Agentic loop: the v1 design

The design for v1 of the kit. A person and the system shape work together until
it can be built with nobody there. The system then builds it in loops, checks it
against a bar fixed before the build, and merges it, and a merge goes live. The
person reviews and steers; they never take part in a build.

The maintainer agreed the decisions in this note on 2 October 2026, after a
review of the kit, its backlog and outside work on agent loops. It replaces the
run, merge and launch parts of [loop-first-redesign.md](loop-first-redesign.md)
and [loop-first-round-2.md](loop-first-round-2.md). The piece contract, the
readiness check and the principle of those notes carry over, changed where this
note says so.

## Why

The loop-first redesign added unattended runs to a flow built for a person who
is present. Its own evidence showed the limit of that approach: rules held when
a command was typed or a machine enforced them, and prose the agent had to
remember did not. Almost every rule between capture and a merge is still prose.

Outside work points the same way. Teams that run agents unattended keep the
person at two places, deciding what to build and reviewing what was built, and
they hold everything between with fixed steps the agent cannot skip. Teams that
removed the human found that agents weaken the checks to get a green result,
so the checks have to sit where the builder cannot reach them.

So v1 turns the flow round. The loop is the default and a command is a manual
override. Each state change goes through a script. Each piece carries its own
bar, and the bar decides how the piece is built.

## The model in one picture

```
SHAPING (person + system)                          IMPLEMENTING (system alone)
------------------------------------------         -----------------------------------------------
raw --triage--> decision loop ------> spec --> check --> READY --> BUILDING (mode loop) --> IN-REVIEW --> merged
                research (facts)                                    fix | build | goal | gauntlet          = live
                clarify (decisions)
                prototype (decisions)
                     ^                                                     |
                     +-------------- kickback, with findings --------------+
```

## Two zones

Shaping is where every decision is made. The person and the system work
together: the system finds facts, builds throwaway prototypes and writes the
spec, and the person makes the choices. Nothing leaves shaping until the piece
can be built with no further question.

Implementing is where the system works alone. It builds, checks, reviews and
integrates. The person takes part only through review, and review never stops
the loop: the loop moves on to the next piece while a review waits. If a build
meets something that needs a person, the shaping was not finished, and the
piece goes back.

## Issue states

Each open issue carries exactly one state label. A state that has sub-labels
carries exactly one of them. Labels are prefixed with their dimension.

| State | Meaning | Sub-label, exactly one |
|---|---|---|
| `state:shaping` | Not ready to build | `shaping:raw`, `shaping:research`, `shaping:clarify`, `shaping:prototype`, `shaping:spec`, `shaping:check` |
| `state:ready` | Passed the ready gate; can be built with nobody there | none |
| `state:building` | A run is building it | none |
| `state:in-review` | Built, every gate green, not yet on `main` | `review:auto` or `review:person` |
| closed | Merged (completed) or dropped (not planned) | GitHub's close reason |

Three other dimensions sit beside the state. `type:` is `feature`, `bug` or
`chore`, set at triage. `mode:` is `fix`, `build`, `goal` or `gauntlet`, set
before the ready gate. The subject labels name the areas a piece touches.

There is no idea, parked, queued or blocked label. Captured work is
`shaping:raw`, which is the backlog. Work nobody will do is closed as not
planned and can be reopened. A failure during a build is a kickback. Being held
up by another issue is a GitHub blocked-by link. Membership of a run lives in
the run record.

Only the gate script changes a state. It checks the condition, writes the new
labels and the run record in one step, and refuses when the condition fails. A
hook and the deny rules stop the agent editing state labels directly. A person
can still change labels on GitHub, and the next gate run reports what it finds.

| From | To | Condition |
|---|---|---|
| (new) | `shaping:raw` | Captured in the person's words |
| `shaping:raw` | next sub-state | Triaged: a `type:` and the first open question |
| any shaping sub-state | another | The current question is settled and recorded in the piece |
| `shaping:check` | `state:ready` | The machine lint passes, a fresh session finds it ready, and a `mode:` is set |
| `state:ready` | `state:building` | A run claims it; its blockers are closed or earlier in the same run |
| `state:building` | `state:in-review` | The bar is met with fresh evidence, and the automatic review passes |
| `state:building` | `state:shaping` | Kickback, to the sub-state the problem needs |
| `state:in-review` | closed | The PR that carries it merges to `main` |
| `state:in-review` | `state:building` | Review finds a defect the spec already covers |
| `state:in-review` | `state:shaping` | Review finds a problem in the spec |
| `state:ready` | `state:shaping` | The person pulls it back before a run claims it |

## Shaping

Each sub-state answers a different kind of question, which is what keeps them
apart.

| Sub-state | Question | Who does it | Output |
|---|---|---|---|
| `raw` | What is this? | Person and system | A type, a first guess at the mode, any duplicate or overlap found |
| `research` | What is true? | System | Findings with a source for each claim, and a recommendation |
| `clarify` | What do we want? | Person | Decisions recorded in the piece |
| `prototype` | What do we want, when it has to be seen? | System builds, person decides | A decision; the prototype is deleted or kept apart |
| `spec` | No question left | System | The full contract, with the mode, its bar and the acceptance checks |
| `check` | Is it complete and buildable? | Fresh session and machine lint | Ready, or the gaps |

Research finds facts and never decides. The system settles a fact by itself;
when a finding needs a choice, the piece moves to `clarify`. Clarify and
prototype produce decisions, and only the person makes those. Spec and check
have no open question, so the system works through them alone, and a question
found there sends the piece back.

The decision loop has no fixed order. The piece sits in the sub-state of its
next open question, and an answer is written into the piece before the label
moves. Shaping reads the lessons earlier runs recorded before it researches.

Ceremony follows the size of the piece. A sub-state with nothing to do is
skipped, so a chore can go from `raw` to `spec` to `check`. Each type has a
length limit for its contract, which the lint holds. A bug with a clear
reproduction takes this short route, and can run at once as a run of one.

Sensitive areas are settled here. The risk notice is given in shaping, and the
person's acceptance is recorded before the ready gate. A piece in an area with
no acceptance cannot pass the gate.

## The piece contract

The contract is one issue. Its human header says what the person will be able
to do and how that will be judged. Its agent layer holds everything a builder
needs, because the builder never sees the shaping conversation. The fields of
the earlier contract carry over, with these additions.

- The mode, and the bar that mode needs, described in the next section.
- Acceptance checks written as real tests, committed with the spec on a
  branch, and failing on `main` today.
- A boundary field naming the areas the piece may change, and a dependency
  field naming the pieces it needs. A run plans its order from these.
- For a fix, a line saying what must not change.
- An out-of-scope list.

The brief rules hold the contract to what a builder can use alone: behaviour
rather than steps, interfaces rather than file paths or line numbers, and each
acceptance criterion checkable on its own. The lint checks them.

## Implementation modes

Shaping chooses the mode, because each mode needs a different bar.

| Mode | Chosen when | Bar in the spec | Loop | Exit |
|---|---|---|---|---|
| `fix` | Something promised, or that once worked, is broken | A reproduction that fails today; what must not change | Reproduce, rank causes, fix, run the regression checks | The reproduction passes and nothing else fails |
| `build` | Done can be stated as checks that pass or fail | The acceptance checks | Show the checks failing, then build until they pass | Every check green, and review passes |
| `goal` | Done is a measured number with a target | The metric and the command that measures it, the target, a budget, guard checks, a held-out check | Measure, change, keep or discard | Target reached with every guard check green |
| `gauntlet` | Done is judged against a specific example | A reference the person approved that can be fetched and compared, the comparison method, a budget, guard checks | Build, then a fresh blind critic compares with the reference | The work wins the comparison with every guard check green |

One piece has one mode. The builder may switch modes during a build, and logs
the switch, only when the new mode's bar comes from the spec with no new
decision. Otherwise the piece is kicked back. Two needs that call for two modes
become two pieces joined by a blocked-by link.

A loop stops at a limit on attempts or at a budget of time or tokens, whichever
comes first. An attempt is a fresh context carrying a short note of what
failed. Within those limits the builder may research and repair by itself,
provided what it learns does not change the spec.

A goal that spends its budget without reaching the target goes to review as
`review:person`, carrying its best result that passed the guard checks and the
numbers. A gauntlet loop that spends its budget is kicked back.

Fixes follow a stricter discipline. No cause is tested before the reproduction
exists. Causes are ranked and each makes a prediction. Three failed fixes send
the piece back to `research`, because the architecture is in question; a bug
that cannot be reproduced goes back to `clarify`. Each fix adds the cheapest
check that would have caught the fault.

## The frozen bar

With automatic review, the checks are the only judge, so the builder cannot
change them. When a piece passes the ready gate, the gate script records a hash
of its contract, and a contract changed during the build is a kickback.

The build gate compares the branch with `main` and refuses a diff that edits,
deletes or skips an acceptance check or an existing test. It also refuses an
added lint or type suppression, a lowered threshold, an updated snapshot, and
any change to the project check, the CI workflow, the hooks or the deny rules.
A piece that truly needs one of those changes is forced to `review:person`.

Before a piece moves to `in-review`, the gate needs fresh evidence: each command
run, its exit code, the commit it ran on, and for fix and build, the same check
failing before the change and passing after it. The builder's own statement
that it is done counts for nothing.

## Review

Every piece gets an automatic review. A fresh session reads only the contract
and the diff, never the builder's account of the work. It gives two verdicts:
whether the change meets the contract, and whether the code is sound. It sorts
each gap as missing, partial, contradicting the contract, or unrequested.
Missing and partial work goes back to the builder within its limits; a
contradiction that needs a decision is a kickback; unrequested work is taken
out, or forces `review:person`. Findings stay within correctness and the stated
requirements, review rounds are capped, and every ruling is logged.

The builder ends each attempt with one status, and each status has one route.

| Builder status | Route |
|---|---|
| Done | Checking: gates and automatic review |
| Done, with concerns | `review:person` |
| Needs context | Kickback |
| Blocked | Kickback |

`review:auto` is the default. The system asks whether the person wants to
review particular pieces, and warns when a piece would benefit from it. A
sensitive area, a goal that missed its target, a change to a check or the
project's guards, a builder's concerns, and the first deployment always force
`review:person`. A review the person owes waits on the shaping board.

## Kickback

A kickback returns a piece to the shaping sub-state the problem needs:
`clarify` for a decision, `research` for a fact, `spec` for a contract that
needs rewriting. The piece gains a Kickback section saying what happened, what
was tried and what decision is needed. Its branch is kept. It appears on the
shaping board, and the run carries on with the pieces that do not depend on it.

## Runs

Every build is a run. A run of one builds a single piece on its own branch and
opens a PR to `main`. A run of several builds each piece on its own branch,
integrates them into one integration branch, and opens one PR from that branch
to `main`.

A run starts when the person picks the pieces, or says all ready pieces. It asks
nothing. How many pieces build at once, the budget and the merge policy come
from project settings. No run starts while `main` is red; the kit files a bug
piece instead.

The run plans waves from the dependency and boundary fields. Pieces that depend
on each other, or that change the same area, build one after another, and the
parallel count drops to one when every piece shares an area.

Pieces join the integration branch one at a time. Each is brought up to date
with the branch, the full checks run on the combined result, and only then is
the piece integrated. On the automatic path an agent never resolves a merge
conflict by judgement: the later piece is rebuilt on the new head, or kicked
back. If the integration branch goes red, the run finds the piece that broke it
by bisecting and kicks back that piece alone.

The run record holds a status for each piece and for the run. These live in the
record, not in labels, and the gate script writes them in the same step as the
labels.

| Piece status in a run | Issue state at the same time |
|---|---|
| queued | `state:ready` |
| building | `state:building` |
| checking | `state:building` |
| integrated | `state:in-review` |
| kicked back | `state:shaping` |
| withdrawn, because a piece it needs was kicked back | `state:ready` |

| Run status | Meaning |
|---|---|
| planned | Pieces chosen, nothing started |
| running | Pieces are building |
| paused | Stopped by the person or by a limit; it can continue |
| in preview | Every piece is finished and the integration branch has a preview |
| merged | The run's PR merged to `main` and is live |
| abandoned | Stopped for good; the branches are kept |

A run has a budget ceiling as well as each piece's budget, and a cap on CI
rounds. Reaching either, or a run of refused commands, pauses the run and
tells the person.

## Merging and going live

A merge to `main` goes live. A run's PR merges automatically when every piece is
`review:auto`, every gate is green, no sensitive area is touched, a smoke test
of the acceptance paths passes on the run's preview, and the project has earned
automatic merge. Otherwise the person merges after looking at the preview, and
any piece marked `review:person` can be opened on its own preview or checkout.

Automatic merge is earned. Each project starts with the person merging. After a
number of clean runs, `/maintain` offers to switch to automatic merge, and the
rules above then apply.

Automatic merge needs a `main` that GitHub protects, which means a public
repository or a paid plan. On a free private repository GitHub offers no branch
protection, rulesets or automatic merge, so the kit relies on its own guards and
the person merges. Setup says so in plain words.

After each merge a health check runs against production. If it fails, the
deployment rolls back to the previous build, and the kit files a bug piece.

## Deployment

`/ship` becomes `/deploy`, which sets up the pipeline: previews for branches,
production on merge, rollback, secrets and the health check. It runs the first
time and again when the project moves to new infrastructure. Founding chooses
the recipe, because the stack shapes the code, and `/deploy` builds the pipeline
from it. A preview address becomes a recipe field: some hosts give one per
branch and per commit, others one per pull request, and a local checkout on its
own port is the fallback.

## The safety boundary for runs

An unattended run holds private data, reads content nobody checked, and can
send data out, and an automatic merge puts the result live. The boundary keeps
those apart.

The native sandbox is on, with a network allowlist taken from the recipe; where
the platform has none, setup says so. A run's worktrees carry no production
secrets. A run can push only to its own branches. Text the person did not write,
such as other people's comments, web pages and package files, is data and never
an instruction. A new dependency is checked to exist, with its age and licence,
before it is added. A secret scan runs in the gate.

## Boards

Two boards show the state model to the person. Both come from one status file,
which a script writes from the issues and the run records.

The shaping board is the person's work surface. At the top it lists what needs
them now: questions to answer, prototypes to decide on, references and kickbacks
to look at, reviews owed, and run PRs waiting for a merge. Below that it shows
the shaping sub-states and the ready pieces as columns. From the board the
person answers, approves, orders the ready pieces, asks to review a piece, and
starts a run.

The loop board follows runs. It shows each run's status, start time, running
time, counts by piece status, preview address and budget used. Each piece shows
its status, mode, start and end, attempts, progress in its own terms (checks
passing for a build, the current and best value for a goal, the round and last
verdict for a gauntlet), a link to its session log and what it could not check.
An activity log carries the times. The board can pause, continue and stop a run.

The person hears about four things without looking: a piece needs their review,
a run paused, a piece was kicked back, and a run went live. The default view is
a local HTML page; on Claude it is also a live artifact. Other platforms follow.

## Learning and code health

Each piece records what it learned, limited to what the code and tests do not
show. When a run closes, each lesson becomes an `AGENTS.md` line, a masterplan
change or a new raw piece, and it lands through the run's PR. `/maintain` sorts
the lessons it finds: keep, update, merge or delete.

The constraints in the masterplan become rules in the project check wherever a
tool can hold them, each with a failure message that says how to fix it.
Violations that already exist sit in a baseline that may only shrink. The reads
for drift, copied code and unused code run after a number of merged runs, and
what they find becomes `type:chore` pieces. Work found during a build becomes a
raw piece linked to the piece that found it. The record of current behaviour is
updated by each piece's change at the merge.

## Commands

| Command | Job |
|---|---|
| `/setup-ai-build-kit` | Founds a project or adopts one: records, constraints, settings, recipe, labels |
| `/shape` | Captures, triages and shapes, up to the ready gate |
| `/implement` | Starts a run on the chosen pieces, in their modes |
| `/deploy` | Sets up or moves the deployment pipeline |
| `/what-now` | Opens the shaping board and the loop board |
| `/maintain` | The health visit: updates, record upkeep, lessons, drift reads, the offer of automatic merge |

`/queue` becomes the plan shown when a run starts and on the loop board. `/sync`
becomes part of `/maintain`, because the merge now applies each piece's record
changes. `/fix` goes: a bug is shaped like any other piece, on the short route
when its reproduction is clear.

The background skills keep their jobs in new places. Change-triage does the
triage in `raw`. Clarify runs the interview in `clarify` and at founding.
Section-builder becomes the engine for the build and fix modes. Second-opinion
becomes the automatic reviewer and the gauntlet's critic. Screen-check becomes a
check a bar can name.

## What a machine enforces

| Rule | Held by |
|---|---|
| One state and one sub-label | The gate script, a hook, deny rules |
| The ready gate | The lint, plus the fresh session's verdict |
| The frozen bar | The gate script's diff check and the contract hash |
| Fresh evidence | The gate script, through a Stop hook that runs the real checks |
| Integration one piece at a time, bisect on red | The run scripts |
| No push to `main`, no force push | Deny rules, and GitHub protection where the plan allows it |
| Automatic merge conditions | The gate script and GitHub's automatic merge |
| Run limits | The run record and the gate script |
| The sandbox and allowlist | The coding agent's sandbox settings |

Judgement stays where a machine cannot reach: research, the fresh readiness
check, the automatic review and the gauntlet's critic. Each runs in a fresh
session and returns a fixed verdict the gate script can read. Every gate names
what it catches, so it can be removed once models no longer need it.

## Platforms

Claude Code comes first, with the gates as hooks. Codex gets the same scripts as
its own hooks and rules, graded expected to work until a recorded run. Other
coding agents get the core of shaping and one piece at a time.

## Moving from today

Founded projects move through `/maintain`. It maps the old labels to the new
ones (an idea becomes raw, a needs label becomes the matching sub-state, to
check becomes in-review, parked and blocked become raw or a blocked-by link),
moves the records to the new format, and asks only where a case is ambiguous.

The mechanisms built in the overnight batch are reused one at a time rather than
merged as a batch: the recovery helper that keeps failed work and checks a
baseline, fresh builder contexts, the rule for which browser a walk-through may
use, the force-push deny rules, the question box, and continuing in the same
turn. The parked state, the try-it opt-in and shaping inside a run do not carry
over.

The draft v0.20.0 release is not published. The next release is this model.

## 1.0

1.0 promises that the commands, the records and the way work is built will not
change underneath a person. That needs:

- this model complete, with all four modes, runs, kickback, `/deploy` and both
  boards;
- founded projects moved to it by `/maintain`;
- real runs recorded, one for each mode, and one `/deploy` for each recipe;
- the compact masterplan, since 1.0 fixes the project's record format.

## What stays

Shaping with the clarify interview, prototypes and research. The readiness check
in a fresh session. The risk notice and its acceptance, now given in shaping.
The rule that the person never has to read code. Recipes as the only place a
product is named. The kit's refusal to become a service. A person deciding what
reaches live, until a project has earned automatic merge.

## Traps this design avoids

Two sources of truth, which is why the gate script writes labels and the run
record together. Ceremony for its own sake, which is why sub-states can be
skipped and contracts have a length limit. A permanent judge, which is why every
gate names what it catches. Agents organised into a hierarchy, where runs and
gates are enough. A number to game, such as coverage. Review requests so
frequent that the person stops reading them. And an agent resolving a merge
conflict by judgement on the automatic path.

## Settled when built

These numbers are left to the pieces that build them, each with a default to
test: the attempt limit (three today), the CI round cap, the run and piece
budgets, the number of clean runs before automatic merge is offered, the number
of merged runs between drift reads, the length limit for each type's contract,
and the time with no progress after which a builder counts as stuck.
