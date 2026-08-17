# AGENTS.md

Standing instructions for this project. Read this file at the start of every
session. The product lives in `masterplan.md`, the remaining work lives in this
project's issues, and the history lives in `CHANGELOG.md`.

## What this project is

(One line, written by the start skill.)

## Before any work

Read the build-path section at the top of `masterplan.md`. It decides which
evidence, review, saving, and outside-help rules apply. Then read the relevant
part of the masterplan and the current plan piece.

Read the capability profile in this file. Never rely on a hook, slash command,
subagent, browser, or remote service the current harness does not have.

## The workflow

Work runs through the seven commands installed as AI Build Kit skills. The user
describes intent in plain language; change-triage chooses the route.

Every promised behaviour needs evidence. Use an automated check for stable
rules, permissions, data changes, integrations, and bugs when a machine can
judge them reliably. Use a guided manual check for visual or exploratory work.
Use a source check when a decision depends on an external fact. Use a rehearsal
for backup, restore, migration, rollback, or other operational claims.

Build one agreed, visible slice at a time. Do not add behaviour the slice did
not ask for. Do not widen a fix into a tidy-up.

## The skills, and how they are invoked

The work lives in eleven installed skills. Seven are commands you type. Four run
in the background when a command needs them.

- Commands: `start`, `build`, `fix`, `ship`, `sync`, `maintain`, `what-now`.
- Background skills: `clarify`, `change-triage`, `section-builder`,
  `second-opinion`.

Use the harness's skill picker or ask for a skill by name. When a skill says to
run another skill, load that installed skill and follow it. If native discovery
is unavailable, open `.agents/skills/<name>/SKILL.md` directly.

The installed skill folders are managed by the shared skills installer. Put
project-specific rules in this file instead of editing an installed skill.

## The records

If it is not written down, it does not exist. Add a dated `CHANGELOG.md` entry
when work lands, written in plain words rather than assembled from titles.
Commit with a clear message.

The remaining work lives in this project's issues, one per piece, in the shape
`.agents/skills/start/references/pieces.md` describes. A merged pull request
saying `Closes #<number>` closes its piece, so no status is set by hand. Each
piece carries a subject label for everything it is about, set once by
change-triage and read by later sessions.

`plan.local.md` is a printout of the open issues, written by
`.agents/tools/plan-refresh.sh`. It is never a source. Nothing reads it back and
nobody edits it to change work: a change goes to the issue, and the printout is
made again.

(A project that keeps its pieces in `plan.md` has that file as its record, and
none of the above applies to it. The capability profile below says which kind
this project is. A repository does not settle it, so an empty issue list on a
project with `plan.md` on disk never means the work has run out.)

When one document says another will do a job, write that job into the other
document too. The masterplan describes the present only, and its build-path
section changes only by rerunning the fit check. Keep the masterplan to roughly
one or two pages.

## How work is saved

Use the save route required by the build path and the change. Private,
disposable exploration may end in a confirmed checkpoint. Shared, live,
behavioural, data, access, integration, service, or operational changes use a
short-lived branch, a pull request, and the project check. Flagged areas also
receive the review named in the build-path section.

A human decides whether to merge. Present what changed, what was checked, and
what remains uncertain. Never ask the person to read code or logs.

## Outside help

The build-path section may require advice, a scoped review, a supervised
change, or professional ownership. At the named boundary, prepare the brief and
give the risk notice: who is exposed, what happens to them, what would normally
prevent it, and that you flag what you can recognise and will miss things.

Nothing is refused. The person may accept the risk and have the work built, and
that acceptance is recorded in the build-path section with the date and who gave
it. What may not happen is the notice being softened or dropped later, or a
named control being recast into something you can satisfy yourself. An
independent review means a reviewer who did not build the work.

Cost, deadlines, team size, and the person's willingness to be responsible all
change what they decide. None of them changes who is exposed, so none of them
changes the notice.

## Working with this team

The people directing the work do not read code. Development commands belong in
these project instructions. A user-facing report describes what they achieved.
Use plain language, define a technical term once when it cannot be avoided, and
describe verification as an action with an expected result.

Keep progress updates tied to a decision, blocker, or visible outcome. Do not
narrate routine inspection, command output, retries, or waiting.

Immediately before a technical confirmation, explain what the person will
notice, why it is needed, whether anything leaves the computer, whether the
action is temporary or saved, and what remains unconfirmed if they decline.
Say that a technical confirmation box will appear next.

## Secrets

Keys, passwords, and tokens live in `.env` and nowhere else. Never print,
commit, or copy one into a document, check, or changelog. Rotate a secret that
appears anywhere it should not.

## Confidential files

If the project works from confidential files, their folder and handling rules
are recorded here by the start skill. Never stage, commit, print, or copy their
contents into code, checks, documents, or the changelog.

(Filled in by the start skill if the project needs it.)

## Dangerous actions

The restrictions in
`.agents/skills/start/references/blocked-commands.md` always apply. Save a
checkpoint before sweeping work. Ask before deleting data, changing stored
data, or doing anything irreversible or outside this computer.

## Stop and ask when

- the work exceeds the agreed slice;
- the request changes data, access, money, automatic actions, reliance, or
  external users;
- a new dependency or service is required;
- real data may change irreversibly;
- the build path requires outside help, or a risk notice is waiting on the
  person's answer;
- the masterplan is silent on a consequential decision;
- the harness lacks a required capability;
- the expected result cannot be reproduced or verified.

## Capability profile

(Filled in by the start skill: harness, file access, shell, Git, local save
identity, online repository, online account access, online authentication,
project check, browser availability, independent-review method, and optional
harness capabilities.)

## Stack, and how to run and check it

(Filled in by the start skill.)
