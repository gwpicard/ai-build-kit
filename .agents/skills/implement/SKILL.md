---
name: implement
description: The everyday command for building a piece that has already been shaped and marked ready. Typed alone it takes the next ready piece from the plan, or, when several are ready, shows what can be built together and what waits on what, and asks which to take. Given an issue number, or a request that matches a ready piece, it builds that one. It shows the result, merges it after the person's yes, and on a live project reads one line of health from the live copy. A request that is not yet a ready piece goes to shape first; implement builds, it does not shape. "/implement auto" builds several ready pieces in a row. A repair is built here too, once shape has reproduced it.
---

# Implement

Use the current session for related, well-bounded work while the context
remains clear. Start fresh after a long, confused, interrupted, or unrelated
session, and whenever an independent review is required. The documents are
the source of truth either way. Read masterplan.md first, build-path section
first, then the project's pieces.

This command builds; it does not shape. It takes a piece that `/shape` has
already shaped and marked ready, and carries it to a confirmed, saved change.
On the pull-request route it then asks the person whether to merge, and merges
only on a yes that names the merge. On a live project that merge is a deploy,
so this is also how a change goes live. section-builder's "Merge" step holds
the rules, and the checks that come before the merge on a live project.
Shaping, sizing, and settling a question all happen in `/shape`, so this command
never has to guess what a piece means. A request that is not yet a ready piece
belongs to `/shape` first.

`sh .agents/tools/plan-refresh.sh` prints the open issues into `plan.local.md`.
Refresh first, then read that, and never sort the pieces by hand in its place.
The `setup-ai-build-kit` skill's `references/pieces.md` describes how the
pieces are kept, and what to run in a project that has no copy of the helper.

Before taking a piece, read whether a kit update is still unfinished. From
the project root, run `python3` with the `maintain` skill's
`scripts/upgrade-check.py`, and keep only its exit code. It reads and changes
nothing. Where it exits 1, say one line: "The kit update is not finished.
/maintain finishes it." Then carry on. The build does not wait for it. Any
other exit says nothing.

When GitHub cannot be reached, say so, say when the printout was last written,
and work from it. The piece already in hand carries on. Anything that would
change what is on the plan waits, because an issue that cannot be updated is
not a record of anything.

## Typed alone

A ready repair comes first: a piece under the printout's `Broken` group marked
`(ready)`, which the printout gives only to a repair nobody is building and
nothing open holds up.
Something that used to work and no longer does outranks anything new.
section-builder builds it with the repair rules. Otherwise, where only one
ready piece is free to start, take it: the one nothing open is holding up and
whose class the current build path allows. Where more than one is, show them
as "Taking on several pieces" below says, and let the person choose. In an
unattended run nobody is there to choose, so take the lowest-numbered one.
A ready piece is one `/shape` has finished
shaping: it carries the `ready` label, has a `## Done when` line, and waits on no
open question. The issue list says which are held up, so this needs no digging.

A piece with open parts is a container, not a slice to build directly. Skip it
and take one of its parts, the same way you would take any other ready piece; the
parent closes on its own when its parts all close. The issue list carries the
sub-issue count, so a parent is known without digging, the way a blocker is.

Before handing an eligible piece to section-builder, confirm it's genuinely
unblocked, confirm the current build path allows it, and identify its
evidence and save route from the piece and the build path. Read the piece's
subject labels rather than reclassifying it; the classification was settled in
`/shape` and section-builder reads it rather than re-deriving it.

A piece labelled `blocked` needs attention before it counts as buildable again:
one safely prepared and stopped at a recorded condition stays skipped until that
condition is met, or until the person carries on after the risk notice and the
acceptance is recorded; one parked
after repeated failure (references/running-longer.md) needs routing back to
`/shape` first, for another look.

## Taking on several pieces

Somebody taking on several pieces at once needs to see the whole set before
choosing. So when no ready repair is waiting, and the printout holds more than
one piece under `To build` marked `(ready)` that the current build path
allows, show what can be built together and what waits on what, and ask which
to take. The same holds when the person asks for the whole list in plain
words, such as "what can I build in parallel?", and wants no build: show it
and stop there.

A ready repair comes before the list, in both cases. Where one is waiting,
name it first, as "Typed alone" says, since something that used to work
outranks anything new. Typed alone, build it. Asked for the list alone, name
the repair above the two groups and still build nothing.

`/what-now` names one next step and at most three things, because somebody lost
cannot use more. That cap stays. The whole list lives here, at the moment of
building, and never goes back into `/what-now`.

The printout is the only source. Where the project has no copy of the helper,
the `setup-ai-build-kit` skill's `references/pieces.md` says what to run
instead. If GitHub cannot be reached, show the printout as it stands and say
when it was written, because an old list a person can see beats no list at
all.

The printout has already done the sorting. A piece under `Blocked` names the
piece holding it up, and a piece with an open blocker is never under
`To build`, so a ready piece cannot be waiting on another ready piece. Never
work that out again from the issues. Read the masterplan's build-path section
too: a piece the path will not allow is not ready work however the label reads.

Two groups, in this order.

**Build these together now.** Every ready piece. They have no dependency between
them, which is what makes them safe to take on at once. Say the count first, in
one line, then the pieces.

**These wait their turn.** The blocked pieces, one line each, saying which piece
releases it: "deposits cannot start until card payments is built". Where a chain
runs deeper than one, put the piece that unlocks the most first and let the
rest follow it.

Piece names, never issue numbers. The person cannot follow a number, and the
printout carries the name of the blocking piece already.

A piece waiting on a question rather than on another piece is not ready and
not blocked by work. Say which of the three questions it needs and leave it out
of both groups. A piece with a `Waiting on you` step is named as the person's own
to do, and you never ask for a key, a password, or a token in a message.

A piece under `To build` carrying no marker at all has been sized but never
marked ready. Name it with those, and say `/shape` is what marks it ready. This
is the one case where a piece looks buildable in the printout and is not, and it
matters most when that piece is the one holding another up.

Where nothing is blocked, say nothing about it rather than printing an empty
group. Where the ready group is long, say once how many pieces a sitting can
realistically hold, since taking on eight at once is the mess this list exists
to prevent. Do not rank the pieces and do not choose for the person.

Showing the list builds nothing. Wait for the person to name what to take, then
build those pieces one at a time, each as section-builder says.

## A piece already built

A piece whose pull request is open with a green check waits only for its
merge. When the person types this command alone, or asks to put such work
live, name each such pull request in one plain line that says what it changes,
and ask for the yes as section-builder's "Merge" step says, after the checks
that step makes on a live project. Their own words count only where they
already named the merge, as in "merge both and put it live". "Put it live"
names no merge, so ask. Never merge a pull request the person has not named
or plainly covered.

## When a piece waits on the person

A piece carrying a `## Waiting on you` section cannot be built until that step is
done. Do not attempt it, and do not pass it over in silence. Say what the step
is, in the words the piece uses, and that building carries on once it is done.

In an unattended run, name the step, leave the piece where it is, and take the
next ready piece, so the run keeps working and the step is waiting when the
person comes back.

Where the step turns out to be something you can do yourself, do it and carry on
rather than asking. A piece should never hold work up for something the agent
could have gone and done.

## When the next piece is not ready

A piece that still carries `needs-clarification`, `needs-prototype`, or
`needs-research` has a question to settle before its code is written. An issue
with no `## Done when` was typed by hand and never sized. Neither is ready, and
building either one only guesses the answer.

This command does not settle the question. Settling it is planning, and planning
is what `/shape` is for. Say in one sentence what the piece is waiting on, and
point the person at `/shape` to shape it. Then take the next ready piece instead,
so a session that asked to build still builds something. Where nothing else is
ready, say so plainly rather than shaping the waiting piece here.

## Given a specific piece or a request

Typed alone, take the next ready piece as above.

Given an issue number, build that piece if it is ready, and send it to `/shape`
if it is not, saying in one line why it is not ready.

Given a report that the live tool broke, wherever it was typed, run the
`change-triage` skill's "A live break after a recent merge" first, so the
earlier version can come back before anything is built.

Given a request in plain words, check whether it already matches a ready piece.
Where it does, build that piece. Where it does not, this is new or unshaped
work: point the person at `/shape`, which shapes a request into a piece. This
command never shapes a typed request itself, and it never builds past an open
question.

## When the pieces contradict each other

The blocked-by link is the truth and the `blocked` label is only a hint, so read
the link. A piece whose blockers have all closed is buildable even with the
label still on it. Say the label looks stale, and leave taking it off to `/maintain`.

When nothing is ready, because everything open is held up, still waiting on a
question, or two pieces hold each other up, say so plainly and name what is
waiting on what. Standing there with nothing to say is the one unhelpful answer.
Two pieces blocking each other is a planning mistake rather than a state to wait
out, so offer to break it in `/shape`.

A piece assigned to somebody else is theirs. Skip it and say who has it. Where
that person is no longer around, offer to take it over and let the person
decide, because reassigning somebody's work is their call.

Two people building the same piece is what claiming a piece exists to prevent,
so say it the moment you see it rather than at the end.

## Naming the next piece

When the report at the end of a build names what can be built next, read it off
the printout section-builder has just refreshed. A repair under `Broken` marked
`(ready)` comes first, since the printout marks one ready only when nobody is
on it and nothing open holds it up. Otherwise, name only a piece under
`To build` marked `(ready)`, and never the piece just built. Where neither
group holds such a piece, say that nothing is ready to build now, say what the rest
are waiting on, and name no piece as next. Never work the next piece out from
the issue list or its blocked-by links by hand: the printout already keeps a
piece with an open blocker out of `To build`, and a hand reading does not.

## Typed with auto, or handed to a goal mode

Auto is not an ordinary peer to normal building; it is earned, not default.
Before enabling it, require: at least three normal pieces completed cleanly,
no unresolved review or flagged work waiting, clean Git state, evidence a machine can
check for every selected piece, no piece still waiting on a question
(`needs-clarification`, `needs-prototype`, or `needs-research`), no repair
labelled `broken`, every selected
piece self-sufficient enough to build without a person present, meaning its
`Under the hood` notes carry what the build needs, nothing needing
human judgement in the batch,
no pending build-path transition, and the user's explicit approval of the
batch. A project has earned auto mode when its records and checks have
repeatedly predicted successful ordinary builds; the presence of an agent
feature called "goal" or "auto" does not itself make the project eligible.

Once eligible, load references/running-longer.md before starting and follow
it. The shape, so the person knows what they are agreeing to: the plan is
approved once, only ready pieces a machine can prove get taken, a failing piece is
retried three times and then parked, a named sensitive area stops the run,
and it ends through the route required by the build path: normally one pull
request carrying a checklist of things to try before merging, or a confirmed
checkpoint for eligible private exploration.

## Done when

The route was followed, the records are true, and the piece is confirmed and saved through the required route, merged on the person's yes or left ready for review with what it waits for, safely blocked at a recorded condition, or the user knows exactly where things stopped and why.
