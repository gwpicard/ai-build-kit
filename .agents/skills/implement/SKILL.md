---
name: implement
description: The everyday command for building a piece that has already been shaped and marked ready. Typed alone it takes the next ready piece from the plan, or, when several are ready, shows what can be built together and what waits on what, and asks which to take. Given an issue number, or a request that matches a ready piece, it builds that one. It shows the result, merges it after the person's yes, and on a live project reads one line of health from the live copy. A request that is not yet a ready piece goes to shape first; implement builds, it does not shape. "/implement auto" builds several ready pieces in a row. A repair is built here too, once shape has reproduced it.
---

# Implement

This command builds; it does not shape. It carries a ready piece to a
confirmed, saved change, and on the pull-request route merges it only on a yes
that names the merge. On a live project that merge is a deploy.
The `merge` skill holds the first upload and the merge.

Read masterplan.md first, build-path section first. Refresh the printout with
`sh .agents/tools/plan-refresh.sh` and read `plan.local.md`; never sort the
pieces by hand. The `records` skill's `references/pieces.md`
describes the pieces, their labels, and what to do when GitHub is unreachable.

Before taking a piece, run `python3` with the `maintain` skill's
`scripts/upgrade-check.py` from the project root and keep only its exit code.
Where it exits 1, say: "The kit update is not finished. /maintain finishes
it." Then carry on.

In Codex, when a Git push, fetch or remote check fails with `unable to get
password from user`, run the installed `setup-ai-build-kit` skill's
`templates/foundation/codex-github-check.py` with python3 and `--message`. Give
its sentence and stop this session's work, without signing in again or
retrying.

## Choosing the piece

Typed alone, a ready repair comes first: a piece under the printout's `Broken`
group marked `(ready)`. Otherwise, where one ready piece under `To build` is
free and the build path allows it, take it. Where several are, show the list
below and let the person choose; in an unattended run take the lowest-numbered.

A ready piece carries `ready`, has a `## Done when`, and waits on no question.
A piece with open parts is a container, not a slice to build directly: take
one of its parts.

Given an issue number, build that piece if it is ready, or send it to `/shape`
with one line on why not. Given a request in plain words, build the ready piece
it matches; otherwise point at `/shape`. Given a report that the live tool
broke, follow the `live-copy` skill's "Rolling back" first.

A piece still carrying a `needs-` label, or with no `## Done when`, is not
ready. This command does not settle the question: say what it waits on, point
at `/shape`, and take the next ready piece instead.

A piece with `## Waiting on you` is not attempted. Say the step in the piece's
words; in an unattended run leave it and take the next. Where you can do the
step yourself, do it.

A piece labelled `blocked` at a recorded condition stays skipped until the
condition is met or the person carries on after the risk notice. One parked
after repeated failure goes back to `/shape`. The blocked-by link decides, not
the label: a piece whose blockers have closed is buildable, and you say the
label looks stale. Two pieces holding each other up is a planning mistake to
break in `/shape`. A piece assigned to somebody else is theirs: skip it, say
who has it, and offer to take it over only if they are gone.

When nothing is ready, say so and name what is waiting on what.

### Taking on several pieces

Where several ready pieces are free, or the person asks what can be built in
parallel, show two groups from the printout, after any ready repair:

**Build these together now.** The count, then every ready piece. None waits on
another.

**These wait their turn.** Each blocked piece in one line naming what releases
it: "deposits cannot start until card payments is built".

Piece names, never issue numbers. Leave out pieces waiting on a question, and
name a sized piece with no marker as one `/shape` still has to mark ready.
Where the ready group is long, say how many a sitting can hold. Do not rank or
choose. Showing the list builds nothing; build the chosen pieces one at a time.

### A piece already built

A piece whose pull request is open with a green check waits only for its
merge. Typed alone, or asked to put such work live, follow
the `merge` skill for each. "Put it live" names no merge, so ask.

## Building the piece

One piece per pass, always. Load the `build-piece` skill and follow it, from
the safe start to the updated records. It holds the save routes, the evidence,
the flagged route and its risk notice, the hand-over, the review and the save.

## Merge

Once the check is green and the records are in the pull request, load the
`merge` skill and follow it.
In an unattended run nobody is there to say yes, so never merge: report the
piece as ready for review.

## Typed with auto, or handed to a goal mode

Auto is earned. Before it runs, require: three ordinary pieces completed
cleanly, no unsettled review finding worth stopping for, no flagged work
waiting, a clean tree, evidence a machine can check for every selected piece,
no piece waiting on a question, no repair, every piece
self-sufficient enough to build without a person present through its
`Under the hood` notes, nothing needing human judgement in the batch, no pending build-path change, and the
person's yes to the batch. Then load `references/running-longer.md` and follow
it.

## Done when

The route was followed and the records are true. Each piece built ends in one
of two outcomes, both complete passes, or the person knows exactly where it
stopped and why:

- Complete: credible evidence, with any available machine check run and green,
  the result confirmed where needed, required review satisfied, the records
  true, and the save route complete. On the pull-request route, the pull
  request is merged on the person's yes, or left open and ready with what it
  waits for.
- Safely blocked: stopped at its recorded condition, labelled `blocked`, the
  caution recorded, unblocked work named, and no claim that the flagged
  capability is ready or live.
