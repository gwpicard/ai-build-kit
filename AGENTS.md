# AGENTS.md

Standing instructions for this project. Read every session, so this file stays short: it points at the documents rather than repeating them. The product lives in masterplan.md, what's left lives in plan.md, the history lives in CHANGELOG.md.

## What this project is

(One line, written by /start.)

## Before any work

Read the build-path section at the top of masterplan.md. It decides which
evidence, review, saving, and outside-help rules apply. Then read the relevant
part of masterplan.md and the current plan piece.

Read the capability profile in this file. Never rely on a hook, slash command,
subagent, browser, or remote service the current harness does not have.

## The workflow

Work runs through the seven commands in .agents/skills/. The user describes
intent in plain language; change-triage chooses the route.

Every promised behaviour needs evidence. Use an automated test for stable rules,
permissions, data changes, integrations, and bugs when a machine can judge the
result reliably. Use a guided manual check for visual or exploratory work. Use a
source check when the decision depends on an external fact. Use a rehearsal for
backup, restore, migration, rollback, or other operational claims.

Build one agreed, visible slice at a time. Do not add behaviour the slice did not
ask for. Do not widen a fix into a tidy-up.

## The skills, and how they are invoked

The work lives in eleven skills under `.agents/skills/`, each a folder with a `SKILL.md`. Seven are the words a human types; four are disciplines the words compose.

- Words (human-invoked): `/start`, `/build`, `/fix`, `/ship`, `/sync`, `/maintain`, `/what-now`.
- Disciplines (composed by the words and each other): `grilling`, `change-triage`, `section-builder`, `second-opinion`.

The load rule, which holds in any tool: when someone types `/word`, or the older `$word`, or asks for a skill by name, open `.agents/skills/<word>/SKILL.md` and follow it; anything typed after the word is the request. When a skill's body says to run another skill by name, open that one's `SKILL.md` the same way.

`.agents/skills/` is the single source of truth. The per-tool folders `.claude/`, `.cursor/`, and `.gemini/` are thin adapters generated from it by `.agents/tools/build-adapters.sh`, so the native slash commands and skills of each tool point back here. Codex reads `.agents/skills/` directly instead of using a generated adapter; each command folder carries `agents/openai.yaml`, which disables implicit invocation. To change a skill, edit its canonical `SKILL.md` and rerun that script; never edit the generated adapters by hand. docs/COMPATIBILITY.md records which tool lights up which.

Before adding a skill or changing what one does, read docs/PHILOSOPHY.md and answer its five questions in writing. It decides what belongs here, and the first question is why there are seven words rather than eight.

## The records

If it isn't written down, it doesn't exist. After every working piece: update
plan.md's status and evidence columns, and append a dated CHANGELOG.md entry
when work actually lands. Commit with a clear message. Each plan piece also
carries a `Class` (visual, behaviour, data/access, service, or operational),
set once by change-triage and read by later sessions rather than
reclassified from scratch.

When one document says another will do a job, write the job into that other document as well: a promise with nowhere to be carried out is drift the day it is written. masterplan.md describes the present only, and its build-path section changes only by re-running the fit check. Keep the masterplan to roughly one to two pages.

## How work is saved

Use the save route required by the build path and the change. Private,
disposable exploration may end in a confirmed checkpoint commit. Shared, live,
behavioural, data, access, integration, service, or operational changes use a
short-lived branch, a pull request, and the project check. Flagged areas also
receive the review named in the build-path section.

A human decides whether to merge. Never ask them to read code or logs; present
what changed, what was checked, and what remains uncertain.

## Outside help

The build-path section may require advice, scoped review, a supervised change,
or professional ownership. Stop at the named boundary, prepare the brief, and
continue only when its recorded condition is met. Do not turn a general concern
into a vague request to "get a developer".

## Working with this team

The people directing you do not read code. Commands and development-tool
names belong in the project instructions for agents; a user-facing report
describes what those commands achieved, not the commands themselves. Use
plain language, and define a technical term once, only when it cannot be
avoided. Give verification as an action and the outcome to expect from it.
Say plainly which parts are confirmed fact, which are assumptions, and which
are judgement calls. Never ask the user to inspect a diff, a stack trace, or
a log.

Before a tool or the harness asks for permission, explain the action first:
what the person will notice, why it is needed now, whether anything leaves
this computer, whether it changes or saves anything, and what stays
unconfirmed if they decline. Describe the outcome, not the mechanism: never
lean on test, smoke test, server, port, localhost, sandbox, process, package,
dependency, Git, commit, branch, remote, push, authentication, repository, or
working tree to carry the explanation; a technical term may follow in
parentheses only when recognising it later will help the person. When the
harness is about to show its own technical confirmation, say so first: "A
technical confirmation box will appear next. It is asking permission for the
action I just described." Never call an action merely safe; say whether it
is local or online, temporary or saved, private or shared, read-only or
changing something, reversible or irreversible. Report the result afterwards
in the same plain language.

## Secrets

Keys, passwords, and tokens live in .env and nowhere else. Never print, commit, or echo one; never paste one into a document, a test, or the changelog. A key that has appeared anywhere it shouldn't gets rotated straight away, and you say so.

## Confidential files

If the project works from confidential files, their folder and handling rules are recorded here by /start. Never stage, commit, print, or copy their contents into code, tests, documents, or the changelog.

(Filled in by /start if the project needs it.)

## Dangerous commands

The list in .agents/guard/blocked-commands.md is off limits. Commit before anything sweeping. Ask before anything irreversible: deleting data, changing the shape of stored data, or anything that leaves this machine.

## Stop and ask when

- the work exceeds the agreed slice;
- the request changes data, access, money, automatic actions, reliance, or external users;
- a new dependency or service is required;
- real data may be changed irreversibly;
- the build path requires outside help;
- the masterplan is silent on a consequential decision;
- the harness lacks a required capability;
- the user's expected result cannot be reproduced or verified.

## Capability profile

(Filled in by /start: harness, file access, shell, Git, local save identity,
online repository, online account access, online authentication, test
command, browser availability, independent-review method, hooks if any.)

## Stack, and how to run and test

(Filled in by /start.)
