# RECIPES.md: the recipe format

This is maintainer documentation and never ships. The kit reads recipes at run
time; it does not read this file. `.agents/tools/check-recipes.sh` enforces the
shape described here, and the validator runs it on every recipe, every shared
part and the blank.

A recipe is one build stack paired with one place to run it, which the kit
knows well enough to check. The shape of the tool picks the stack: a web app
with sign-in and saved data wants a different one from a static site. The
place to run it is where the tool lives once people use it. Each pair is its
own recipe, so a stack that runs in two places is two recipes.

## A recipe is a folder

Recipes live in `.agents/skills/setup-hosting/recipes/`, one folder each, named
for the pair in lower case with hyphens. The folder holds three things:

- `recipe.md`, which the kit reads at run time. It stays short, around 700
  words, because every word competes for the agent's attention.
- `scripts/`, one script for each check the kit can run on this computer,
  each action a section names, and `live-check.sh`.
- `PROVEN.md`, the record of the real run. The kit never loads it.

The recipes folder is the menu: a folder in it with a `recipe.md` is offered
once it is there, and not before. `setup-hosting/templates/recipe.md` is the
blank `recipe.md` to copy.

## What recipe.md holds

It opens with six lines.

- `Fits:` the shape of tool the recipe suits, in words the person would use.
- `Recommended when:` one plain sentence saying when founding should recommend
  this recipe over another that fits the same shape.
- `Build stack:` what the tool is built with.
- `Deploy target:` where it runs once it is live.
- `Command-line tools:` the tools the recipe's scripts run on the person's
  machine, as command names separated by commas, or `none`. The setup tooling
  check reads this line and reports each one, and a missing one never stops
  founding, because only a project on this recipe needs it.
- `Last checked:` a date, written YYYY-MM-DD, when somebody last read the
  recipe against the current documentation of everything it names. The date
  moves only when somebody did that.

A seventh line may follow. `Plan terms:` says, in one plain sentence, who a
free or entry plan the recipe relies on is not for, and which plan such a
person needs instead. It ends with when and where the terms were read, as
`(read YYYY-MM-DD at <source page>)`, from the service's own page. Terms change
without notice, and a restriction with no date cannot be told from a current
one. The line never quotes a price. Founding reads it when it offers the
recipe, and says it only to a person it applies to.

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
  it is written in.
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

`setup-hosting/scripts/run-recipe.sh` runs a recipe's nine checks in its
order, prints one line for each, and writes the run's dated changelog entry. A
warning the changelog already holds comes back as a pointer. Off a recipe it
lists the nine section names as warnings and nothing more.

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
a live address and through all nine sections, with the maintainer's approval
and accounts, and written down. A shared part proven once, in another recipe's
real run, counts for every recipe that links it, and its outcome line says so.

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
