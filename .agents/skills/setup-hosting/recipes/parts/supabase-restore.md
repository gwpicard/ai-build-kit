# Shared part: restore on hosted Supabase

Every recipe whose data lives in a hosted Supabase project links this part. The
restore test never touches the live database. It proves a copy can be put back
by putting one back on the person's own machine.

How it works: The script dumps the live project three times, leaves the project's own local database running, and starts an empty, labelled local copy in a throwaway folder outside the project, with the live project's service versions copied across so the data loads. It loads the three files as `supabase_admin` in one transaction, counts each table's rows, and removes the local copy afterwards. The minutes from the first dump to the last count are the restore time. Putting a daily backup back onto the live project starts from the Supabase dashboard, and nobody can reach the project while it runs.
The temporary copy still needs the default local ports, including database port 54322. If one is occupied, startup fails and the check reports that it could not run. Leave the other service running; identify its owner and arrange a safe time to stop it, or run the check on another computer with those ports free. Then repeat the check.

How it is checked: For every table in `data.sql`, its rows equal `select count(*)` on that table in the local copy, and at least one table holds rows. A restore that loads nothing passes no test.
Script: scripts/restore.sh
Who runs it: the kit
