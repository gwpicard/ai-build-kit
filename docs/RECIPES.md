# RECIPES.md: the recipe format

This is maintainer documentation and never ships. The kit reads recipes at run
time; it does not read this file. `.agents/tools/check-recipes.sh` enforces the
shape described here, and the validator runs it on every recipe, every shared
part and the blank.

A recipe fixes the whole stack and where the tool runs. The shape of the tool
picks the stack; the host decides which checks the kit can run itself. Each
stack and host pair is its own recipe.

## The current set

The pinned menu has two recipes and no optional parts. A recipe must fit the
tools the kit can check and use a stack the team can prove on every run. Both
recipes use strict TypeScript, Next.js 16 and hosted Supabase, on Vercel or
Coolify. The shared starter pins `next` and `eslint-config-next` to 16.4.2.
Python document work and a read-only link to an existing database remain drafts
in `.agents/tests/recipes-awaiting-run/parts/` until their runs are recorded.

1. Next.js and Supabase on Vercel. It suits dashboards, admin panels,
   approvals, CRMs, light ERP, trackers, HR, case management, booking, forms
   and portals. It is the work-team default because Vercel runs previews,
   launch and rollback, and the kit can run its checks on this computer.
2. The same stack on Coolify. It suits those tools when the team has a server,
   needs long-running work, or must keep processing on a server it chooses.
   Python document work is a draft, and no recipe offers it today. Its checks need the person or a companion to read the
   server and paste the result back.

Vercel Pro and Supabase Pro are the work-team default. Free plans remain
available. Their terms are recorded on each recipe. Supabase Free
pauses after low activity and has no backups; Vercel Hobby is for personal,
non-commercial use and permits one outside person through its preview gate.

The recipe set comes from the October 2026 research on tool types and stacks,
saved as `.agents/tmp/stack-research/2026-10-tool-types-and-stacks.md`. Git
ignores that folder, so the note stays on the maintainer's computer and this
section is the record of the decisions and their reasons. The research found
thin evidence on category shares, so this set covers the well-supported common
shapes rather than claiming to cover every tool.

The following stay off the road:

- Python-only stacks: Django with HTMX, FastAPI as the whole tool, Streamlit,
  Reflex and NiceGUI. They would need a second set of checks, and the research
  found weaker role or agent support for some of them.
- Other front ends: SvelteKit 3, Remix 3, React Router 8 and TanStack Start.
  The first three have recent breaking changes or thin agent support; TanStack
  Start is young and worth watching.
- Other sign-in services: Clerk, which gets expensive quickly for invitations
  and roles; Auth.js, which is maintenance only; and Better Auth as a default.
  Better Auth remains the route off Supabase.
- Other databases: Neon, self-hosted Postgres and self-hosted Supabase. Neon
  does not supply the same sign-in and file services; self-hosting leaves
  managed backups behind.
- Other job services: Inngest, whose server licence is SSPL and needs a second
  account, and Trigger.dev until a real run proves it.
- Other hosts: Netlify, which has no Python worker or free work gate;
  Cloudflare Workers, which is least portable; Fly.io, with no free plan or
  built-in previews; Render and Railway, with no built-in web gate found; and
  Dokploy, whose forward-auth and SSO need a commercial licence.
- Mobile apps that work offline. Field teams may need them, but offline sync
  is outside this web recipe set.
- Public sign-up and payments. Both need a risk notice and no recipe fixes
  their checks yet.
- Marker, because of its model licence.

The Python document worker draft targets Coolify. The read-only existing
database draft targets both recipes. Neither is offered until proven.

## A recipe is a folder

Recipes live in `.agents/skills/setup-hosting/recipes/`, one folder each, named
for the pair in lower case with hyphens. The folder holds three things, and a
fourth where a host needs one:

- `recipe.md`, which the kit reads at run time. Keep it concise because every
  word competes for the agent's attention.
- `scripts/`, one script for each check the kit can run on this computer,
  each action a section names, and `live-check.sh`.
- `PROVEN.md`, the record of the real run. The kit never loads it.
- `hosting-request.md`, only where a host needs a request from whoever runs
  the server. The Coolify recipe has one; the Vercel recipe does not.

The recipes folder is the menu: a folder in it with a `recipe.md` is offered
once it is there, and not before. `setup-hosting/templates/recipe.md` is the
blank `recipe.md` to copy.

## What recipe.md holds

It opens with fixed fields. Each names a tool only, so checks can read it.

- `Fits:` the shape of tool the recipe suits, in words the person would use.
- `Work-team default:` whether this is the default for a team.
- `Recommended when:` one plain sentence saying when founding should recommend
  this recipe over another that fits the same shape.
- `Language:`, `Framework:` (including the pinned major), `Typing:`,
  `User interface:`, `Database:`, `Sign-in:`, `Email:`, `Files:`, `Jobs:`, `Testing:` and
  `Linting:` name the whole stack.
- `Starter:` names the pinned starter folder, or says when it is coming.
- `Optional parts:` names the parts the recipe accepts, or `none`. A part
  already in the parts folder is named without a note. A planned part may say
  `(coming in part B)` or `(coming in part C)` until it
  is added.
- `Deploy target:` where it runs once it is live.
- `Health-check tool:` names the tool used to read the live health route.
- `Command-line tools:` the tools the recipe's scripts run on the person's
  machine, as command names separated by commas, or `none`. The setup tooling
  check reads this line and reports each one, and a missing one never stops
  founding, because only a project on this recipe needs it.
- `Last checked:` a date, written YYYY-MM-DD, when somebody last read the
  recipe against the current documentation of everything it names. The date
  moves only when somebody did that.
- `Last proven:` the date of the latest real run, which matches `PROVEN.md`.
- `Proven on:` the tool versions recorded for that run.
- `Superseded settings:` environment variable names a script can check in a
  project's settings files, or `none`. `/maintain` offers to move a project
  that still records one of these names.

One or more `Plan terms:` lines may follow. Each says, in one plain sentence,
which rule of a free or entry plan the person should read before choosing. It
points to the service's own page and never interprets it, because what a
service's terms mean is between the person and that service. It ends with when
and where the terms were read, as
`(read YYYY-MM-DD at <source page>)`, from the service's own page. Terms change
without notice, and a restriction with no date cannot be told from a current
one. The line never quotes a price. Founding reads it when it offers the
recipe and tells the person to read the terms themselves.

The shared stack part holds sign-in and roles, row rules, files, jobs, email,
the user interface, the project check and updates. Each section carries the same four lines as a
recipe section. The access gate stays in each recipe because it differs by
host. The starter workflow checks row rules against a local database built
from migrations on each pull request and push to main. The launch check reads
the live database.

Then comes one section for each of the eight things a live tool needs, in this
order: preview, going live, rollback, backup, restore, secrets, logs and
health.

- Preview is how a change is seen somewhere safe before it goes live.
- Going live is how a checked change reaches the live address.
- Rollback is how the live tool goes back to the last version that worked.
- Backup is what is saved, where, and how often.
- Restore is how a backup is put back, and roughly how long that takes.
- Secrets is where keys live and how they reach the tool.
- Logs is where the tool's record of requests and errors is read.
- Health is how anyone knows the live tool is up.

A ninth section, access, follows health. Every recipe carries it, because
every tool is private by default. It says how private keeps out everyone not
invited, with sign-up closed and the host's gate where the host has one, and
how public takes the gate off. Where a host has no gate, or only on a paid
plan, it says so plainly, and the check covers what it can. Its script reads
the live tool and compares it with the masterplan's `Access:` line, and fails
when they differ either way. A script that changes the setting changes a live
service, so the coding agent's settings ask before it runs.

Each section carries four lines, and a fifth where the kit does not run the
check itself.

- `How it works:` what happens on this pair, in the order it happens, naming
  the scripts that act, such as one that connects the host or applies
  migrations.
- `How it is checked:` what a pass means, in plain words.
- `Script:` the check, as `scripts/<name>.sh`, read from the folder of the file
  it is written in. The shared stack's Project check names
  `starters/nextjs-supabase/.github/workflows/check.yml` instead.
- `Who runs it:` one of three values. `the kit` when the kit runs the check
  itself. `a companion or the person, result read back` when the check needs
  somewhere the kit cannot reach, and the script reads what is pasted back. `a
  person looking` when no machine can judge the result; the script reads
  whatever a machine can, and the person's answer decides.
- `Ask:` the fixed words the person hears, for a section the kit does not run.
  The runner prints them, so every launch asks the same way.

A section with no check is not finished. Saying the service handles it tells
nobody how they would find out that it did not.

## Scripts

Every script runs from the project's folder and decides by its exit code: 0 a
pass, 1 a fail, 2 could not run, such as a missing tool or an unknown location.
Its last line is one plain sentence saying what it found, and that sentence is
what the person hears. A script never prints a secret. A password is read
inside the script from the location the masterplan records.

A check whose result is pasted back takes `--pasted <file>` and reads it.
Where the paste has a fixed shape, such as a health answer or a list of names,
the script reads that shape, so the kit never judges it by eye.

`live-check.sh` makes the six reads a later `/setup-hosting` run and every
`/maintain` visit make: the live copy against `main`, a hold since a rollback,
a migration not applied, setting names on the host, health and access. It changes
nothing. Exit 0 means no gap, 1 a gap, and 2 that a read could not be made.

The Vercel recipe's `get-supabase-keys.sh` writes the publishable and secret
keys to private files. `add-secret.sh` reads one file on standard input, checks
Supabase key shapes, and removes an existing production setting only after a
valid value when `--replace` is given. A Vercel setting change needs a new
build before production uses it: `vercel redeploy <production deployment URL>`.

`setup-hosting/scripts/run-recipe.sh` runs a recipe's nine checks in its
order, prints one line for each, and writes the run's dated changelog entry. A
warning the changelog already holds comes back as a pointer. With no recipe it
gives one notice that nothing is guaranteed, records the person's words and the
date, and checks nothing.

## Shared parts

Two recipes often share a half. A stack deployed in two places keeps the same
data service, so its backup and restore read the same in both. Such a section
is written once, as a part in `recipes/parts/`, and a recipe links it in place
of writing the section out, with one line: `Shared part:` followed by a
Markdown link to `../parts/<file>.md`. A part holds the lines a section would,
and its script sits in `recipes/parts/scripts/`. Scripts several recipes use,
such as the migration read, sit there too, beside `check-lib.sh`, which they
all share. The parts folder holds no `recipe.md`, so nothing reads it as a
menu entry.

When it copies a starter with a project workflow, `use-starter.sh` also copies
the shared `rls.sh` and `check-lib.sh` into the project's `scripts/` folder.
It refuses existing files before copying anything. The workflow can then run
the same row rules query whichever coding agent installed the kit, including
a plugin whose files stay outside the project. Its `--local` option reads the
disposable database and never reads a linked database password or the live
security advisor. The workflow uses the database container's PostgreSQL 17.6
client, so the host needs no separate client installation.

The recipe workflow reports `recipe-check`. The foundation reports
`project-check`. Founding requires both when the recipe workflow is present,
so a failed recipe check also blocks a merge on GitHub. Existing protection
keeps its other required checks and settings.

## Settings the kit can read

A recipe may carry one more section, `## Settings the kit can read`, after
access. It names the script that reads settings of the services the tool runs
on with a key the project already sends to the browser, so the launch review
reads them rather than asking the person. It carries the same lines as the
others, or a `Shared part:` link. It is not one of the nine, and the runner
gives it no line. `PROVEN.md` gives it an outcome line like each of the nine.

## What proven means

A recipe joins the menu only when two things are true. A rehearsal named
`.agents/tests/recipe-<name>.sh` runs every script it names against stand-ins
for its tools, to a pass and to something else, and then runs the whole recipe
through the runner. And one real deploy has been run from an empty project to
a live address, with the maintainer's approval and accounts, and written down.
The goal is a real run through all nine sections. That goal is not yet met.
The `PROVEN.md` of each current recipe lists which sections a real run covered
and which are still untried, and it is the only record of what is proven. A
shared part proven once, in another recipe's real run, counts for every recipe
that links it, and its outcome line says so.

A section added after the real run is marked unproven: its outcome line says
`No real run yet` after the section's name, and gives the date it was added.
That does not take the recipe off the menu. The next real run covers it.

`PROVEN.md` opens with `Real run:` and the date, then gives one outcome line
for each of the nine sections, starting with the section's name, saying what
was done and what came out.

A recipe waiting for its real run sits in `.agents/tests/recipes-awaiting-run/`
as a folder of the same shape, which ships nowhere, and its rehearsal reads it
there. Its `PROVEN.md` says `Real run: awaiting the first real run`, and the
shape check must fail on that line alone. Once the run is recorded, move the
folder into the recipes folder with `git mv`. There is no draft state, because
a draft on the menu would be offered.

When a recipe leaves the menu, keep its name and the route to a current recipe
in `maintain/references/recipe-move.md`. `/maintain` reads that route for a
project that still records the retired recipe and offers a move that requires approval.

A change to what a section does, in `recipe.md`, a part or a script, needs a
new real run before the next release. Moving a command from prose into a
script, unchanged and in the same order, does not.

## Where product names go

A recipe folder names the services the person's tool runs on: its hosting,
its data and its deploy. That is its job, and the README may name them as
well. No other file in the kit names one. A skill that needs to know how one
behaves reads the project's recipe, so the skills read the same whichever
recipe a project runs on.

## Where a project records its recipe

A project names its recipe in its own AGENTS.md, in the stack section, as
`Recipe: <folder name>`, or `Recipe: none` when the person chose their own
stack or no recipe fits. A project founded before recipes became folders
names the file, `Recipe: <folder name>.md`. The kit reads that as the folder,
and `/maintain` offers to rewrite the line.
