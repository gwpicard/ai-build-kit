# Recipe: Next.js and hosted Supabase on Coolify

Fits: a web app people use in a browser, with sign-in and saved data
Recommended when: the team already runs Coolify, or wants the app on a server it rents, such as a Hetzner or Hostinger VPS, rather than on a hosting platform.
Build stack: Next.js with TypeScript and the App Router, built into a container image from a Dockerfile, with the database and sign-in in a hosted Supabase project whose tables are made by migrations
Deploy target: Coolify on a rented server, with the Coolify GitHub App connected to the project's repository
Command-line tools: supabase, docker, psql, curl, git
Last checked: 2026-09-24

The kit never contacts the server. The person, or a companion working with them, pastes back what only the server knows, and a script reads it.

## Preview

How it works: Coolify builds each pull request into its own container and removes it on close. Previews start off: the person or the companion presses Enable preview deployments on the app's Preview Deployments page. A preview has an address only when the app has a domain; without one the kit says once that nobody can open it. Its settings point at a second Supabase project, which `../parts/scripts/migrate.sh --apply <preview project ref>`, with that project's password location as `PREVIEW_DB_PASSWORD_FILE`, gives the branch's migrations. Where no second project can exist, they point at the live one: the kit says once that previews use live data, records it, and gives a preview no migrations.
How it is checked: A finished preview deployment whose health shows the database reachable, the pull request's commit, and a project other than the live one, unless the record says previews share it.
Script: scripts/preview.sh
Who runs it: a companion or the person, result read back
Ask: Please paste the preview deployment's status from Coolify, and the answer from the preview's /api/health, read at its address or on the server.

## Going live

How it works: Coolify does not run migrations, so before the build that needs them the kit applies them with `../parts/scripts/migrate.sh --apply <live project ref>`. A migration only adds, so the container still live keeps working. Before the merge, the kit runs the Health part's container check. Before the first launch, the person or the companion switches on Coolify's health check, off by default, with path `/api/health`, port 3000 and host `127.0.0.1`. The health route reports the commit from `SOURCE_COMMIT`. After a merge, Coolify builds `main` and swaps the new container in once its check passes, which needs no published host port and no custom container name. On a first launch `scripts/hosting-request.sh` prints the request for whoever runs the server, as `hosting-request.md` says, and the address comes from its answer.
How it is checked: A finished deployment, Coolify's health check on as above and passing, a health answer with the database reachable and the commit on `main`, and no public table open to anyone holding the public key.
Script: scripts/going-live.sh
Who runs it: a companion or the person, result read back
Ask: Please paste the deployment's status, the app's health check settings and the container's health status from Coolify, and the answer from the live address's /api/health.

## Rollback

How it works: Coolify keeps earlier images until its nightly cleanup, which leaves the two newest. After a yes that names it, the person or the companion clicks Roll Back To This Image on the app's Rollback page, under Operations; nothing the kit can call does it. The old container serves for about half a minute, so the kit asks for a second health read. A later deploy of `main` rolls forward. A rollback does not undo a migration.
How it is checked: An earlier image is still kept, so a rollback is possible. It is not tried, since that would change the live tool.
Script: scripts/rollback.sh
Who runs it: a companion or the person, result read back
Ask: Please paste the list of kept images from the app's Rollback page in Coolify, under Operations.

## Backup

Shared part: [backup on hosted Supabase](../parts/supabase-backup.md)

## Restore

Shared part: [restore on hosted Supabase](../parts/supabase-restore.md)

## Secrets

How it works: The hosting request carries setting names, never a value. The person or the companion enters each value in Coolify, available at build time where Next.js needs it. The Supabase address and public key carry the `NEXT_PUBLIC_` prefix and reach the browser by design; row-level security keeps them harmless. The service role key never carries that prefix. No value goes into the repository or the Dockerfile.
How it is checked: Coolify holds every name in `.env.example`, no public name carries a secret, and git ignores `supabase/.temp`.
Script: scripts/secrets.sh
Who runs it: a companion or the person, result read back
Ask: Please paste the names of the settings Coolify holds for the app, with no values.

## Logs

How it works: What the tool writes with `console.error` lands in the container's output in Coolify, which the kit cannot read. Coolify's own build lines, such as a missing build helper container or orphan containers, are not the tool's errors.
How it is checked: The container's output since the deployment holds no error from the tool, and the kit names to the person any that it holds.
Script: scripts/logs.sh
Who runs it: a companion or the person, result read back
Ask: Please paste the error lines from the container's output in Coolify since the deployment.

## Health

Shared part: [the Next.js container and its health route](../parts/nextjs-container.md)

## Access

How it works: The masterplan's `Access:` line says private, open address with invitation only, or public. Private is the default: `../parts/scripts/set-signup.sh closed` closes sign-up, so people get in only by an invitation from the Supabase dashboard, under Authentication, then Users. The server holds the gate. Private keeps the address reachable only on the team's private network, or puts a shared password in front of it, which the browser asks for before the page loads. Coolify calls that HTTP Basic Authentication; it is in the app's General settings, under Security, then Authentication, and takes a save and a redeploy, with the password kept in the team's password manager. Open address with invitation only suits a tool whose address anyone can reach: the gate is off, and sign-up stays closed. Public takes the gate off and opens sign-up. The person or the companion makes the server's change, and the kit never sees the password. Each change waits for a yes that names its effect, and goes in the changelog.
How it is checked: For private, a request signed in to nothing from outside the private network is refused, or cannot connect while the same request from inside is answered. For the other two it is answered. Sign-up, read by the shared `../parts/scripts/signup.sh` with an attempt that has no password and so makes no account, matches the record.
Script: scripts/access.sh
Who runs it: a companion or the person, result read back
Ask: Please paste what `curl -sS -o /dev/null -w '%{http_code}' <live address>/api/health` prints on a computer outside your private network, or the error it gives. If it cannot connect, also paste what the same command prints on a computer inside the network.

## Settings the kit can read

Shared part: [sign-in settings on hosted Supabase](../parts/supabase-settings.md)
