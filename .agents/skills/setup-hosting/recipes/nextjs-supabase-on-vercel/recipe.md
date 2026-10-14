# Recipe: Next.js 16, TypeScript and Supabase on Vercel

Fits: Dashboards and reporting on existing data; Admin panels and back office over an existing database; Approvals and request workflows; CRMs, contact trackers and sales tools; Light ERP: stock, orders, purchasing, assets; Client, vendor and partner portals; Project and task trackers; HR and onboarding; Case management, tickets and incident logs; Booking and scheduling; Forms and data collection; AI assistants over team documents
Recommended when: the team has no server of its own and wants the host to handle previews, going live and rollback. A private tool needs each person to hold a Vercel account with access, and Hobby allows one outside person.
Language: TypeScript
Framework: Next.js 16
Typing: TypeScript tsc
Database: Supabase Postgres
Sign-in: Supabase Auth
Email: Resend
Files: Supabase Storage
Jobs: Supabase Cron and Queues
Testing: Vitest and Playwright
Linting: ESLint
Starter: coming
Optional parts: read-only existing database
Work-team default: yes (Vercel Pro, Supabase Pro)
Deploy target: Vercel, with the project's GitHub repository connected so that each push builds
Command-line tools: vercel, supabase, docker, psql, curl, git
Health-check tool: curl
Last checked: 2026-10-14

Shared stack: [Next.js, TypeScript and Supabase](../parts/nextjs-supabase-stack.md)
Database types check: `if [ ! -f types/database.ts ] || ! git ls-files --error-unmatch types/database.ts >/dev/null 2>&1; then echo 'could not run: types/database.ts is missing or untracked'; exit 2; fi; if ! supabase status >/dev/null 2>&1; then echo 'could not run: local Supabase is not running'; exit 2; fi; tmp=$(mktemp) || exit 2; trap 'rm -f "$tmp"' EXIT; supabase gen types typescript --local > "$tmp" || { echo 'could not run: database types could not be generated'; exit 2; }; diff -u types/database.ts "$tmp"`
Plan terms: Supabase Free pauses projects after 7 days of low activity and has no backups, so it is for exploring privately; a work team should use Pro (read 2026-10-14 at https://supabase.com/docs/guides/platform/free-project-pausing and https://supabase.com/docs/guides/platform/backups)
Plan terms: Vercel Hobby is for personal, non-commercial use only; paid employees or consultants writing the code count as commercial. A work team should use Pro (read 2026-10-14 at https://vercel.com/docs/limits/fair-use-guidelines)
Plan terms: Hobby allows one outside person through the preview gate; a work team should use Pro (read 2026-10-14 at https://vercel.com/docs/deployment-protection/methods-to-protect-deployments/vercel-authentication)

## Preview

How it works: A first launch runs `scripts/connect.sh <project>` before anything is pushed, to create the Vercel project and connect the GitHub repository. Where the repository is private, only its owner can let Vercel see it, and the script's last line says how. The first push is `main`, because Vercel sends the first build it gets to production. Each later branch gets its own preview, whose settings point at a second Supabase project, never the live one. Before each preview, `../parts/scripts/migrate.sh --apply <preview project ref>`, with that project's password location as `PREVIEW_DB_PASSWORD_FILE`, gives that project the branch's migrations. Reading a preview's health through Vercel makes a lasting key on the project that gets past Vercel's sign-in, the first time, so the kit asks the person before setting `PREVIEW_HEALTH=yes`.
How it is checked: The preview is Ready, and the person opens it and tries the change. Where read, its health shows the database reachable, the branch's commit, and a project other than the live one.
Script: scripts/preview.sh
Who runs it: a person looking
Ask: Open the preview address signed in to Vercel, try the change, and tell me whether it does what you expected.

## Going live

How it works: Vercel does not run migrations, so before the build that needs them the kit applies them to the live database with `../parts/scripts/migrate.sh --apply <live project ref>`. A migration only adds, so the version still live keeps working. Before the merge, the kit runs the Health part's container check, so the build that goes live has already answered here. Vercel then builds `main` and moves the production address to the new build once it succeeds. The health route reports the commit from `VERCEL_GIT_COMMIT_SHA`.
How it is checked: The live address answers 200 with the database reachable and the commit on `main`, and no public table is open to anyone holding the public key beyond the ones on the record.
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

How it works: The person gives each value, and `scripts/add-secret.sh <NAME>` hands it to Vercel on standard input, so it never sits on a command line. The Supabase address and public key carry the `NEXT_PUBLIC_` prefix and reach the browser by design; row-level security keeps them harmless. The service role key never carries that prefix. The kit never pulls production values and never writes a value into the repository.
How it is checked: Vercel holds every name in `.env.example`, no public name carries a secret, and git ignores `supabase/.temp`, `.vercel` and `.env.local` while `.env.example` can still be committed.
Script: scripts/secrets.sh
Who runs it: the kit

## Logs

How it works: What the tool writes with `console.error` lands in Vercel's logs for each deployment. The Hobby plan keeps them for one hour, so on Hobby the kit reads them within the hour after a launch.
How it is checked: The production logs from the last hour are readable, and the kit names to the person any error from the new build.
Script: scripts/logs.sh
Who runs it: the kit

## Health

Shared part: [the Next.js container and its health route](../parts/nextjs-container.md)

## Access

How it works: The masterplan's `Access:` line says private, open address with invitation only, or public. Private is the default: `../parts/scripts/set-signup.sh closed` closes sign-up, so people get in only by an invitation from the Supabase dashboard, under Authentication, then Users. `scripts/set-access.sh private` puts Vercel's sign-in in front of every address, so each person also needs a Vercel account with access to the project. Pro can add people who only view, and Hobby lets in one person outside the account owner; both are to be confirmed at the real run. A larger group on Hobby cannot be kept private, and the access check names that limit and the three ways out: Pro, open address with invitation only, or the Coolify recipe. `scripts/set-access.sh public` takes the gate off the live address for the other two settings, and sign-up opens only for public. Each change waits for a yes that names its effect, and goes in the changelog. Reading through the gate waits for a yes.
How it is checked: Sign-up, read by the shared `../parts/scripts/signup.sh` with an attempt that has no password and so makes no account, Vercel's setting, and a request signed in to nothing all match the record.
Script: scripts/access.sh
Who runs it: the kit

## Settings the kit can read

Shared part: [sign-in settings on hosted Supabase](../parts/supabase-settings.md)
