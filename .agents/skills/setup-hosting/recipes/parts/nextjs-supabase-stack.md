# Shared stack: Next.js, TypeScript and Supabase

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
How it works: Supabase Storage holds files in private buckets, with policies that follow the person's role. Document extraction defaults to plain text on the team's own server. Sending documents to a model is opt-in and needs the notice in [document processing](references/document-processing.md) at founding. Database backups do not include Storage files, so the team records a separate file backup plan.
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

## Project check
How it works: One project check runs database types, type checks, lint, tests and the container check on every change. Part D adds the row rules check against migrations and a local database.
How it is checked: The project check is green, including database types and row rules against the local database.
Script: coming in part D
Who runs it: the kit

For hosting requests, mark each build value in `.env.example` with a `# build` comment on the line immediately above it. Names beginning `NEXT_PUBLIC_` also count as build values. Other names are runtime values.

## Updates
How it works: Dependabot or Renovate opens dependency updates. Security updates for Next.js are merged quickly.
How it is checked: The dependency update service is on and its update file is present.
Script: coming in part B
Who runs it: the kit
