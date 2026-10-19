# The trim

Before hand-over, remove additions the behaviour does not need, such as an
unused export or a wrapper with one caller. Run once after checks,
repairs included.

## Run the script

Commit the piece, then run `python3` with `scripts/quality.py trim --base
<start commit>`. Exit 0: say nothing. Exit 1: act on findings. Exit 2: each
unavailable check appears as `not-checked`; act on findings and read named
code only as a fallback. Record the fallback in internal evidence.

Unused imports and unused local names are the linter's, so the script leaves
them out.

On the first missing engine, ask once whether the kit may fetch tools per
build without adding them to the project. Record `Quality engines: fetch` or
`Quality engines: local only` in AGENTS.md. With fetch, rerun using `--fetch`.

## Act on each line

- `remove`: take out the named code, file or dependency. Leave it when it is
  something the piece exists to provide, such as a page, route or command a
  person uses, or a function other projects call.
- `fold`: put the wrapper's body in the one place named at the end of the
  line, then remove the wrapper.
- `report`: change nothing, and list it on the piece.

Make each edit separately. Rerun the reach-check tests, type check and linter;
if one fails, undo the edit and record the wrong call. Never change a test.

The script misses options every caller sets the same way and interfaces with
one implementation. Find these in changed code: fold the first, report the
second.

Trim only removes or folds. Renames, splits, reordering, restyling and added
code are reports.

After edits, run the script once more, apply nothing new and list its findings
on the piece. Run the whole suite, then save with
this skill's `scripts/trim-commit.sh`. It commits the trim on its own, under a
subject that starts `Trim:`, and refuses when a test changed. When it refuses,
undo the edit that touched the test and run it again. The project check fails
any `Trim:` commit that changed a test, once the project has the trim step.
Founding adds it, and `/maintain` offers it to a project founded before it.

## What the person hears

When the trim changed nothing and has nothing to report, say nothing.

Otherwise, at hand-over, one line: "I took out <count> things this change did
not need. They are listed on the piece." Use "one thing" for a single
removal. When there are reports too, add "<count> more could be simpler, and
are listed there too." With reports only, say "<count> things in this change
could be simpler. They are listed on the piece."

On the piece, list each item in plain words: what was taken out or folded and
why nothing needed it, each wrong call, and each report. Name an `over-limit`
function as harder to follow than the usual limit. Never show a score or an
engine's name. A person who wants something back undoes the trim commit, and
the piece they confirmed is untouched.
