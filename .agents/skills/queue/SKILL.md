---
name: queue
description: The plan a run would follow, for somebody taking on more than one piece. Trigger when someone asks what can be built in parallel, what order the rest comes in, what a run would do, or wants to see everything that is ready rather than the next thing. Prints the order, the groups that can go together, what a run can do with each piece, what stacks on what, and the command that runs it. Never builds, shapes, or changes anything.
---

# Queue

`/what-now` is for somebody who is lost, so it names one next step and at most
three things. This is for somebody who has decided to take several pieces on at
once and needs to see the whole set. Typing it is the person saying so. It
shows what a run would do, and `/implement` does it.

## Read

Refresh the printout with `sh .agents/tools/plan-refresh.sh` and read
`plan.local.md`. That is the only source. Where the project has no copy of the
helper, the `setup-ai-build-kit` skill's `references/pieces.md` says what to
run instead; never sort the pieces by hand. If GitHub cannot be reached, work from
the printout as it stands and say when it was written, because an old list a
person can see beats no list at all.

The printout has already done the sorting. A piece under `To build` marked
`(ready)` is shaped and free to start. A piece under `Held up` names the piece
holding it up. `Go together` holds the pieces under `To build` in groups, and
two pieces in one group name no area in common on their `Touches:` lines.
Nothing else needs working out, and a piece with an open blocker is never under
`To build`, so a ready piece cannot be waiting on another ready piece.

Then read each piece in the plan with `gh issue view <number>`, for its
`## Readiness` section and any `Waiting on you` line, and the masterplan's
build-path section, for the sensitive areas and the `Accepted:` lines. Read the
project's `.ai-build-kit-maintenance` for a `check-myself|yes` line. Reading a
piece changes nothing on it.

## Say

Five parts, in this order: the order, the groups, what a run can do with each
piece, the stack, and the command. Piece names, never issue numbers, in every
part but the command, which needs the numbers. The person cannot follow a
number, and the printout carries the name of the blocking piece already.

**The order.** The plan is every piece under `To build` marked `(ready)`, and
every piece under `Held up` whose open blockers are all in the plan: the pieces
`/implement queue` would take. Say the count first, in one line, then the
pieces in the order a run builds them, each after every piece it depends on,
and by number where the blocked-by links leave a choice. The pieces under
`To build` are free of each other: they have no dependency between them, which
is what makes them safe to take on at once.

Among the pieces under `Held up`, one whose blocker is outside the plan waits
its turn. Give it one line after the order, saying which piece releases it: "deposits cannot
start until card payments is built". Where a chain runs deeper than one, the
order falls out of the chain itself, so put the piece that unlocks the most
first and let the rest follow it.

**The groups.** Read the `Go together` groups as the printout wrote them, and
never group the pieces yourself. Each group can be built in one run in any
order, because no two pieces in it change the same area. Pieces in different
groups do change one, so their pull requests merge one at a time. Say each
group in one line of piece names. Where a piece's line says its Touches is
unknown, say that its Touches line is missing, so it goes alone until `/shape`
writes one. A piece under `Held up` is in no group, since it is not free to
start.

**What a run can do with each.** One line for every piece in the plan, with the
first of these that holds:

- Needs you: it lies in a sensitive area the build-path section names, and no
  `Accepted:` line covers it. A run never takes it, and never accepts on the
  person's behalf. A piece with a `Waiting on you` step other than `try it`
  needs the person too: name the step as their own to do, and never ask for a
  key, a password, or a token in a message.
- Not ready: its `## Readiness` section says Not ready. A run leaves it, and
  `/shape` is where it goes back.
- Not yet checked: it has no `## Readiness` section, because it was shaped
  before the check existed. A run checks it before claiming it, and it goes
  back to shaping if the check finds a gap.
- Taken, then waits for your try: it carries a `Waiting on you: try it` line, or
  the project carries a `check-myself|yes` line. The piece is still taken by a
  run and stops at `to check` for the person's try, and it is never merged
  under pre-approval. A `Waiting on you: try it` line alone does not keep a
  piece out of the groups.
- A run can take it: none of the above holds, and its `## Readiness` section
  says Ready.

**The stack.** A piece that depends on another piece in the plan stacks on it:
a run builds it on that piece's branch, and its pull request merges after that
one. Say each in one line: "deposits stacks on card payments, and merges after
it". Where nothing stacks, say nothing about it.

**The command.** The last line is the exact command that runs the plan, and
nothing follows it. It is `/implement queue` when a run can take every piece
in the plan, counting a piece not yet checked and a piece that waits for the
person's try. Otherwise it is `/implement` followed by the numbers of the
pieces a run can take, in the order above, such as `/implement 4 7 9`.

Where a piece is waiting on a question rather than on another piece, say which
of the three it needs and leave it out of the plan. It is not ready and it is
not blocked by work; it is waiting on somebody.

A piece under `Building` or `To check` is in neither group, nor anywhere in the
plan. The first is
already claimed, and the second is built and waiting for the person to try it
or merge it. Say how many are under `To check`, in one line, when any are.

A piece that has been sized but never marked ready sits under `Idea`, not under
`To build`, so `/implement` will not take it either. Name it with those, and say
`/shape` is what marks it ready. It matters most when that piece is the one
holding another up. A held-up piece's blocker may sit under `Idea` or
`Shaping`, so name it there, because otherwise the person is told to wait for
something they never see.

Where nothing is ready, say so plainly, say what would make something ready,
usually `/shape`, and print no command. Where a run can take none of the pieces
in the plan, leave the command off too, and say what would change that. Where
nothing is blocked, say nothing about it rather than printing an empty group.

Do not rank the pieces beyond the order the links give, and do not choose for
the person. This command only ever reports: it never labels, claims or starts a
piece, and running the plan is the person's choice.

## Done when

The person can see the plan a run would follow: the order, which pieces can go
together, what a run can do with each, what stacks on what, and the command
that runs it. Nothing has been changed.
