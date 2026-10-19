# Building a repair

For a piece labelled `broken`, the `build-piece` skill follows this file from
step 4. Its other steps still apply: safe start, save route, evidence,
hand-over, review and merge.

## Check and rank

Run the recorded check first. If it no longer fails, say so and ask whether
the fault still happens before changing code. If it fails, keep that case as
the regression test.

Read `CHANGELOG.md` and closed pieces for the same area. Rule out a failed
attempt or rank an established cause first. If the history changes the
ranking, say: "This was tried on <date> and did not hold, so it is ruled out."
History informs the present check; it is not a verdict.

List two to five plausible causes internally, each with a prediction that
could disprove it. Show the list only if the person's domain knowledge could
change the ranking. If the person or changelog identifies when it last worked,
bisect saved history before testing causes and report the change and date. Do
not bisect without a known-good point.

## Change one cause at a time

Change one variable per attempt. Keep temporary instrumentation targeted and
labelled; name its log file and read it back while testing. After a failed
attempt, say what the reset will remove, then run this skill's
`scripts/reset-attempt.sh --start` and the same script with no option. It
prints a snapshot of the failed attempt and removes only files added since the
start. Commit useful work, such as a reproducing test, before the attempt so
the reset cannot remove it.

Create regression evidence at the highest credible user-facing boundary. Use
the matching D number or the repair's number line in its test title. Watch the
test fail, commit it under `Test:`, then make the smallest fix for the cause.
Watch it pass, rerun the original unminimised case, and run
`quality.py tests --base <start commit> --piece <number>` once after the fix.
If no credible automated boundary exists, record a maintainability finding
and use the strongest manual or operational evidence available. For a test in
a mapped risk area, also run `quality.py strength --base <start commit>`
and act on its exit code. Exit 2 means part of the changed code was not checked.

## Finish

Name and remove every temporary log or harness, then rerun the evidence
without them. Clear this piece's shaping files from `.agents/tmp/`. Apply the `quality-checks` skill's
`references/trim.md`. Confirm the original symptom is gone, record its cause
in the changelog, update the other records and use the build-piece save and
review route. Report what was removed and that the evidence still passed.
Remove the `broken` label once the symptom is gone.

After three unsuccessful attempts, follow `escalation.md` before trying again.
