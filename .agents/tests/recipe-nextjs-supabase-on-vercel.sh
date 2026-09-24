#!/usr/bin/env sh
# recipe-nextjs-supabase-on-vercel.sh: guard the recipe for Next.js and hosted
# Supabase on Vercel, offline.
#
# A recipe is what the kit checks a live tool against, so a rule that quietly
# leaves it is a launch step nobody checks. The rules held hardest are the ones
# whose loss would look harmless: previews never touch the live database,
# migrations run before the build that needs them and only add, a rollback
# stops later pushes going live until somebody promotes again, the health
# route makes a real round trip and is never answered from a build-time copy,
# and the secrets check reads names and never a value.
#
# It also runs every command the recipe writes against stand-ins for its
# tools, and holds the recipe out of the menu until its real run is recorded.
# The recipe file is recipes/nextjs-supabase-on-vercel.md.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"
. "$ROOT/.agents/tests/lib/recipe-rehearsal.sh"

rs_init "Next.js and Supabase on Vercel recipe"
rr_locate "$ROOT/.agents/skills/ship/recipes/nextjs-supabase-on-vercel.md"
rr_shape

# Preview.
rs_rule "previews never reach the live database" 'a second supabase project kept for previews, never at the live one'
rs_rule "the kit waits for the preview to be ready" 'waits until .vercel inspect <preview address>. reports the deployment as ready'
rs_rule "a protected preview is opened by the person" 'vercel protects preview addresses with a sign-in by default'
rs_rule "the preview answers from its own project" 'a .project. that is not the live project.s reference'

# Going live.
rs_rule "migrations run before the build that needs them" 'the kit applies new migrations to the live database first, because vercel does not run them'
rs_rule "a dry run lists the migrations first" '.supabase db push --dry-run. lists what would change'
rs_rule "a migration in a release only adds" 'a migration in a release only adds'
rs_rule "row-level security off is named once" 'names once any finding called .rls_disabled_in_public.'
rs_rule "the live commit is the one on main" 'its .commit. equals .git rev-parse origin/main.'

# Rollback.
rs_rule "rollback reaches back one build on Hobby" 'on the hobby plan only the build just before is eligible'
rs_rule "a rollback stops later pushes going live" 'stops moving new pushes to production until .vercel promote. is run on a newer build'
rs_rule "the person hears that in the same reply" 'the kit says so in the same reply'
rs_rule "a rollback leaves migrations alone" 'a rollback does not undo database migrations'
rs_rule "the rollback is read back from the health route" 'is the earlier commit rather than the one rolled back'

# Backup and restore come from the shared parts.
rs_rule "backup links the shared part" '## backup shared part: \[backup on hosted supabase\]\(parts/supabase-backup\.md\)'
rs_rule "restore links the shared part" '## restore shared part: \[restore on hosted supabase\]\(parts/supabase-restore\.md\)'

# Secrets.
rs_rule "the service role key never reaches the browser" 'the service role key stays on the server and never carries that prefix'
rs_rule "production values are never pulled" 'never runs .vercel env pull. for production'
rs_rule "the secrets check reads names only" 'lists every name in .\.env\.example. and no value'
rs_rule "no public name carries a secret" 'no name that starts with .next_public_. contains .service_role. or .secret.'

# Logs.
rs_rule "errors are read from production" 'vercel logs --environment production --level error --since 1h --json'
rs_rule "an error from the new build is named" 'names to the person any error from the new build'

# Health.
rs_rule "the health route makes a real round trip" 'it makes one real round trip to the database'
rs_rule "it is never answered from a build-time copy" 'export const dynamic = "force-dynamic"'
rs_rule "the commit comes from the build" 'the commit comes from .vercel_git_commit_sha.'
rs_rule "a failed query is not called up" 'answers 503 rather than claiming the tool is up'
rs_guard "$RR_RECIPE" "the Vercel recipe"

# Who runs each check. Only the preview is left to a person, because Vercel
# puts a sign-in in front of it; every other check the kit can run itself.
rr_who=$(sed -n 's/^Who runs it: //p' "$RR_RECIPE" | sort | uniq -c | tr -s ' ' | sed 's/^ //')
rs_report "the preview is the one check a person looks at, and the kit runs the rest" \
  "$([ "$rr_who" = "$(printf '1 a person looking\n5 the kit')" ] && echo yes || echo no)"

rr_guard_supabase_parts
rr_stand_ins
rs_done
