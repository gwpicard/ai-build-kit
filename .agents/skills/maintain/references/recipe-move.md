# Offering a move onto a recipe

A project with no `Recipe:` line, `Recipe: none`, or a recipe no longer in the
installed setup-hosting skill's `recipes/` folder is off a recipe. Off a
recipe, /setup-hosting can only name what it could not check, so the monthly
visit may offer a move. It is never required. A name written with `.md` means
the folder of that name. A project whose stack still records `Build stack:`
uses the old recipe format and may also be offered a move.

1. On a current recipe without an old `Build stack:` line, or with an open
   piece already proposing a move, stop here.
2. Read the menu now: each folder in `recipes/` holding a `recipe.md`, and
   its language, framework, database, sign-in, and deploy target fields. Take
   every product name from those files.
3. A recipe is close when the project's code and dependency files show the
   same language, framework and database. A different deploy target, or a
   missing Dockerfile or health route, still counts as close. A self-hosted
   copy of the data service does not, since it lacks the managed backups.
4. Where the person chose their own stack at founding, offer only a close
   recipe that is new since founding (not on the `founding-menu` line in
   `.ai-build-kit-maintenance`; with no such line, every close recipe counts
   once), or one the stack has grown close to since the commit that first
   saved masterplan.md.
5. Where a `recipe-move-declined` line exists, offer again only for a recipe
   it does not list, or after a saved change to the dependency files since its
   date. The widened-format offer is made once for the named recipe.
6. With nothing left, say nothing. With several, take the closest match across
   the stack fields, or the first by name.
7. Offer once: name the recipe, the launch checks /setup-hosting would then
   run, and what the move would change (such as a Dockerfile and health
   route, a new deploy target, or dashboard-made tables moved into
   migrations). Never quote a price. Say nothing changes on a no.
8. On a yes, open a piece titled as a move onto the recipe, holding its folder
   name and the changes named. Do not make the move this visit. On a no,
   record `recipe-move-declined|<YYYY-MM-DD>|<recipe>|<menu recipes, comma separated>`,
   replacing any earlier line. For the widened-format offer, record a no with
   `--decline recipe-format`; the check writes `recipe-move-declined` and leaves
   the project files alone.
