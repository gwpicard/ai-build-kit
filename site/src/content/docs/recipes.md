---
title: Hosting recipes
description: What a hosting recipe is, which recipes exist, and what has been tried on each.
draft: false
---

A hosting recipe fixes one software stack and one place to run it. It settles in advance how a change is previewed, goes live, is backed up, is restored and is rolled back to an earlier version, so you do not have to decide any of that. The kit offers hosting only on a recipe, because the guarantees it can check depend on one.

## What a recipe contains

Each recipe is a folder. Its instructions name the language, framework, database, sign-in, email, file storage, background jobs and test tools, and point to a starter project. They then describe ten parts of running a live tool: preview, going live, rollback, backup, restore, secrets, logs, health, access and the settings the kit can read.

Each part says what happens, what a pass means and which script checks it. The script ends with a pass, a failure or "could not run", plus one plain sentence. Some checks need a person or a companion tool to read a server and paste the result back; the recipe then holds the fixed question to ask. Each folder also holds a record of what was tried on a real deployment. The kit never reads that record while it works.

## The recipes today

The kit has two recipes. Both use TypeScript, Next.js 16 and Supabase.

- **Next.js and Supabase on Vercel** is the default for a work team. Vercel handles previews, going live and rollback, and the kit can run its checks on your computer. Private tools need a Vercel account for each person with access.
- **Next.js and Supabase on Coolify** suits a team that rents its own server. It also suits long-running work. Its checks often need you, or a companion tool, to read the server and paste the result back.

They suit dashboards, admin panels, approvals, customer trackers, light stock and order tools, portals, booking and forms. Each recipe records the plan terms of the services it uses, for example that a free plan is for personal use only.

## What a real run showed

A recipe joins the menu after it has been run on real accounts, from an empty project to a live address, with the maintainer's approval. Each recipe's record says exactly what that run covered.

On Vercel (16 October 2026), the production address answered its health check at commit `29f8b0c`, and two database migrations were applied. Preview, rollback, backup, restore, secrets, logs, access, the settings the kit can read and founding are recorded as not tried.

On Coolify (September 2026), a throwaway app on a rented server went through preview, launch, rollback, secrets, logs and health on a private network. A second run on a public address covered only preview and going live. The rollback button had to be pressed by hand in Coolify, because no script could press it. Backup, restore, access and the settings the kit can read were not run on this recipe.

Parts added after a run are marked "No real run yet" in the record until a later run covers them. On Coolify these are sign-in and roles, row rules, files, jobs, email, the project check and updates. Founding has no real run on either recipe.

## Outside a recipe

If your stack or host matches no recipe, the kit says once that it guarantees no rollback, no backup and no checked launch. It records your reply with the date, and it carries on helping by hand. It does not refuse. A project on its own stack can also be offered a move to a close recipe at a maintenance visit. A move happens only after you agree.

## Keeping recipes current

Services rename settings and change plan terms. Each recipe therefore records the date it was last read against the services' own documentation, the date of its last real run, the versions it was run on, and any setting names that have since been replaced. At each maintenance visit, a script reports a recipe that was last checked more than 90 days ago, that has left the menu, or whose replaced setting names the project still uses. Before each release the maintainer reads every recipe against upstream changes and records proposals in a dated note, which changes nothing by itself.

## Why well-known stacks

The kit prefers stacks that many people use and that the tools it checks support well. A recipe must fit the checks the kit can run, and use a stack the team can prove on every run. The maintainer's research found weaker agent support or recent breaking changes in several alternatives, and a second set of checks would be needed for a Python-only stack, so these stay off the menu. The research also found thin evidence on how many tools each category covers. The two recipes therefore cover common shapes of tool, not every tool.

## What comes next

Written down today: two draft recipe parts wait for a real run, Python document work on Coolify and a read-only link to an existing database. Neither is offered until its run is recorded. Open work items plan a real run on every command of each final recipe, and a routine that keeps recipes current. These items are public on GitHub.

The intended direction is more recipes for well-known stacks, each tried and hardened on real accounts, so that the kit grows more reliable on a stack the more it has been run there. There is no schedule, and no further recipe is promised.
