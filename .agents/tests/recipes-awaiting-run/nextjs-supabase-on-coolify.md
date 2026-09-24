# Recipe: Next.js and hosted Supabase on Coolify

Fits: a web app people use in a browser, with sign-in and saved data
Recommended when: the team already runs Coolify, or wants the app on a server it rents, such as a Hetzner or Hostinger VPS, rather than on a hosting platform.
Build stack: Next.js with TypeScript and the App Router, built into a container image from a Dockerfile, with the database and sign-in in a hosted Supabase project whose tables are made by migrations
Deploy target: Coolify on a rented server, with the Coolify GitHub App connected to the project's repository
Command-line tools: supabase, docker, psql, curl, git
Last checked: 2026-09-24

## Preview

How it works: With the GitHub App connected and preview deployments switched on, Coolify builds each pull request into its own container at the address Coolify's preview template gives, by default `{{pr_id}}.{{domain}}`, and removes it when the pull request closes. The preview gets its own environment variables, set in Coolify's preview view, and those point at a second Supabase project kept for previews, never at the live one. Before each preview, the kit gives that project the branch's migrations with `supabase link --project-ref <preview project ref>` and `supabase db push`. The kit never contacts the server, so the person or the hosting companion reads the preview.
How it is checked: The person or the companion opens `<preview address>/api/health` and pastes the answer back. The kit reads 200, `"database":"ok"`, the pull request's commit, and a `project` that is not the live project's reference.
Who runs it: a companion or the person, result read back

## Going live

How it works: The kit links back to the live project with `supabase link --project-ref <live project ref>`, then applies new migrations to the live database before the build that needs them, because Coolify does not run them: `supabase db push --dry-run` lists what would change, and `supabase db push` applies it. A migration in a release only adds, so the container still live keeps working until the new one takes over. The kit lists the public tables with row-level security off, `psql --dbname "$SUPABASE_DB_URL" --tuples-only --command "select tablename from pg_tables where schemaname = 'public' and not rowsecurity;"`, with the connection string from the person's environment and never shown, and names each table it lists once and records it. The Supabase security advisor, `curl -fsS -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" https://api.supabase.com/v1/projects/<project ref>/advisors/security`, is an optional second read, since that endpoint is marked experimental. Before the merge, the kit runs the local container check from the Health part, so an image that fails to build, bind or answer is found on the person's machine and not on the server. Coolify's health check is off by default. Before the first launch, the person or the companion switches it on in the app's health check settings, with path `/api/health` and port 3000. The image carries no `HEALTHCHECK` line, as the Health part says, so Coolify's setting is the only check. The health route reports the commit from `SOURCE_COMMIT`. The branch then merges into `main`. Coolify builds `main` from the Dockerfile on each push and, as a rolling update, swaps the new container in once its health check passes. A rolling update cannot happen when the app publishes a port on the host or has a custom container name, so this recipe uses neither. On a first launch the hosting request reads `Port: 3000`, `Healthcheck: /api/health`, `Build: Dockerfile at root, image has curl or wget` and `Bind: 0.0.0.0`, and the address comes from its answer.
How it is checked: The row-level security query returns no rows, or each table it returns is on the record. The person or the companion pastes back the deployment's status, the health check settings and the container's health status in Coolify, and the answer from `<live address>/api/health`. The kit reads a finished deployment, the check switched on for `/api/health` on port 3000, healthy, 200, `"database":"ok"`, and a `commit` equal to `git rev-parse origin/main`.
Who runs it: a companion or the person, result read back

## Rollback

How it works: Coolify keeps the images of earlier deployments on the server, two by default, and its cleanup of unused images can remove the one a rollback needs. The person or the companion picks an earlier deployment in Coolify and redeploys its kept image, with no new build. A rollback does not undo database migrations, which is why a migration only adds.
How it is checked: Before relying on a rollback, the person or the companion confirms the earlier image is still listed in Coolify. After it, they paste back the answer from `<live address>/api/health`. The kit reads 200, `"database":"ok"`, and a `commit` that is the earlier commit rather than the one rolled back.
Who runs it: a companion or the person, result read back

## Backup

Shared part: [backup on hosted Supabase](parts/supabase-backup.md)

## Restore

Shared part: [restore on hosted Supabase](parts/supabase-restore.md)

## Secrets

How it works: The hosting request carries the names of the environment variables and never a value. The person or the companion enters each value in Coolify's environment variables for the app, marked as available at build time where Next.js needs it in the build. The Supabase address and public key carry the `NEXT_PUBLIC_` prefix and reach the browser by design. Row-level security is what keeps them harmless. The service role key stays on the server and never carries that prefix. No value is written into the repository or the Dockerfile.
How it is checked: The person or the companion pastes back the list of names set in Coolify, with no values. The kit reads every name in `.env.example` on that list. No name that starts with `NEXT_PUBLIC_` contains `SERVICE_ROLE` or `SECRET`.
Who runs it: a companion or the person, result read back

## Logs

How it works: Coolify keeps the output of each running container and of each deployment's build. What the tool writes with `console.error` lands in the container's output. The kit cannot read it, since it never contacts the server.
How it is checked: After a launch, the person or the companion pastes back the error lines from the container's output in Coolify since the deployment. The kit reads them and names to the person any error from the new build.
Who runs it: a companion or the person, result read back

## Health

Shared part: [the Next.js container and its health route](parts/nextjs-container.md)

## Proven

Real run: awaiting the first real run

Preview: awaiting the first real run
Going live: awaiting the first real run
Rollback: awaiting the first real run
Backup: awaiting the first real run
Restore: awaiting the first real run
Secrets: awaiting the first real run
Logs: awaiting the first real run
Health: awaiting the first real run
