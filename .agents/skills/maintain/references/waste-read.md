# Waste read

At the quarterly visit, on Build and run it and on Build with care, gather
three kinds of waste before proposing anything: code copied from one place to
another, code nothing uses, and dependencies nothing imports.

## Run the script

From the project, run `python3` with the `implement` skill's
`scripts/quality.py`, passing `waste --skip-offered`, and `--fetch` where
AGENTS.md's stack section says `Quality engines: fetch`. It runs the engines
over the whole project, drops any name found elsewhere in it, and leaves out
each finding an earlier visit offered.

- Exit 0: nothing to offer. Say nothing about it.
- Exit 1: each line is one finding: `copy`, `unused-export`, `unused-file`,
  `unused-code`, `unreachable-code` or `unused-dependency`, with its place.
- Exit 2: some part could not run, and a `not-checked` line names each one.
  Use any findings it printed. Then read the areas the quarterly spread count
  named for each part it names. That reading is the last resort, so say in
  the internal evidence that it was the fallback, and for which part.

Where a `not-checked` line names a missing engine and the person has not been
asked, ask once whether the kit may fetch the missing tools, as the trim does,
and record the answer in the same line of AGENTS.md.

## Turning findings into proposals

Open each finding at its line and confirm it is meant as part of this
project. A name reached by a framework convention the script cannot see, such
as a page file the framework loads by its place, is not waste. Drop it.

Findings join the other hot-spot inputs, under the cap of three proposals.
Rank a finding higher when it sits in an area the spread count or a repeated
bug already named. Say which kind it is, in plain words, with the place:

- "The same total calculation is written twice, in `src/pricing.js` at line 1
  and `src/report.js` at line 1. Keeping one would mean a fix lands once."
- "`discount` in `src/pricing.js` at line 13 is never used."
- "The project lists `left-pad` as something it needs, and nothing uses it."

Say how many more findings there are in one line, and offer to list them.
Remove nothing without a yes.

Record what the person was offered, and only that: pipe the line of each
finding you named to the same script, as `quality.py offered waste`, one
line each, exactly as printed. A later visit leaves those out. A finding you
did not name comes back at the next visit.

When a proposal names copied code, or the person asks whether duplication was
checked, say once: "This finds copied code. It does not find two pieces of
code that do the same job written differently."
