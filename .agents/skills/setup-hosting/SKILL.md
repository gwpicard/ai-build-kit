---
name: setup-hosting
description: Set up or check how the tool runs live, including moving it to another host or recipe. The first run connects each merge to main to a deploy; this skill never merges code. Follow the build path and only its required evidence, review and launch steps.
---

# Setup hosting

The first run puts `main` live and connects later merges to deploy. A later run
compares the live copy with `main` and repairs differences.

## Before acting

Read the build path in the masterplan. If a `Recheck when` item occurred since
`Last checked`, run `fit-check` first. For each sensitive area, say whether
its caution is done, accepted or not yet done. On Build with care, run the
sensitive-area check and stop if it disagrees.

Read the `Recipe:` line in AGENTS.md's stack section and the matching folder's
`recipe.md`, not `PROVEN.md`. An old `.md` recipe name means its folder.
`Recipe: none`, a missing line or folder means off-recipe; say so once. If a
live address is recorded, follow `references/later-run.md`. Leave open pull
requests open; say `/implement` merges one after a yes, which puts it live.
Python document work and a read-only link to an existing database are not offered yet.

## Follow the build path

Follow only the matching path and stop where it says.

### Explore privately

Confirm data is disposable, nobody relies on the tool,
there are no consequential automatic actions and any preview is private. Say
it is not approved for real use, record what Build and run it would need, then
stop.

### Build and run it

Load `references/build-run.md`.

#### On a recipe

Follow `recipe.md` in order, run its action scripts from the project root and
follow any hosting request it names. Then load `references/recipe-launch.md`.

#### Off a recipe

Load `references/recipe-launch.md`. For a server this session
cannot reach, use `references/hosting-request.md`.

### Build with care

Outside named areas, follow Build and run it. For an area,
follow `fit-check`'s “An area going live”.

Before any live change, load `references/live-records.md`.

Connect one service at a time, starting with harmless parts. Never print what
the hosting request record contains. Give the live-change warning before asking
the person to go live.

When going live changes the build path or names a sensitive area, record why,
its caution and which work continues or waits.

## Done when

The address is recorded, each check has its line, warnings and gaps are in one
dated changelog entry, and no code was merged.
