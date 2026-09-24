# Shared part: restore on hosted Supabase

Every recipe whose data lives in a hosted Supabase project links this part. The
restore test never touches the live database. It proves a copy can be put back
by putting one back on the person's own machine.

How it works: The kit dumps the live project three times with `supabase db dump --linked`: with `--role-only` into `roles.sql`, with no option into `schema.sql`, and with `--data-only --use-copy` into `data.sql`. It checks that Docker is running with `docker info`, starts an empty local database with `supabase start`, and loads the three files into it with `psql --single-transaction --variable ON_ERROR_STOP=1 --file roles.sql --file schema.sql --command 'SET session_replication_role = replica' --file data.sql --dbname postgresql://postgres:postgres@127.0.0.1:54322/postgres`. The minutes from the first dump to the last count are written down as the restore time. Putting a daily backup back onto the live project starts from the Supabase dashboard, and nobody can reach the project while it runs.
How it is checked: For every table in `data.sql`, the number of rows between its `COPY` line and the closing `\.` equals `select count(*)` on that table in the local database, and at least one table holds rows. A restore that loads nothing passes no test. Afterwards, `supabase stop --no-backup` removes the local copy.
Who runs it: the kit
