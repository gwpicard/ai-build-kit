#!/usr/bin/env sh
# recipe-nextjs-supabase-on-coolify.sh: run the Coolify recipe through the
# shape check, and every script it names through stand-ins for its tools and
# through pasted answers from the server. If this breaks, a script misreads
# what the person pastes back, or a check that needs the server slides back to
# "the kit", which has promised never to contact it.
# The recipe folder is recipes/nextjs-supabase-on-coolify.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/recipe-rehearsal.sh"

rr_init "Next.js and Supabase on Coolify recipe"
rr_locate "$ROOT/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-coolify"
rr_shape

# Every section this recipe writes needs the server, so each is run by the
# companion or the person and read back. The shared parts are the kit's.
rr_who=$(sed -n 's/^Who runs it: //p' "$RR_RECIPE/recipe.md" | sort -u)
rr_report "every check this recipe writes is run by the companion or the person and read back" \
  "$([ "$rr_who" = "a companion or the person, result read back" ] && echo yes || echo no)"
rr_count=$(grep -c '^Who runs it: ' "$RR_RECIPE/recipe.md" || true)
rr_report "all five sections that need the server say so" "$([ "$rr_count" -eq 5 ] && echo yes || echo no)"
rr_asks=$(grep -c '^Ask: ' "$RR_RECIPE/recipe.md" || true)
rr_report "each of the five gives the words the person hears" "$([ "$rr_asks" -eq 5 ] && echo yes || echo no)"

# What is pasted back: a good answer passes, the thing each check exists to
# catch fails it, and nothing pasted yet could not be checked.
for rr_section in preview going-live rollback secrets logs; do
  rr_case 0 good "$rr_section.sh" --pasted "$(rr_paste good "$rr_section")"
  rr_case 1 good "$rr_section.sh" --pasted "$(rr_paste bad "$rr_section")"
  rr_case 2 good "$rr_section.sh"
done
rr_case 0 good SHARED_PREVIEW=yes preview.sh --pasted "$(rr_paste bad preview)"
# Only the newest deployment's status counts, the health check's values must
# sit in its own settings, and an image needs a tag. A paste the script
# cannot read with confidence asks again in the recipe's words.
rr_case 0 good preview.sh --pasted "$(rr_paste older-failed preview)"
rr_case 0 good going-live.sh --pasted "$(rr_paste older-failed going-live)"
rr_case 1 good going-live.sh --pasted "$(rr_paste newest-failed going-live)"
rr_case 1 good going-live.sh --pasted "$(rr_paste wrong-port going-live)"
rr_case 2 good going-live.sh --pasted "$(rr_paste unlabelled going-live)"
rr_said yes "$(sed -n '/^## Going live$/,/^## /s/^Ask: //p' "$RR_RECIPE/recipe.md")"
rr_case 2 good rollback.sh --pasted "$(rr_paste untagged rollback)"
rr_said yes "$(sed -n '/^## Rollback$/,/^## /s/^Ask: //p' "$RR_RECIPE/recipe.md")"
rr_case 2 good secrets.sh --pasted "$(rr_paste value secrets)"
# The kit's own half of going live: the table read.
rr_case 1 bad going-live.sh --pasted "$(rr_paste good going-live)"
rr_case 2 down going-live.sh --pasted "$(rr_paste good going-live)"

# The live check: the pasted health and names, and the kit's migration read.
rr_case 0 good live-check.sh --pasted-health "$(rr_paste good live-health)" --pasted-names "$(rr_paste good live-names)"
rr_case 1 good live-check.sh --pasted-health "$(rr_paste bad live-health)" --pasted-names "$(rr_paste good live-names)"
rr_case 1 good live-check.sh --pasted-health "$(rr_paste good live-health)" --pasted-names "$(rr_paste bad live-names)"
rr_case 1 bad live-check.sh --only migration
rr_case 2 good live-check.sh

# The hosting request, filled from the project.
rr_case 0 good hosting-request.sh --lane internal
rr_case 0 good hosting-request.sh --lane public
rr_case 2 good hosting-request.sh --lane outside
rr_case 2 good GIT_DIR=/nonexistent hosting-request.sh
printf 'FROM node:22-slim\nCMD ["node", "server.js"]\n' > "$RR_TMP/fixture/Dockerfile"
rr_case 1 good hosting-request.sh
for rr_bind in 'ENV HOSTNAME="0.0.0.0"' "ENV HOSTNAME='0.0.0.0'" 'ENV HOSTNAME 0.0.0.0'; do
  printf 'FROM node:22-alpine\n%s\nCMD ["node", "server.js"]\n' "$rr_bind" > "$RR_TMP/fixture/Dockerfile"
  rr_case 0 good hosting-request.sh
done
# A remote address holding a sign-in is printed without it.
RR_ORIGIN=https://someone:token-stand-in@github.com/team/app.git
rr_case 0 good hosting-request.sh
RR_ORIGIN=
rr_said no "token-stand-in"
rr_said yes "Repo:          https://github.com/team/app.git, branch main"
printf 'FROM node:22-alpine\nENV HOSTNAME=0.0.0.0 PORT=3000\nCMD ["node", "server.js"]\n' > "$RR_TMP/fixture/Dockerfile"

# The shared parts this recipe names.
rr_case 0 good migrate.sh
rr_case 1 bad migrate.sh
rr_case 2 down migrate.sh
rr_case 0 good migrate.sh --apply liveref
rr_case 0 good container-check.sh
rr_case 1 bad container-check.sh
rr_case 2 down container-check.sh
rr_case 0 good backup.sh
rr_case 1 bad backup.sh
rr_case 2 down backup.sh
rr_case 0 good restore.sh
rr_case 1 bad RR_RESTORE=1 restore.sh
rr_case 2 down restore.sh
rr_case 0 good settings.sh
rr_case 1 bad settings.sh
rr_case 2 down settings.sh

rr_scripts
echo
echo "recipe-nextjs-supabase-on-coolify.sh: all checks passed"
