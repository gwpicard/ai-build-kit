# Offering a move onto a recipe

A project with no `Recipe:` line, `Recipe: none`, or a recipe no longer in the
installed setup-hosting skill's `recipes/` folder is off a recipe. Off a
recipe, /setup-hosting can only name what it could not check, so the monthly
visit may offer a move. It is never required. A name written with `.md` means
the folder of that name.

1. On a recipe, or with an open piece already proposing a move, stop here.
2. Read the menu now: each folder in `recipes/` holding a `recipe.md`, and its
   `Build stack:` and `Deploy target:` lines. Take every product name from
   those files.
3. A recipe is close when the project's code and dependency files show the
   same framework and the same data service. A different deploy target, or a
   missing Dockerfile or health route, still counts as close. A self-hosted
   copy of the data service does not, since it lacks the managed backups.
4. Where the person chose their own stack at founding, offer only a close
   recipe that is new since founding (not on the `founding-menu` line in
   `.ai-build-kit-maintenance`; with no such line, every close recipe counts
   once), or one the stack has grown close to since the commit that first
   saved masterplan.md.
5. Where a `recipe-move-declined` line exists, offer again only for a recipe
   it does not list, or after a saved change to the dependency files since its
   date.
6. With nothing left, say nothing. With several, take the best `Build stack:`
   match, or the first by name.
7. Offer once: name the recipe, the launch checks /setup-hosting would then
   run, and what the move would change (such as a Dockerfile and health
   route, a new deploy target, or dashboard-made tables moved into
   migrations). Never quote a price. Say nothing changes on a no.
8. On a yes, open a piece titled as a move onto the recipe, holding its folder
   name and the changes named. Do not make the move this visit. On a no,
   record `recipe-move-declined|<YYYY-MM-DD>|<recipe>|<menu recipes, comma separated>`,
   replacing any earlier line.
