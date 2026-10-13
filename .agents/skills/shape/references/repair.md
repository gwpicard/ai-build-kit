# Shaping a repair

A report that something is broken is a piece like any other, in whatever words
it arrives. These four checks come first, in this order, before the usual
steps. Then reproduce the fault as the rest of this file says. `/implement`
builds the repair by the `implement` skill's `references/repair.md`.

## Was this ever promised?

Read the masterplan, build-path section first. A report is a repair only where
the behaviour it asks for was promised. Where it was never promised, say so
kindly and route it as new behaviour: a new wish treated as a repair ends up in
the wrong procedure. Nobody can misfile work by typing the wrong words;
catching that is this check's whole job.

## A live break after a recent merge

Where the report is that the live tool broke after a recent merge, follow the
`setup-hosting` skill's "Rolling back" first: it says when to offer the earlier
version back, and how. Then shape the repair, whatever the answer.

## A fault that has survived three attempts

Read the history for the same area before shaping anything: `CHANGELOG.md`,
closed pieces and merged pull requests. Count the attempts the way the
`implement` skill's `references/repair.md` counts them under "What counts
as three": by the fault surviving, not by your own tally. Where this report
means the fault has survived three attempts, follow that file's "Escalation"
in this same reply, notice included, before marking anything ready. A fresh
session is no reason to start the count again.

## A small, clear repair

Where one look on this computer shows the fault, on the screen, in a command's
output or in the code, and the change is a few lines, such as a typo or a wrong
label, that look is the reproduction. A report alone is not enough: you must
have seen the fault yourself. Still define the symptom as below, and write
what the look was onto the piece. Mark the piece ready at once, with the
failing case as its `## Done when`, by running the `shape` skill's
`scripts/mark-ready.sh` on the piece's number, and offer to build it in this
same session rather than a fresh one. Anything less certain is shaped by
reproducing it, as below.

Shaping changes no file the project saves. Reproduce with what runs as it is:
the project's own tests, a command or request run from the shell, the app in a
browser on this computer, or replayed input. A throwaway harness goes in
`.agents/tmp/`, which git ignores, so `/implement` later starts on a clean
tree. Temporary logging inside the code waits for the build.

## Define the symptom

Record the exact steps that trigger it, the expected result, the actual
result, the error text or artifact verbatim if there is one, the environment
it happened in, and whether it's intermittent. A bug you can't describe this
precisely is a bug you can't verify as fixed.

## Build the tightest feedback loop available

After launch on Build and run it or Build with care, read the tool's own
request record alongside the person's report as a source for the reproduction.
Use it to find the failed step and the smallest repeatable case. If the record
is absent or cannot be reached, say what evidence is missing and continue with
the other sources below; never ask the person to read logs. The project's
Secrets and Confidential files rules still apply to anything read or reported.
A step that needs a secret reads where it lives from the masterplan first, as
the Secrets rule says, and asks once when that is unknown.

Load the `implement` skill's `references/reach-check.md` and run its
reach check now. Run the existing tests it finds before writing a new focused
test. Prefer the existing test when it catches the exact symptom; the build
adds the new regression test once the cause is known.

Find one repeatable check that catches the exact symptom. Prefer, in order:
an existing failing test; a new focused automated test, written in
`.agents/tmp/` while shaping; a request or command script;
browser automation; replayed input; a small throwaway harness; structured
human-in-the-loop steps, when nothing else can reach the bug.

The user never needs to know which technique this was. The piece states how
the bug is triggered, what result marks failure, how long the check takes,
and whether it's reliable.

When no loop can be built, ask for the missing artifact, access, or
permission. Where the person cannot give it now, file the piece with `broken`,
the symptom as far as it is known, and a `## Waiting on you` section naming
what is missing. Do not label it `ready`, and never begin speculative patching
without a loop.

## Reproduce and minimise

Run the check, confirm it actually catches the user's bug, then remove
irrelevant steps or inputs one at a time until only the smallest case that
still fails remains.

## Write the piece

A repair is ready once it is reproduced. Write it in the shape
the `setup-ai-build-kit` skill's `references/pieces.md` describes, with
`broken` beside its subjects. Its `## Done when` is the failing case: the
smallest steps, what they give now, and what they give once repaired, for
example "Booking the tripod once shows one loan on the calendar, not two."
Put the check itself, how it is run and how reliable it is, in `Under the
hood`, so the build starts from the same loop. Then label it `ready`.
