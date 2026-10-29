## Checks and testing status

Checks cover error logs and health, including whether the live copy responds. A documented procedure is not proof of a real deployment test.

| Recipe | Recorded testing |
|---|---|
| [Vercel deployment record](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/PROVEN.md) | Deployment, health and database structure changes were tested in October 2026. Preview, rollback, secrets and logs remain untested. |
| [Coolify deployment record](https://github.com/gwpicard/ai-build-kit/blob/stable/.agents/skills/setup-hosting/recipes/nextjs-supabase-on-coolify/PROVEN.md) | Runs in September 2026 covered preview, deployment, one rollback by hand, secrets, logs and health. The newer rollback procedure has not been tried. Previews shared the production database, so isolation from production data remains unproven. Other deployment procedures have also changed since those runs and remain untested. |

Neither recipe has had a real test of backup, restore or access. Coolify’s record also marks sign-in and roles, database access rules, file storage, background jobs, email and updates as untested. Both records mark the project check and user interface as not yet tried. Vercel also marks Founding as not tried. The linked records give the full coverage and limits.

When a live address is set, the launch script blocks its live-address record if a backup is unconfirmed, a rollback method is not defined, or a later launch has no earlier build available. It records the tool as live only after these conditions pass. It cannot stop a host that deploys on merge. Other failed or incomplete recipe checks are reported as warnings.

## Outside a recipe

If no recipe matches your stack or host, the kit explains once that it provides no guarantees, including rollback, backup or launch validation. If you choose to continue, it records your decision and the date, then provides individual guidance. During maintenance, it may offer a move to a suitable recipe. Moving requires your approval and a separate task.

## Keeping recipes current

Services change their settings and plan terms. During [maintenance](https://gwpicard.github.io/ai-build-kit/how-it-works/#maintain-the-project), a script flags recipes whose documentation review is more than 90 days old, recipes no longer offered, and projects still using superseded setting names. The script reports these findings without changing your project or service settings.
