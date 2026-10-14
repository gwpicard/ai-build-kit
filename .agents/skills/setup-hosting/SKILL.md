---
name: setup-hosting
description: Set up how the tool runs live, and run it again to check or change that. Use when the person wants people to use the tool, wants to check the live copy against main, or wants to move it to another host or recipe. The first run sets the host up so that each merge to main deploys; after that a merge is a deploy, and /implement makes each merge on the person's yes. This skill never merges code. Follows the project's current build path and applies only the evidence, review, or launch steps that path requires.
---

# Setup hosting

The live copy is the one the team uses. The first run takes what `main` holds
live and sets the host up so each later merge reaches it; after that a merge
is a deploy, and /implement makes it on the person's yes. A later run compares
the live copy with `main` and repairs what differs.

## 0. Before anything

Read the masterplan's build-path section. If anything under `Recheck when` has
happened since `Last checked`, run the fit check first. For each line under
`Sensitive areas`, say whether its caution is done, accepted or `not yet done`.
On Build with care, run the shipped sensitive-area check and stop if it does
not agree with the project.

Read the `Recipe:` line in AGENTS.md's stack section. It names a folder in this
skill's `recipes/`; a name written with `.md`, as older projects record it,
means the same folder. Read that folder's `recipe.md`, never its `PROVEN.md`.
`Recipe: none`, no line, or a folder that is not there means the project is
off a recipe; say so once where the line names a missing one.

Where "How it stays running" records a live address, this is a later run:
follow "A later run". Where an open pull request holds a piece, leave it open
and say in one line that /implement merges it after the person's yes, which
puts it live.

## 1. Follow the current path

Follow only the branch that matches the build path, and stop where it says.

### Explore privately

Nothing here reaches a live address. Confirm the data is disposable, nobody
relies on it, no consequential automatic action runs, and any preview stays
private. Say plainly it is not approved for real use, record what Build and
run it would need, and stop.

### Build and run it

1. Run the evidence run in `references/evidence-run.md`.
2. Run second-opinion with the best independent method AGENTS.md records.
3. Make the two judgements the runner cannot. Does the tool record what each
   request did, one line per event with a run id, a time, a level and the
   step? Check with disposable inputs, never print what it holds, and treat a
   record holding personal data or secrets as a repair. Does the fit check
   name somebody to receive alerts? Pass the answers to the runner as
   `--request-record yes|no` and `--alerts named|none`. Neither is a sensitive
   area, and the kit never sets up a hosted service for them.
4. Go live one connection at a time, harmless parts first.

#### On a recipe

Take `recipe.md`'s sections in its order. Where a section's `How it works:`
names a script that acts, such as one that connects the host or applies
migrations, run it from the project root. On a first launch these are the
launch the person asked for and need no further yes. Where the recipe sends a
hosting request to whoever runs the server, follow the file it names.

Then run `scripts/run-recipe.sh <recipe>` with `--set LIVE_ADDRESS=`, the
password's location as `--set DB_PASSWORD_FILE=`, `BACKUP_DIR` outside the
repository, and the two answers above. Run it first with `--asks` and put each
question it prints in your reply word for word. Pass what is pasted back as
`--pasted <section>=<file>`, and what the person saw as
`--looked <section>=yes|no`.

Give its lines as printed. Exit 0 means every check passed. Exit 1 means
warnings: each is in the changelog, none holds the launch, and the person is
never asked to choose to go live without one. A warning the changelog already
held comes back as a pointer; say only that. Asked what is left, give the
runner's `Left:` line as printed, and nothing more about those checks: no
reason, no risk, and nothing to do about them. Exit 3 means no address is
recorded, so the tool is not live yet.
Record the live address in "How it stays running", and tell the person once
that each merge /implement makes puts that change live.

#### Off a recipe

Run `scripts/run-recipe.sh none` with the two answers above, and the live
address once the person gives one. It lists the eight section names and the
general readiness items as one-line warnings and records them, and the kit
checks nothing more. A server this session cannot reach gets the request in
`references/hosting-request.md`.

#### A secret a check needs

Pass a secret by the location "How it stays running" records, never its
value; the scripts read it themselves. With none recorded, ask once and record
the answer as a location. A secret given as an answer is recorded nowhere: say
it is now in this conversation and ask for it to be rotated. Asked to show a
secret, say plainly that the kit does not read or show it, because anything
shown here stays in the conversation's record, and that they can open it at
its location. Where
the location is unknown, the check is a warning saying so, never that the
secret is missing.

Never use a login, token or password another tool keeps for itself, in the
keychain, a credential store or its files. Use only a tool's own commands and
keys the tool already sends to the browser. Read a setting where the recipe
names a script for it before asking the person; where the kit cannot, say so
and name the page where it lives.

#### A change to a live service

Outside a first launch, a command that changes a live service's settings or
data waits for a yes that names every change it makes and says whether it can
be undone. A no leaves the service as it was, and the step is a warning.
Changing the masterplan's `Access:` line is one: say who gains or loses the
way in, and on the yes run the recipe's Access scripts, write the new line,
dated when public, and add a changelog line.
Never write a secret key to a shared temporary folder.

#### Deploying, and the records

Before deciding a deploy failed, read its whole output or the host's list of
deployments. Never deploy again before checking the first did not go live: a
second deploy replaces the rollback target, so say that in one line first.

Save the run's records through the `implement` skill's save route: one branch
and pull request for each run with its `scripts/save-records.sh`, never pushed
to `main`, never sweeping the person's uncommitted work in, and merged on the
pull request only after a yes that names it, asked for in the reply that
reports the run. Where the host builds every change to `main`, say that merge
moves the rollback target and offer to leave it open.

### Build with care

Outside every named area, follow Build and run it. Inside one, take each area
as the `setup-ai-build-kit` skill's `references/fit-check.md` says: do the
kit's caution now and write `done` with the date, or give the risk notice once,
in full, at the moment the area goes live. If the person carries on, write the
`Accepted:` line, mark the area `accepted`, read it back, and go on in the same
reply. On a recipe, an area goes live with the merge that carries it, and the
next run of the checks reports it. Where a caution is a person and nobody can
be asked, offer the handover in the `maintain` skill once.

## 2. Graduation

When going live changes the build path or names a new sensitive area, record
what changed and why, each new area and its caution, and which work continues
and which waits.

## Rolling back

Offer the earlier version back first where a live address is recorded, the
recipe says how to roll back, the live tool broke, and a recent merge is the
likely cause, once the changelog, the closed pieces or the person show the
version before it worked. Say in one line what comes back and that it puts
nothing else right. Either way, the repair is shaped in `/shape`.

A rollback waits for a yes that names it, even where the recipe names the
command. Before asking, name the version it brings back by its change and
date, from the host's list, and say it does not undo a database addition. On
the yes, run the recipe's rollback once, or give its words to whoever clicks
it, and check health names the earlier version before anything else.

Record it in a dated changelog line through the records route, and on the
repair's piece. Where the host now holds the live copy, say so in the same
reply and write a dated hold line into "How it stays running". Promote the
repair once it has merged and its build is listed, after its own named yes,
then remove the hold line. Off a recipe, say that whoever runs the host can
bring back an earlier build it still keeps.

## A later run

Rerun the fit check first if reliance, data or consequence has grown. Then
compare, changing nothing: run the recipe's `scripts/live-check.sh` with
`--address`, `--password-file` and `--needs` for the names on an open piece's
`Live side needs:` line. Where its checks are pasted back, ask for the health
answer and the setting names. Say each gap in one line.

Repair each gap only after a yes that names it, saying what it changes and
whether it can be undone. A migration is applied with the shared
`migrate.sh --apply`, once, before the merge that needs it. A piece's
migration not yet on `main` is applied from a temporary checkout of its
branch, removed afterwards; then say /implement can ask for the merge.

Then run `scripts/run-recipe.sh --later`, with a first launch's values and a
`--note` for each gap repaired or left. It writes the run's one dated entry,
gap or no gap, with its rollback line. A recorded hosting request is read
back as the recipe's file says. Moving to another host or recipe is a later
run too: run the
new recipe as a first launch while the old copy keeps serving, change the
`Recipe:` line and the address only once the new one answers, and say how to
switch the old one off.

## Done when

Explore privately: nothing went live. Otherwise the address is recorded,
each check has its line, each warning and each gap is in one dated changelog
entry, and no code was merged.
