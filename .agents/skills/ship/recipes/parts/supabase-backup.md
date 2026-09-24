# Shared part: backup on hosted Supabase

Every recipe whose data lives in a hosted Supabase project links this part. The
backup reads the same wherever the app itself runs.

How it works: On a paid plan, Supabase takes a daily backup of the database and keeps it for a set number of days: seven on Pro and fourteen on Team. The Free plan takes none, so on Free the kit takes its own after each launch with `supabase db dump --linked --role-only -f roles.sql`, `supabase db dump --linked -f schema.sql` and `supabase db dump --linked --data-only --use-copy -f data.sql`. The three files go into a dated folder outside the repository, which the team keeps somewhere safe. A daily backup holds neither the passwords of custom roles nor the files in Storage, so for a tool that keeps uploaded files the kit names that gap once and records it.
How it is checked: On a paid plan, `curl -fsS -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" https://api.supabase.com/v1/projects/<project ref>/database/backups` lists a backup taken in the last day. On Free, the dated folder holds all three files from today, and `data.sql` is not empty. The access token comes from the person's environment, and the kit never prints it or writes it down.
Who runs it: the kit
