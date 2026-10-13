#!/usr/bin/env sh
# backup.sh: check the hosted Supabase database has a backup from today.
#
# Usage: backup.sh
#
# On a paid plan (PLAN=paid) Supabase takes a daily backup, and this reads its
# list with the person's access token, `SUPABASE_ACCESS_TOKEN`, never printed:
# a backup from the last day, or point-in-time recovery switched on, passes.
#
# On the Free plan (PLAN=free, the default) Supabase takes none, so this takes
# one: three dumps of the linked project, roles, structure and data, into a
# dated folder under BACKUP_DIR, which must sit outside the repository. A
# dump needs Docker running and the database password, read from the file
# DB_PASSWORD_FILE names. All three files from today, with `data.sql` not
# empty, pass. The two storage tables the official backup guide leaves out
# are left out here.
#
# Exit 0 when today's backup is there, 1 when it is not, 2 when the check
# could not run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../../scripts/check-lib.sh"

ref=$(cl_ref)
[ -n "$ref" ] || cl_cannot "The kit does not know which database project this is, so the backup could not be checked."

if [ "${PLAN:-free}" = paid ]; then
  cl_need curl
  [ -n "${SUPABASE_ACCESS_TOKEN:-}" ] ||
    cl_cannot "No Supabase access token is set on this computer, so the backup list could not be read."
  list=$(curl -fsS -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" "https://api.supabase.com/v1/projects/$ref/database/backups" 2>/dev/null) ||
    cl_cannot "Supabase did not answer the backup list, so the backup could not be checked."
  verdict=$(printf '%s' "$list" | python3 -c '
import datetime, json, sys
data = json.load(sys.stdin)
if data.get("pitr_enabled"):
    print("pitr"); sys.exit()
now = datetime.datetime.now(datetime.timezone.utc)
for backup in data.get("backups", []):
    when = str(backup.get("inserted_at", ""))[:19]
    try:
        taken = datetime.datetime.strptime(when, "%Y-%m-%dT%H:%M:%S").replace(tzinfo=datetime.timezone.utc)
    except ValueError:
        continue
    if now - taken <= datetime.timedelta(days=1):
        print("today"); sys.exit()
print("none")
' 2>/dev/null)
  case "$verdict" in
    pitr) cl_pass "Supabase keeps a running backup of the database, with point-in-time recovery switched on." ;;
    today) cl_pass "Supabase took a backup of the database in the last day." ;;
    *) cl_fail "Supabase lists no backup of the database from the last day." ;;
  esac
fi

cl_need supabase docker
docker info >/dev/null 2>&1 ||
  cl_cannot "Docker's engine is not running on this computer, so the backup could not be taken."
[ -n "${BACKUP_DIR:-}" ] ||
  cl_cannot "No folder for backups was named, so the backup could not be taken."
top=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
mkdir -p "$BACKUP_DIR" 2>/dev/null ||
  cl_cannot "The backup folder could not be made, so the backup could not be taken."
folder=$(CDPATH= cd -- "$BACKUP_DIR" && pwd -P)
case "$folder/" in
  "$(CDPATH= cd -- "$top" && pwd -P)/"*) cl_cannot "The backup folder is inside the repository, so the backup was not taken there." ;;
esac
cl_password

folder="$folder/$(date +%Y-%m-%d)"
mkdir -p "$folder"
supabase db dump --linked --role-only -f "$folder/roles.sql" >&2 &&
  supabase db dump --linked -f "$folder/schema.sql" >&2 &&
  supabase db dump --linked --data-only --use-copy -x storage.buckets_vectors -x storage.vector_indexes -f "$folder/data.sql" >&2 ||
  cl_fail "The backup was not taken: a dump of the database failed."
for file in roles.sql schema.sql data.sql; do
  [ -f "$folder/$file" ] || cl_fail "The backup is incomplete: $file is missing from $folder."
done
[ -s "$folder/data.sql" ] || cl_fail "The backup's data file is empty, so it holds nothing to put back."
cl_pass "Backup taken today into $folder: roles, structure and data."
