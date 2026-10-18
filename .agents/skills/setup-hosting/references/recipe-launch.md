# Recipe launch

## No recipe

Run `scripts/run-recipe.sh none`. It prints one notice and exits 5. Give the
notice in plain words and ask whether to go on. On a yes, run it again with
`--chose "<their words>"`, the request record and alert answers and the address
the person gives. It records their words and the date, holds nothing and checks
nothing. Later runs print a pointer, not the notice. Then help by hand. Never
call anything it set up guaranteed.

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
