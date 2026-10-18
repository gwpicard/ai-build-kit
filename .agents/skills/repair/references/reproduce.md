# Shaping a repair

A report that something is broken is a piece like any other. Run these checks
in order, then reproduce the fault. `/implement` builds it by
`fixing.md`.

## Check the report

1. Read the masterplan's risk record. Repair only behaviour it promised;
   route unpromised behaviour as new work.
2. If the live tool broke after a recent merge, follow the `live-copy` skill's
   "Rolling back" first, then shape the repair.
3. Read `CHANGELOG.md`, closed pieces and merged pull requests for the same
   area. Count by the fault surviving, not your tally. After three attempts,
   follow `escalation.md` in this reply, notice included, before
   marking work ready.
4. If one look on this computer shows a small, clear fault, such as a typo or
   wrong label, that look is the reproduction. A report alone is not enough.
   Run `quality.py reach --paths <suspected files> --run`, write the look and
   reach onto the piece, mark it ready with `records` skill's
   `scripts/mark-ready.sh`, and offer to build it. Otherwise reproduce below.

Use what already runs: project tests, a command, the app in a browser, or
replayed input. Put a throwaway harness in ignored `.agents/tmp/`. Temporary
logging in source waits for the build.

## Define and minimise the symptom

Record exact steps, expected and actual results, error text verbatim,
environment, and whether it is intermittent. Read the project's own request
record after launch to find the failed
step. If it is missing, name the missing evidence and continue; do not ask the
person to read logs. If a step needs a secret, use its location in the
masterplan. Run `quality.py reach --paths <suspected files> --run` and the
existing tests it finds before adding a test.

Find one repeatable check at the strongest available boundary, preferring an
existing failing test, a focused test in `.agents/tmp/`, a request or command
script, browser automation, replayed input, a throwaway harness, then guided
human steps. If no loop can be built, ask for the missing artefact, access or
permission. If they cannot provide it now, mark the piece `broken`, record the
known symptom and add `## Waiting on you`. Never mark it ready or patch it.

Run the check, confirm it catches the fault, then remove steps or inputs one
at a time until only the smallest failing case remains.

## Write the piece

Use `pieces.md`'s shape and mark it `broken`. Its `## Done when` states the
failing steps, present result and repaired result. Put the check, how to run
it, and its reliability in `Under the hood`. Then mark it `ready`.
