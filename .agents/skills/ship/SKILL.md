---
name: ship
description: Take checked work to the copy of the tool the team actually uses. The only skill that touches that copy. Use when the user thinks the tool, or a batch of work on it, is ready for people to rely on. Follows the project's current build path and applies only the evidence, review, handover, or launch steps that path requires.
---

# Ship

Everything build and fix make lives on the draft copy until this command moves it over. Read masterplan.md, build-path section first.

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
   AGENTS.md.
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
   a later /ship visit. A named alert recipient satisfies this caution. Having
   nobody to receive alerts is the person's choice, which the caution covers;
   it is never a piece on the readiness list. Do not set up a hosted service,
   dashboard or alerting as part of this check.
4. Go live, one connection at a time: take the harmless parts live first.
   On a recipe, go live the way its going-live section says, when that
   section's turn comes in the checks below. Any merge or deploy on the way
   follows "Merging and deploying" below.
   If hosting uses a preview address, this is the moment work moves to the
   team's address. That move is what /ship means.

   Where the tool will run on a server this session cannot reach, such as one
   the team or a hosting companion runs, the address comes from whoever runs
   that server. The kit never contacts that server. The person carries a short
   request there by hand, and carries the answer back.

   On a recipe whose going-live section the kit runs itself, no hosting
   request is written. The address that section produces, recorded as "On a
   recipe" below says, is the address the first launch waits for.

   On a first launch, read the masterplan's "How it stays running" section.
   When it holds no hosting request, write one there, filled from the project
   itself rather than by asking the person:

   ```
   Hosting request
   Repo:          <url>, branch <branch>
   Lane:          internal (private network) | public (internet)
   Port:          <port the tool listens on>
   Env vars:      <names only>
   Persist:       <paths that must survive a restart, or none>
   Healthcheck:   <path, or none>
   Build:         Dockerfile at root, image has curl or wget | lock file or requirements.txt, plus a Procfile | neither yet
   Bind:          0.0.0.0 | reads HOST and PORT | 127.0.0.1 (not hostable yet)
   ```

   Take the lane from the fit check: internal unless somebody outside the team
   signs in or relies on it. Take Build from the files at the project's root,
   and Bind from the address the server listens on when it starts. The server
   builds and checks the tool from those two facts, so read them from the code
   rather than from a plan. A tool that listens only on 127.0.0.1 cannot be
   reached from outside its container: say so once, and record it. Env vars
   carry names only; values are entered on the server. Never write a value, key, password or token into the request.
   Where the project does not say, write `none` rather than guess. A project
   on a recipe always has a health route, because the recipe's health section
   names one, so there Healthcheck is that path and never `none`. Print the
   same block in the reply, so the person can paste it, and say once: "This
   tool needs a home. Take this request to whoever runs the server. Paste what
   they send back here, and I will record it for the next /ship."

   The first launch is not finished until an address is recorded under the
   request, or by the kit's own going-live on a recipe. Until then, tell the person plainly that the tool is not live yet
   and is waiting on the server's answer. Do not write it into CHANGELOG.md as
   live.

   Whenever the person pastes an answer, in this session or a later one,
   record its address and names under the request, and leave out any secret
   value it carries.

   On a later /ship, read the recorded hosting request back instead of asking
   again. Where no address is recorded under it, the request went out and no
   answer came back. Say so plainly, print the request again for the person to
   carry, and ask them to paste the answer here when it arrives. Where the
   project has changed a field since, update that line from the project and
   print the request again for the person to carry.

#### On a recipe

Here the recipe file says what to run and what a pass looks like. Every
command, service and address comes from it at run time. This skill names none
of them, so it reads the same whichever recipe the project is on.

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
not ask the person to choose to go live without it. The one wait that remains
is the address. Where the kit ran the going-live section itself, record the
live address it produced in the masterplan's "How it stays running" section.
A tool with no recorded address is not called live, on a recipe or off one:
tell the person so plainly, and keep it out of CHANGELOG.md as a launch.

#### Merging and deploying

These rules hold at every go-live, on a recipe or off one, and on Build with
care as well.

A person decides whether to merge, as with /implement. Before a merge, name
each pull request in one plain line that says what it changes. Then ask for a
yes that names the merge, for example: "Say yes to put it live, which merges
the two record changes." Merge only when the person's reply plainly covers
that merge. Where their own words already named the merge, as in "merge both
and put it live", that is the yes: do not ask again. A yes to going live, to a
hosting step, or to any question asked before the merge was named does not
cover it: ask again, and merge nothing until they answer. A no leaves the pull
request open and the live tool as it was.

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

A warning said once in a /ship is not said again in that /ship, even when a
step runs twice. Where it matters again, one line saying the changelog already
holds it is enough. The risk notice for a named area is not a warning, and
Build with care still gives it at the moment that area goes live.

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
   is not carrying on: leave that area where it is and ship everything
   outside it;
5. only after the caution is done or accepted does that area get its own
   operational readiness check (including the request record and monitoring
   rules above, without repeating their notices) and its own go-live
   step, one connection at a time, with the result recorded on its line. On a
   recipe, the recipe deploys the whole tool at once, so an area whose caution
   is done or accepted goes live through the next run of the eight checks,
   not through a separate deploy.

Where a caution is a person and the team has nobody to ask, offer the
handover once: `templates/handover.md`, filled in for that area, is what the
team gives somebody outside it to look at that area or to take the build on.
Offer it, prepare it if they say yes, and carry on with everything outside
the area either way. A handover is a document the person asks for, not a
stop.

## 2. Graduation

When shipping or preparing a handover changes the build path or names a new
sensitive area, record:

- what changed;
- why the previous path no longer fits;
- each new area and its caution;
- which work may continue;
- which work waits.

## After the first launch

Applies only once Build and run it, or Build with care outside its named
areas or in an area whose caution is done or accepted, has actually gone live
at least once. Lighter from
then on: re-run the evidence for what changed since the last ship, and move
that over. On a recipe, run its eight checks again, as above; a warning the
changelog already holds gets a one-line pointer rather than the warning again.
The hosting request recorded at the first launch still holds, and
step 4 says how to read it. If reliance, data sensitivity, or consequence has
grown since the build path was last checked, rerun the fit check before
shipping further.

## Done when

Explore privately: the private-preview checks are recorded and nothing moved
to a live address. Build and run it, and Build with care outside its named
areas or in an area whose caution is done or accepted: the team can rely on
the copy they use, each readiness item is in place or recorded as a warning,
on a recipe each of the eight checks has its line, and the changelog
says what went live, when, and under which build path. Where a handover was
asked for, it is complete and says what it does not cover.
