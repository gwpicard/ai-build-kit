# Stand the project up

Ask whether the team will use it in a browser and whether it must work when
this computer is off, unless the interview already said. Name the app's shape
in one plain sentence, such as "a web app your team signs in to, with saved
data".

The recipe menu is the folders in the installed setup-hosting skill's
`recipes/` folder that hold a `recipe.md`, read now. Keep the ones whose
`Fits:` line fits the shape, and run `scripts/recipe-menu.sh` from this
installed skill folder with `--record .ai-build-kit-maintenance` and those
recipes, or `--none`. Exit 3: several fit, and it prints what each says;
recommend the one whose `Recommended when:` line best matches the interview, or
the first by name, and run it again with `--recommend <recipe>`. Exit 4: a name
is not on the menu; correct it. Exit 0: it printed the lines to say. Any other
exit: follow these rules by hand.

Run it once the shape is known, and put its lines word for word in the reply
that closes the interview, never only in the reply that reports the stand-up.
After the numbered list and before its last sentence, say for each recipe in
plain words what the kit can check at launch on it (such as preview, rollback,
backup and restore), which accounts the person will hold, and whether the tool
runs on a hosting platform or a server they rent. Take every product name from
the recipe now. Never quote a price. Where the tool is for a work team or paid
work, say a recipe's `Plan terms:` line once, beside it; never call that
account free. For a personal project leave it out; where unclear, give it once
as a condition. That reply ends on its own question, and founding carries on
with the recommended recipe unless they pick another.

If they choose their own stack, say once what the kit then cannot check,
record `Recipe: none`, and do not raise it again. Where no recipe fits the
shape, the script's line says so; record `Recipe: none` and set up on one
established, conventional stack.

Once a recipe is chosen, build on its fixed stack fields and record `Recipe:
<folder name>` in AGENTS.md's stack section. Run `scripts/check-tooling.sh
--recipe <recipe folder>` with the path `recipe-menu.sh` printed. A tool it
reports missing becomes a setup task for before the first /setup-hosting, named
once; it never stops founding. Run `scripts/use-starter.sh <recipe folder>`
with that same path. For a project without a recipe, copy
`templates/foundation/env.example` to `.env.example`.

On any stack, use managed services for sign-ins, payments and files. Never
hand-build those unless a person who does that work for a living owns a
different design on the record. Use `manual-setup.md` beside this file for any step
only a person can do. If hosting is needed, arrange for pushes to land at a
preview address, by the recipe's preview section where there is one.
/setup-hosting sets up the team's address later.

Choose routine technical parts quietly. Record run and check commands and any
unusual conventions in AGENTS.md's stack section. Record a design tool named in
the interview, or `Design tool: none recorded`. If the interview surfaced
confidential working files, create their folder, add it to .gitignore and to
the list of files carried into a working copy (`.worktreeinclude` in Claude
Code), and record their handling rules in AGENTS.md.

If `.github/workflows/checks.yml` is missing, copy it from
`templates/foundation/checks.yml`. Edit only `jobs.project-check`, replacing
the placeholder `Install and test` commands with the project's real ones, never
rewriting the file from memory. Leave an older `source-kit-validation` job
alone. Load the `quality-checks` skill's `references/check-floor.md` for the type check and linter. On
a hosted database recipe, part D adds the row rules check against migrations
and a local database. The launch check reads the live database.
On Build with care, where an area names a boundary, load the
`quality-checks` skill's `references/boundary-rules.md` and offer once to have the check hold it.
Explore privately needs a local check; the other paths need the remote check
working before shared or live work. Say once: "green means the tests really
passed; red means don't merge, tell /implement."

Before starting the unfinished tool to prove it runs, say close to: "I'm going
to start the unfinished tool briefly and check that its main page opens at the
recorded address. It will run only on this computer, nothing will be
published, and I'll stop it again once the check is done." Then give AGENTS.md's
warning that a confirmation box may appear next.

Before saving, say close to: "The initial setup is ready to save. I'm going to
save a checkpoint inside this project so this working state can be recovered
later. Nothing will be uploaded."

Save with `sh scripts/found-save.sh` from the project root. It sets the
neutral "Local project user" label only where no save name is set, never
copying an earlier author, saves the checkpoint, writes its hash into the
masterplan's `Trued against:` line in a second records-only checkpoint, and
checks the mark. Until then the line keeps `not yet checked`. Any exit other
than 0 means no checkpoint was made: say what its line says. An `identity`
line saying `neutral` gets one line: the checkpoint carries that label, it can
be changed, and nothing was uploaded; record the real identity as an open
question. A `left` line names a change left unsaved; say so in one line.

The founding save is always this local checkpoint, as the skill says.

Finish with one command that proves the project starts, one small passing
check, a recorded preview or local run path, and the saved checkpoint. Load
`completion-report.md` beside this file and report in its shape.
