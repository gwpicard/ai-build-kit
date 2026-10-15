# Queued and automatic merges

## Queue and conflicts

Where several pieces wait, name each pull request on its own line. A yes covers
only the ones named, or all when the person plainly says so, such as “merge
both”. If merging one leaves another `CONFLICTING`, the same yes covers bringing
`main` into it only when the records settle the conflict plainly. A conflict
that needs a question, or touches data, a migration, deployment settings or a
sensitive area, needs a new yes. After bringing in `main`, rerun the project
and live checks before merging.

Say which intentions collided. Resolve only when the records make the outcome
clear; otherwise keep both sides and ask. Never force-push or rebase.

## Automatic merge

`--auto` is available only when `Runs on its own:` on `main` records the
person's words and date. It holds for red, missing or pending checks, open
review findings, touched sensitive areas, migrations, new settings, live
requirements, repairs and `(try it)` items. It requires three earlier merges made through `--approved` and a branch containing the newest `main`. The merge script checks that the branch is current before any merge mode proceeds.

The automatic holds and the main-only setting govern `--auto`; no extra Claude
permission rule is needed. If a check on `main` or the live check fails after
an automatic merge, pause with `scripts/merge.py --pause "live check failed"`.
Only the person may clear that pause with `scripts/merge.py --resume`.

An unattended run merges only through `--auto` when the setting is on. It never
merges unattended through another route.
