#!/usr/bin/env sh
# recipe-nextjs-supabase-on-coolify.sh: run the Coolify recipe through the
# shape check and every command it writes through stand-ins for its tools. If
# this breaks, a mistyped command reaches the menu, or a check that needs the
# server slides back to "the kit", which has promised never to contact it.
# The recipe file is recipes/nextjs-supabase-on-coolify.md.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/recipe-rehearsal.sh"

rr_init "Next.js and Supabase on Coolify recipe"
rr_locate "$ROOT/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-coolify.md"
rr_shape

# Every section this recipe writes needs the server, so each is run by the
# companion or the person and read back. The shared parts are the kit's.
rr_who=$(sed -n 's/^Who runs it: //p' "$RR_RECIPE" | sort -u)
rr_report "every check this recipe writes is run by the companion or the person and read back" \
  "$([ "$rr_who" = "a companion or the person, result read back" ] && echo yes || echo no)"
rr_count=$(grep -c '^Who runs it: ' "$RR_RECIPE" || true)
rr_report "all five sections that need the server say so" "$([ "$rr_count" -eq 5 ] && echo yes || echo no)"
awk '!done && /^Who runs it: / { print "Who runs it: the kit"; done = 1; next } { print }' "$RR_RECIPE" > "$RR_TMP/kit-runs-it.md"
rr_who=$(sed -n 's/^Who runs it: //p' "$RR_TMP/kit-runs-it.md" | sort -u)
rr_report "a copy where the kit runs a server check is caught" \
  "$([ "$rr_who" != "a companion or the person, result read back" ] && echo yes || echo no)"

rr_stand_ins
echo
echo "recipe-nextjs-supabase-on-coolify.sh: all checks passed"
