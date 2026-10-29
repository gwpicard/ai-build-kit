---
title: Live data and recovery
description: Understand what hosting checks do with live and local data.
draft: false
---

## Restore check

For a hosted Supabase database, the recipe's restore check copies the live database to this computer and tries to restore it into a temporary local database. It stops the project's local database first because the restore uses the same ports. The check removes the temporary copy afterwards. It reads the live database but does not restore anything onto it. See [hosting recipes](/ai-build-kit/recipes/) for the steps and their test status.

This check is not the same as restoring a backup to the live service. A live restore starts from the service dashboard and may make the service unavailable while it runs. `/setup-hosting` runs the recipe's backup, restore and preview checks when they are due or needed.

## Previews

A preview can use live data if the recipe shares the production database with preview deployments. Check the recipe before using real data in a preview. Keep test data separate from live data where the recipe provides that option.

## Limits and service terms

The checks provide evidence about the tool, but do not establish that it is safe for every purpose. The kit cannot replace a professional developer or provide legal, medical, financial or security advice. You use the kit and its output at your own risk. The terms of the services you run the tool on, such as a host or database plan, are between you and those services. You are responsible for reading and following them.
