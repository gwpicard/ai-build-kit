---
name: repair
description: Reproduce a fault, then fix one cause at a time, with the risk notice after three failed attempts. Used by shape to reproduce a fault and by implement to build the repair.
user-invocable: false
---

# Repair

A repair brings the tool back to doing what it already should. A bug is a
piece like any other. `/shape` reproduces it and writes the failing case into
the piece, by `references/reproduce.md`, and `/implement` builds the repair by
`references/fixing.md`. The discipline is the order:
never change code before the problem repeats reliably and the cause is
understood and explained.

Load the one the step needs:

- `references/reproduce.md`: the four checks before shaping, then reproducing
  and minimising the fault and writing the piece.
- `references/fixing.md`: building the repair, one cause at a time, the
  cleanup, and the escalation after three failed attempts, with the notice it
  owes.
