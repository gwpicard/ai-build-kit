# The trim

Before the person tries a piece, take out what the change added that its
behaviour does not need: an export nothing calls, a wrapper only one place
uses. Each is free to remove now and harder once later work leans on it.

The trim runs once, on Build and run it and Build with care, a repair
included, after the tests, the type check and the linter pass. It does not run
on Explore privately, where the work is thrown away.

## Run the script

1. Commit the piece as built.
2. From the project, run `python3` with this skill's `scripts/quality.py`,
   passing `trim --base <commit the piece started from>`.

Exit 0 means there is nothing to do: say nothing. Exit 1 means it printed
findings: act on them below. Exit 2 means no engine could run: read the
changed code directly for the same things, and say in the internal evidence
that this was the fallback.

A `not-checked` line names a check that had no engine. The first time that
happens in a project, ask the person once whether the kit may fetch the
missing tools for each build without adding them to the project. Write the
answer into AGENTS.md's stack section as `Quality engines: fetch` or
`Quality engines: local only`. With fetch, run the script again with
`--fetch`.

## Act on each line

- `remove`: take out the named code, file or dependency. Leave it when it is
  something the piece exists to provide, such as a page, route or command a
  person uses, or a function other projects call.
- `fold`: put the wrapper's body in the one place named at the end of the
  line, then remove the wrapper.
- `report`: change nothing, and list it on the piece.

Make each edit on its own. Then run the tests the reach check names, the type
check and the linter. When any of them fails, undo that edit and record it on
the piece as a wrong call. Never change a test to keep an edit.

The script does not look for an option every caller sets to the same value,
or an interface with one implementation. Look for both in the changed code.
Fold the first; report the second.

The trim only removes and folds. It never renames, splits, reorders, restyles
or adds code. Any other improvement, however clear, is a report.

When the edits are done, run the script once more, apply nothing it finds,
and list anything new on the piece. Run the whole test suite. Then save with
this skill's `scripts/trim-commit.sh`. It commits the trim on its own, under a
subject that starts `Trim:`, and refuses when a test changed. When it refuses,
undo the edit that touched the test and run it again. The project check fails
any `Trim:` commit that changed a test.

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
