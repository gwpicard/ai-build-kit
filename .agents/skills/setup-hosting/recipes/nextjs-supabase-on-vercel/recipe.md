# Recipe: Next.js and hosted Supabase on Vercel

Fits: a web app people use in a browser, with sign-in and saved data
Recommended when: the team has no server of its own and wants the host to handle previews, going live and rollback.
Build stack: Next.js with TypeScript and the App Router, with a Dockerfile that Vercel ignores, and the database and sign-in in a hosted Supabase project whose tables are made by migrations
Deploy target: Vercel, with the project's GitHub repository connected so that each push builds
Command-line tools: vercel, supabase, docker, psql, curl, git
Last checked: 2026-09-25
Plan terms: Vercel's free Hobby plan is for personal, non-commercial use only, and Vercel counts a tool built by a paid employee as commercial, so a work team needs the paid Pro plan (read 2026-09-28 at https://vercel.com/docs/limits/fair-use-guidelines#commercial-usage)

Each script runs from the project's folder. Exit 0 is a pass, 1 a fail and 2 could not run.

## Preview

How it works: A first launch runs `scripts/connect.sh <project>` before anything is pushed. It creates the Vercel project, sets its framework, links the folder and connects the GitHub repository. When the repository is private, only its owner can let Vercel's GitHub app see it, and the script's last line says where they do that. The first push is `main`, because Vercel sends the first build it gets to production. After that each pushed branch gets its own preview, whose settings point at a second Supabase project, never the live one. Before each preview, `../parts/scripts/migrate.sh --apply <preview project ref>` gives that project the branch's migrations. Reading a preview's health through Vercel creates a protection bypass token on the project the first time, so the kit asks the person before setting `PREVIEW_HEALTH=yes`.
How it is checked: The preview is Ready, and the person opens it and tries the change. Where read, its health shows the database reachable, the branch's commit, and a project other than the live one.
Script: scripts/preview.sh
Who runs it: a person looking
Ask: Open the preview address signed in to Vercel, try the change, and tell me whether it does what you expected.

## Going live

How it works: Vercel does not run migrations, so before the build that needs them the kit applies them to the live database with `../parts/scripts/migrate.sh --apply <live project ref>`. A migration only adds, so the version still live keeps working. Before the merge, the kit runs the Health part's container check, so the build that goes live has already answered on this machine. The merge into `main` is /implement's. Vercel then builds `main` and moves the production address to the new build once it succeeds. The health route reports the commit from `VERCEL_GIT_COMMIT_SHA`.
How it is checked: The live address answers 200 with the database reachable and the commit on `main`, and no public table is open to anyone holding the public key, beyond the ones on the record.
Script: scripts/going-live.sh
Who runs it: the kit

## Rollback

How it works: `scripts/roll-back-to.sh <earlier deployment> <its commit>` points the production address back at an earlier build in seconds, with no new build, after a yes that names it. On the Hobby plan only the build just before is eligible; on Pro, any earlier production build. After a rollback, Vercel stops moving new pushes to production until a newer build is promoted with `scripts/promote.sh <deployment> <its commit>`, which waits for its own yes. A rollback does not undo a migration, which is why a migration only adds.
How it is checked: An earlier production build is listed, so a rollback is possible. It is not tried, since that would change the live tool.
Script: scripts/rollback.sh
Who runs it: the kit

## Backup

Shared part: [backup on hosted Supabase](../parts/supabase-backup.md)

## Restore

Shared part: [restore on hosted Supabase](../parts/supabase-restore.md)

## Secrets

How it works: The person gives each value, and `scripts/add-secret.sh <NAME>` hands it to Vercel on standard input, so it never sits on a command line. The Supabase address and public key carry the `NEXT_PUBLIC_` prefix and reach the browser by design; row-level security keeps them harmless. The service role key stays on the server and never carries that prefix. Linking writes a short-lived token into `.env.local`, which stays on this machine. The kit never pulls production values and never writes a value into the repository.
How it is checked: Vercel holds every name in `.env.example`, no public name carries a secret, and git ignores `supabase/.temp`, `.vercel` and `.env.local` while `.env.example` can still be committed.
Script: scripts/secrets.sh
Who runs it: the kit

## Logs

How it works: Vercel keeps the record of requests and function output for each deployment, and what the tool writes with `console.error` lands there. The Hobby plan keeps runtime logs for one hour, so on Hobby the kit reads them within the hour after a launch.
How it is checked: The production logs from the last hour are readable, and the kit names to the person any error from the new build.
Script: scripts/logs.sh
Who runs it: the kit

## Health

Shared part: [the Next.js container and its health route](../parts/nextjs-container.md)

## Settings the kit can read

Shared part: [sign-in settings on hosted Supabase](../parts/supabase-settings.md)
