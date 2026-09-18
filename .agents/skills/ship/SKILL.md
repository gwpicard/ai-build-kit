---
name: ship
description: Take checked work to the copy of the tool the team actually uses. The only skill that touches that copy. Use when the user thinks the tool, or a batch of work on it, is ready for people to rely on. Follows the project's current build path and applies only the evidence, review, handover, or launch steps that path requires.
---

# Ship

Everything build and fix make lives on the draft copy until this command moves it over. Read masterplan.md, build-path section first.

## 0. Confirm the build path

Read the build-path section first.

If anything under `Recheck when` has happened since `Last checked`, run the
fit check before continuing.

Read each line under `Sensitive areas`. Say for each whether its caution is
done, waiting on a person, or accepted, and do not carry on past one that is
none of those. On Build with care, walk its `paths`, its optional `boundary`,
and the folders assigned to `none`; stop if the shipped sensitive-area check
does not agree with the current project.

## 1. Follow the current path

Each branch below is self-contained. Follow only the branch that matches the
current build path, stop where it says stop, and do not carry a step from one
branch into another.

### Explore privately

Do not run the production evidence or launch procedure. Nothing below this
point in this branch ever moves work to a live address.

Confirm only:

- the prototype still uses disposable data;
- nobody relies on it;
- no consequential automatic action is active;
- the question or experiment it exists to answer has been checked;
- any preview remains private;
- the user is told plainly that it is not approved for operational reliance.

Record what would need to change before the path could become Build and run
it, then stop.

### Build and run it

1. Run the full evidence run.
2. Run second-opinion using the best independent method recorded in
   AGENTS.md.
3. Operational readiness: before any first live use, require whatever of
   this actually applies: a named alert recipient, a named service and
   billing owner, a backup, a successful restore rehearsal, a manual
   fallback, a rollback or disable procedure, removal of test data, an
   access review, and clear service-account ownership. Do not require a
   database restore rehearsal for a tool with no stored data, or invent
   readiness steps a tool with no live reliance doesn't need.
4. Go live, one connection at a time: take the harmless parts live first.
   If hosting uses a preview address, this is the moment work moves to the
   team's address. That move is what /ship means.

### Build with care

Separate the work into what is outside every named area and what is inside
one.

Outside every named area, follow the same four steps as Build and run it
above: evidence run, second-opinion, operational readiness, then go live one
connection at a time.

Inside a named area, take each area in turn:

1. read its line in the build-path section: what touches it, its caution, and
   where the caution stands;
2. where the caution is the kit's to do (a backup restored once, a rehearsal
   on a copy, a managed service, an approval step), do it now or check it was
   done, and write `done` with today's date on the line;
3. where the caution is a person, stop at it. Say in one sentence what that
   person must confirm. Do not merge or activate that area until they have
   looked and that is recorded, or the person accepts the risk on the record.
   No session meets it; fit-check.md says who does;
4. restate the risk notice here, at the moment the area is actually going
   live, rather than only when it was first scoped;
5. only after the caution is done or accepted does that area get its own
   operational readiness check (the same list as above) and its own go-live
   step, one connection at a time, with the result recorded on its line.

Where a caution is a person and the team has nobody to ask, offer the
handover once: `templates/handover.md`, filled in for that area, is what the
team gives somebody outside it to look at that area or to take the build on.
Offer it, prepare it if they say yes, and carry on with everything outside
the area either way. A handover is a document the person asks for, not a
stop.

## 2. Graduation

When shipping or preparing a handover changes the build path or names a new
sensitive area, record:

- what changed;
- why the previous path no longer fits;
- each new area and its caution;
- which work may continue;
- which work waits.

## After the first launch

Applies only once Build and run it, or Build with care outside its named
areas or in an area whose caution is done or accepted, has actually gone live
at least once. Lighter from
then on: re-run the evidence for what changed since the last ship, and move
that over. If reliance, data sensitivity, or consequence has grown since the
build path was last checked, rerun the fit check before shipping further.

## Done when

Explore privately: the private-preview checks are recorded and nothing moved
to a live address. Build and run it, and Build with care outside its named
areas or in an area whose caution is done or accepted: the team can rely on
the copy they use, required operational readiness is real, and the changelog
says what went live, when, and under which build path. Where a handover was
asked for, it is complete and says what it does not cover.
