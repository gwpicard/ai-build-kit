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
done, waiting on a person, or accepted, and do not carry on past one that is
none of those. On Build with care, walk its `paths`, its optional `boundary`,
and the folders assigned to `none`; stop if the shipped sensitive-area check
does not agree with the current project.

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
3. Operational readiness: before any first live use, require whatever of
   this actually applies: a named service and billing owner, a backup, a
   successful restore rehearsal, a manual fallback, a rollback or disable
   procedure, removal of test data, an access review, and clear
   service-account ownership. Do not require a database restore rehearsal
   for a tool with no stored data, or invent readiness steps a tool with
   no live reliance doesn't need.

   Check that the tool records what each request did: one line per event,
   with a run id shared by that request's events, a time, a level and the step.
   Check this with disposable inputs. Apply AGENTS.md's Secrets and
   Confidential files rules to the record: it must contain no personal data,
   keys, passwords, tokens or confidential file contents. Never print those
   contents while checking it. Keep the field names out of the person's report.

   If the record is absent or cannot trace a request, name or reuse one piece
   before go-live and say once: "The tool does not yet keep a record of what
   each request did, so a report cannot be traced. That is one piece, before
   it goes live." Leave launch waiting until that piece is built or the person
   explicitly chooses to go live without the record.

   Record that choice in CHANGELOG.md, with the date and what remains
   untraceable. Do not add a sensitive area or an `Accepted:` line for this
   operational gap. A record containing forbidden data needs a repair;
   accepting a missing record never waives the data exclusions.

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
   If hosting uses a preview address, this is the moment work moves to the
   team's address. That move is what /ship means.

   Where the tool will run on a server this session cannot reach, such as one
   the team or a hosting companion runs, the address comes from whoever runs
   that server. The kit never contacts that server. The person carries a short
   request there by hand, and carries the answer back.

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
   ```

   Take the lane from the fit check: internal unless somebody outside the team
   signs in or relies on it. Env vars carry names only; values are entered on
   the server. Never write a value, key, password or token into the request.
   Where the project does not say, write `none` rather than guess. Print the
   same block in the reply, so the person can paste it, and say once: "This
   tool needs a home. Take this request to whoever runs the server. Paste what
   they send back here, and I will record it for the next /ship."

   The first launch is not finished until an address is recorded under the
   request. Until then, tell the person plainly that the tool is not live yet
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

### Build with care

Separate the work into what is outside every named area and what is inside
one.

Outside every named area, follow the same four steps as Build and run it
above: evidence run, second-opinion, operational readiness, then go live one
connection at a time.

Inside a named area, take each area in turn:

1. read its line in the build-path section: what touches it, its caution, and
   where the caution stands;
2. where the caution is the kit's to do (a backup restored once, a rehearsal
   on a copy, a managed service, an approval step), do it now or check it was
   done, and write `done` with today's date on the line;
3. where the caution is a person, stop at it. Say in one sentence what that
   person must confirm. Do not merge or activate that area until they have
   looked and that is recorded, or the person accepts the risk on the record.
   No session meets it; fit-check.md says who does;
4. restate the risk notice here, at the moment the area is actually going
   live, rather than only when it was first scoped;
5. only after the caution is done or accepted does that area get its own
   operational readiness check (including the request record and monitoring
   rules above, without repeating their notices) and its own go-live
   step, one connection at a time, with the result recorded on its line.

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
that over. The hosting request recorded at the first launch still holds, and
step 4 says how to read it. If reliance, data sensitivity, or consequence has
grown since the build path was last checked, rerun the fit check before
shipping further.

## Done when

Explore privately: the private-preview checks are recorded and nothing moved
to a live address. Build and run it, and Build with care outside its named
areas or in an area whose caution is done or accepted: the team can rely on
the copy they use, required operational readiness is real, and the changelog
says what went live, when, and under which build path. Where a handover was
asked for, it is complete and says what it does not cover.
