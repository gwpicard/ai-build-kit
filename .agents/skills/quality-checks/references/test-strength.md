# Check whether the tests notice

For a change inside a mapped sensitive area, run `python3` with this skill's
`scripts/quality.py`, passing `strength --base <start commit>`. For a repair,
run it on the regression test only when that test touches a mapped area.
`quality.py tests` triggers this read itself for changed lines in mapped areas
and reports its misses as `strength` lines. Tell the person what those lines
mean in one line. Never invent a runner or write a test to raise the count.
Act on its exit code: 0 means the changed code was checked and no breakage was
missed, 1 lists breakages the tests missed, and 2 means part of the check could
not run. Never report exit 2 as a pass.
