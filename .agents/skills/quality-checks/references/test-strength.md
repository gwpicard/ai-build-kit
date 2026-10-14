# Check whether the tests notice

For a change inside a mapped sensitive area, run `python3` with this skill's
`scripts/quality.py`, passing `strength --base <start commit>`. For a repair,
include the regression test. Act on its exit code: 0 means the changed code
was checked and no breakage was missed, 1 lists breakages the tests missed,
and 2 means part of the check could not run. Never report exit 2 as a pass.
