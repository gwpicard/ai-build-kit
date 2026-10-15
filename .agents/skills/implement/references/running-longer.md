# Running longer

Load this when the person asks to build several pieces in one sitting.
Everything here is off unless `Runs on its own:` in `masterplan.md` records
the person's words and date. Explore privately never uses these options.

## Queue

With `queue` recorded, after each merge take the next ready, unblocked,
unassigned piece from `sh .agents/tools/plan-refresh.sh --next`. Build no more
than five pieces in one sitting. Each starts from the newest `main` and gets
its own pull request. Without `merge`, stop when an open pull request blocks
the next piece and name the piece it waits for.

## Parallel builds

With `parallel N` recorded, use one worktree and branch per piece. The default
is two builders; never start more than three. Before starting them, run
`quality-checks/scripts/quality.py overlap --pieces` with the
piece numbers. A shared file, table, migration, sensitive area or project
setting stops the pair. Each pull request still goes through the merge script.
Before a later merge, bring in the newest `main` and run the checks again.

## Short loop

With `loop` recorded, run `scripts/attempt.sh <piece>`
before each build or repair attempt. It counts three attempts for the piece,
including a repair. The fourth call stops and labels the piece `blocked`. A
`Test fix:` commit ends the loop. Stop earlier on a failing test or project
check, or when a finding has no failing test to prove it. A repair uses the
same three attempts, with the person present. Never loop unattended on a
repair or in an unaccepted sensitive area. An accepted area may use the loop,
but automatic merge still holds it.

## Merge on its own

With `merge` recorded, use
`merge/scripts/merge.py --auto` only when the checks and review
record pass, and the change touches no sensitive area, migration, setting,
live requirement or `Done when` line ending `(try it)`. Repairs wait for a
named yes. Every other gate still holds. The script reads the setting from
`main`, requires three earlier named-yes merges, and refuses a branch behind
`main`. A pending check waits up to 15 minutes. A red, missing or still-pending
check holds the merge.

After an automatic merge, say which piece merged. If a check on `main` or the
live check fails, pause automatic merging and tell the person what failed.
Keep it paused until the person turns it on again. A person can turn any
option off in their own words.
