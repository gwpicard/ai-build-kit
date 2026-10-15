# Recipe launch

For a recipe, run the commands below. Off-recipe, run
`scripts/run-recipe.sh none` with the request record and alert answers and the
address the person gives. It reports section names and general readiness as
warnings.

Run `scripts/run-recipe.sh <recipe>` with `LIVE_ADDRESS`, the database
password's file path, `BACKUP_DIR` outside the repository, and the request
record and alert answers. First run `--asks`, then pass each printed question
back verbatim. Submit pasted answers and what the person saw with `--pasted`
and `--looked`.

Report runner lines as printed. Exit 0 passes. Exit 1 records warnings but
does not hold launch; a repeated warning is only a pointer. When asked what
remains, give its `Left:` line alone. Exit 3 means no live address is recorded.
Record the address and say once that each merge made by `/implement` puts its
change live.
