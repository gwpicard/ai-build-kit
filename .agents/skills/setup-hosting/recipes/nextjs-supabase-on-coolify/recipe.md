# Recipe: Next.js 16, TypeScript and Supabase on Coolify

Fits: Dashboards and reporting on existing data; Admin panels and back office over an existing database; Approvals and request workflows; CRMs, contact trackers and sales tools; Light ERP: stock, orders, purchasing, assets; Client, vendor and partner portals; Project and task trackers; Document processing: upload, extract, review, export; AI assistants over team documents; HR and onboarding; Case management, tickets and incident logs; Booking and scheduling; Forms and data collection; Field, inspection and service apps; Screenless sync and automation
Recommended when: the team wants a rented Coolify server. AI Build Kit builds and checks the tool, coolify-launchpad sets up the server, and coolify-devops puts it live.
Language: TypeScript
Framework: Next.js 16
Typing: TypeScript tsc
User interface: Tailwind CSS 4 and shadcn/ui on Radix
Database: Supabase Postgres
Sign-in: Supabase Auth
Email: Resend
Files: Supabase Storage
Jobs: Supabase Cron and Queues
Testing: Vitest and Playwright
Linting: ESLint
Starter: ../parts/starters/nextjs-supabase
Optional parts: none
Work-team default: no
Deploy target: Coolify on a rented server, with the Coolify GitHub App connected to the project's repository
Command-line tools: supabase, docker, psql, curl, git
Health-check tool: curl
Last checked: 2026-10-14
Last proven: 2026-10-23
Proven on: Next.js 16; Supabase CLI 2.117; Coolify 4.3.23; coolify-devops 0.4.0
Superseded settings: NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

Shared stack: [Next.js, TypeScript and Supabase](../parts/nextjs-supabase-stack.md)
Database types check: `if [ ! -f types/database.ts ] || ! git ls-files --error-unmatch types/database.ts >/dev/null 2>&1; then echo 'could not run: types/database.ts is missing or untracked'; exit 2; fi; if ! supabase status >/dev/null 2>&1; then echo 'could not run: local Supabase is not running'; exit 2; fi; tmp=$(mktemp) || exit 2; trap 'rm -f "$tmp"' EXIT; supabase gen types typescript --local > "$tmp" || { echo 'could not run: database types could not be generated'; exit 2; }; diff -u types/database.ts "$tmp"`
Plan terms: Supabase Free pauses projects after 7 days of low activity and has no backups, so a work team should use Pro (read 2026-10-14 at https://supabase.com/docs/guides/platform/free-project-pausing and https://supabase.com/docs/guides/platform/backups)

The kit never contacts the server. The person, or a companion working with them, pastes back what only the server knows, and a script reads it.

## Preview

How it works: Coolify builds each pull request into its own container and removes it on close. Previews start off. With coolify-devops 0.8.2 (not yet proven in a real run), the request says `Previews: yes, second Supabase project <ref>, Basic Authentication in front` only when the person wants them. The companion creates every `Env vars` and `Build vars` name again, scoped to previews and pointed at the second project, with the same build/runtime flags and a `REPLACE_ME` value. It waits for the person to fill those values before deploying, so preview builds do not use production data. The companion cannot set Basic Authentication, so it reports that as a step for the person to do before the first pull request. The address block's `Preview:` line records whether Basic Authentication is confirmed with `basic auth: set by hand, confirmed` or `basic auth: set by hand, not yet confirmed`. Without a companion, use Enable preview deployments on the app's Preview Deployments page. A preview has an address only when the app has a domain; without one the kit says once that nobody can open it. Its settings point at the second Supabase project, and `../parts/scripts/migrate.sh --apply <preview project ref>` applies the branch's migrations to it, with that project's password location as `PREVIEW_DB_PASSWORD_FILE`. Without a second project, previews stay off.
How it is checked: A finished preview deployment whose health shows the database reachable, the pull request's commit, and a project other than the live one.
Script: scripts/preview.sh
Who runs it: a companion or the person, result read back
Ask: Please paste the preview deployment's status from Coolify, and the answer from the preview's /api/health, read at its address or on the server.

## Going live

How it works: Coolify does not run migrations, so before the build that needs them the kit applies them with `../parts/scripts/migrate.sh --apply <live project ref>`. A migration only adds, so the container still live keeps working. Before the merge, the kit runs the Health part's container check. Exit 2 means the check could not run on this computer, so do not ask to merge without it. Exit 1 means it failed and also holds the merge. Before the first launch, the person or the companion switches on Coolify's health check, which Coolify documents as off by default and the real run never saw off, because the companion created the app with it on, with path `/api/health`, port 3000 and host `127.0.0.1`. The health route reports the commit from `SOURCE_COMMIT`. With `Deploys on merge: yes`, Coolify builds `main` after a merge and swaps the new container in once its check passes, which needs no published host port and no custom container name. On a first launch `scripts/hosting-request.sh` prints the request for whoever runs the server, as `hosting-request.md` says, and the address comes from its answer.
How it is checked: A finished deployment, Coolify's health check on as above and passing, and a health answer with the database reachable and the commit on `main`. The database check detects public tables without row-level security, except those on the record. It does not inspect whether policies restrict access.
Script: scripts/going-live.sh
Who runs it: a companion or the person, result read back
Ask: Please paste the deployment's status, the app's health check settings and the container's health status from Coolify, and the answer from the live address's /api/health.

## Rollback

How it works: Coolify keeps earlier images until its nightly cleanup, which leaves the two newest. After the person approves that specific rollback, the person can click Roll Back To This Image on the app's Rollback page, under Operations, or the companion can use `/host` rollback via the kept images. The companion route has not yet been proven in a real run. The old container serves for about half a minute, so the kit asks for a second health read. A later deploy of `main` rolls forward. A rollback does not undo a migration.
How it is checked: The check confirms that an earlier image is still kept, which shows a rollback is possible. It does not perform one, because that would change the live tool.
Script: scripts/rollback.sh
Who runs it: a companion or the person, result read back
Ask: Please paste the list of kept images from the app's Rollback page in Coolify, under Operations, or the `deployment rollback_images` listing from `/host`.

## Backup

Shared part: [backup on hosted Supabase](../parts/supabase-backup.md)

## Restore

Shared part: [restore on hosted Supabase](../parts/supabase-restore.md)

## Secrets

How it works: Use `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` and `SUPABASE_SECRET_KEY`; the legacy `NEXT_PUBLIC_SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` still work. The hosting request carries setting names, never a value. With coolify-devops 0.8.2 (not yet proven in a real run), the companion creates hand-set secrets as runtime-only (`is_buildtime: false`) with a `REPLACE_ME` placeholder, then waits for the person to fill them before deploying. Build vars are the exception: the companion creates them for build time and runtime with a `REPLACE_ME` placeholder, and waits for the person to fill them before deploying. A build var change needs a redeploy, not a restart. The publishable key reaches the browser by design; row-level security limits it. The secret key stays on the server. No value goes into the repository or the Dockerfile.
How it is checked: The pasted list includes every name in `.env.example`. The check rejects names there that start with `NEXT_PUBLIC_` and contain `SERVICE_ROLE` or `SECRET`, and rejects pasted values. It does not verify values on the host. Git ignores `supabase/.temp`.
Script: scripts/secrets.sh
Who runs it: a companion or the person, result read back
Ask: Please paste the names of the settings Coolify holds for the app, with no values.

## Logs

How it works: What the tool writes with `console.error` lands in the container's output in Coolify, which the kit cannot read. Coolify's own build lines, such as a missing build helper container or orphan containers, are not the tool's errors.
How it is checked: The container's output since the deployment holds no error from the tool, and the kit reports to the person any that it holds.
Script: scripts/logs.sh
Who runs it: a companion or the person, result read back
Ask: Please paste the error lines from the container's output in Coolify since the deployment.

## Health

Shared part: [the Next.js container and its health route](../parts/nextjs-container.md)

## Access

How it works: The masterplan's `Access:` line says private, open address with invitation only, or public. Production is protected by the tool's invite-only sign-in. Previews are off by default. Turn them on only behind Coolify Basic Authentication, and never point them at live data. Private keeps the address reachable only on the team's private network. Basic Authentication protects previews only; production has no second lock. Set it in the app's General settings, under Security, then Authentication, and keep the password in the team's password manager. Open address with invitation only leaves the gate off and sign-up closed. Public takes the gate off and opens sign-up. The person or companion makes the server's change, and the kit never sees the password. Each change needs the person's approval, given for that named effect, and goes in the changelog.
How it is checked: For private, the check accepts an outside response of 401 or 403 as an authentication gate. If the outside request cannot connect, it requires an inside response. This does not prove private-network isolation. For the other two settings the outside request answers 200. Sign-up, read by the shared `../parts/scripts/signup.sh` with an attempt that has no password and so makes no account, matches the record.
Script: scripts/access.sh
Who runs it: a companion or the person, result read back
Ask: Please paste what `curl -sS -o /dev/null -w '%{http_code}' <live address>/api/health` prints on a computer outside your private network, or the error it gives. If it cannot connect, also paste what the same command prints on a computer inside the network.

## Settings the kit can read

Shared part: [sign-in settings on hosted Supabase](../parts/supabase-settings.md)
