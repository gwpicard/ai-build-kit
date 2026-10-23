# Recipe: Next.js 16, TypeScript and Supabase on Vercel

Fits: Dashboards and reporting on existing data; Admin panels and back office over an existing database; Approvals and request workflows; CRMs, contact trackers and sales tools; Light ERP: stock, orders, purchasing, assets; Client, vendor and partner portals; Project and task trackers; HR and onboarding; Case management, tickets and incident logs; Booking and scheduling; Forms and data collection; AI assistants over team documents
Recommended when: the team has no server of its own and wants the host to handle previews, going live and rollback. A private tool needs each person to hold a Vercel account with access, and Hobby allows one outside person.
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
Work-team default: yes (Vercel Pro, Supabase Pro)
Deploy target: Vercel, with the project's GitHub repository connected so that each push builds
Command-line tools: vercel, supabase, docker, psql, curl, git
Health-check tool: curl
Last checked: 2026-10-14
Last proven: 2026-10-23
Proven on: Next.js 16.4.2; Supabase CLI 2.117; Vercel CLI 60.0.0
Superseded settings: NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

Shared stack: [Next.js, TypeScript and Supabase](../parts/nextjs-supabase-stack.md)
Database types check: `if [ ! -f types/database.ts ] || ! git ls-files --error-unmatch types/database.ts >/dev/null 2>&1; then echo 'could not run: types/database.ts is missing or untracked'; exit 2; fi; if ! supabase status >/dev/null 2>&1; then echo 'could not run: local Supabase is not running'; exit 2; fi; tmp=$(mktemp) || exit 2; trap 'rm -f "$tmp"' EXIT; supabase gen types typescript --local > "$tmp" || { echo 'could not run: database types could not be generated'; exit 2; }; diff -u types/database.ts "$tmp"`
Plan terms: Supabase Free pauses projects after 7 days of low activity and has no backups; teams use Pro (read 2026-10-14 at https://supabase.com/docs/guides/platform/free-project-pausing and https://supabase.com/docs/guides/platform/backups)
Plan terms: Vercel sets its own rules for the Hobby plan, including what counts as commercial use, so read them and choose a plan yourself (read 2026-10-21 at https://vercel.com/docs/limits/fair-use-guidelines)
Plan terms: Vercel sets how many outside people a protected tool can admit on the Hobby plan, so check its current limit before choosing a plan (read 2026-10-21 at https://vercel.com/docs/deployment-protection/methods-to-protect-deployments/vercel-authentication)

## Preview

How it works: A first launch runs `scripts/connect.sh <project>` before anything is pushed, to create the Vercel project and connect the GitHub repository. Where the repository is private, only its owner can let Vercel see it, and the script's last line says how. Before the first push to `main`, close sign-up with `../parts/scripts/set-signup.sh closed` and turn on Vercel sign-in with `scripts/set-access.sh private`. Until both settings are on, the address is public. Vercel sends its first build to production, so the first push is `main`. Each later branch gets its own preview, whose settings point at a second Supabase project, never the live one. Before each preview, `../parts/scripts/migrate.sh --apply <preview project ref>`, with that project's password location as `PREVIEW_DB_PASSWORD_FILE`, applies the branch's migrations to that project. Reading a preview's health through Vercel, the first time, creates a lasting key on the project that bypasses Vercel's sign-in, so the kit asks the person before setting `PREVIEW_HEALTH=yes`.
How it is checked: The preview is Ready, and the person opens it and tries the change. Where read, its health shows the database reachable, the branch's commit, and a project other than the live one.
Script: scripts/preview.sh
Who runs it: a person looking
Ask: Open the preview address signed in to Vercel, try the change, and tell me whether it does what you expected.

## Going live

How it works: Vercel does not run migrations, so before the build that needs them the kit applies them to the live database with `../parts/scripts/migrate.sh --apply <live project ref>`. A migration only adds, so the version still live keeps working. Before the merge, the kit runs the Health part's container check, so the build that goes live has already answered here. Exit 2 means the check could not run on this computer, so do not ask to merge without it. Exit 1 means it failed and also holds the merge. Vercel then builds `main` and moves the production address to the new build once it succeeds. A changed Vercel setting reaches production only after a new build; run `vercel redeploy <production deployment URL>`. The health route reads `VERCEL_GIT_COMMIT_SHA` on Vercel. `SOURCE_COMMIT` remains a fallback for local runs and hosts that do not supply a commit.
How it is checked: The live address answers 200 with the database reachable and the commit on `main`, and no public table is open to anyone holding the publishable key beyond the ones on the record.
Script: scripts/going-live.sh
Who runs it: the kit

## Rollback

How it works: `scripts/roll-back-to.sh <earlier deployment> <its commit>` points the production address back at an earlier build in seconds, with no new build, after the person approves that specific rollback. On the Hobby plan only the build just before is eligible; on Pro, any earlier production build. After a rollback, Vercel stops moving new pushes to production until a newer build is promoted with `scripts/promote.sh <deployment> <its commit>`, which needs its own approval. A rollback does not undo a migration, which is why a migration only adds.
How it is checked: The check confirms that an earlier production build is listed, which shows a rollback is possible. It does not perform one, because that would change the live tool.
Script: scripts/rollback.sh
Who runs it: the kit

## Backup

Shared part: [backup on hosted Supabase](../parts/supabase-backup.md)

## Restore

Shared part: [restore on hosted Supabase](../parts/supabase-restore.md)

## Secrets

How it works: Use `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` and `SUPABASE_SECRET_KEY`; the legacy `NEXT_PUBLIC_SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` still work. Run `scripts/get-supabase-keys.sh <project ref> <folder>` to write the publishable and secret keys to private files without using the clipboard. Pass a file to `scripts/add-secret.sh <NAME>` on standard input. Use `--replace` to remove that exact production name before adding its checked value. The publishable key reaches the browser by design; row-level security limits it. The secret key stays on the server. The kit never pulls production values or writes a value into the repository.
How it is checked: Vercel holds every name in `.env.example`, no public name carries a secret, and git ignores `supabase/.temp`, `.vercel` and `.env.local` while `.env.example` can still be committed.
Script: scripts/secrets.sh
Who runs it: the kit

## Logs

How it works: What the tool writes with `console.error` lands in Vercel's logs for each deployment. The Hobby plan keeps them for one hour, so on Hobby the kit reads them within the hour after a launch.
How it is checked: The production logs from the last hour are readable, and the kit reports to the person any error from the new build.
Script: scripts/logs.sh
Who runs it: the kit

## Health

Shared part: [the Next.js container and its health route](../parts/nextjs-container.md)

## Access

How it works: The masterplan's `Access:` line says private, open address with invitation only, or public. Private is the default: `../parts/scripts/set-signup.sh closed` closes sign-up, so people get in only by an invitation from the Supabase dashboard, under Authentication, then Users. `scripts/set-access.sh private` puts Vercel's sign-in in front of every address, so each person also needs a Vercel account with access to the project. Pro can add people who only view, and Hobby lets in one person outside the account owner; neither limit has been confirmed in a real run. A larger group on Hobby cannot be kept private, and the access check reports that limit and the three ways out: Pro, open address with invitation only, or the Coolify recipe. `scripts/set-access.sh public` removes the gate from the live address for both open address with invitation only and public, and sign-up opens only for public. Each change needs the person's approval, given for that named effect, and goes in the changelog. Reading through the gate also needs the person's approval.
How it is checked: Three readings must match the record: sign-up, read by the shared `../parts/scripts/signup.sh` with an attempt that has no password and so creates no account; Vercel's setting; and a request made without signing in.
Script: scripts/access.sh
Who runs it: the kit

## Settings the kit can read

Shared part: [sign-in settings on hosted Supabase](../parts/supabase-settings.md)
