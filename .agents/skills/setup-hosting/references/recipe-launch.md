# Recipe launch

## No recipe

Run `scripts/run-recipe.sh none`. It prints one notice and exits 5. Say the
notice plainly and ask whether to go on. On a yes, run it again with
`--chose "<their words>"`, the usual answers and the address. It records their
words and the date and holds nothing. A later run gives no second notice. Then
help by hand, and call nothing guaranteed.

## On a recipe

Run `scripts/run-recipe.sh <recipe>` with `LIVE_ADDRESS`, the database
password's file path, `BACKUP_DIR` outside the repository, and the request
record and alert answers. First run `--asks`, then pass each printed question
back verbatim. Submit pasted answers and what the person saw with `--pasted`
and `--looked`.

Report runner lines as printed. Exit 0 passes. Exit 1 records warnings but
does not hold launch; a repeated warning is only a pointer. When asked what
remains, give its `Left:` line alone. Exit 3 means no live address is recorded.
Exit 4 means no way back or no backup: give its `Launch held:` line and its one
step, do not record the address, and stop.
Record the address and say once that each merge made by `/implement` puts its
change live.
