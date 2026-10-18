# Stand the project up

Ask whether the team uses a browser and needs the tool when this computer is
off, unless answered. Describe it in one plain sentence.

Read `recipe.md` files in the installed `setup-hosting/recipes/`. Keep recipes
whose `Fits:` line matches. Run `scripts/recipe-menu.sh` from this installed
skill with `--record .ai-build-kit-maintenance` and the matching recipes or
`--none`. Exit 3 means several fit: recommend the best `Recommended when:`
match, or the first by name, then rerun with `--recommend <recipe>`. Exit 4:
correct an invalid name. Exit 0: use its printed lines. Handle other exits by
these rules.

Include menu lines word for word in the closing reply. After the list, explain
launch checks, account ownership, and whether the recipe runs on a platform or
rented server. Use recipe product names, not prices. For work or paid use,
include `Plan terms:` once; omit it for personal use. If
unclear, state the condition. End with the menu question and continue with the
recommendation unless they choose another recipe.

If they choose another stack, record `Recipe: none`, explain what the kit
cannot check, and do not raise it again. If no recipe fits, record none and
use an established stack.

For a chosen recipe, use its fixed stack fields; record its folder name in
AGENTS.md. Run `scripts/use-starter.sh <folder>` with the menu's path.
If the harness refuses a starter command, say so in one plain line and ask
whether to build the starter another way. Wait for yes before writing
replacement starter files.
Starter exit 1: list clashing files and ask which to keep. Exit 2: say what
could not run. With no recipe, copy `templates/foundation/env.example` to
`.env.example`.

Use managed services for sign-in, payments and files. Hand-build them only if
a professional responsible for the work owns another recorded design.
For tasks only the person can do, follow `manual-setup.md`. If hosting is
needed, arrange a preview address using the recipe; `/setup-hosting` sets up
the team's address later. Record run/check commands, unusual conventions, and
the interview's design tool in AGENTS.md. If none, record
`Design tool: none recorded`. If confidential files came up, create and ignore
their folder, include it in the working-copy file list, and record handling
rules in AGENTS.md.

If `.github/workflows/checks.yml` is missing, copy the foundation template and
edit only `jobs.project-check` with install and test commands. Preserve
`source-kit-validation`. Follow `quality-checks/references/check-floor.md` for
type checks and linting. On Build with care, use
`boundary-rules.md` and offer once to have the check hold the named boundary.
Explore privately needs a local check; other paths need a working remote
check before shared or live work. Say: "green means the tests passed;
red means don't merge, tell /implement."

Before starting the unfinished tool, say it will check the recorded main page
on this computer, publish nothing, then stop. Give AGENTS.md's
warning about a possible confirmation box. Before saving, say it will save a
local checkpoint and upload nothing.

Then run `scripts/check-tooling.sh --conditions`, with `--recipe <folder>` for
a chosen recipe. It opens and closes one test issue. A non-zero exit stops
founding: give each `missing:` line and its step, and save no checkpoint.

Run `sh scripts/found-save.sh` from the project root. It makes the local
checkpoint and checks its record. Any non-zero exit means no checkpoint was
made; report the script's line. If identity is `neutral`, say the checkpoint
uses that changeable label, nothing was uploaded, and record the real identity
as an open question. If a `left` line names unsaved work, report it.

Finish with a command that proves the project starts, a passing check, a
recorded preview or local run path, and the saved checkpoint. Follow
`completion-report.md` for the report.
