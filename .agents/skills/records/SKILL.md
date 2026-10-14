---
name: records
description: Write and keep the project's records true. A piece and its labels, the printout, a piece's change to the masterplan and its checked mark, the coverage read, and the records a finished build updates. Used by every command.
user-invocable: false
---

# Records

The records are the pieces as GitHub issues, masterplan.md and CHANGELOG.md.
Load the reference the step needs:

- `references/pieces.md`: how a piece is written, its labels, the printout,
  and what to do when somebody acts on GitHub by hand.
- `references/masterplan-changes.md`: applying a piece's change to the
  masterplan, and the trued-against mark.
- `references/coverage-read.md`: comparing the masterplan's promises with the
  pieces.

## The scripts

Each decides by its exit code, and changes only what it names.

- `scripts/mark-ready.sh <number>` labels a piece `ready`. It refuses while
  `## Done when` is missing, or `## Decided` after a `needs-` label, and says
  which; write it, then run it again. It refreshes the printout.
- `scripts/piece-labels.sh start <number>` swaps `ready` for `building` and
  assigns the piece; `merged <number>` takes both off after the merge.
- `scripts/trued-mark.sh` says whether the masterplan's mark can be used: exit
  0 prints its commit, any other exit says why not.

## After a build

Update the piece, a dated changelog line written from its `So that` and `Done
when` in plain words, the masterplan through its recorded change, and AGENTS.md
only for a lasting convention. Where the tool now reaches something new outside
itself, update the connections picture and say what it reaches. A finished
build leaves nothing for /maintain to correct.

When naming what comes next, read it from a refreshed printout, by
`references/pieces.md`'s rule, and never name the piece just built.
