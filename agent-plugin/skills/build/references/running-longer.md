# Running longer: auto and goal modes

Loaded when a run covers several pieces instead of one. The discipline is
unchanged; what changes is that nobody is present between the steps, so the
conditions carry the quality and everything gets a cap.

## Eligibility by build path

- **Explore privately:** permitted only for disposable work with
  machine-checkable evidence.
- **Build and run it:** permitted once at least three normal pieces have
  completed cleanly.
- **Build with expert help:** permitted only for pieces entirely outside every
  named expert scope.
- **Professional-led:** not used for production implementation; the kit does
  not autonomously cross that boundary.

## Capability rule

Assume nothing beyond ordinary sequential agent work: no native goal mode, no
background agents, no worktrees. Where a harness offers those as an
enhancement, they may speed the run up, but the portable implementation is
plain sequential building, one piece after another in the same way a person
would run them by hand.

## Typed with auto

The plan gets approved once; the pieces then run in a row with nobody in
between. The rules of the mode: every piece still gets the evidence its
consequence classification requires, and every piece gets its own commit, so
anything can be unwound piece by piece.

Which pieces the run may take: only those whose done line a machine can
prove, meaning it names a test or a command with a checkable result. A piece
whose done line needs human eyes ("you see it in the browser", "you check it
by hand") gets skipped and left marked to-build; say so in the report. The
plan sorts itself: the how-to-check phrase on each done line is the
eligibility rule.

When a piece fails: retry within the piece, up to three attempts, the same
number fix uses. After the third, park it, mark it blocked in plan.md with
one line on what kept failing, and move to the next piece; never let one
piece consume the run. Route the parked piece further when the failure
points somewhere specific: a missing decision goes to grilling, a missing
external fact goes to the source check, and a shape the team could not
safely own goes to a build-path reassessment rather than a fourth attempt.

Stop the whole run at anything change-triage would escalate, at any touch of
a flagged area or expert scope, and at anything ambiguous; never guess to
keep a run going.

The whole run happens on one branch and ends as one pull request, where the
build path requires a pull request at all; a run confined to the checkpoint
route may end in a single confirmed checkpoint instead. Skip the per-piece
hand-over; end the run with the evidence run (ship/references/evidence-run.md),
and write the report as: what was parked and why first, then what was built
and what passed, what was skipped as eyes-only, and a checklist of things to
try before merging, riskiest first, anything near a flag or expert scope on
top.

When a run disappoints, the fix is in the documents rather than in the code by
hand: sharpen the done lines that let weak work through, add the missing rule
to the masterplan, then run it again. Hand-editing what a run wrote turns a
readable project into a mystery.

## Goal modes

Some tools ship a /goal feature: state a condition and the agent keeps going
until a separate model judges it met. Treat it as this mode wearing the
tool's clothes, under the same rules: the condition comes from a done line or
a plan area's done lines, read aloud; flagged areas and expert scopes stay
stop conditions the goal may not cross; the three-attempt parking rule still
applies per piece; and the result still lands through the save route the
build path requires, because merging belongs to a human however long the
machine ran.
