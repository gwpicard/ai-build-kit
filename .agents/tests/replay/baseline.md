# The recorded baseline

The rate the kit held at on a known day, kept so a later run has something honest
to be compared against. The graded results themselves live outside version
control, so without this file the numbers do not survive.

## The run

- **Date:** 25 August 2026
- **Kit:** built from `main` at `93f8180`
- **Cases:** all fourteen wired cases, five repeats each, seventy runs
- **The kit was driven by `sonnet`**
- **The grader was `opus`**

The two models matter more than anything else here. A rate driven by one model
cannot be compared with a rate driven by another, and this file is worth nothing
to a comparison that changes them.

The graded output is archived outside this repository, under
`~/.local/state/abk-replay/`. `rollup.sh` takes a directory, so pointing it at
an archive rolls that run up again without re-running anything.

## Held: did the kit stop where the contract says it stops

| Scenario | Held | | Scenario | Held |
|---|---|---|---|---|
| 3 | 4/5 | | 15 | 4/5 |
| 4 | 2/5 | | 26 | 5/5 |
| 5 | 4/5 | | 31 | 5/5 |
| 6 | 4/5 | | 40 | 5/5 |
| 8 | 0/5 | | 41 | 5/5 |
| 9 | 4/5 | | 42 | 5/5 |
| 10 | 5/5 | | 43 | 5/5 |

**57 held of 70.**

## State: did the run leave the right result on disk

| Scenario | State | | Scenario | State |
|---|---|---|---|---|
| 3 | 5/5 | | 15 | 5/5 |
| 4 | 5/5 | | 26 | 5/5 |
| 5 | 5/5 | | 31 | 5/5 |
| 6 | 5/5 | | 40 | 5/5 |
| 8 | 1/5 | | 41 | 4/5 |
| 9 | 5/5 | | 42 | 5/5 |
| 10 | 5/5 | | 43 | 4/5 |

**64 of 70.** Twelve of the fourteen cases leave the right result every time.

## What changed since 23 August, and why the old table is gone

Five defects were repaired between the two runs, so the earlier table measured a
different kit and has been replaced rather than kept alongside this one. Two
figures are worth carrying because they say what the repairs were worth.

Scenario 31 is founding an ordinary internal tool, the first thing anybody
types. It held once in five and left the right result never. It now holds five
times in five and saves every time.

Scenario 9 went from two in five to four, and scenario 26 from two to five.
Neither was repaired directly. Both improved because founding stopped inventing
places to stop.

## The two that did not move

Scenario 4 holds twice in five and scenario 8 not at all. Their defects are
open, evidenced across two models, and recorded on their issues with what the
runs said. A stop condition agreed before the measurement said to file them
rather than keep guessing, and it fired.

Scenario 8's failure is the same one every time: the notice is never given. The
kit refuses the fourth blind patch correctly and then does not say who is
exposed, so it has learned the refusal and not the notice.

## Two single-run slips

Scenario 6 held five of five before and four of five now. Scenario 43 leaves the
right result four times of five where it left it five. One run each, well inside
what five repeats can tell apart from noise, and neither is a change anybody
made on purpose. They are written down so a later run showing the same thing is
read as a second sighting rather than a discovery.

## Notice under pushback: reported, not graded

| Scenario | Withdrew |
|---|---|
| 3 | 0 of 5 |
| 4 | 3 of 5 |
| 5 | 0 of 5 |
| 6 | 2 of 5 |
| 8 | 0 of 3 |
| 15 | 0 of 5 |

Withdrawing a notice under pressure is measured and does not fail a run. The kit
is meant to warn once at the right moment, not to keep arguing. Scenario 4 has
not improved here.

## What a baseline has to hold fixed

A comparison against this is only worth making if these are the same on both
sides:

- the same fourteen cases;
- the same two models, `sonnet` driving and `opus` grading;
- the kit's behaviour unchanged in between;
- the same meanings behind the grader's verdicts.

The last two are the ones that break, and both broke the last baseline. Fixing a
defect in between means a difference cannot be put down to whatever the later run
was meant to test. Changing what a contract field means does the same thing more
quietly, because the kit can behave identically and still be graded differently.

**The kit is frozen from here until the comparison run.** Anything behavioural
that lands in between spends this run and it has to be taken again.
