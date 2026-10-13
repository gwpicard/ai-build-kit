#!/usr/bin/env sh
# recipe-nextjs-supabase-on-vercel.sh: run the Vercel recipe through the shape
# check and every command it writes through stand-ins for its tools. If this
# breaks, a recipe with a mistyped command or a missing section reaches the
# menu, and the person meets the mistake on launch day.
# The recipe file is recipes/nextjs-supabase-on-vercel.md.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/recipe-rehearsal.sh"

rr_init "Next.js and Supabase on Vercel recipe"
rr_locate "$ROOT/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel.md"
rr_shape

# Only the preview is left to a person, because Vercel puts a sign-in in front
# of it; the kit runs every other check itself.
rr_who=$(sed -n 's/^Who runs it: //p' "$RR_RECIPE" | sort | uniq -c | tr -s ' ' | sed 's/^ //')
rr_report "the preview is the one check a person looks at, and the kit runs the rest" \
  "$([ "$rr_who" = "$(printf '1 a person looking\n4 the kit')" ] && echo yes || echo no)"

rr_stand_ins
echo
echo "recipe-nextjs-supabase-on-vercel.sh: all checks passed"
