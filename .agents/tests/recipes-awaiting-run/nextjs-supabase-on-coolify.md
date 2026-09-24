# Recipe: Next.js and hosted Supabase on Coolify

Fits: a web app people use in a browser, with sign-in and saved data
Recommended when: the team already runs Coolify, or wants the app on a server it rents, such as a Hetzner or Hostinger VPS, rather than on a hosting platform.
Build stack: Next.js with TypeScript and the App Router, built into a container image from a Dockerfile, with the database and sign-in in a hosted Supabase project
Deploy target: Coolify on a rented server, with the Coolify GitHub App connected to the project's repository
Command-line tools: supabase, docker, psql, curl
Last checked: 2026-09-24

## Preview

How it works: With the GitHub App connected and preview deployments switched on, Coolify builds each pull request into its own container at `{{pr_id}}.preview.<domain>`, and removes it when the pull request closes. The preview gets its own environment variables, set in Coolify's preview view, and those point at a second Supabase project kept for previews, never at the live one. The kit never contacts the server, so the person or the hosting companion reads the preview.
How it is checked: The person or the companion opens `<preview address>/api/health` and pastes the answer back. The kit reads 200, `"database":"ok"`, the pull request's commit, and a `project` that is not the live project's reference.
Who runs it: a companion or the person, result read back

## Going live

How it works: The kit applies new migrations to the live database first, because Coolify does not run them: `supabase db push --dry-run` lists what would change, and `supabase db push` applies it. A migration in a release only adds, so the container still live keeps working until the new one takes over. The kit asks the Supabase security advisor, `curl -fsS -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" https://api.supabase.com/v1/projects/<project ref>/advisors/security`, and names once any finding called `rls_disabled_in_public`. It builds the image locally with `docker build .`, so a Dockerfile that fails is found on the person's machine and not on the server. The branch then merges into `main`. Coolify builds `main` from the Dockerfile on each push and swaps the new container in once its health check passes. On a first launch the hosting request reads `Port: 3000`, `Healthcheck: /api/health`, `Build: Dockerfile at root, image has curl or wget` and `Bind: 0.0.0.0`, and the address comes from its answer.
How it is checked: The person or the companion pastes back the deployment's status in Coolify and the answer from `<live address>/api/health`. The kit reads a finished deployment, 200, `"database":"ok"`, and a `commit` equal to `git rev-parse origin/main`.
Who runs it: a companion or the person, result read back

## Rollback

How it works: Coolify keeps the images of earlier deployments on the server, as many as its setting for images to keep allows. The person or the companion picks an earlier deployment in Coolify and redeploys its kept image, with no new build. A rollback does not undo database migrations, which is why a migration only adds.
How it is checked: The person or the companion pastes back the answer from `<live address>/api/health`. The kit reads 200, `"database":"ok"`, and a `commit` that is the earlier commit rather than the one rolled back.
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

How it works: The Dockerfile builds Next.js with `output: "standalone"` in `next.config.ts` and runs `node server.js` with `HOSTNAME=0.0.0.0` and `PORT=3000`, so the server answers from outside the container. It starts from a Node Alpine image, which carries `wget`, because Coolify runs its health check from inside the container and a slim image without `curl` or `wget` fails every check. Coolify's health check calls `/api/health` on port 3000. That route makes one real round trip to the database, a count on one table through the Supabase client, and answers 200 with `status`, `database`, `commit` and `project`, or 503 when the query fails. The commit comes from `SOURCE_COMMIT`. The route sets `export const dynamic = "force-dynamic"`, so Next.js never answers it from a copy made at build time.
How it is checked: The person or the companion pastes back the container's health status in Coolify and the answer from `<live address>/api/health`. The kit reads healthy, 200 and `"database":"ok"`.
Who runs it: a companion or the person, result read back

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
