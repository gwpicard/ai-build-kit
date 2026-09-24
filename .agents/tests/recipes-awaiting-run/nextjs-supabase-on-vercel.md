# Recipe: Next.js and hosted Supabase on Vercel

Fits: a web app people use in a browser, with sign-in and saved data
Recommended when: the team has no server of its own and wants the host to handle previews, going live and rollback.
Build stack: Next.js with TypeScript and the App Router, with the database and sign-in in a hosted Supabase project
Deploy target: Vercel, with the project's GitHub repository connected so that each push builds
Command-line tools: vercel, supabase, docker, psql, curl
Last checked: 2026-09-24

## Preview

How it works: Each branch pushed to GitHub gets its own Vercel preview deployment at its own address, built with the Preview environment variables. Those point at a second Supabase project kept for previews, never at the live one. The kit waits until `vercel inspect <preview address>` reports the deployment as Ready. Vercel protects preview addresses with a sign-in by default, so the person opens it in their own browser.
How it is checked: The person opens the preview address and tries the change, then opens `<preview address>/api/health`. It shows `"database":"ok"`, the branch's commit, and a `project` that is not the live project's reference.
Who runs it: a person looking

## Going live

How it works: The kit applies new migrations to the live database first, because Vercel does not run them: `supabase db push --dry-run` lists what would change, and `supabase db push` applies it. A migration in a release only adds, so the version still live keeps working until the new one takes over. The kit then asks the Supabase security advisor, `curl -fsS -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" https://api.supabase.com/v1/projects/<project ref>/advisors/security`, and names once any finding called `rls_disabled_in_public`, since such a table can be read by anyone holding the public key. The branch then merges into `main`, Vercel builds `main`, and the production address moves to the new build once it succeeds. `vercel promote <deployment>` moves a chosen build live by hand.
How it is checked: `curl -fsS https://<live address>/api/health` returns 200 with `"database":"ok"`, and its `commit` equals `git rev-parse origin/main`.
Who runs it: the kit

## Rollback

How it works: `vercel rollback <earlier deployment>` points the production address back at an earlier build in seconds, with no new build. On the Hobby plan only the build just before is eligible; on Pro, any earlier production build. After a rollback, Vercel stops moving new pushes to production until `vercel promote` is run on a newer build, and the kit says so in the same reply. A rollback does not undo database migrations, which is why a migration only adds.
How it is checked: After the rollback, `curl -fsS https://<live address>/api/health` returns 200 with `"database":"ok"`, and its `commit` is the earlier commit rather than the one rolled back.
Who runs it: the kit

## Backup

Shared part: [backup on hosted Supabase](parts/supabase-backup.md)

## Restore

Shared part: [restore on hosted Supabase](parts/supabase-restore.md)

## Secrets

How it works: The person enters each value in Vercel with `vercel env add <NAME> production`, or in the dashboard, and the tool receives it as an environment variable when it builds and runs. The Supabase address and public key carry the `NEXT_PUBLIC_` prefix and reach the browser by design. Row-level security is what keeps them harmless. The service role key stays on the server and never carries that prefix. The kit never runs `vercel env pull` for production and never writes a value into the repository.
How it is checked: `vercel env ls production` lists every name in `.env.example` and no value. No name that starts with `NEXT_PUBLIC_` contains `SERVICE_ROLE` or `SECRET`.
Who runs it: the kit

## Logs

How it works: Vercel keeps the record of requests and function output for each deployment. What the tool writes with `console.error` lands there, and `vercel logs` reads it from the project folder.
How it is checked: `vercel logs --environment production --level error --since 1h --json` prints one JSON object for each error line. After a launch the kit reads it, and names to the person any error from the new build.
Who runs it: the kit

## Health

How it works: Vercel has no health check of its own for an app, so the recipe adds a route at `/api/health`. It makes one real round trip to the database, a count on one table through the Supabase client, and answers 200 with `status`, `database`, `commit` and `project`, or 503 when the query fails. The commit comes from `VERCEL_GIT_COMMIT_SHA`, and the project is the reference in the Supabase address. The route sets `export const dynamic = "force-dynamic"`, so Next.js never answers it from a copy made at build time.
How it is checked: `curl -fsS https://<live address>/api/health` returns 200 with `"database":"ok"`. Run locally with `next start` and the database address pointed nowhere, the same route answers 503 rather than claiming the tool is up.
Who runs it: the kit

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
