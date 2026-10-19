---
name: setup-hosting
description: Set up or check how the tool runs live, including moving it to another host or recipe. The first run connects each merge to main to a deploy; this skill never merges code. Run the evidence run and the review first, and record any risk area's caution.
---

# Setup hosting

The first run puts `main` live and connects later merges to deploy. A later run
compares the live copy with `main` and repairs differences.

## Before acting

Read the risk record in the masterplan. If a `Recheck when` item occurred since
`Last checked`, run `fit-check` first. For each risk area, say whether its
caution is done, accepted or not yet done. Run the risk-area check and
stop if it disagrees.

Read the `Recipe:` line in AGENTS.md's stack section and the matching folder's
`recipe.md`, not `PROVEN.md`. An old `.md` recipe name means its folder.
`Recipe: none`, a missing line or folder means no recipe: hosting is offered
only on a recipe. If a live address is recorded, follow
`references/later-run.md`. Leave open pull requests open; say `/implement` merges one after a yes, which puts it live.
Python document work and a read-only link to an existing database are not offered yet.

## Launch

Load `references/build-run.md`.

### On a recipe

Follow `recipe.md` in order, run its action scripts from the project root and
follow any hosting request it names. Then load `references/recipe-launch.md`.

### On no recipe

Load `references/recipe-launch.md`: one notice, the choice recorded, no
refusal. Then help by hand. For a server this session cannot reach, use
`references/hosting-request.md`.

For a risk area, follow `fit-check`'s "Rechecks and going live".

Before any live change, load `references/live-records.md`.

Connect one service at a time, starting with harmless parts. Never print what
the hosting request record contains. Give the live-change warning before asking
the person to go live.

When going live changes the risk record or names a risk area, record why,
its caution and which work continues or waits.

## Done when

The address is recorded, each check has its line, warnings and gaps are in one
dated changelog entry, and no code was merged.
