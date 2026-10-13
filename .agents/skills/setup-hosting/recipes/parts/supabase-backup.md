# Shared part: backup on hosted Supabase

Every recipe whose data lives in a hosted Supabase project links this part. The
backup reads the same wherever the app itself runs.

How it works: On a paid plan, Supabase takes a daily backup of the database and keeps it for a set number of days: seven on Pro and fourteen on Team. The script reads that list with the person's access token, with `PLAN=paid`. The Free plan takes none, so on Free the kit takes its own after each launch: three dumps of the linked project, roles, structure and data, into a dated folder under `BACKUP_DIR`, outside the repository, which the team keeps somewhere safe. A dump needs Docker running and the database password, read from where the masterplan says it is kept. A daily backup holds neither the passwords of custom roles nor the files in Storage, so for a tool that keeps uploaded files the kit names that gap once and records it.
How it is checked: On a paid plan, a backup from the last day is listed, or point-in-time recovery is on. On Free, today's folder holds all three files and `data.sql` is not empty.
Script: scripts/backup.sh
Who runs it: the kit
