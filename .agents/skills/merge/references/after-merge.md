# After the merge

**After the merge, held after a rollback.** Say: "This is merged. The live
copy stays on the earlier version until /setup-hosting puts this change live."
Do not read the health line as "did not update", and suggest no redeploy.

**After the merge, live on a recipe.** Once the host has had time to build,
read the live copy with the recipe's `live-check.sh --only commit` and
`--address` set to the recorded live address. Where the recipe reads health
from a paste, ask for the live address's health answer and pass it with
`--pasted-health`. Exit 0: "The live copy now runs this change." Otherwise read
the host's list of deployments where the recipe names a command, or ask for it.
A build still running: say so, wait, and read again; never suggest a second
deploy. Only where the build failed or is missing, say "The live copy did not
update," and point at /setup-hosting to compare the live copy with `main`. Off
a recipe, say the change reaches the live copy the way the project's hosting
works, and claim no more than you saw.

After an automatic merge, a red check on `main` pauses automatic merging
before the next piece. A failed live check pauses it too: run
`scripts/merge.py --pause "live check failed"` and tell
the person what failed in one line. Keep the
pause until the person asks to turn merging on again; then run
`scripts/merge.py --resume`.

Change nothing live after the merge: no deploy, no rollback, no second push to
`main`. Asked to put the change out again, read the health line again and say
what it shows; a further deploy belongs to /setup-hosting. Asked whether they
can go back, say what the recipe's rollback section offers, that a rollback
has not been tried, and run none here. A live break after this merge goes to
the `live-copy` skill's "Rolling back", which asks its own yes.
