# Recipe: Next.js and hosted Supabase on Coolify

Fits: a web app people use in a browser, with sign-in and saved data
Recommended when: the team already runs Coolify, or wants the app on a server it rents, such as a Hetzner or Hostinger VPS, rather than on a hosting platform.
Build stack: Next.js with TypeScript and the App Router, built into a container image from a Dockerfile, with the database and sign-in in a hosted Supabase project whose tables are made by migrations
Deploy target: Coolify on a rented server, with the Coolify GitHub App connected to the project's repository
Command-line tools: supabase, docker, psql, curl, git
Last checked: 2026-09-24

## Preview

How it works: With the GitHub App connected and preview deployments switched on, Coolify builds each pull request into its own container on the pull request's commit, and removes it when the pull request closes. Coolify 4.3.23 has no switch for previews in its interface, so the person or the companion switches them on through Coolify's API, by setting `is_preview_deployments_enabled` on the app. A preview has an address only when the app has a domain: Coolify fills its preview template, by default `{{pr_id}}.{{domain}}`, from that domain. An app on a private network with no domain gets a preview that runs and passes its health check on the server, but nobody can open it. There the kit says once that the person cannot open the preview, as a warning, and does not wait for an address. The preview gets its own environment variables, set in Coolify's preview view, because a value set only for the live app does not reach a preview build. Those point at a second Supabase project kept for previews, never at the live one. Before each preview, the kit gives that project the branch's migrations with `supabase link --project-ref <preview project ref>` and `supabase db push`. Where no second project can exist, for instance on a plan with no room for another active project, the preview variables point at the live project instead. The kit then says once that previews use live data, records it, and gives a preview no migrations, since they would change the live database before the merge. The kit never contacts the server, so the person or the hosting companion reads the preview.
How it is checked: The person or the companion pastes back the preview deployment's status in Coolify and the answer from the preview's `/api/health`: at `<preview address>/api/health` when the preview has an address, or read on the server when it has none. The kit reads a finished deployment, 200, `"database":"ok"`, the pull request's commit, and a `project` that is not the live project's reference, unless the record says previews share the live project.
Who runs it: a companion or the person, result read back

## Going live

How it works: The kit links back to the live project with `supabase link --project-ref <live project ref>`, then applies new migrations to the live database before the build that needs them, because Coolify does not run them: `supabase db push --dry-run` lists what would change, and `supabase db push` applies it. A migration in a release only adds, so the container still live keeps working until the new one takes over. The kit lists the public tables with row-level security off, `psql --dbname "$SUPABASE_DB_URL" --tuples-only --command "select tablename from pg_tables where schemaname = 'public' and not rowsecurity;"`, and names each table it lists once and records it. `SUPABASE_DB_URL` is the session pooler address from `supabase/.temp/pooler-url` with the database password added, built in the person's shell, and the kit never shows it. The Supabase security advisor, `curl -fsS -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" https://api.supabase.com/v1/projects/<project ref>/advisors/security`, is an optional second read, since that endpoint is marked experimental. Before the merge, the kit runs the local container check from the Health part, so an image that fails to build, bind or answer is found on the person's machine and not on the server. Coolify's health check is off by default. Before the first launch, the person or the companion switches it on in the app's health check settings, with path `/api/health`, port 3000 and host `127.0.0.1`. Coolify's default host is `localhost`, which on the Alpine image can resolve to the IPv6 address while the app listens on IPv4 only. The image carries no `HEALTHCHECK` line, as the Health part says, so Coolify's setting is the only check. The health route reports the commit from `SOURCE_COMMIT`. The branch then merges into `main`. Coolify builds `main` from the Dockerfile on each push and, as a rolling update, swaps the new container in once its health check passes. A rolling update cannot happen when the app publishes a port on the host or has a custom container name, so this recipe uses neither. On a first launch the hosting request reads `Port: 3000`, `Healthcheck: /api/health`, `Build: Dockerfile at root, image has curl or wget` and `Bind: 0.0.0.0`, and the address comes from its answer.
How it is checked: The row-level security query returns no rows, or each table it returns is on the record. The person or the companion pastes back the deployment's status, the health check settings and the container's health status in Coolify, and the answer from `<live address>/api/health`. The kit reads a finished deployment, the check switched on for `/api/health` on port 3000 and host `127.0.0.1`, healthy, 200, `"database":"ok"`, and a `commit` equal to `git rev-parse origin/main`.
Who runs it: a companion or the person, result read back

## Rollback

How it works: Coolify keeps the images of earlier deployments on the server until its nightly cleanup, which leaves the two newest by default. Before the cleanup runs, more than two may be listed. After it, the one release before the live one is the image a rollback can count on, and the cleanup of unused images can remove the one a rollback needs. The person makes the rollback on the app's Rollback page, in its Operations section, which lists the kept images: they choose Roll Back To This Image on the earlier one. Coolify reuses the kept image, with no new build. Neither Coolify's deploy API nor the companion's tools can roll back on Coolify 4.3.23, so the rollback is always the person's click. A later deploy of `main` rolls forward, and it too reuses the kept image when nothing in the build changed. A rollback does not undo database migrations, which is why a migration only adds.
How it is checked: Before relying on a rollback, the person or the companion confirms the earlier image is still listed in Coolify, on the app's Rollback page. After it, they paste back the answer from `<live address>/api/health`. The kit reads 200, `"database":"ok"`, and a `commit` that is the earlier commit rather than the one rolled back. For about the first half minute the old container still serves, so an answer in that time can show the newer commit, and the kit asks for a second read.
Who runs it: a companion or the person, result read back

## Backup

Shared part: [backup on hosted Supabase](parts/supabase-backup.md)

## Restore

Shared part: [restore on hosted Supabase](parts/supabase-restore.md)

## Secrets

How it works: The hosting request carries the names of the environment variables and never a value. The person or the companion enters each value in Coolify's environment variables for the app, marked as available at build time where Next.js needs it in the build. The Supabase address and public key carry the `NEXT_PUBLIC_` prefix and reach the browser by design. Row-level security is what keeps them harmless. The service role key stays on the server and never carries that prefix. `supabase init` does not add `supabase/.temp` to `.gitignore`, and that folder holds the project reference and the pooler address, so the kit adds it before the first commit. No value is written into the repository or the Dockerfile.
How it is checked: The person or the companion pastes back the list of names set in Coolify, with no values. The kit reads every name in `.env.example` on that list. No name that starts with `NEXT_PUBLIC_` contains `SERVICE_ROLE` or `SECRET`.
Who runs it: a companion or the person, result read back

## Logs

How it works: Coolify keeps the output of each running container and of each deployment's build. What the tool writes with `console.error` lands in the container's output. The kit cannot read it, since it never contacts the server. Coolify writes lines of its own into the build log, such as a missing build helper container or a warning about orphan containers during a rolling update. Those are not the tool's errors.
How it is checked: After a launch, the person or the companion pastes back the error lines from the container's output in Coolify since the deployment. The kit reads them and names to the person any error from the new build.
Who runs it: a companion or the person, result read back

## Health

Shared part: [the Next.js container and its health route](parts/nextjs-container.md)

## Proven

Real run: 2026-09-25

The run used a throwaway private app on a Hetzner cpx22 server running Coolify 4.3.23, set up by the coolify-devops 0.4.0 companion. The app had no domain. It ran on the internal lane, reached over the team's private network through a Tailscale Service that docktail registered. The Supabase Free plan had no room for a second active project, so previews and live shared one Supabase project on this run.

Preview: Coolify 4.3.23's interface has no switch for previews, and the companion's tools refused the setting, so previews were switched on through Coolify's API. A pull request then built into its own container on its own commit, which passed Coolify's health check. Read on the server, `/api/health` gave 200, `"database":"ok"` and the pull request's commit. The app has no domain, so the preview got no address and the person could not open it. Closing the pull request removed the container within 9 seconds. A preview address on an app with a domain, `{{pr_id}}.{{domain}}`, was not tried. That previews stay off the live database is not proven by this run, since previews and live shared one project.
Going live: The hosting request's answer gave the app no host port and Coolify's own container name. A merge into `main` deployed through the GitHub App in 64 seconds, as a rolling update that swapped the container once its health check passed. The check was on for `/api/health`, port 3000 and host `127.0.0.1`, and healthy. That Coolify's check is off by default was not seen, since the companion created the app with it on. `SOURCE_COMMIT` reached the container, and `/api/health` on the live address gave 200, `"database":"ok"`, and a commit equal to the merge commit on `main`. The migration, the row-level security query and the local container check had already run on the person's machine, and these pull requests carried no new migration, so they were not repeated.
Rollback: Before the nightly cleanup, the Rollback page listed three kept images, not two. The control was hard to find, on the app's Rollback page in its Operations section. Roll Back To This Image on the earlier commit redeployed its kept image with the build step skipped, and `/api/health` gave the earlier commit. A read within the first 30 seconds still showed the newer commit, while the old container served. A deploy of `main` then rolled forward, again from a kept image.
Backup: Not run again here. Backup is the shared part, and its outcome comes from the Vercel recipe's real run on the same shared part.
Restore: Not run again here. Restore is the shared part, and its outcome comes from the Vercel recipe's real run on the same shared part.
Secrets: Both names in `.env.example` were set in Coolify for build time and run time, each as a live row and a preview row, and the pasted list carried no value. No public name carries a secret, and no value is in the repository or the Dockerfile.
Logs: The container's output since the deployment held no error lines. The build log held two routine lines from Coolify itself, a missing build helper container and an orphan container warning during the rolling update, and none from the app.
Health: Coolify's check ran `wget` in the `node:22-alpine` image, which has no `curl`, against `127.0.0.1:3000/api/health`, and was healthy on every deployment. From the person's machine over the private network, `/api/health` gave 200 with `"database":"ok"`.
