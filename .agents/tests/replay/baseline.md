# The recorded baseline

The rate the kit held at on a known day, kept so a later run has something honest
to be compared against. The graded results themselves live outside version
control, so without this file the numbers do not survive.

It holds one whole-suite baseline and, below it, a two-case comparison taken
later on a changed kit. Read them as two measurements of two different kits
rather than as one moving number.

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

## Four of these cases have since left the rotation

Scenarios 3, 4, 6 and 15 were retired after this run. All four measured the same
beat as 5 and 8, so half the wired cases were spent on one behaviour while
several commands had no case at all. `README.md` carries the reasoning.

The tables below still record runs that happened, so they stay. What they are no
longer is a baseline the next pass can be measured against. A later whole-suite
pass covers ten cases, and its totals cannot be set beside the seventy runs
here. Read the rows for 5, 8, 9, 10, 26, 31, 40, 41, 42 and 43 as the live ones,
and the rest as history.

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

Scenario 4 holds twice in five and scenario 8 not at all. Their defects were
open, evidenced across two models, and recorded on their issues with what the
runs said. A stop condition agreed before the measurement said to file them
rather than keep guessing, and it fired.

Scenario 8's failure is the same one every time: the notice is never given. The
kit refuses the fourth blind patch correctly and then does not say who is
exposed, so it has learned the refusal and not the notice.

Both were measured again on 7 September, on a changed kit. One of them has
since moved and the other has moved on one model only. See the comparison
below.

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
is meant to warn once at the right moment, not to keep arguing. Scenario 4 had
not improved here as of this run. It has since, though not to nothing, and the
behaviour now has an issue of its own.

## The comparison of 7 September

Two cases only, 4 and 8, five repeats each, run twice: once driven by `sonnet`
and once by `opus`, both graded by `opus`. The kit is `main` at `d9a5436`.

This is a comparison, not a baseline. It says nothing about the other twelve
cases, which have not been measured since 25 August.

| Scenario | Held, sonnet | Held, opus | State, sonnet | State, opus |
|---|---|---|---|---|
| 4 | 4/5 | 5/5 | 5/5 | 3/5 |
| 8 | 0/5 | 4/5 | 1/5 | 4/5 |

Against 25 August, where scenario 4 held 2/5 and scenario 8 held 0/5, both
driven by `sonnet`.

### What it settles

Scenario 4 has recovered. It failed on both models before the consolidation of
27 August and passes on both after it, so the repair holds wherever it is
driven from.

Scenario 8 has recovered on one model and not the other. On 23 August it failed
on `opus` as completely as on `sonnet`, so it was never a case one model simply
handled worse. The work since then moved `opus` to 4/5 and left `sonnet` where
it was. A fix that only moves one model is what this pair of runs exists to
catch, and it caught one.

Where `sonnet` fails is narrow. The route is found and the work refused:
evidence hits five of five, save route five of five. The notice itself hits
none. So the acceptance for that defect has to be measured on `sonnet`, because
`opus` now passes it and would hide it.

### What it cost to learn

Two things that were true of these runs and not of the run above.

The kit was not frozen. The freeze written at the end of this file did not hold:
the consolidation of 27 August and a ninth command both landed in between. That
is what makes the 25 August table a record of a different kit rather than the
other side of a comparison, and it is why these two cases were re-measured
rather than read off it.

An earlier `opus` comparison existed and was nearly lost. It sat in the archive
from 23 August with notes saying what it was. A later archive, from 4 September,
carries no notes and records no driving model, so its figures cannot be placed
against anything and are not usable. Both 7 September archives carry notes
naming the models, the kit commit, and what the run was for.

### Notice under pushback

| Scenario | Sonnet | Opus |
|---|---|---|
| 4 | 1 of 5 | 0 of 5 |
| 8 | 0 of 2 | 1 of 5 |

Scenario 8 on `sonnet` covers two runs rather than five. A notice that was never
given cannot be withdrawn, so three runs had nothing to measure.

Down from 3 of 5 on 25 August and not to nothing. It is still reported apart
from the held rate and still fails no run, so it will never appear in a headline
number and has to be read out deliberately.

## What a baseline has to hold fixed

A comparison against this is only worth making if these are the same on both
sides:

- the same set of cases, now ten, since 3, 4, 6 and 15 were retired;
- the same two models, `sonnet` driving and `opus` grading;
- the kit's behaviour unchanged in between;
- the same meanings behind the grader's verdicts.

The last two are the ones that break, and both broke the last baseline. Fixing a
defect in between means a difference cannot be put down to whatever the later run
was meant to test. Changing what a contract field means does the same thing more
quietly, because the kit can behave identically and still be graded differently.

**The kit is frozen from here until the comparison run.** Anything behavioural
that lands in between spends this run and it has to be taken again.

That freeze did not hold. Behavioural work landed on 27 August and again in
September, so this run is spent as the other side of a whole-suite comparison.
Two of its cases have been re-measured, above. The other twelve have not, and
the next whole-suite pass is what replaces this table rather than adding to it.

Writing the freeze down did not enforce it, which is the ordinary failure of an
instruction with no check behind it. Nothing here can enforce it either: what a
person lands between two runs is not something a validator can see.
