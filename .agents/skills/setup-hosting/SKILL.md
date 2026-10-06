---
name: setup-hosting
description: Set up how the tool runs live, and run it again to check or change that. Use when the person wants people to use the tool, wants to check the live copy against main, or wants to move it to another host or recipe. The first run sets the host up so that each merge to main deploys; after that a merge is a deploy, and /implement makes each merge on the person's yes. This skill never merges code. Follows the project's current build path and applies only the evidence, review, or launch steps that path requires.
---

# Setup hosting

The live copy is the one the team uses. The first run takes the code already on
`main` live and sets the host up so that each later merge to `main` reaches it.
After that, a merge is a deploy, and /implement makes each merge after the
person's yes. A later run compares the live copy with `main` and repairs what
differs. This skill never merges a pull request that changes the tool's code.
Read masterplan.md, build-path section first.

## 0. Confirm the build path

Read the build-path section first.

If anything under `Recheck when` has happened since `Last checked`, run the
fit check before continuing.

Read each line under `Sensitive areas`. Say for each whether its caution is
done, accepted, or `not yet done`. An area `not yet done` gets the risk notice
in its own step below, and the rest of the work does not wait for it. On Build
with care, walk its `paths`, its optional `boundary`, and the folders assigned
to `none`; stop if the shipped sensitive-area check does not agree with the
current project.

Read the `Recipe:` line in the stack section of the project's AGENTS.md. A file
name there, written with its `.md` as founding records it, is the project's
recipe: read that file in this skill's `recipes/`
folder, and each part it links with `Shared part:`. `Recipe: none`, or no line
at all, means the project is off a recipe. If the named file is not there, say
so once and treat the project as off a recipe.

Read the masterplan's "How it stays running" section. Where it records a live
address, the tool has gone live before, and this is a later run: follow "A
later run" below. Otherwise this is the first run, and section 1 sets it up.

Where an open pull request holds a piece, leave it open. Say in one line that
/implement merges it after the person's yes, and that the merge then puts it
live. A request to put such work live is a request to /implement, never a
merge here.

## 1. Follow the current path

Each branch below is self-contained. Follow only the branch that matches the
current build path, stop where it says stop, and do not carry a step from one
branch into another.

### Explore privately

Do not run the production evidence or launch procedure. Nothing below this
point in this branch ever moves work to a live address.

Confirm only:

- the prototype still uses disposable data;
- nobody relies on it;
- no consequential automatic action is active;
- the question or experiment it exists to answer has been checked;
- any preview remains private;
- the user is told plainly that it is not approved for operational reliance.

Record what would need to change before the path could become Build and run
it, then stop.

### Build and run it

1. Run the full evidence run.
2. Run second-opinion using the best independent method recorded in
   AGENTS.md. Before the review asks the person to look up a setting, it
   follows "A setting the kit can read" below.
3. Operational readiness, before any first live use. On a recipe, the
   recipe's own checks replace the general list; "On a recipe" below says how
   to run them. Off a recipe, check whatever of this actually applies: a named
   service and billing owner, a backup, a successful restore rehearsal, a
   manual fallback, a rollback or disable procedure, removal of test data, an
   access review, and clear service-account ownership. Leave out a database
   restore rehearsal for a tool with no stored data, and invent no readiness
   steps a tool with no live reliance doesn't need. Each item that applies and
   is not in place is a warning: name it once in one plain line, record it in
   CHANGELOG.md with the date, and carry on. None of them holds the launch.

   Check that the tool records what each request did: one line per event,
   with a run id shared by that request's events, a time, a level and the step.
   Check this with disposable inputs. Apply AGENTS.md's Secrets and
   Confidential files rules to the record: it must contain no personal data,
   keys, passwords, tokens or confidential file contents. Never print those
   contents while checking it. Keep the field names out of the person's report.

   If the record is absent or cannot trace a request, say once: "The tool
   keeps no record of what each request did, so a fault reported after launch
   cannot be traced. I have noted that in the changelog, and adding the record
   is one piece whenever you want it." Record in CHANGELOG.md, with the date,
   that the tool keeps no such record and what remains untraceable. Then carry
   on with the launch. Do not hold launch for the record, and do not ask the
   person to choose to go live without it. Say it once a visit. When the
   person later asks what remains, a line saying the changelog already notes
   it is enough; do not give the reason or the risk again.

   Do not add a sensitive area or an `Accepted:` line for this operational
   gap. A record containing forbidden data needs a repair; going live without
   a record never waives the data exclusions.

   Give the monitoring caution once, unless the fit check already names an
   alert recipient: "Once real people use this, the only record of what went
   wrong will be the record the tool writes. If you want somebody to be told
   when it breaks, that is a service somebody runs and pays for, and the kit
   does not set one up." Record that the caution was given in CHANGELOG.md;
   do not repeat it in a later reply of the same visit, for another area, or on
   a later run of /setup-hosting. A named alert recipient satisfies this
   caution. Having nobody to receive alerts is the person's choice, which the caution covers;
   it is never a piece on the readiness list. Do not set up a hosted service,
   dashboard or alerting as part of this check.
4. Go live, one connection at a time: take the harmless parts live first.
   Take the code already on `main` live, and set the host up so that each
   later merge to `main` reaches it. Pieces reach `main` through /implement,
   so the first run merges no code. On a recipe, go live the way its
   going-live section says, when that section's turn comes in the checks
   below. Any deploy on the way follows "Deploying, and the records" below.
   If hosting uses a preview address, this is the moment the team's address
   is set up. From then on, tell the person once, in one plain line, that
   each merge /implement makes puts that change live.

   Where the tool will run on a server this session cannot reach, such as one
   the team or a hosting companion runs, the address comes from whoever runs
   that server. The kit never contacts that server. The person carries a short
   request there by hand, and carries the answer back.

   On a recipe whose going-live section the kit runs itself, no hosting
   request is written. The address that section produces, recorded as "On a
   recipe" below says, is the address the first launch waits for.

   On a first launch, read the masterplan's "How it stays running" section.
   When it holds no hosting request, write one there, as
   `references/hosting-request.md` says. That file gives its fields, where
   each comes from, the one line the person hears, how to record the answer,
   and how a later /setup-hosting reads the request back.

   The first launch is not finished until an address is recorded under the
   request, or by the kit's own going-live on a recipe. Until then, tell the
   person plainly that the tool is not live yet and is waiting on the
   server's answer. Do not write it into CHANGELOG.md as
   live.

#### On a recipe

Here the recipe file says what to run and what a pass looks like. Every
command, service and address comes from it at run time. This skill names none
of them, so it reads the same whichever recipe the project is on. Where a
recipe's going-live section speaks of a branch merging into `main`, that
merge is /implement's. This skill takes live what `main` already holds.

Take the recipe's eight sections in its order: preview, going live, rollback,
backup, restore, secrets, logs and health. For each one, read `How it works:`
for what happens and `How it is checked:` for what a pass looks like. Then let
`Who runs it:` decide how the check is done:

- `the kit`: run the check from the project and read the output against the
  pass the recipe describes.
- `a companion or the person, result read back`: the check runs somewhere this
  session cannot reach. Say in one plain sentence what to fetch and from
  where, ask the person to paste it here, and read it against the pass
  yourself.
- `a person looking`: no machine can judge it. Ask the person to look, say in
  one sentence what they are looking for, and record what they say in their
  own words.

A check that would change the live tool only to prove it can, as a rollback
does, is not run against the live tool. For rollback, confirm with the
recipe's own commands that an earlier production build is listed, and report
the line as "rollback possible, not tried", so it never claims more than was
checked. Run the check in full only when the person asks for a rollback.

Report each section in one plain line, in this order: preview up, live address
updated, rollback possible, backup present, restore works, no secret in the
repo, logs readable, health answers. Each line says what was found, in plain
words, and leaves the command out.

A check that failed, could not run, or got no answer is a warning. Say it once,
on that section's line, record it in CHANGELOG.md with the date and the
section, and go on to the next section. Do not hold the launch for it, and do
not ask the person to choose to go live without it.

On a launch after the first, read CHANGELOG.md before you write these lines.
Where it already holds the same warning for the same section, that section's
line is a one-line pointer and nothing more, such as "backup present: still
none, as the changelog has recorded since 19 September". Leave out the reason
and the risk, and add no second changelog entry for it. A warning the
changelog does not hold, or one whose cause has changed, is new: say it once
in full, as above.

The one wait that remains is the address. Where the kit ran the going-live
section itself, record the live address it produced in the masterplan's "How
it stays running" section. A tool with no recorded address is not called live,
on a recipe or off one: tell the person so plainly, and keep it out of
CHANGELOG.md as a launch.

#### A setting the kit can read

This holds for the launch review and for every check in this skill, on a recipe
or off one. Before you ask the person to look up a setting of a service the
tool uses, check whether the kit can read it with what it already has: an
address the service answers in public, a command-line tool this session is
already signed in to, through that tool's own commands, or the project's own
files. Where it can, read the setting and report its value in one plain line,
instead of asking. On a recipe, its `Settings the kit can read` section, where
it has one, says which settings the kit reads and how.

Such a read uses only a key the project already sends to the browser. Never use
a secret key, a service key or a password to read a setting, and never sign in
to anything new for it. Ask the person only for a setting the kit cannot read
that way, and say in the same sentence why it cannot, for example that the
service shows it only on its own settings page.

#### A login the kit does not own

This holds for the launch review and for every step in this skill that
reaches a service. The kit uses only what a tool offers through its own
commands, and the keys the tool already sends to the browser. It never reads a
stored login, token or password out of the keychain, a credential store, or
another tool's own files, such as its settings or sign-in file. It never calls
a service's management API with such a login. A command-line tool uses its own
sign-in when the kit runs that tool's commands, and the kit never takes that
sign-in out to use it another way.

When the kit cannot read or change a setting that way, it says so truthfully
and asks the person, naming the page where the setting lives. Once it has said
it cannot read something, it never reads it another way. If the person asks it
to try, it says again what it can reach and what it cannot.

This is about a login another tool keeps for itself. A key the person gave
this project, kept where the masterplan records it, belongs to the project,
and "A secret a check needs" below says how to use it.

#### A change to a live service

A command that changes a live service's settings or data, other than saving
code through the save route, waits for a yes that names the change and says
whether it can be undone. Name every setting or record the command will
change, not only the one you meant to change, taken from the command's own
preview where it has one. Pushing a whole local settings file changes
everything in it that differs from the live project. Other examples are
applying migrations to the live project, or changing its sign-in settings.
Where the kit does not know whether the change can be undone, it says that.

The commands the project's recipe names, in any section, are the launch the
person asked for, and need no further yes. A later run is the exception:
nobody asked for a launch, so each repair waits for the yes "A later run"
describes. Anything the recipe does not name, and any push of a settings file,
waits for the named yes. A no leaves the service as it was, and the step is a
warning like any other.

A token in the person's environment that reaches the whole account is used
only for the reads the recipe names. A change made with it waits for the yes
above.

A secret key is never written to a shared temporary folder such as `/tmp`.
Write what a step needs straight into the git-ignored file that uses it.

#### A secret a check needs

This holds at every go-live, on a recipe or off one. Before a check that needs
a secret, such as the database password for the backup, the restore or the
database guard, read where that secret lives from the masterplan's "How it
stays running" section. Pass it by its location, as a command built in the
person's shell or read inside a script. Never read, print or show the value.
Checking the record means checking that the file or variable exists, never
reading it. When no location is recorded, or nothing is where the record says,
ask the person once where it lives. Record their answer in that section as a
location, never a value, and run the check.

If the answer is the secret itself, record it nowhere. Say plainly that it is
now in this conversation, ask the person to rotate it, and ask for its location
instead.

If they cannot say, the check could not run, and that is a warning like any
other. Its line and its changelog entry say that the kit does not know where
the secret is kept. Never write that the secret is absent, missing or not on
this computer: the kit only knows that it did not find it. Give no reason
for a skipped check that the kit did not itself confirm.

#### Deploying, and the records

These rules hold at every go-live, on a recipe or off one, and on Build with
care as well.

This skill merges no code. The one pull request it may merge is its own
records pull request, below, and only on a yes that names it.

The records /setup-hosting writes during a run, such as its CHANGELOG.md
entries and a confirmation the person gives later, such as a colleague saying
the new version is live, take the save route the build path already requires:
the three routes section-builder names, with no fourth for records. On the
checkpoint route, a checkpoint commit is enough. Otherwise put them on one
branch for this run, cut from the up-to-date `main`, and stage only the files
this run itself changed. Open one pull request for them, once, after the
launch is checked and its records are written, and ask for its yes in the
reply that reports the launch. Where GitHub cannot be reached, save the
records on that branch, note in one plain line the step that did not happen,
and open the pull request once GitHub is reachable. The project's first upload
waits for the yes section-builder's "The first upload" describes. Never push
records straight to `main`. A later confirmation joins that branch while its
pull request is open, or a new branch and pull request once it has merged.

The records pull request is a merge like any other: name it in one plain line
and ask for a yes that names it. No yes given earlier covers it, because that
pull request did not exist when the person gave it. Make the merge as
section-builder's "Merging" says: on the pull request itself, never on this
computer with a push of `main`. Where the host builds every change to `main`,
merging it starts one more build of the same code and moves the rollback
target. Say so in the line that asks for its yes, and offer to leave it open
so it goes out with the next change. If they say yes, correct the rollback
line on that branch before the merge. Merging it writes no record of its own.
Uncommitted work of the person's stays exactly where it is: never sweep it
into the records commit, and never discard it to get a clean tree.

Before you decide a deploy failed, read its whole output, or read the host's
own list of deployments or have it read. Where the kit cannot reach the host,
the person or a companion reads that list and pastes it here. Never cut the
output short. Where neither says whether the deploy went live, ask the live
address which version it serves, through its health route where it has one,
or have the person ask it. Never run a deploy a second time until you have
checked that the first did not go live. A second deploy of the same version
replaces the earlier build as the rollback target, so a rollback would bring
back the same version. When a second deploy is still needed, say that in one
line before you run it, and correct the rollback line to match.

A warning said once in a run of /setup-hosting is not said again in that run,
even when a step runs twice. Where it matters again, one line saying the changelog already
holds it is enough. That holds when the person asks what is left: name the
warning in one line that points to the changelog, without its reason or its
risk. The risk notice for a named area is not a warning, and
Build with care still gives it at the moment that area goes live.

#### Rolling back

This holds whenever the live copy is brought back to an earlier version, on a
recipe or off one. The `change-triage` skill's "A live break after a recent
merge" offers it first when the live tool broke after a recent merge. Where a
run of this skill starts with such a report, run that check first. The person
may also ask for a rollback outright.

A rollback changes the live service, so it waits for a yes that names it, as
"A change to a live service" says, even where the recipe names the command.
Nobody asked for a launch. Before asking, read the host's list of deployments
the way the recipe's rollback section says, and name the version the rollback
brings back, by the change it carried and its date. Say that a rollback does
not undo a database addition, which is why migrations only add.

On a yes, run the recipe's rollback once, read its whole output, and check it
as the recipe's `How it is checked:` says: the health answer names the earlier
version. Never run it a second time before you have checked the first. Where
`Who runs it:` is a companion or the person, say in one sentence what they do
and where, and read back what they paste.

Record the rollback when it happens, not when the repair lands: a CHANGELOG.md
line with the date, the version brought back and why, saved through
"Deploying, and the records". Name the rollback on the repair's piece too, so
whoever builds the repair knows the live copy is on the earlier version.

Some hosts stop putting new merges live after a rollback, until a newer build
is promoted, and the recipe's rollback section says so where its host does.
On such a host, say it plainly in the same reply: "The live copy now stays on
this earlier version. New merges will not go live until the repair is put
live."

Write the hold into the masterplan's "How it stays running" in the same
records save: a line saying the live copy is held on an earlier version, with
the date. Every later merge reads it from `main` that way, before the repair
lands. The repair's merge then needs that promote. It is a change to the live
service, so it waits for its own named yes, and it runs only once the repair
has merged and its build is listed. Once the promote has gone live, remove the
hold line and add a dated changelog line, through the same records route.

Off a recipe, say what a rollback would need: an earlier build the host still
keeps, and a way to point the live address back at it. Say that the kit cannot
do it here, and that whoever runs the host can.

### Build with care

Separate the work into what is outside every named area and what is inside
one.

Outside every named area, follow the same four steps as Build and run it
above: evidence run, second-opinion, operational readiness, then go live one
connection at a time. On a recipe, readiness and going live are the recipe's
checks, as "On a recipe" says.

Inside a named area, take each area in turn:

1. read its line in the build-path section: what touches it, its caution, and
   where the caution stands;
2. where the caution is the kit's to do (a backup restored once, a rehearsal
   on a copy, a managed service, an approval step), do it now or check it was
   done, and write `done` with today's date on the line;
3. where the caution is a person who has not looked, give the risk notice
   here, once and in full, at the moment the area is actually going live
   rather than only when it was first scoped. Say in one sentence what that
   person would confirm. No session meets it; fit-check.md says who does.
   Where an acceptance is already recorded for the area, give no notice; say
   in one line what was accepted and when;
4. if the person carries on after the notice, write the `Accepted:` line with
   their words and the date, as fit-check.md describes, and mark the area's
   line `accepted`, never `done`. Read the line back, then go on in the same
   reply, without a further question about that area. A lock whose only
   purpose is to wait for this caution opens with the acceptance, unless the
   person asks to keep it. Silence, a question, or a request for other work
   is not carrying on: leave that area where it is and take everything
   outside it live;
5. only after the caution is done or accepted does that area get its own
   operational readiness check (including the request record and monitoring
   rules above, without repeating their notices) and its own go-live
   step, one connection at a time, with the result recorded on its line. On a
   recipe, the recipe deploys the whole tool at once, so an area whose caution
   is done or accepted goes live with the merge that carries it, and the next
   run of the eight checks reports it, not through a separate deploy.

After the first launch, a piece inside a named area goes live when /implement
merges it. section-builder asks for that merge only once the area's caution is
done or accepted on the record, so this skill does not hold each later
go-live.

Where a caution is a person and the team has nobody to ask, offer the
handover once. A handover is what the team gives somebody outside it to look
at that area or to take the build on, and the `maintain` skill's "A handover"
section prepares it. Offer it, prepare it there if they say yes, and carry on
with everything outside the area either way. A handover is a document the
person asks for, not a stop.

## 2. Graduation

When going live changes the build path or names a new sensitive area, record:

- what changed;
- why the previous path no longer fits;
- each new area and its caution;
- which work may continue;
- which work waits.

## A later run

Applies once Build and run it, or Build with care outside its named areas or
in an area whose caution is done or accepted, has gone live at least once.
After that, each merge /implement makes is a deploy, so a later run does not
move work over. It compares the live copy with `main` and repairs what
differs. If reliance, data sensitivity, or consequence has grown since the
build path was last checked, rerun the fit check first.

Compare first, and change nothing while comparing. /maintain makes the reads
in this list, except the backup, on every visit, stops there, and sends any
gap here for its repair. The backup, the restore, the preview and the rest of
the recipe's checks run only in this later run, since they can stop the local
database, copy the live one, or need the person. Report each gap in one plain
line, and say nothing more about a part that matches:

- whether the live copy runs the latest merge on `main`, read from its health
  route or the host's list of deployments, as the recipe's going-live check
  says;
- whether the live copy is still held on an earlier version since a rollback,
  as "Rolling back" describes. "How it stays running" may record it, and the
  host's list of deployments shows it whether or not it was recorded. The
  repair is the promote, after its own named yes;
- whether `main` holds a database migration the live database does not have,
  read with the recipe's own dry run where it has one;
- whether a secret or setting the tool needs is missing on the host, by name
  only: the names in `.env.example`, and each name an open piece's `Live side
  needs:` line gives;
- whether health answers;
- whether the backup works.

On a recipe, those lines come from its eight checks, run again as "On a recipe"
says, and "On a recipe" says how a warning the changelog already holds is
given: as a one-line pointer, never again in full. Off a recipe, check what
the general list in Build and run it names, and ask the person for what the
kit cannot reach.

Then repair each gap after a yes that names it. Nobody asked for a launch in a
later run, so a recipe's command waits for that yes too. Name what the repair
changes and whether it can be undone, as "A change to a live service" says. A
migration is applied before the merge that needs it, since migrations only
add and the version live now keeps working. On a recipe, apply it the way the
going-live section does, with the checks that section runs on the live
database afterwards. A redeploy follows "Deploying, and
the records". A no leaves that part as it is, and its line is a warning like
any other.

/implement sends the person here when a piece needs something on the live side
before its merge: a migration applied, or a name on its `Live side needs:` line
present on the host. Report that part first. A piece's migration is not on
`main` yet, so read it from that piece's pull request branch. Apply it only
after a yes that names it, and from a separate temporary checkout of that
branch, such as a git worktree, so the person's own uncommitted work is never
touched. Remove that checkout afterwards. Migrations only add, so applying one
before the merge leaves the version live now working. Once it is applied or
present, say in one line that /implement can now ask for the merge.

Moving to a different host or recipe is a later run too. Read the new recipe,
and run its sections as a first launch does on the new host, while the old
live copy keeps serving. Record the new `Recipe:` line in AGENTS.md, and the new
address in the masterplan, only once the new live copy answers its health
check, and say in one line how to switch the old one off.

The hosting request recorded at the first launch still holds, and
`references/hosting-request.md` says how to read it back.

## Done when

Explore privately: the private-preview checks are recorded and nothing moved
to a live address. Build and run it, and Build with care outside its named
areas or in an area whose caution is done or accepted: the team can rely on
the copy they use, each merge to `main` reaches it, each readiness item is in
place or recorded as a warning, on a recipe each of the eight checks has its
line, and the changelog says what went live, when, and under which build path.
A later run: each gap between the live copy and `main` has its line, and each
is repaired or recorded as a warning. No code was merged.
