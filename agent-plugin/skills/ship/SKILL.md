---
name: ship
description: Take checked work to the copy of the tool the team actually uses. The only skill that touches that copy. Use when the user thinks the tool, or a batch of work on it, is ready for people to rely on. Follows the project's current build path and applies only the evidence, review, handover, or launch steps that path requires. Type this command when you want it; it never starts on its own.
disable-model-invocation: true
---

# Ship

Everything build and fix make lives on the draft copy until this word moves it over. Read masterplan.md, build-path section first.

## 0. Confirm the build path

Read the build-path section first.

If anything under `Recheck when` has happened since `Last checked`, run the
fit check before continuing.

Confirm that any outside-help condition already required by the current path
has either been met or remains visibly open.

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

### Build with expert help

Separate the work into:

- functionality outside the named expert scope;
- functionality inside the named expert scope.

For unflagged functionality, follow the same four steps as Build and run it
above: evidence run, second-opinion, operational readiness, then go live one
connection at a time.

For flagged functionality:

1. generate or refresh the expert brief;
2. stop at the recorded gate;
3. record what the expert must confirm;
4. do not merge or activate that capability until the gate is met.

Only after the gate is met does that capability get its own operational
readiness check (the same list as above) and its own go-live step, one
connection at a time, with the result recorded.

### Professional-led

Do not perform a production launch. Nothing in this branch ever reaches
operational readiness or go-live steps; those belong to the professional
owner's own process once they take the build on.

Check that the handover package contains:

- the current masterplan;
- the current plan;
- acceptance criteria;
- any decision prototypes;
- evidence gathered so far;
- the expert brief;
- known limitations and unresolved questions;
- service, data, access, and ownership information without secrets.

The professional owner decides the production build, checks, deployment, and
operating model. Stop here.

## 2. Graduation

When shipping or preparing a handover changes the build path, record:

- what changed;
- why the previous path no longer fits;
- the new outside-help level and scope;
- which work may continue;
- which work is blocked.

## After the first launch

Applies only once Build and run it, or an unflagged or gate-cleared part of
Build with expert help, has actually gone live at least once. Lighter from
then on: re-run the evidence for what changed since the last ship, and move
that over. If reliance, data sensitivity, or consequence has grown since the
build path was last checked, rerun the fit check before shipping further.

## Done when

Explore privately: the private-preview checks are recorded and nothing moved
to a live address. Professional-led: the handover package is complete and no
production launch happened. Build and run it, and Build with expert help for
its unflagged or gate-cleared parts: the team can rely on the copy they use,
required operational readiness is real, and the changelog says what went
live, when, and under which build path.
