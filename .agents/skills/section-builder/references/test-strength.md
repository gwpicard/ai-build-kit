# Check whether the tests notice

On Build with care only, once the ordinary tests pass, offer: "I can break
the changed code on purpose to check the tests notice." It is optional
evidence. A no, or a check that cannot run, holds up nothing, and no result
from it becomes a gate. Required checks and sensitive-area cautions still
apply.

## Run the script

On a yes, run `python3` with this skill's `scripts/quality.py` from the
project, passing `strength --base <commit the piece started from>`. It breaks
only the lines this piece changed, in a throwaway copy, and leaves the project
as it was. The copy holds no real records and reaches nothing live: it leaves
out every `.env` file but `.env.example`. In a repair, the regression test is
among the tests it runs.

Exit 2 means the check did not happen for some of the changed code, and each
`not-checked` line says why. That includes a run that broke nothing: changed
code with nothing tried, or tests that failed before anything was broken. A
zero there is not a pass. Say in one line that the tests were not checked for
that code, and never report it as "missed none". Never invent a runner or use
a hosted service.

Exit 0 or 1 means it ran on all the changed code. It prints `tried` and
`caught` counts, then a `missed` line for each breakage the tests let
through, at its file and line, and an `unchecked` line for any that crashed
or timed out. Those are not counted as caught. When exit 2 comes with counts
for the code that did run, report those counts too.

## What the person hears

One line, with the counts it printed: "The tests were checked by breaking the
code on purpose <tried> times. They caught <caught>. The <missed> they missed
are listed on the piece." Use the singular for one miss, and end with "They
missed none." when there are none. Keep the engine's name and the word
"mutation" out of it.

On the piece, describe each miss in plain words: what changed, what the tests
let through, and which promised behaviour that could affect. Compare its place
with the masterplan's sensitive-area map. A miss inside a named area goes under
"Worth stopping for", with the area named; any other miss goes under "Worth
knowing". The person decides whether a miss matters; record that on the piece.

Add or improve a test only when it protects promised behaviour, and show that
it now catches the breakage. Never write one to raise the count. A higher
count does not prove the software correct.
