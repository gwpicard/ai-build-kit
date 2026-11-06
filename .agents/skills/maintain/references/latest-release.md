# Checking for a newer kit

From the project root, run `python3` with this skill's
`scripts/upgrade-check.py --latest --route`. Exit 1: read `compare`.
`newer` means a newer release is out. `different` means the installed version
could not be read; report that uncertainty instead of repeating the script's
claim that a newer release is available.
Name the held and latest versions, give the supported `say` lines and `route`/`then`
commands, summarise that release's notes and require approval before updating
on a clean checkpoint. Record `upgrade-offered|latest|<latest VERSION>` in
`.ai-build-kit-maintenance` after the offer. If already recorded, say only
that the offer still stands, even on monthly visits. Exit 0: at most one
short line. Exit 3: say the check could not run; never call the kit current.
Exit 4: more than one update route is active; ask which to keep.

Before offering replacement, use `gh api` to download the proposed public
release's `maintain/scripts/kit-released-copies.json` from its tag into ignored
`.agents/tmp/kit-released-copies-next.json`. The installed record can predate
its own release's files.
Run `scripts/kit-local-edits.py --record <downloaded record> --skills <installed skills folder>`.
It compares installed files and missing paths with the installed release's
record, including committed edits and ignoring generated caches. Exit 0 adds
nothing to the offer. Exit 1: name each `local-edit` file,
give the `say` line and require approval naming those files before replacement.
With that approval, rerun with `--approved --overwrite <file>` for each file
and `--run <update command>`; it checks again before running the command.
Without approval, leave those files in place. Exit 2, or a failed download:
report that local edits could not be checked and do not replace the skills.
A missing release baseline or file inventory is inconclusive, never evidence
of local edits.
For plugin routes, the skills folder is in the installed plugin, outside the
project. Check the selected route's folder before its plugin update too.
