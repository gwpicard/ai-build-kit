# Proven: Next.js and Supabase on Vercel

Real run: 2026-10-16
Last proven: 2026-10-23
Versions: Next.js 16.4.2; Supabase CLI 2.117; Vercel CLI 60.0.0

Preview: Not tried. Preview isolation awaits a second Supabase project.
Going live: Production `/api/health` returned 200 on 16 October 2026 at commit `29f8b0c`.
Rollback: Not tried.
Backup: Not tried.
Restore: Not tried.
Secrets: Not tried.
Logs: Not tried.
Health: On 2026-10-23, the existing test deployment returned HTTP 200 with `database: "reachable"`. The previous health reader rejected that answer; the repaired reader passed against the same live address. The shared container check built the supplied starter against a real local Supabase database and confirmed HTTP 200, then rebuilt it with an invalid database address and confirmed HTTP 503. The script retries requests while the container starts. This run did not redeploy the hosted app or test other hosting steps.
Access: Not tried. Before the Access step, `/`, `/login` and `/admin/setup` returned 200 without sign-in.
Settings the kit can read: Not tried.
Migration: Two migrations were applied once.
Founding: Not tried.

User interface: No real run yet; added 2026-10-23.

Project check: No real run yet; CI workflow added 2026-10-23. The first green pull request still needs a real GitHub run.

## Release decision: 2026-11-05, v1.2.6

The backup, restore and container checks now label their Docker resources and
remove their own resources after success or failure. Restore leaves the
project's local database running; its temporary copy still needs the default
local ports, including 54322. Starter database handling also uses labelled
resources and clean-up.

No new real run was made for these changes. The maintainer decided to release
v1.2.6 without one. Backup and restore remain untried in a real run; the earlier
evidence above does not prove the changed steps.
