# Check whether the tests notice

For a change inside a mapped sensitive area, run `python3` with this skill's
`scripts/quality.py`, passing `strength --base <start commit>`. For a repair,
run it on the regression test only when that test touches a mapped area.
`quality.py tests` triggers this read itself for changed lines in mapped areas
and reports its misses as `strength` lines. Act on its exit code: 0 means the
changed code was checked and no breakage was missed, 1 lists breakages the tests
missed, and 2 means part of the check could not run. Never report exit 2 as a
pass.

The strength run uses a throwaway copy with no real records, live access or
real `.env` files.

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
