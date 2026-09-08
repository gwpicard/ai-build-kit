---
name: queue
description: The whole list of ready work at once, for somebody taking on more than one piece. Trigger when someone asks what can be built in parallel, what order the rest comes in, or wants to see everything that is ready rather than the next thing. Reads the plan and reports two groups. Never builds, shapes, or changes anything. Type this command when you want it; it never starts on its own.
disable-model-invocation: true
---

# Queue

`/what-now` is for somebody who is lost, so it names one next step and at most
three things. This is for somebody who has decided to take several pieces on at
once and needs to see the whole set. Typing it is the person saying so.

## Read

Refresh the printout with `.agents/tools/plan-refresh.sh` and read
`plan.local.md`. That is the only source. If GitHub cannot be reached, work from
the printout as it stands and say when it was written, because an old list a
person can see beats no list at all.

The printout has already done the sorting. A piece under `To build` marked
`(ready)` is shaped and free to start. A piece under `Blocked` names the piece
holding it up. Nothing else needs working out, and a piece with an open blocker
is never under `To build`, so a ready piece cannot be waiting on another ready
piece.

Read the masterplan's build-path section too, for the `Accepted:` lines and any
subject the current path does not permit. A piece the path will not allow is not
ready work however the label reads.

## Say

Two groups, in this order.

**Build these together now.** Every ready piece. They have no dependency between
them, which is what makes them safe to take on at once. Say the count first, in
one line, then the pieces.

**These wait their turn.** The blocked pieces, one line each, saying which piece
releases it: "deposits cannot start until card payments is built". Where a chain
runs deeper than one, the order falls out of the chain itself, so put the piece
that unlocks the most first and let the rest follow it.

Piece names, never issue numbers. The person cannot follow a number, and the
printout carries the name of the blocking piece already.

Where a piece is waiting on a question rather than on another piece, say which of
the three it needs and leave it out of both groups. It is not ready and it is not
blocked by work; it is waiting on somebody. The same goes for a piece with a
`Waiting on you` step: name it as the person's own to do, and never ask for a
key, a password, or a token in a message.

A piece under `To build` carrying no marker at all has been sized but never
marked ready, so `/implement` will not take it either. Name it with those, and
say `/shape` is what marks it ready. This is the one case where a piece looks
buildable in the printout and is not, and it matters most when that piece is the
one holding another up, because otherwise the person is told to wait for
something they never see.

Where nothing is ready, say so plainly and say what would make something ready,
usually `/shape`. Where nothing is blocked, say nothing about it rather than
printing an empty group.

Say how many pieces a sitting can realistically hold, once, if the ready group is
long. Taking on eight at once is how the mess this command exists to prevent
starts. Do not rank them for the person and do not choose for them.

End by naming the command that acts on this, which is `/implement`. This command
only ever reports.

## Done when

The person can see everything ready to build, knows which of it can go at the
same time, knows what the rest is waiting on and why, and nothing has been
changed.
