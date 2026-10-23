# Shared stack: Next.js, TypeScript and Supabase

Vercel plan terms: Vercel sets its own rules for the Hobby plan, including what counts as commercial use and how many outside people a protected tool can admit. Read them and choose a plan yourself. Read 2026-10-21: [fair use](https://vercel.com/docs/limits/fair-use-guidelines) and [preview access](https://vercel.com/docs/deployment-protection/methods-to-protect-deployments/vercel-authentication).

## Sign-in and roles
How it works: Supabase Auth keeps public sign-up off. A server call invites each person by email. A roles table and the Custom Access Token hook pass each person's role to database policies. Server route handlers and actions check access; Proxy is never the only check.
How it is checked: The settings script confirms public sign-up is off. The role access test comes in part B.
Script: scripts/settings.sh
Who runs it: the kit

## Row rules
How it works: Row-level security is on for every table. Policies check the person's role and row access.
How it is checked: At launch, the row rules script reads the live database and finds no public table without row-level security, except tables named on the record.
Script: scripts/rls.sh
Who runs it: the kit

## Files
How it works: Supabase Storage holds files in private buckets, with policies that follow the person's role. Document extraction defaults to plain text on the team's own server. Sending documents to a model is opt-in and needs the notice in [fit-check's risk notice](../../../fit-check/references/risk-notice.md) at founding. Database backups do not include Storage files, so the team records a separate file backup plan.
How it is checked: Each bucket is private and has a policy for the roles that use it.
Script: coming in part B
Who runs it: the kit

## Jobs
How it works: Supabase Cron runs schedules and Supabase Queues holds work that can wait. Both are recorded in migrations. Recipe 1 uses Vercel Cron only when a route itself must run.
How it is checked: The job list matches the schedules and queues in migrations.
Script: coming in part B
Who runs it: the kit

## Email
How it works: Resend sends invitations and notices through Supabase Auth's custom SMTP setting. Public sign-up stays off. Postmark is the fallback.
How it is checked: Supabase Auth sends a test invitation through the configured provider, and public sign-up is still off.
Script: coming in part B
Who runs it: the kit

## User interface
How it works: Tailwind CSS 4 and shadcn/ui on Radix supply design colours and components in src/components/ui/. Field supplies form layout for react-hook-form and zod.
How it is checked: Lint runs no-unknown-classes and no-conflicting-classes, and rejects raw controls and colours outside the generated components. Playwright runs axe on sign-in and checks that its label is visible; this does not prove the screen is accessible.
Script: scripts/interface.sh
Who runs it: the kit

## Project check
How it works: Each pull request and push to main installs the locked packages and browser, starts local Supabase and applies the migrations. It compares the generated database types, runs `next typegen` and the type check, lint, Vitest with coverage and the build, then checks row rules with `scripts/rls.sh --local`. Playwright starts `next start` and runs every browser test, including the accessibility test.
How it is checked: The workflow passes. A table without row-level security or database types that differ from the migrations fails it.
Script: starters/nextjs-supabase/.github/workflows/check.yml
Who runs it: the kit

Local rehearsal: On 2026-10-23, the workflow's shell steps took 76.450 seconds
on this computer, an arm64 Mac running macOS 15.1 with Docker 29.8.0. The
database started from stopped containers. Package, browser and database image
caches were warm. This includes database shutdown and excludes the three
GitHub setup actions and the planted fault cases. A real GitHub run has not
been timed or proven.

For hosting requests, mark each build value in `.env.example` with a `# build` comment on the line immediately above it. Names beginning `NEXT_PUBLIC_` also count as build values. Other names are runtime values.

## Updates
How it works: Dependabot or Renovate opens dependency updates. Security updates for Next.js are merged quickly.
How it is checked: The dependency update service is on and its update file is present.
Script: coming in part B
Who runs it: the kit
