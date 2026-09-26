# AGENTS.md

Standing instructions for this project. Read this file at the start of every
session. The product lives in `masterplan.md`, the remaining work lives in this
project's issues, and the history lives in `CHANGELOG.md`.

Before any work, read the build-path section at the top of `masterplan.md`. It
decides which evidence, review, saving, and sensitive-area rules apply. Then
read the relevant part of the masterplan, the current piece, and the capability
profile below. Never rely on a hook, slash command, subagent, browser, or remote
service the current harness does not have.

Keep this file under 200 lines and hold only what the code cannot show: the
save and review routes, conventions that differ from the default, and pointers
to the records. Never add a directory layout, dependency list, architecture
overview, or style rule an automatic check could enforce. `/maintain` measures
it monthly and offers a trim when it reaches 200 lines or carries any of that
content, even below the ceiling. Cut nothing without the person's yes.

## What this project is

(One line, written by the setup-ai-build-kit skill.)

## The skills

The work lives in fourteen installed AI Build Kit skills. Nine are commands:
start the one the user types, names, or asks for in plain words, and say which
one you are running. Never start a command the user did not ask for. The other
five run in the background when a command needs them.

- Commands: `setup-ai-build-kit`, `shape`, `implement`, `queue`, `fix`, `ship`,
  `sync`, `maintain`, `what-now`.
- Background skills: `clarify`, `change-triage`, `screen-check`,
  `section-builder`, `second-opinion`.

When a skill says to run another skill, load that installed skill and follow
it. The skills sit in `.agents/skills/`, `.claude/skills/` or a plugin's folder,
depending on how the kit was installed. A pointer such as the `ship` skill's
`templates/handover.md` names a file in there, and so does `<name>/SKILL.md`
when native discovery is unavailable. Keep project rules in this file instead.

## The workflow

The user describes intent in plain language; change-triage chooses the route.
Build one agreed, visible slice at a time. Do not add behaviour the slice did
not ask for, and do not widen a fix into a tidy-up.

Every promised behaviour needs evidence: an automated check where a machine can
judge it reliably, a guided manual check for visual or exploratory work, a
source check for a decision that rests on an external fact, and a rehearsal for
backup, restore, migration, rollback, or other operational claims.

When a piece carries `visual`, or a change touches a screen file, load
`screen-check` before the guided manual check. It reads this project's design
rules first and never calls a screen accessible, compliant, or good.

When a written instruction and an automatic check disagree, trust the check and
say so plainly. It tests the real work, and an instruction can fall out of date.

## The records

If it is not written down, it does not exist. When work lands, add a dated
`CHANGELOG.md` entry in plain words and commit with a clear message.

The remaining work lives in this project's issues, one per piece, in the shape
the `setup-ai-build-kit` skill's `references/pieces.md` describes. A merged pull
request saying `Closes #<number>` closes its piece. Each piece carries a subject
label, set once by change-triage and read by later sessions. `plan.local.md` is
a printout of the open issues, written by `.agents/tools/plan-refresh.sh`. It is
never a source: a change goes to the issue, and the printout is made again.

When one document says another will do a job, write that job into the other
document too. The masterplan describes the present only, in roughly one or two
pages, and its build-path section changes only by rerunning the fit check.

## How work is saved

Use the save route the build path and the change require. Private, disposable
exploration may end in a confirmed checkpoint. Shared, live, behavioural, data,
access, integration, service, or operational changes use a short-lived branch,
a pull request, and the project check. A human decides whether to merge.
Present what changed, what was checked, and what remains uncertain. Never ask
the person to read code or logs.

## Sensitive areas

The build-path section may name sensitive areas, each with a caution: a backup
restored once, a managed service, or a person who looks before the work goes
live. On Build with care, each area also lists where it lives and may name one
boundary. Update that map in the same save as a code move; the sensitive-area
step in the project check says whether it still matches. At the named
boundary, do the caution where it is the kit's to do. Where it is a person's
and they have not looked, give the risk notice once, in full: who is exposed,
what happens to them, what would normally prevent it, what the person can do,
and that you flag what you can recognise and will miss things.

Nothing is refused, and the work does not stop there. If the person carries on
after the notice, that is their acceptance: record it in the build-path section
with the date and their own words, and build in that same reply, with no
further yes asked for. A lock that only waits for that caution opens with it,
unless the person asks to keep it. Silence is not carrying on. The record says
the risk was accepted, never that the caution was done. Cost, deadlines and
team size change what the person decides, never who is exposed, so never soften
or drop the notice, or recast a named control into something you can satisfy
yourself. Where the notice names who should look, that is a person, and no
session meets it: not a fresh one, not a subagent, and not the project's own
review method. That method exists for a different job from the one a named
reviewer was named for.

## Working with this team

The people directing the work are not required to read code. A report describes
what they achieved, in plain language. Define a technical term once when it
cannot be avoided, and describe verification as an action with an expected
result. Keep progress updates tied to a decision, blocker, or visible outcome.
Do not narrate routine inspection, command output, retries, or waiting.

Immediately before a technical confirmation, explain what the person will
notice, why it is needed, whether anything leaves the computer, whether the
action is temporary or saved, and what remains unconfirmed if they decline.
Say that a technical confirmation box will appear next.

## Secrets and confidential files

Keys, passwords, and tokens live in `.env` and nowhere else. Never print,
commit, or copy one into a document, check, or changelog. Rotate a secret that
appears anywhere it should not.

If the project works from confidential files, the setup-ai-build-kit skill
records their folder and handling rules here. Never stage, commit, print, or
copy their contents into code, checks, documents, or the changelog.

(Filled in by the setup-ai-build-kit skill if the project needs it.)

## Dangerous actions, and when to stop and ask

The restrictions in the `setup-ai-build-kit` skill's
`references/blocked-commands.md` always apply. Save a checkpoint before
sweeping work. Stop and ask when:

- the work exceeds the agreed slice, or needs a new dependency or service;
- the request changes data, access, money, automatic actions, reliance, or
  external users, or would delete data or do anything irreversible or outside
  this computer;
- a sensitive area's caution is a person who has not yet looked, or a risk
  notice is waiting on the person's answer;
- the masterplan is silent on a consequential decision, or the harness lacks a
  required capability;
- the expected result cannot be reproduced or verified.

## Capability profile

(Filled in by the setup-ai-build-kit skill: harness, file access, shell, Git,
local save identity, online repository, online account access, online
authentication, project check, browser availability, independent-review method,
and optional harness capabilities.)

## Stack, and how to run and check it

(Filled in by the setup-ai-build-kit skill: `Recipe: <file name>.md` or
`Recipe: none`, then run, test, type check and lint commands, or `none for
<language>`, and conventions that differ from the default, including
`Design tool: <name>` or `Design tool: none recorded`. Leave dependency lists
in the code.)
