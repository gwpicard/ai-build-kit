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

Before offering replacement, download the proposed release's
`maintain/scripts/kit-released-copies.json` into ignored `.agents/tmp/` with
`gh api -H 'Accept: application/vnd.github.raw+json' 'repos/gwpicard/ai-build-kit/contents/.agents/skills/maintain/scripts/kit-released-copies.json?ref=<latest VERSION>' > .agents/tmp/kit-released-copies-next.json`.
Run `scripts/kit-local-edits.py --record <downloaded record> --skills <installed skills folder>`.
It reads every file in the kit's installed skill folders, including committed
edits. Exit 0 adds nothing to the offer. Exit 1: name each `local-edit` file,
give the `say` line and require approval naming those files before replacement.
With that approval, rerun with `--approved --overwrite <file>` for each file
and `--run <update command>`; it checks again before running the command.
Without approval, leave those files in place. Exit 2, or a failed download:
report that local edits could not be checked and do not replace the skills.
For plugin routes, the skills folder is in the installed plugin, outside the
project. Check the selected route's folder before its plugin update too.
