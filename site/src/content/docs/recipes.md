---
title: Hosting recipes
description: Choose a hosting recipe, understand its checks, and see what remains untested.
draft: false
---

A hosting recipe specifies a software stack, the combination of software used to build your tool, and a hosting service. It defines how to preview and publish changes, back up and restore data, and return to an earlier application version. Both available recipes have been used in real deployments, but neither has been tested through every procedure.

## The recipes today

Both recipes use TypeScript, Next.js 16 and Supabase, a combination supported by the kit's existing checks. They suit internal tools such as dashboards, approval workflows, trackers and portals.

[Next.js and Supabase on Vercel](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/recipe.md) is the default for work teams. Vercel handles previews, deployment and rollback. The kit can run its automated checks on your computer; you open the preview and try the change. Private tools require a Vercel account for each person with access.

[Next.js and Supabase on Coolify](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-coolify/recipe.md) suits teams with a rented server or long-running work. The kit does not access the server directly. Some checks require you, or a separate tool with server access, to retrieve information and paste it into the session for validation.

Each recipe links to its providers' plan terms. Read those terms before choosing a plan; the kit does not interpret them.

## Checks and testing status

Recipes define how to deploy and recover the tool, control access and store keys and passwords. Their checks also cover error logs and health, including whether the live tool responds. A documented procedure does not mean it has been tested in a real deployment.

| Recipe | Recorded testing |
|---|---|
| [Vercel deployment record](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/PROVEN.md) | Deployment, health and database structure changes were tested in October 2026. Preview, rollback, secrets and logs remain untested. |
| [Coolify deployment record](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-coolify/PROVEN.md) | Runs in September 2026 covered preview, deployment, rollback, secrets, logs and health. Previews shared the production database, so isolation from production data remains unproven. Some deployment procedures have changed since those runs and remain untested. |

Neither recipe has had a real test of backup, restore, access controls, sign-in settings or initial project setup. Coolify's newer sign-in, database access rules, file storage, background jobs, email, project checks and update procedures also await real testing. The linked records give the full coverage and limitations.

The launch checks require a confirmed backup and a defined rollback procedure. Later launches also require an earlier build to be available. Other failed or incomplete recipe checks are reported as warnings; they do not automatically block launch.

## Outside a recipe

If no recipe matches your stack or host, the kit explains once that it provides no guarantees, including rollback, backup or launch validation. If you choose to continue, it records your decision and the date, then provides individual guidance. During maintenance, it may offer a move to a suitable recipe. Moving requires your approval and a separate task.

## Keeping recipes current

Services change their settings and plan terms. During [maintenance](/ai-build-kit/how-it-works/#maintain-the-project), a script flags recipes whose documentation review is more than 90 days old, recipes no longer offered, and projects still using superseded setting names. The script reports these findings without changing your project or service settings.
