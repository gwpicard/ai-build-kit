# Mutation audit

Reading the suite tells you what it means to catch. Only breaking something
tells you what it does catch. This records what happened when twenty-one
promises were broken one at a time, on 11 August 2026, against `bb81109`.

Reproduce it with `.agents/tests/mutate.sh`. The script clones the repository
for each mutation, applies one reversible edit, runs the checks, and records
which ones noticed. It refuses to report a mutation that left the tree
unchanged, because a mutation matching nothing looks exactly like a hole in the
suite.

## What came out of it

Twenty-one mutations. Twenty were caught. One was not.

Nothing here is dead weight. Every check file is the only thing standing between
the kit and at least one of these faults, so the answer to "can the suite be
made smaller" is no, not by deleting a file. What it can be is sharper in two
specific places.

## The hole

The session hook is supposed to stay silent inside the kit's own source, so a
maintainer is never told their own repository is overdue a check-up. Break that
guard and nothing notices.

The guard itself works. The check that claims to prove it cannot fail. Its
fixture folder in `session-start.sh` has no `masterplan.md` and no maintenance
record, so the hook says nothing because there is nothing to say, not because
the guard stopped it. Proved by hand:

| Folder that looks like the kit's source, with a masterplan | Hook |
|---|---|
| guard intact | silent |
| guard broken | speaks: "The project is 2414 days old and has had no check-up yet." |

`session-start.sh` passed either way. Giving that fixture a masterplan and a
stale maintenance record was the whole fix, and it is done. The check now also
takes the source markers back off and insists the same folder speaks, so the
silence above has to come from the guard rather than from an empty project.

Re-running `mutate.sh hook-speaks-in-source` against the fix confirms
`session-start.sh` catches it. Note that the audit clones committed history, so
a fix has to be committed before it can be measured; the first attempt at
confirming this appeared to fail for that reason alone.

## The weak spot

Three checks count skills and expect eleven:
`release-builder.sh:120`, `release-builder.sh:126`, and
`starter-rehearsal.sh:72`. Removing a skill leaves ten and all three fail, as
they should. Replacing one skill with a copy of another leaves eleven of the
wrong set, and all three pass.

Only `agent-plugin.sh:152-156` catches that, because it compares the sorted
names rather than counting them. The counting checks are not useless, since they
catch a skill going missing, but they are strictly weaker than a name
comparison, and a name comparison catches both faults. Replace them rather than
remove them.

## What each check is alone in catching

Excluding `validate-kit.sh`, which runs all seven of the others itself at lines
870 to 946 and is therefore an aggregate rather than an independent opinion.

| Check | The only thing catching |
|---|---|
| `agent-plugin.sh` | wrong skill set, stale adapters, a background skill claiming a person starts it, a manifest field the standard omits |
| `release-builder.sh` | the writing skill leaking, the private repository named publicly, a file dropped from the allowlist alone |
| `kit-updater.sh` | a local customisation discarded, a version advanced by a failed update |
| `release-publication.sh` | a version that is not a stable release, a used version republished with different contents |
| `session-start.sh` | the hook speaking before a visit is due |
| `validate-kit.sh` own checks | a broken local link, retired vocabulary |
| `starter-rehearsal.sh` | nothing on its own, though it catches four faults alongside others |

## Two results that look stronger than they are

Dropping `docs/SOURCES.md` from the allowlist was caught by all five checks, but
for one reason rather than five: `update-manifest.txt` still names the file, and
the builder refuses when the two disagree. Dropping a file named only in the
release allowlist is caught by `release-builder.sh` alone, and only because its
required-file list happens to name that file. A file in neither list would go
quietly.

`starter-rehearsal.sh` never caught anything by itself. It is not therefore
removable: it rehearses the shared-installer route, which nothing else does, and
the audit simply contains no mutation that only that route would reveal. That is
a gap in this audit rather than a verdict on the check.

## Corrections made while running it

Recorded because the same mistakes are easy to repeat.

Three mutations targeted wording that a recent change had rewritten, so they
edited nothing and reported three holes that did not exist. Every mutation now
asserts the text it expects is present before touching it, and the runner
refuses any mutation that leaves the tree unchanged.

One mutation created an untracked stray file and expected it to reach the
release. It did, because the runner stages changes so that new files reach the
builder's tracked-file list. Creating an untracked file does not break the
promise; the promise is that untracked files do not ship. The mutation now stops
the builder consulting Git at all, and every check catches it.

The first run was also derailed part way through by editing `mutate.sh` while it
was executing. A shell reads a script as it goes.

## The skill structure, 14 October 2026

Two mutations joined when the commands were thinned. One makes a command point
into another command's references instead of calling a background skill. The
other grows a command past its word budget. The validator caught both, through
`check-structure.py`, on the branch that turned that check from reporting to
failing.

A third joined after review: a background skill left with one caller and no
agent that loads it. The validator caught it too.

## Replay-owned behaviour, 16 October 2026

Three behaviour mutations pass every shell check because their outcomes depend
on what the agent does in a conversation. They now have named replay owners:

| Mutation | Replay case | Behaviour the case measures |
|---|---:|---|
| `build-nothing-mark` | 45 | A build moves the masterplan mark when its change is `nothing`. |
| `founding-starter-refusal` | 58 | Founding waits before writing replacement starter files after refusal. |
| `prelaunch-migration-route` | 59 | A pre-launch migration goes through `/setup-hosting` and waits for yes. |

`replay-contract-owners.sh` checks that each named case and its contract still
exist. `mutate.sh` reports these mutations as owned by their replay cases, not
as shell-check catches or holes. The replay harness was not run for this audit.

## The behaviour set and the harness, 18 October 2026

Twelve mutations joined with the behaviour set. Each breaks one thing the replay
harness relies on, and each is caught by a shell rehearsal that calls no model.

| Mutation | Caught by |
|---|---|
| `backbone-review-unbound-passes` | `replay-behaviour.sh` |
| `backbone-merge-before-yes-passes` | `replay-behaviour.sh` |
| `backbone-canary-ignored` | `replay-behaviour.sh` |
| `behaviour-extras-untouched-passes` | `replay-behaviour.sh` |
| `replay-backbone-not-merged` | `replay-behaviour.sh` |
| `behaviour-answer-ungated` | `replay-behaviour-cases.sh` |
| `replay-preflight-fault-unreported` | `replay-preflight.sh` |
| `replay-failed-preparation-silent` | `replay-preflight.sh` |
| `replay-nothing-graded-exits-zero` | `replay-preflight.sh` |
| `replay-old-kit-section-missing` | `replay-preflight.sh` |
| `replay-startup-read-unchecked` | `replay-preflight.sh` |
| `replay-plan-helper-not-installed` | `replay-project-helper.sh` |

What these prove is the measuring, not the kit. A disk check that cannot fail,
a scripted answer with no question to answer, or a run that dies without
leaving a result would each make a rate mean less than it says. The replay
harness itself was not run for this audit.
