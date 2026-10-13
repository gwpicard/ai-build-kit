#!/usr/bin/env sh
# recipe-nextjs-supabase-on-vercel.sh: run the Vercel recipe through the shape
# check, and every script it names through stand-ins for its tools. If this
# breaks, a recipe whose script mistypes a command, misses what it exists to
# catch, or says a check passed when it could not run reaches the menu, and the
# person meets the mistake on launch day.
# The recipe folder is recipes/nextjs-supabase-on-vercel.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/recipe-rehearsal.sh"

rr_init "Next.js and Supabase on Vercel recipe"
rr_locate "$ROOT/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel"
rr_shape

# Only the preview is left to a person, because Vercel puts a sign-in in front
# of it; the kit runs every other check itself.
rr_who=$(sed -n 's/^Who runs it: //p' "$RR_RECIPE/recipe.md" | sort | uniq -c | tr -s ' ' | sed 's/^ //')
rr_report "the preview is the one check a person looks at, and the kit runs the rest" \
  "$([ "$rr_who" = "$(printf '1 a person looking\n4 the kit')" ] && echo yes || echo no)"

# The first launch.
rr_case 0 good connect.sh rehearsal-app
rr_case 1 bad connect.sh rehearsal-app
rr_case 1 down connect.sh rehearsal-app
rr_case 2 good connect.sh

# Preview: built and Ready, then its health read only after the person's yes.
rr_case 0 good PREVIEW_ADDRESS=https://preview.example.test preview.sh
rr_case 0 good PREVIEW_ADDRESS=https://preview.example.test PREVIEW_HEALTH=yes preview.sh
rr_case 1 bad PREVIEW_ADDRESS=https://preview.example.test preview.sh
rr_case 1 good PREVIEW_ADDRESS=https://preview.example.test PREVIEW_HEALTH=yes LIVE_REF=previewref preview.sh
rr_case 2 good preview.sh
rr_case 2 down PREVIEW_ADDRESS=https://preview.example.test preview.sh

# Going live: main is live, and no table is open to the public key.
rr_case 0 good going-live.sh
rr_case 1 bad going-live.sh
rr_case 2 good LIVE_ADDRESS= going-live.sh

# Rollback: possible when an earlier build is listed, and never tried here.
rr_case 0 good rollback.sh
rr_said yes "from 2026-01-01"
rr_case 0 good RR_HELD=1 LIVE_ADDRESS=https://app.example.test/ rollback.sh
rr_said yes "from 2026-01-01"
rr_case 1 bad rollback.sh
rr_case 2 down rollback.sh
rr_main=$(git -C "$RR_TMP/fixture" rev-parse main)
rr_case 0 good roll-back-to.sh dpl_earlier "$rr_main"
rr_case 1 bad roll-back-to.sh dpl_earlier "$rr_main"
rr_case 2 good roll-back-to.sh
rr_case 0 good promote.sh dpl_live "$rr_main"
rr_case 1 bad promote.sh dpl_live "$rr_main"
rr_case 2 good promote.sh

# Secrets: every name on the host, no public secret, nothing committable.
rr_case 0 good secrets.sh
rr_case 1 bad secrets.sh
rr_case 2 down secrets.sh
printf 'a-value\n' > "$RR_TMP/value"
RR_STDIN="$RR_TMP/value"
rr_case 0 good add-secret.sh SUPABASE_SERVICE_ROLE_KEY
rr_case 0 good add-secret.sh NEXT_PUBLIC_SUPABASE_URL
rr_case 1 bad add-secret.sh SUPABASE_SERVICE_ROLE_KEY
rr_case 2 good add-secret.sh
RR_STDIN=

# Logs, and the live check every later run and /maintain visit makes.
rr_case 0 good logs.sh
rr_case 1 bad logs.sh
rr_case 2 down logs.sh
rr_case 0 good live-check.sh
rr_case 1 bad live-check.sh
rr_case 0 good live-check.sh --only hold
rr_case 1 good RR_HELD=1 live-check.sh --only hold
rr_case 2 down live-check.sh --only migration
rr_case 2 good live-check.sh --only nothing

# The shared parts this recipe names.
rr_case 0 good migrate.sh
rr_case 1 bad migrate.sh
rr_case 2 down migrate.sh
rr_case 2 good DB_PASSWORD_FILE= migrate.sh
rr_case 0 good migrate.sh --apply liveref
rr_case 1 bad migrate.sh --apply liveref
rr_case 0 good rls.sh
rr_case 1 bad rls.sh
rr_case 0 bad rls.sh --on-record notices
rr_case 2 down rls.sh
rr_case 0 good keep-out-of-git.sh
rr_case 2 good GIT_DIR=/nonexistent keep-out-of-git.sh
rr_case 0 good container-check.sh
rr_case 1 bad container-check.sh
rr_case 2 down container-check.sh
rr_case 0 good backup.sh
rr_case 1 bad backup.sh
rr_case 2 down backup.sh
rr_case 0 good PLAN=paid SUPABASE_ACCESS_TOKEN=stand-in backup.sh
rr_case 1 bad PLAN=paid SUPABASE_ACCESS_TOKEN=stand-in backup.sh
rr_case 2 good PLAN=paid backup.sh
rr_case 0 good restore.sh
rr_case 1 bad RR_RESTORE=1 restore.sh
rr_case 2 down restore.sh
rr_case 0 good settings.sh
rr_case 1 bad settings.sh
rr_case 2 down settings.sh

rr_scripts
echo
echo "recipe-nextjs-supabase-on-vercel.sh: all checks passed"
