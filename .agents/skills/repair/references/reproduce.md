# Shaping a repair

A report that something is broken is a piece like any other. Run these four
checks first, in this order, then reproduce the fault. `/implement` builds the
repair by `fixing.md` beside this file.

## Was this ever promised?

Read the masterplan, build-path section first. A report is a repair only where
the behaviour was promised. Where it was not, say so kindly and route it as new
behaviour.

## A live break after a recent merge

Where the live tool broke after a recent merge, follow the `live-copy`
skill's "Rolling back" first. Then shape the repair, whatever the answer.

## A fault that has survived three attempts

Read the history for the same area before shaping anything: `CHANGELOG.md`,
closed pieces and merged pull requests. Count the attempts the way the
`repair` skill's `references/fixing.md` counts them under "What counts
as three": by the fault surviving, not by your own tally. Where this report
means the fault has survived three attempts, follow that file's "Escalation"
in this same reply, notice included, before marking anything ready. A fresh
session is no reason to start the count again.

## A small, clear repair

Where one look on this computer shows the fault (the screen, a command's
output, or the code) and the change is a few lines, such as a typo or a wrong
label, that look is the reproduction. A report alone is not enough: you must
have seen it. Define the symptom as below, run `quality.py reach --paths
<suspected files> --run`, write the look and its reach onto the piece, mark it
ready with the `records` skill's `scripts/mark-ready.sh`, and offer to build it
in this session. Anything less certain is reproduced as below.

Reproduce with what runs as it is: the project's tests, a command, the app in a
browser on this computer, or replayed input. A throwaway harness goes in
`.agents/tmp/`, which git ignores. Temporary logging in the code waits for the
build.

## Define the symptom

Record the exact steps, the expected result, the actual result, any error text
verbatim, the environment, and whether it is intermittent.

## Build the tightest loop

After launch on Build and run it or Build with care, read the tool's own
request record beside the report to find the failed step. If it is missing,
say what evidence is missing and carry on; never ask the person to read logs.
A step that needs a secret reads its location from the masterplan, as
AGENTS.md's Secrets rule says.

Run `quality.py reach --paths <suspected files> --run` and act on its exit code,
and run the existing tests it finds before writing a new one.

Find one repeatable check that catches the exact symptom, preferring in order:
an existing failing test; a new focused test written in `.agents/tmp/`; a
request or command script; browser automation; replayed input; a throwaway
harness; guided human steps when nothing else reaches it.

When no loop can be built, ask for the missing artifact, access or permission.
Where the person cannot give it now, file the piece with `broken`, the symptom
as far as known, and a `## Waiting on you` section. Do not label it `ready`,
and never patch without a loop.

## Reproduce and minimise

Run the check, confirm it catches the person's fault, then remove steps or
inputs one at a time until only the smallest failing case remains.

## Write the piece

Write it in pieces.md's shape with `broken` beside its subjects. Its `## Done
when` is the failing case: the steps, what they give now, and what they give
once repaired, such as "Booking the tripod once shows one loan on the
calendar, not two." Put the check, how to run it and how reliable it is, in
`Under the hood`. Then label it `ready`.
