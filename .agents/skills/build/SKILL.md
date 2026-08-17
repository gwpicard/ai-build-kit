---
name: build
description: The everyday command for making the tool do something new or different. Typed alone it takes the next piece from the plan. Typed with words after it, it takes the request in plain language and works out what kind of work it is. "/build auto" builds several pieces in a row. Do not use for repairs of promised behaviour; that is fix. Type this command when you want it; it never starts on its own.
disable-model-invocation: true
---

# Build

Use the current session for related, well-bounded work while the context
remains clear. Start fresh after a long, confused, interrupted, or unrelated
session, and whenever an independent review is required. The documents are
the source of truth either way. Read masterplan.md first, build-path section
first, then the project's pieces.

Where the pieces are issues, `.agents/tools/plan-refresh.sh` prints the open ones
into `plan.local.md`. Refresh first, then read that. Where the project keeps
`plan.md`, read that instead. The capability profile in AGENTS.md says which
applies, and `.agents/skills/start/references/pieces.md` describes both.

A repository is not the test. A project can have one and still keep `plan.md`, so
a refresh that returns no issues at all on a project with `plan.md` on disk means
the file is the record. Read it, and say that is where the pieces live. Never
report an empty list while that file sits unread.

When GitHub cannot be reached, say so, say when the printout was last written,
and work from it. The piece already in hand carries on. Anything that would
change what is on the plan waits, because an issue that cannot be updated is
not a record of anything.

## Typed alone

Take the lowest-numbered open piece that nothing open is holding up and whose
class the current build path allows. The issue list says which are held up, so
this needs no digging.

A piece labelled `blocked` needs attention before it counts as buildable again:
one safely prepared and stopped at a recorded condition stays skipped until that
condition is met, or until the person accepts the risk on the record; one parked
after repeated failure (running-longer.md) needs routing onward first, to
clarify, a source check, or a build-path reassessment.

Before handing an eligible piece to section-builder, confirm it's genuinely
unblocked, confirm the current build path allows it, and identify its
evidence and save route from the piece and the build path. Read the piece's
subject labels rather than reclassifying it; reclassify only when the piece
carries none, the request materially changed, or a subject contradicts the
masterplan.

## When the next piece is only a note

An issue with no `## Done when` was typed by hand and has never been sized. Do
not build it, and do not guess what done means.

Say in one sentence why it is not ready, and offer both the interview and the
way out in the same breath: a few questions now, or "not now" and you take the
next piece that is ready instead. Somebody who typed `/build` wanted something
built, so an escape hatch mentioned afterwards is no escape hatch at all.

When they agree, run clarify on it there and then. Write what comes out into
the shape `.agents/skills/start/references/pieces.md` describes, keep their
original words underneath, take the subjects from change-triage rather than
picking them yourself, and then build it.

"Not now" leaves the note alone, still labelled `needs-clarification`, and you carry
on to the next ready piece. The list stays in its order either way.

## When the pieces contradict each other

The blocked-by link is the truth and the `blocked` label is only a hint, so read
the link. A piece whose blockers have all closed is buildable even with the
label still on it. Say the label looks stale, and leave taking it off to `/sync`.

When nothing is ready, because everything open is held up or two pieces hold
each other up, say so plainly and name what is waiting on what. Standing there
with nothing to say is the one unhelpful answer. Two pieces blocking each other
is a planning mistake rather than a state to wait out, so offer to break it.

A piece assigned to somebody else is theirs. Skip it and say who has it. Where
that person is no longer around, offer to take it over and let the person
decide, because reassigning somebody's work is their call.

Two people building the same piece is what claiming a piece exists to prevent,
so say it the moment you see it rather than at the end.

## Typed with words

Run change-triage on the request and follow its route: build it now through
section-builder, run clarify first, run a decision prototype, run a source
check, update the masterplan first, or stop and rerun the fit check. Say
which route you chose and why, in one line.

## Typed with auto, or handed to a goal mode

Auto is not an ordinary peer to normal build; it is earned, not default.
Before enabling it, require: at least three normal pieces completed cleanly,
no unresolved review or flagged work waiting, clean Git state, evidence a machine can
check for every selected piece, nothing needing human judgement in the batch,
no pending build-path transition, and the user's explicit approval of the
batch. A project has earned auto mode when its records and checks have
repeatedly predicted successful ordinary builds; the presence of an agent
feature called "goal" or "auto" does not itself make the project eligible.

Once eligible, load references/running-longer.md before starting and follow
it. The shape, so the person knows what they are agreeing to: the plan is
approved once, only pieces a machine can prove get taken, a failing piece is
retried three times and then parked, flags and expert scopes stop the run,
and it ends through the route required by the build path: normally one pull
request carrying a checklist of things to try before merging, or a confirmed
checkpoint for eligible private exploration.

## Done when

The route was followed, the records are true, and the piece is confirmed and saved through the required route, safely blocked at a recorded condition, or the user knows exactly where things stopped and why.
