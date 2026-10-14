---
name: setup-ai-build-kit
description: Begin a new project, or resume a beginning that was interrupted. Use when the user types /setup-ai-build-kit or asks to start or set up a new tool. Runs once per project; if the founding documents already exist and are complete, say so and point at /implement. Do not use for new features or repairs on an existing project; both are shape.
---

# Setup AI Build Kit

You take a team from an idea to a project ready to build: interviewed,
assessed, documented, stood up. You write no feature code here. It is
resumable: read what exists, say which step you are resuming from, and carry
on.

## Conversation contract

Speak when the person needs to answer, decide, approve, understand a blocker,
or see a result that changes what they can do next. Finishing an internal step
is not a user-facing result by itself. Routine reading, research, setup, and
checking happen quietly. Do not narrate commands, searches, versions, retries,
waiting, or terminal output, and do not repeat a harness's own status text.

Ask every question in the shape clarify's "How to ask" section describes,
whichever step you are on.

Name a tool or service only when the person must choose it, pay for it, own
its account, grant it access, or understand a limit it puts on the product.
When you name one, say what it is in one plain sentence at the same moment.
Record technical choices in AGENTS.md.

Give the plain permission explanation once, immediately before a real
confirmation box. Do not announce that a confirmation might appear later.

## Founding ends with something stood up

No step below is a gate. Founding is finished when the project exists and a
checkpoint is saved, and that outranks any answer still outstanding. An answer
you want but do not need becomes an open question in the masterplan, with your
best guess beside it. A step that says to check something is a check, not an
interview question: record a gap as a setup task or open question and tell the
person what was recorded. A person who says to get on with it has answered
everything: take your guesses, say in one line what you assumed, and stand the
project up.

## 0. Resume safely

In Codex, before anything else, run this skill's
`templates/foundation/codex-github-check.py` with `python3`. On failure, give
its restart sentence and stop; do not sign in again or retry.

Run `scripts/bootstrap-project.sh` from this installed skill folder in the
project root. It creates only missing foundation files and never replaces one.
If the harness cannot run it, copy the missing files from
`templates/foundation/` to the paths it names. Where an existing `AGENTS.md`
lacks the installed-skill load rule, keep its instructions and add the
smallest compatible rule. If the script reports both a plugin and a separate
kit installation, stop and keep one: the plugin for one coding agent, the
shared skills for several. A broken link: say so plainly and offer to install
the kit again the same way. A setup note: say it once and record it as an open
question.

In Codex, run `scripts/setup-codex.py` with python3 and `--hooks` and say: "The
GitHub check runs when Codex starts; trust this project and review its hook
with /hooks, then restart." Never trust it for the person. On macOS, also run
it with `--shell-status` and give its offer once, outside the interview. On a
yes naming the file, run `--shell-install`; on a no, `--shell-decline`. Both
record the answer, so it is never asked again.

A folder holding `.ai-build-kit-version` is an installation waiting for a
project: found here without asking, however much it looks like the kit's
source. Only where `release-manifest.txt`, `.agents/tests/` and
`docs/MAINTAINING.md` sit at the root is this the kit's own source: stop and
say which of them you found. Never wait on a location otherwise.

Read the current state: whether masterplan.md, CHANGELOG.md and the pieces
exist, whether any look half-written, a placeholder still in
`.github/workflows/checks.yml`, uncommitted changes, an open question in the
changelog. Say where you are resuming from. Never overwrite a record without
saying so and getting agreement. Where `.agents/tmp/setup-notes.md` exists and
masterplan.md does not, say you are carrying on from those answers, read them
back as one short list, and wait for a yes.

## 1. Orientation

Before any technical action, say close to: "First I'll help turn your idea
into a small plan. Then I'll prepare a private working version, check that it
opens, and save a checkpoint. Nothing will be published or shared unless I
explain that separately and you approve it." For an existing project to adopt,
say you will understand what exists before anything changes. Say nothing about
GitHub yet. Skip this when a resumed session already said it.

## 2. Capability check

Run `scripts/check-tooling.sh` from this installed skill folder. It reports
whether Git, the GitHub command line tool and python3 are ready and signed in.
If the harness cannot run it, work through references/required-tools.md by
hand; its "When GitHub access fails" route applies to any GitHub failure.
Guide a missing tool's install by references/manual-setup.md.

Then work through references/capability-check.md and record the result in
AGENTS.md under Capability profile. A missing optional capability becomes a
setup task or a reduced-automation fallback, decided at the step that needs
it, never before the interview.

## 3. Fresh project, or adopting something that exists?

Ask whether code already exists: an app from an all-in-one builder, a tool
inside a chat assistant, an earlier attempt. If yes, follow
references/adopting.md, which reshapes the steps below.

## 4. Test the need for software

Test the idea against the ladder, cheapest first: a process change, a feature
in something already paid for, a spreadsheet or database view, an
off-the-shelf product, an automation in an existing service, a configured AI
chat, an agent skill, a form or no-code workflow, custom software. Ask: will it
keep records that build up? Will others use it without its maker? Should it
act on its own? Must it enforce rules?

Where custom software adds no real value over something cheaper, say so once,
plainly, with what would do instead, and carry straight on in the same reply.
Do not end the turn on it, ask which way they want to go, or send them on an
errand. If they want the tool anyway, record the cheaper option and their
choice in the masterplan and never raise it again.

## 5. Founding interview

Run the clarify skill. Settle overloaded terms, use concrete examples, run the
source check for an outside fact, settle a visual or behavioural question with
something they have or a throwaway prototype, and keep open questions visible.
It ends when your guesses keep being right. The reply that closes it also
shows the recipe menu (step 11).

Write each agreed answer into `.agents/tmp/setup-notes.md` before the next
question, as plain sentences under the question. Before the first write, make
sure `.gitignore` carries `.agents/tmp/`. Say nothing about the file.

## 6. Fit check and build path

Go through the `fit-check` skill: who will use it, then the consequence and
ownership questions, one at a time, guesses attached. Record in the notes: the
access setting, the build path and why,
each sensitive area and its caution, the recheck triggers, and today's date.
Before naming an area, work through the redesign options; if a redesign
changes the answers, run the check again. Where an area survives, give the risk
notice fit-check.md describes, once and in full, before any flagged work. If
the person carries on after it, write their acceptance into the notes with
their words and the date, so the masterplan's `Accepted:` line carries it, and
go on in that same reply with no further yes. If they do not, founding goes on
and the caution stays `not yet done`. A no to an ownership question becomes a
founding task, never a path move.

## 7. Write the masterplan

Create masterplan.md from templates/masterplan.md, in the present tense, the
build-path section first. Create CHANGELOG.md from its template, empty. Create
`.ai-build-kit-maintenance` from `templates/maintenance-record` with today's
date on its `founded` line, keeping any `codex-shell` line already there and
leaving the pass lines empty. Do not mention that file. Fill AGENTS.md's
project line and capability profile.

Replace README.md's project-name and purpose placeholders with a short
description. Where it has no placeholders, it is somebody's real file: leave it
exactly as it is and say in one line that the description went into
masterplan.md and AGENTS.md.

Fill the masterplan from the notes and the conversation, then delete
`.agents/tmp/setup-notes.md`.

Read the connections section back in plain words, and let the team confirm
each outside connection: their email, their calendar, whatever it reaches.

On Build with care, write the sensitive-area paths and any boundaries by
fit-check.md, read each area and its home back in plain words, and run the
sensitive-area check the bootstrap installed. On the other paths, leave the map
out.

Delete docs/MAINTAINING.md if it exists, in the same commit. If the project
needs a `.env`, copy `.env.example` to `.env`, confirm `.gitignore` lists it,
and never print its contents.

## 8. Review the masterplan

On Build with care only, review the masterplan before flagged work continues,
by the best independent method in the capability profile: an independent
subagent, a clean separate session, or a clean chat the person opens with a
prepared instruction. Where none exists, say so, record it in the changelog as
a gap to close before flagged work, and carry on. On the other paths, say in
one line that the review was skipped and why, and record that in the changelog.

## 9. Ownership check

Answer from the masterplan alone: can the team explain the main flow, who can
see and change what, where data, secrets and service accounts live, how to
carry on manually if the tool stops, and who owns alerts, backups, bills and
access? A no becomes a setup task, by fit-check.md's ownership rule. The
changelog records only that this check ran and when.

## 10. Cut the plan

Cut pieces sized for one sitting, in the order they unblock each other, each a
vertical slice through the whole tool: what the person can do or see when it is
done, its evidence, and its real dependencies. Never split one capability into
"database", "API" and "UI" pieces.

Before the first issue, run `sh scripts/found-issues.sh check` from the project
root. Exit 6 means `origin` is still the kit's own repository: change nothing
there, say so in one line, and ask for the person's own. With one, point
`origin` at it and check again. With none, save everything else and say the
pieces are created once the project has its own repository.

Say in one line what founding is about to do on GitHub: open the pieces as
issues, replace GitHub's labels with the kit's own, and remove a pull request's
branch once it merges. Name the repository as `owner/name` and whether it is
public or private, from the `repository` and `visibility` lines, or `unknown`.
On a public repository add that the plan will be public, and that they can ask
for a private one at any point. Carry on in the same reply either way. Where
they ask to stop, open no more issues, say the ones opened stay readable, and
save everything else.

Each piece becomes an issue in the shape the `records` skill's `references/pieces.md` describes. Where
the GitHub tool is not ready, guide it now by references/manual-setup.md; there
is no file-based substitute, and a private repository works as well. Run
`sh scripts/found-issues.sh prepare` to create the kit's labels,
delete the labels GitHub made by itself (`bug`, `documentation`, `duplicate`,
`enhancement`, `good first issue`, `help wanted`, `invalid`, `question`,
`wontfix`) while no issue exists, set `delete_branch_on_merge` and turn off
squash and rebase merges, and copy the issue template. Say which ones went,
from its `removed` and `kept` lines, and that merged branches are now removed.
A label it could not remove stays and founding carries on.

Open one issue per piece, label each shaped piece `ready` or with the `needs-`
label for its open question, and link real dependencies with GitHub's
blocked-by relationship. An idea left out becomes a closed issue labelled
`parked`, with the reason. Then run `sh scripts/found-issues.sh refresh` once.

Then load the `records` skill's `references/coverage-read.md` and run the coverage read.

Where the GitHub setup cannot be finished in this session, save everything
else, and name signing in the GitHub command line tool as the one remaining
step. Never invent a file in place of the issues.

## 11. Stand the project up

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

Once a recipe is chosen, build on its `Build stack:` line and record `Recipe:
<folder name>` in AGENTS.md's stack section. Run `scripts/check-tooling.sh
--recipe <recipe folder>` with the path `recipe-menu.sh` printed. A tool it
reports missing becomes a setup task for before the first /setup-hosting, named
once; it never stops founding.

On any stack, use managed services for sign-ins, payments and files. Never
hand-build those unless a person who does that work for a living owns a
different design on the record. Use references/manual-setup.md for any step
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
Build with care, where an area names a boundary, load the
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

The founding save is always this local checkpoint. Do not push it or open a
pull request, whatever the tool will grow into: founding said nothing would be
uploaded. The first upload waits until the first piece that pushes asks, as
"The first upload" in the `merge` skill's `references/merge.md` describes.

Finish with one command that proves the project starts, one small passing
check, a recorded preview or local run path, and the saved checkpoint. Load
references/completion-report.md and report in its shape.

## Done when

The build path is recorded, the records exist (masterplan.md, CHANGELOG.md, and
the pieces as issues), AGENTS.md contains the capability profile and project
commands, the masterplan has had whatever review its build path called for or a
changelog line saying why none ran, the initial state is saved as a local
checkpoint, the plan is made of visible pieces each labelled `ready` or with its
open question, one check passes, and the user has received the plain-language
completion report, which ends on a clean cut naming `/implement` and `/shape`
rather than an offer to build in this session.
