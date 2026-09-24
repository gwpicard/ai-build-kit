# The recipe format

A recipe is one build stack paired with one place to run it, which the kit knows
well enough to check. The shape of the tool picks the stack: a web app with
sign-in and saved data wants a different one from a static site. The place to
run it is where the tool lives once people use it. Each pair is its own recipe,
so a stack that runs in two places is two recipes, and each file stands alone.

Recipes live in `ship/recipes/`, one file each, named for the pair in lower case
with hyphens. The folder is the menu: a recipe is offered once its file is there,
and not before. `ship/templates/recipe.md` is the blank to copy.

## What a recipe holds

The file opens with four lines.

- `Fits:` the shape of tool the recipe suits, in words the person would use.
- `Build stack:` what the tool is built with.
- `Deploy target:` where it runs once it is live.
- `Last checked:` a date, written YYYY-MM-DD, when somebody last read the recipe
  against the current documentation of everything it names. The date moves only
  when somebody did that.

Then comes one section for each of the eight things a live tool needs, in this
order: preview, going live, rollback, backup, restore, secrets, logs and health.

- Preview is how a change is seen somewhere safe before it goes live.
- Going live is how a checked change reaches the live address.
- Rollback is how the live tool goes back to the last version that worked.
- Backup is what is saved, where, and how often.
- Restore is how a backup is put back, and roughly how long that takes.
- Secrets is where keys live and how they reach the tool.
- Logs is where the tool's record of requests and errors is read.
- Health is how anyone knows the live tool is up.

Each section carries two lines. `How it works:` says what happens on this pair,
in the order it happens. `How it is checked:` says how anyone would know it
worked, by machine where a machine can judge it, naming the command or check and
what a pass looks like. Where no machine can, name who checks by hand and what
they look at. A section with no check is not finished. Saying the service
handles it tells nobody how they would find out that it did not.

The file ends with a `## Proven` section, which holds the record of the real run.

## What proven means

A recipe joins the menu only when two things are true. Offline rehearsals guard
its rules, so a maintainer check reads the recipe and fails when a rule goes
missing. And one real deploy has been run from an empty project to a live
address and through all eight sections, with the maintainer's approval and
accounts, and written down.

The record lives in the recipe's own proven section, so it travels with the
recipe and anyone can read what was tried. It opens with `Real run:` and the
date, then says for each of the eight sections what was done and what came out.
A recipe without its real run stays out of the folder. There is no draft state,
because a draft in the folder would be on the menu.

## Where product names go

A recipe names the products it uses. That is its job, and the README may name
them as well. Nothing else in the kit does. A skill that needs to know how a
product behaves reads the project's recipe, so the skills read the same whichever
recipe a project runs on.

## Where a project records its recipe

A project names its recipe in its own AGENTS.md, in the stack section, as
`Recipe: <file name>`, or `Recipe: none` when the person chose their own stack.
It does not go in the build-path block. The build path says how carefully the
work is built and the recipe says what it runs on, and the two change for
different reasons.

A project on its own stack still works with the kit, with fewer promises. On a
recipe the kit can check each of the eight sections by machine. On a stack it
does not know, it can only name what it could not check.
