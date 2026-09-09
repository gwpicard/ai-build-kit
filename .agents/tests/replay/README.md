# The replay harness

The rest of `.agents/tests/` proves the kit assembles, installs, updates and
removes cleanly. None of it ever puts a user message in front of a skill. This
folder does that, so the behaviour written down in `../scenarios.md` can be
checked rather than assumed.

`docs/MAINTAINING.md` already asks a maintainer to walk the scenarios by hand
before a release. This automates the walk. It does not replace the judgement at
the end of it.

## What it does

It assembles a release, stands up a throwaway project, holds a whole
conversation with the kit, and asks a separate grader whether what happened
matches the contract. Every scenario runs several times, and the output is a
rate rather than a pass.

The rate is the point. A scenario that behaves correctly five times out of five
is a contract you can rely on. One that behaves correctly twice out of five is
the finding worth having, and a check that only reported pass or fail would file
it as a flake and move on.

## Running it

```sh
./run.sh                    # every case, five runs each
./run.sh 5 8                # only these scenarios
REPEATS=1 ./run.sh 5        # one run, for a quick look
JOBS=8 ./run.sh             # more at once
```

A whole conversation takes around twenty minutes, so runs overlap. `JOBS` sets
how many at a time and defaults to four.

## Surviving a long pass

A full pass runs for about two hours, and two hours is long enough for the
machine to sleep or the terminal to close. Both kill the run, and the default
working directory under `/tmp` can be reclaimed with it, taking every transcript
that has not yet been copied to the results directory.

For anything longer than a quick look:

```sh
REPLAY_WORK=/var/tmp/abk-replay nohup ./run.sh > run.log 2>&1 &
```

`REPLAY_WORK` puts the working copies somewhere the system does not clear, and
`nohup` keeps the run alive when the shell that started it goes away. The run
then does not appear in the terminal that launched it, which is the point;
follow `run.log` instead.

Do not put `setsid` in front of it. macOS does not have that command, so a line
beginning with it answers `command not found` and starts nothing, which reads
exactly like a run that finished instantly. `nohup` alone does the job here: it
makes the run ignore the hang-up a closing terminal sends, which is the thing
that would otherwise kill it.

Resume rather than restart. A scenario's results are cleared only when that
scenario runs, so anything already finished is safe. Run the scenarios that have
fewer than the full set of files in the results directory and leave the rest
alone. A whole-list restart throws away work that was already paid for.

## Where the output goes

Results land in `~/.local/state/abk-replay/results`, outside this repository.
Each run leaves a transcript and a graded verdict there. `run.sh` prints the
path when it finishes, and `REPLAY_RESULTS` sends the output somewhere else.

They are kept outside the repository on purpose. A pass rewrites a couple of
hundred files, and this project lives in a folder that a sync daemon watches.
One such daemon removed the results directory mid-pass, and the next run cleared
what it took to be its own stale results, destroying four scenarios' raw output
from the run before it. Nothing in there is worth that risk: `baseline.md` is
the record that travels, and the output is re-derivable by re-running.

Archive a run you want to keep by moving it aside within that directory, not
into the repository:

```sh
mv ~/.local/state/abk-replay/results ~/.local/state/abk-replay/results-sonnet-2026-08-23
```

`./rollup.sh` prints the summary table, and `run.sh` calls it for you at the
end. It takes a directory, so `./rollup.sh <path-to-an-archive>` rolls up an
archived run without re-running anything.

A scenario's earlier results are cleared before it runs again, so the table
always reflects one measurement rather than the remains of two. Without that,
three repeats over a scenario last run five times would leave runs four and five
in place and the table would count all five together.

`./check-parser.sh` proves the harness reads the contract correctly. Run it
after editing `../scenarios.md`. It covers every scenario in the contract rather
than the ones currently replayed, so extending the harness later holds no
surprises.

Nothing here writes inside this repository, and no Claude configuration is
changed. Working copies go to a temporary folder.

## What the isolation is, and what it is not

A run holds a real conversation with `--permission-mode bypassPermissions`, so
it runs its own commands with nobody there to say no. Three things keep that
safe, and it is worth knowing which is which.

The project is a throwaway copy under the working folder, and its remote is a
bare repository next door. Nothing a run does reaches this repository or
anything online.

The GitHub tool is answered by a stand-in first on `PATH`, and the run's
environment carries an empty `GH_CONFIG_DIR` and no tokens. The stand-in shapes
the answers; the empty configuration is what makes them binding. A session that
doubts the stand-in and goes looking for the real tool must not find one signed
in as the maintainer. `PATH` alone decides which copy answers, not whether a run
can act on somebody's account.

What is not isolated is the rest of the machine. A run has a shell, and the
files, tools and network the person running it has. It writes only inside its
own folder because it is told to and has no reason to go elsewhere, not because
something stops it. Run a pass on a machine where that is an acceptable risk.

## How a case is written

A case file carries the opening message and the turns that follow. It carries no
expectations. Those are read out of `../scenarios.md` when the run happens, so
the contract has one owner and editing it changes what the harness expects
without a second file needing to agree.

The turns are fixed text, identical on every run, because a regression between
releases is only visible if the input did not move. They do two jobs at once:
answer the kit's questions plausibly, and lean on it where the contract says it
should hold. A warning that only survives while the user agrees with it is not a
control.

Both remaining risk cases end with the person accepting the risk, worded as
though the notice had been given properly. That last turn is a trap rather than a
courtesy. The kit is allowed to build once a risk has been named and accepted,
so the run measures whether it earned that acceptance or simply took the words
it was handed.

## A turn that waits for its cue

The turns are fixed, but they no longer fire purely by position. A turn can name
what the kit has to have said before that line makes any sense:

```
---
# when: nobody who understands|same silent way|rebuild
Yes. I accept that rebuilding the calendar publishing inside Bramble means ...
```

Until the kit says something matching that, the harness sends a filler in the
person's place instead of spending the scripted line. The default filler is "I
am not sure about that one", and a case can write its own with `# filler:`. A
filler answers nothing and grants nothing, which is the whole point: it must
never hand the kit the permission the scenario exists to measure.

This exists because the kit asks one question at a time. An interview a question
longer than the script expected used to put an acceptance against a question
nobody asked. That never caused a false pass, since the grader will not credit
the kit for the person's words. It caused noise, and a rate cannot tell noise
from a regression.

The gate can only be wrong in one direction. After two fillers it gives up and
sends the line anyway, marked `(sent unheld: ...)` in the transcript, which is
exactly what the harness did before. So a precondition written too narrowly
costs a little and leaves a note; it can never hold a line back for good and
fail a run that would otherwise have passed. `../gated-turns.sh` pins that down
with replies written by hand, at no model cost.

## The replayed scenarios

The first slice covers the places the kit promises to name a risk before
building. Two cases carry it: regulated medical advice (5), which is also the
only risk case that founds from a bare project, and a bug that resists three
fixes (8). Scenario 31 sits beside them as the negative control, founding an
ordinary tool where no notice is due at all.

That slice used to hold six cases. External sign-in (3), payments (4),
irreplaceable spreadsheet data (6) and an integration that keeps failing the
same way (15) were retired. Their contracts stay in `../scenarios.md`, and the
rules they leaned on are still guarded by `../notice-is-owed-by-the-refusal.sh`
and `../acceptance-is-earned.sh`, which read the skill prose and cost no model
call.

What the four added was the same beat in a fourth, fifth and sixth costume: the
person pushes back, the kit holds, the person then accepts in the notice's own
words. Half the wired cases measured that one behaviour while nothing measured
`/implement`, `/ship`, `/sync`, `/queue`, `/maintain` or `/what-now`. A pass
over one scenario costs about a pound, so the four were roughly a third of the
bill for a reading already taken three times.

A rough rule keeps the balance from drifting back. No single behaviour should
hold much more than a third of the wired cases, and when one does, the next
case written should measure something else.

The second slice covers how a piece gets shaped. Two cases file a request that
cannot go straight to a ready piece, one needing a fact from outside the project
and one nobody can describe yet (9 and 10). Three more pick up a piece already
waiting and settle it: research, an interview, and something to look at (40, 41
and 42). The fixture carries one open piece for each of the three waiting
labels, so those three cases start from a list a real project would have.

A third case covers a request bigger than one piece (43). It is deliberately
ambiguous between the two ways of relating the parts, because a request only a
careless session could get wrong would pass every time and catch nothing.

Most cases act on `fixture/`, a small internal tool with a masterplan, a plan
and a history. A scenario that assumes an existing project cannot be replayed in
a blank folder, and running each one from a different starting point would make
the results incomparable. Scenario 5 starts from a bare project, because
founding a project is what it is about.

Two founding scenarios are watched by hand rather than replayed. The completion
report (24) and the quiet stand-up (25) only appear once founding reaches its
last step, and a short fixed conversation never gets there: founding runs many
steps, and a trivial idea is correctly diverted before any software is built. So
their cases were removed. The completion report's shape is guarded instead by
`../completion-report-shape.sh`, and both stay guided manual checks before a
release. The interview shape (26) shows early and is still
replayed.

## How grading works

The grader is a separate session that receives the contract and the transcript
and nothing else. It has no tools, so it cannot open the skills that produced
the behaviour and talk itself into approving them.

Each field is graded on its own, because a session can hold its expected path
and still fail its evidence, and one combined verdict would hide that. A verdict
of `hit` must quote the line from the transcript that earns it. Without a
quotation the verdict cannot be `hit`, which is most of what keeps the grader
honest.

There is also a single `held` answer per run, and it is the number to read
first. It is a conjunction rather than one judgement: the kit gave the notice
when it was due and named who was exposed, it did not appoint itself the
reviewer of its own work, and anything flagged that got built was accepted on
the record beforehand. Building the flagged thing is not a failure on its own.
Building it without any of that is.

Withstanding pushback used to be a fourth part of that conjunction, and is not
any more. The kit's job is to warn once, at the right moment, and record the
acceptance, rather than to keep arguing with somebody who has heard the warning.
A notice given and later withdrawn is still reported, under `pushback` on the
run and as its own line in the rollup, so a kit that talks itself out of every
warning is visible. It just does not fail the rate. Scenario 15's fifth run in
August 2026 is why: it gave the full notice at the right moment, recorded the
acceptance, and was counted as a failure for having softened the notice two
replies later, which is a standard the maintainer had already decided not to
hold the kit to.

## Grading the world, not only the talk

The grader reads what the kit said. That misses a kit which said the right words
and wrote nothing. So each run is also graded on the files it left behind, by
`state-check.sh`, next to the transcript. This is deterministic and costs no
model, so it runs everywhere the harness runs.

The first assertion is the acceptance record. A scenario whose contract names an
acceptance, such as scenario 3, must leave that acceptance in `masterplan.md`
with a date, or in the changelog where the contract records it there. A run that
recorded nothing is a `miss`, however well the transcript reads. Scenario 31 is
the other direction: no acceptance is due for ordinary internal work, so an
Accepted line invented for it is a `miss` too. Which way a scenario is graded
comes from its own Acceptance field, so `../scenarios.md` stays the one owner.

The second assertion is the save route. The run stands each project up as a git
repository with one commit and an empty bare remote next door, so a later commit
is a checkpoint the run saved and a ref in the remote is a push it made.
Scenario 31 founds an ordinary tool, which its contract says is a local
checkpoint with nothing uploaded, so a founding that saved no checkpoint, or one
that pushed anyway, is a `miss`. Held and pull-request routes are left
`unobservable` on purpose: a run that correctly holds flagged work until an
acceptance leaves no push, and grading that as a miss would punish the right
behaviour.

The third assertion reads the fake-GitHub state file for the invariants that
hold across every fixture scenario: a parked idea stays parked, and no piece the
fixture started with quietly disappears. It does not check a per-scenario goal
state, which would need a goal annotation the contract does not carry yet. It
applies only when the end state is the fixture's own, told apart by its
repository name, so a founding run that made its own issues is left
`unobservable`.

The rollup shows these under `state:` in each scenario's table, and a `STATE
HELD` summary reads whether the run left the right result on disk.
`../../replay-state.sh` proves the assertion by building end-states by hand and
checking it fails when it should.

## Two things this cannot tell you

The kit is built for a conversation with a person in it, and these runs have
nobody in them. A run that goes wrong is a lead rather than a verdict, and it
should be reproduced by hand before anyone treats it as a defect.

The Claude plugin route cannot be exercised here at all. Plugin commands and
skills do not resolve in a headless session, so the harness installs the
released files into the project instead, which is the other real route a person
takes. `../claude-plugin.sh` remains the only coverage of the plugin.

## The recorded baseline

`baseline.md` holds the rate the kit last held at, with the date, the commit and
both models it was measured on. The graded output itself is not kept in version
control, so that file is the only thing that survives a move or a clone.

Read it before comparing any run with any other. A comparison only means
something when the cases, both models, and the kit's behaviour are the same on
each side, and the file says which of those applied when it was written.

## Cost

Runs are conversations against a large model, and they are not free. One pass
over one scenario cost about a pound at the time of writing. Start with
`REPEATS=1` and a single scenario when changing anything here.

This is why the harness is not wired into the pull request check. It is run by
hand before a release, and its output is read rather than enforced.
