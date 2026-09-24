#!/usr/bin/env sh
# recipe-nextjs-supabase-on-coolify.sh: guard the recipe for Next.js and hosted
# Supabase on Coolify, offline.
#
# On this pair the app runs on a server the kit never contacts. So the rule
# held hardest is who runs each check: every check that needs the server is run
# by the hosting companion or the person, and the kit reads back what they
# paste. A section that slid back to "the kit" would have the kit reaching for
# a server it has promised never to touch. The data half is the same hosted
# Supabase as the Vercel recipe, and the kit runs those checks itself.
#
# It also holds the image that makes the app hostable at all: a standalone
# Next.js build bound to 0.0.0.0, on an image that carries wget, because the
# server runs its health check from inside the container. And it holds the two
# hosting request fields that say so, Build and Bind.
#
# It runs every command the recipe writes against stand-ins for its tools, and
# holds the recipe out of the menu until its real run is recorded. The recipe
# file is recipes/nextjs-supabase-on-coolify.md.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"
. "$ROOT/.agents/tests/lib/recipe-rehearsal.sh"

rs_init "Next.js and Supabase on Coolify recipe"
rr_locate "$ROOT/.agents/skills/ship/recipes/nextjs-supabase-on-coolify.md"
rr_shape

# Preview.
rs_rule "each pull request gets its own preview" '\{\{pr_id\}\}\.preview\.<domain>'
rs_rule "previews never reach the live database" 'a second supabase project kept for previews, never at the live one'
rs_rule "the kit never contacts the server" 'the kit never contacts the server, so the person or the hosting companion reads the preview'
rs_rule "the preview answers from its own project" 'a .project. that is not the live project.s reference'

# Going live.
rs_rule "migrations run before the build that needs them" 'the kit applies new migrations to the live database first, because coolify does not run them'
rs_rule "a migration in a release only adds" 'a migration in a release only adds'
rs_rule "row-level security off is named once" 'names once any finding called .rls_disabled_in_public.'
rs_rule "the image is built locally first" 'builds the image locally with .docker build \.., so a dockerfile that fails is found on the person.s machine'
rs_rule "the new container waits for its health check" 'swaps the new container in once its health check passes'
rs_rule "the request says how it builds" 'build: dockerfile at root, image has curl or wget'
rs_rule "the request says it binds to every address" 'bind: 0\.0\.0\.0'
rs_rule "the live commit is the one on main" 'a .commit. equal to .git rev-parse origin/main.'

# Rollback.
rs_rule "a rollback redeploys a kept image" 'redeploys its kept image, with no new build'
rs_rule "a rollback leaves migrations alone" 'a rollback does not undo database migrations'
rs_rule "the rollback is read back from the health route" 'is the earlier commit rather than the one rolled back'

# Backup and restore come from the shared parts.
rs_rule "backup links the shared part" '## backup shared part: \[backup on hosted supabase\]\(parts/supabase-backup\.md\)'
rs_rule "restore links the shared part" '## restore shared part: \[restore on hosted supabase\]\(parts/supabase-restore\.md\)'

# Secrets.
rs_rule "the request carries names and never a value" 'the hosting request carries the names of the environment variables and never a value'
rs_rule "the service role key never reaches the browser" 'the service role key stays on the server and never carries that prefix'
rs_rule "the pasted list carries names only" 'pastes back the list of names set in coolify, with no values'
rs_rule "no public name carries a secret" 'no name that starts with .next_public_. contains .service_role. or .secret.'

# Logs.
rs_rule "the kit cannot read the server's logs" 'the kit cannot read it, since it never contacts the server'
rs_rule "an error from the new build is named" 'names to the person any error from the new build'

# Health.
rs_rule "Next.js builds standalone" 'output: "standalone"'
rs_rule "the server listens on every address" 'hostname=0\.0\.0\.0'
rs_rule "the image carries wget for the health check" 'starts from a node alpine image, which carries .wget.'
rs_rule "a slim image fails every check" 'a slim image without .curl. or .wget. fails every check'
rs_rule "the health route makes a real round trip" 'that route makes one real round trip to the database'
rs_rule "it is never answered from a build-time copy" 'export const dynamic = "force-dynamic"'
rs_rule "the commit comes from the server" 'the commit comes from .source_commit.'
rs_guard "$RR_RECIPE" "the Coolify recipe"

# Who runs each check. The kit never contacts the server, so every section
# written in this recipe is run by the companion or the person and read back.
# The two parts are the kit's, since they reach Supabase and not the server.
rr_who=$(sed -n 's/^Who runs it: //p' "$RR_RECIPE" | sort -u)
rs_report "every check this recipe writes is run by the companion or the person and read back" \
  "$([ "$rr_who" = "a companion or the person, result read back" ] && echo yes || echo no)"
rr_count=$(grep -c '^Who runs it: ' "$RR_RECIPE" || true)
rs_report "all six sections that need the server say so" "$([ "$rr_count" -eq 6 ] && echo yes || echo no)"
awk '!done && /^Who runs it: / { print "Who runs it: the kit"; done = 1; next } { print }' "$RR_RECIPE" > "$rs_dir/kit-runs-it.md"
rr_who=$(sed -n 's/^Who runs it: //p' "$rs_dir/kit-runs-it.md" | sort -u)
rs_report "a copy where the kit runs a server check is caught" \
  "$([ "$rr_who" != "a companion or the person, result read back" ] && echo yes || echo no)"

rr_guard_supabase_parts
rr_stand_ins
rs_done
