# A later run

Rerun the fit check first if reliance, data or consequence has grown. Then
compare, changing nothing, as the `live-copy` skill's "Comparing the live
copy with main" says. Say each gap in one line.

Repair each gap only after a yes that names it, saying what it changes and
whether it can be undone. A migration is applied with the shared
`migrate.sh --apply`, once, before the merge that needs it. A piece's
migration not yet on `main` is applied from a temporary checkout of its
branch, removed afterwards; then say /implement can ask for the merge.

Then run `.agents/skills/setup-hosting/scripts/run-recipe.sh --later <recipe
from AGENTS.md>`, with a first launch's values and a `--note` for each gap repaired or left. It writes the run's one dated entry,
gap or no gap, with its rollback line. A recorded hosting request is read
back as the recipe's file says. Moving to another host or recipe is a later
run too: run the
new recipe as a first launch while the old copy keeps serving, change the
`Recipe:` line and the address only once the new one answers, and say how to
switch the old one off.
