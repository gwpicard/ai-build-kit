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
