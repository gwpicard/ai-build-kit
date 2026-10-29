# Maintaining AI Build Kit

This file is for people working on the kit itself. The release allowlist keeps
it out of the kit a project receives.

## Configure the commit hook

Run `git config core.hooksPath .githooks` in a fresh clone before its first
commit. Git does not inherit this local setting; the hook removes attribution
lines and session links from commit messages. [AGENTS.md](../AGENTS.md) explains
the rule and its other enforcement.

## How the issues are organised

Track the kit's work in this repository's GitHub issues. The scheme has no
dates because the work is not deadline driven.

An **epic** is one issue that describes an initiative, with the work under it as
**sub-issues** (GitHub's own parent and child link). The parent shows a progress
bar that fills as children close. Use two levels only: an epic and its tasks.
Mark the parent `epic`. Add a child with
`gh issue edit <parent> --add-sub-issue <child>`, or open one under a parent with
`gh issue create --parent <parent>`. Put an issue under an epic only when it belongs to that initiative; link a
related issue in the body.

**Labels** carry the categories. Each open issue takes exactly one `area:` label,
one of `area:skills`, `area:tests`, `area:release`, or `area:docs`. Its type is
one of the existing `bug`, `enhancement`, `feature`, `documentation`, or `chore`.
Two labels carry readiness, and they never sit on one issue together:
`needs-answers` means a question only a person can answer is open, and `ready`
means a person judged the piece shaped. `ready` is also the state name used in
projects the kit founds. Add `status:blocked` only while a piece is blocked.
Use one colour per label family. There is no priority label; the maintainer's
cadence sets what comes next.

Do not rename or remove the release labels `release-major`, `release-minor`,
`release-patch` and `skip-release-notes`, or the `bug`, `enhancement`,
`feature` and `documentation` labels used for version bumps and release notes.
Add organising labels alongside them.

Milestones are not used because the work has no timeline. The `epic` and type
labels replace GitHub Issue Types, which require an organisation account.

### What a shaped issue carries

A piece is shaped when its `## Done when` section gives a checkable condition.
Use the same heading as projects the kit founds, and preserve the original
report beneath the template.

```md
<!-- elaborated:v1 -->
## Problem
What is wrong now, who it affects, and how often.

## Evidence
The files, functions and lines involved. Related issues and pull requests.

## Goal
The correct behaviour, in one or two sentences.

## Scope
**In scope:** what this piece changes.
**Out of scope:** the related changes it leaves alone.

## Done when
- [ ] A result a person can see or test. One result per line.

## Assumptions
- I assumed X, because Y. Correct me if this is wrong.

## Risks
What can break, and who or what the change touches.

<details><summary>Original report</summary>

The unchanged original body.

</details>
```

## Every rule says where it applies

Every rule declares whether it applies always, to named changes, or only to
work touching a named risk area. [PHILOSOPHY.md](PHILOSOPHY.md) explains why.
Do not add a strict step to the default workflow just because it is good
practice elsewhere. Put safeguards for a named risk behind that risk area's
condition.

## The backbone and its mechanisms

PHILOSOPHY.md names seven promises for every project. This section lists the
mechanism behind each. A promise marked "none yet" is not a guarantee; do not
claim it until the piece beside it closes the gap.

| Promise | Mechanism today | Gap |
|---|---|---|
| By default, a person approves each merge unless they chose auto-merge with its limits. | `merge.py --approved` spends the person's recorded approval through the approval gate, `records/scripts/approval.py`; `.agents/tests/merge-gate.sh` and `.agents/tests/approval-gate.sh`; the autonomy limits in `.agents/tests/autonomy-boundaries.sh`; the local push guard and branch protection where the plan allows it, checked by `.agents/tests/push-guard.sh` and `.agents/tests/check-tooling.sh` | A private repository on Free has no GitHub protection; a person with permission can merge by hand there. |
| Nothing goes online without approval. | One approval gate, `approval.py`, called by `merge.py --approved` and by every recipe step that moves what is live, applies a migration, adds a secret, or changes access, sign-up or the host connection: `.agents/tests/approval-gate.sh`, `.agents/tests/merge-gate.sh`, `.agents/tests/recipe-nextjs-supabase-on-vercel.sh`. Claude Code asks before approval is recorded, checked by `.agents/tests/push-to-main-rules.sh`; `.agents/tests/first-upload.sh`. In the behaviour set, `.agents/tests/replay/backbone.py` fails a replay in which a merge, a push to main or a change to the host came before the person's approval | Closed for the kit's own scripts. A host tool run outside a kit script is subject only to Claude Code's rules. |
| Secrets are never shown. | `.agents/tests/secrets-gates.sh` and `.agents/tests/push-guard.sh` for commits and command output; `.agents/tests/record-secrets.sh` for the saved records: the pull request body `gate.py` writes, the changelog and masterplan `run-recipe.sh` writes, and what Claude Code writes into a record file or a GitHub body. In the behaviour set, each replay project contains a planted canary secret in an untracked file, and `.agents/tests/replay/backbone.py` fails the replay if the canary or any secret-shaped value appears in what the run said or saved | Closed for the kit's scripts and Claude Code. On Codex, Cursor and Gemini CLI, a secret printed by a tool reaches the agent; see COMPATIBILITY.md. Another agent writing a record by hand is caught when the record is pushed. |
| Checks pass before a merge. | The project checks workflow, read by `merge.py`; `.agents/tests/merge-gate.sh`. When a billing limit alone stopped GitHub's check, `merge.py --approved` runs the same steps on a clean copy of the commit with `merge/scripts/local-check.py`; `.agents/tests/merge-billing.sh`. Every check reports a result from `quality-checks/scripts/results.py`; `.agents/tests/result-vocabulary.sh` | In the billing case, this computer's own tools stand in for the steps that set up tools on GitHub, so the result can differ from a run on GitHub's fresh machine. |
| A review matches the code it read. | The review record names the commit the review read and carries a seal over itself and the stopping findings. `check-review.sh` and `merge.py` reject review records for another commit, a hand-edited record and an older record with no commit. A review without approval from a second login is recorded as unverified. `.agents/tests/review-gate.sh`, `.agents/tests/merge-gate.sh`. In the behaviour set, `.agents/tests/replay/backbone.py` fails a replay whose merge landed a version the review did not read, and `.agents/tests/replay-behaviour.sh` proves it | The seal stops a hand edit, and anyone who runs the kit's code can still write a record. A review counts as verified only when a second GitHub login approved that commit. |
| On a proven recipe, every launch requires a way back and a confirmed backup. | Each recipe must carry rollback, backup and restore sections, checked by `.agents/tools/check-recipes.sh`. `run-recipe.sh` blocks launch when a live address has no confirmed backup, the recipe names no rollback, or a later run has no earlier build to return to. Hosting is recipe-only. With no recipe, `run-recipe.sh none` gives one notice that nothing is guaranteed, records the person's words and the date, blocks nothing and checks nothing. `.agents/tests/run-recipe.sh` | A first launch has no earlier build, so its way back is the recipe's rollback step, untried. Off a recipe the promise does not hold, and the kit reports that limit. |
| Records say "accepted", never "done". | `.agents/tests/replay/state-check.sh` reads the end state a replay leaves and fails when an area is marked done on the date of an acceptance; `.agents/tests/replay-state.sh` proves that assertion. The project check reports an accepted area as accepted, and `.agents/tests/sensitive-area-map.sh` proves it. The move from an older path record keeps each acceptance as accepted, and `.agents/tests/risk-move-rehearsal.sh` proves it | The replay check measures the kit; it does not run in a project. Nothing stops an agent writing "done" by hand there. |

Each mechanism needs a check that fails when the mechanism is removed. The
mutation run breaks each one in turn.

### Two kinds of check

[PHILOSOPHY.md](PHILOSOPHY.md) explains integrity checks and judgement risks.
When it is unclear which applies, ask who can judge the harm. If the person can
judge it from where they sit, it is a judgement risk; otherwise it is an
integrity check.

### Results

Every check that gates a merge reports one of five results: `PASS`, `FAIL`,
`NOT_RUN`, `INCONCLUSIVE` or `NOT_APPLICABLE`. A missing runner, a crashed tool
or a check that never started is `NOT_RUN`. It is never shown as `PASS`. The table in
`.agents/skills/quality-checks/scripts/results.py` maps results to merge blocks,
review requests and information-only outcomes. `FAIL` and `NOT_RUN` stop
it, `INCONCLUSIVE` asks for a review, and the other two inform. `quality.py`,
`gate.py` and `merge.py` keep their own exit codes and map them onto these
names where they report. A test the replay harness breaks is recorded as `could not run` and is neither a pass nor a fail.

The hosting recipe checks are the exception. They report in plain words, as
warnings the person can accept, and a check that did not run reports "not checked".

### Rollout states

A check that a project cannot yet run is in one of three states: `off`,
`report-only` or `enforced`. A project starts at `report-only` when it lacks
what the check needs, such as a second identity for a review. A report-only
check reports its state in plain words and never shows a false pass. The move to
`enforced` is recorded with the date.

A review that the kit cannot verify, because the agent and the reviewer share
one login, is recorded as unverified: the record contains `verified=no`, and the pull request and merge report the
status in plain words. The hand-over never calls it
an independent review.

A project moved from an older path record lists the checks it cannot yet run on
a `Report-only:` line of its risk record, with the date. The line names areas
without a `paths:` line, which the project check does not block, and open pieces
that name no risk area. Nothing on that line is shown as
passed.

### The risk record

The fit-check skill owns the risk record and its fields. `mark-ready.sh`
requires a `Risk areas:` line on each piece, and
`.agents/tests/sensitive-area-map.sh` fails on an open area and passes on an
accepted area.

`/maintain` moves older path records only with the person's approval. It shows
the old section and proposed record before approval; a declined offer leaves the
project records unchanged and records the decline in
`.ai-build-kit-maintenance`. With approval, it preserves each area, acceptance
and date, keeps the old path and its reason as history, adds risk areas to open
pieces where their reach identifies them, and records the move in the changelog.
An acceptance never becomes a completed caution.
`.agents/tests/risk-move-rehearsal.sh` covers the old path values and fields.

### Working conditions

Setup requires a repository with issues switched on, an agent session that can
read and write issues, branch protection or a recorded private Free plan limit,
and the command-line tools named by the chosen recipe. A script stops setup
when one of those conditions is missing. Host and database sign-in cannot yet
be checked, so the script reports them as unchecked. The person creates the
accounts.

The script is `check-tooling.sh --conditions` in the setup skill, covered by
`.agents/tests/check-tooling.sh`. It proves issue access by opening a
test issue, closing it and labelling it `skip`. A private repository on Free
carries on with the local push guard; `protect-branch.py` records the condition
in `.ai-build-kit-maintenance` and explains the missing GitHub layer once.
Maintenance offers protection when the plan later allows it. An unreadable
protection check is recorded as `could not check` and leaves the local checkpoint
available; first upload checks protection again. Missing admin rights still stop
founding.

For host and database access it stops only on the tools the chosen recipe names.
No recipe currently names a host or database sign-in check, so the script
reports those as `could not check`. It also reports whether the agent and
reviewer share one GitHub login; that result does not stop setup.

### Settled points

- The kit never deletes unfinished work; it explains how to recover it.
- A request to fix a live error still needs approval for the named change.
- When setup lacks detail, the kit asks only the three fit-check questions,
  records gaps as assumptions and continues.

## Changing a skill

This section covers canonical skills in `.agents/skills/` and agents in
`.agents/agents/`. Read [PHILOSOPHY.md](PHILOSOPHY.md) first and answer its four
questions in the pull request description. Reshape a change that cannot answer
them. When retiring a term, mode or behaviour, add its old phrases to the stale
claim checks in `.agents/tools/validate-kit.sh`. Keep numbers owned by a check
in that check rather than repeating them in prose.

`.agents/skills/` is the single source of truth. Edit `<name>/SKILL.md`, run
`.agents/tools/build-adapters.sh`, and include the regenerated compatibility
fixtures. Never hand-edit generated files under `.claude/`, `.cursor/`,
`.gemini/`, `.codex/agents/` or `.github/agents/`. The Claude plugin selects the
six generated commands, background skills and agents; its metadata is in
`.claude-plugin/`. Agent Plugins uses `agent-plugin/`, whose skills folder is
assembled from the release allowlist. Codex reads `.agents/skills/` directly.
The adapters remain in the repository for maintainer checks; the builder and
`check-structure.py` compare them with the canonical files.

A command routes work, while a background skill owns one method and its
references. An agent is a brief in `.agents/agents/` that names the skills it
loads, the access it needs and what it returns; it never starts another agent.
`.agents/tools/kit-inventory.txt` lists each skill and agent with its kind.
`check-structure.py` enforces the structure, callers and word budgets. A script
may be called by path from any skill because that costs the agent no attention.
When moving a rule, move it whole. Compare the old and new files line by line
before saving, so each sentence appears at its new home or points to it.

### How a skill is triggered

A background skill called by another skill has `user-invocable: false` in its
own file; a skill without it is a command. The adapter builder reads this
setting, and the count check catches a dropped or misspelt declaration.

The agent may start a command when the person types it, names it in a message,
or asks for its job in plain words. It reports which command it is running and
never starts one the person did not ask for. The person cannot choose a
background skill; the tool enforces that boundary. The shared installer and
Agent Plugins clients read canonical files, so the setting must be correct in
the skill itself.

`user-invocable` is absent from the written Agent Skills standard, so the
reference checker reports background skills as invalid. Keep the setting with
that cost recorded: a strict Agent Plugins client would skip skills that fail
the standard, while Claude Code accepts it. If the standard adopts an
equivalent setting, follow it and update the person-facing summary in
`docs/COMPATIBILITY.md`.

### Maintainer skills

Maintainer skills live in `.agents/maintainer-skills/`, outside folders that
installers scan. Root [AGENTS.md](../AGENTS.md) lists them and explains how to
load them. They have no generated adapters or release entries. The validator
checks that no maintainer skill appears in an installer folder.

The shared installer scans `.agents/skills/` and `.claude/skills/`, merging
files by frontmatter `name`. Adapters use the canonical names, so they merge
with their source files. A maintainer skill copied into either folder would
instead be offered to project users. A marker file cannot prevent that because
external installers do not recognise this repository's convention.

`stack-research` records proposals in the git-ignored
`.agents/tmp/stack-research/`; it changes no recipe, version or date. A proposal
worth keeping becomes an issue. Its research note and the recipe record remain
separate from the installed skills.

The writing-review skill's pattern guidance draws on version 2.9.1 of
[the upstream writing guide](https://github.com/blader/humanizer/tree/v2.9.1),
used under its included MIT licence. The maintainer supplied the audience-aware
framework. Review upstream changes before replacing the pattern guidance.

### Project templates and hooks

A project's Claude settings come from
`.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json`,
not this repository's `.claude/settings.json`. Keep the deny lists aligned;
`validate-kit.sh` compares both with `.agents/guard/blocked-commands.md`. Only
the template carries session-start wiring, and `setup-ai-build-kit` installs
that script in a project.

`.agents/hooks/session-end-sync.sh` is opt-in. Its header documents per-tool
wiring; `/what-now` at the next session start serves the same purpose. The hook
keeps its existing name because projects may already refer to it.

Editing a skill body usually leaves adapters unchanged because they contain
pointers and frontmatter descriptions. A changed description changes the
adapter. [COMPATIBILITY.md](COMPATIBILITY.md) owns the per-tool map.

## The source validator

Run `.agents/tools/validate-kit.sh` after changes to skills or kit machinery.
Its output names each rule and reports `PASS` or `FAIL`; read the script for the
checks and their scope. CI runs it on source pull requests alongside the
rehearsal suite.

The starter project check intentionally fails until
`setup-ai-build-kit` replaces the placeholder with the project's real commands
during stand-up. The template is
`.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml`.

## Behaviour tests: scenarios, replays and seeded products

Before a release, read `.agents/tests/scenarios.md` and confirm each scenario
still resolves to its risk record, evidence and route. It is a maintainer
contract, not material shown to project users.

`.agents/tests/replay/` runs whole conversations against an assembled release
and uses a separate grader over several runs. Read its table before a release;
a replay result is a rate. A run with nobody present is a lead, so repeat any
finding by hand before treating it as a defect. The folder documents its scope
and limits.

`.agents/tests/replay/behaviour.sh` runs scenarios 64 to 81, three per command:
expected path, skipped step and pushback. It also runs seeded products 03, 04
and 08 as additional `/implement` cases. Each scenario has four to six checks,
read from disk by `behaviour_checks.py` or answered by the grader, and is also
graded against the backbone by `backbone.py`. The maintainer reads draft
scenarios before relying on them. For a comparison, set `KIT_SRC` for each kit,
run the six expected paths first, then compare result folders with `compare.sh`.

`preflight.sh` checks the replay harness before calling a model. A broken run is
recorded as `could not run`, excluded from rates, and a round with no graded
result exits 2.

`.agents/tests/seeded/` measures whether the kit catches a planted fault before
merge, fixes it, and avoids blocking a healthy twin. Answer keys stay outside
the project being tested. Results include counts and denominators, not one
score.

## What earns a shell test

The suite under `.agents/tests/` grew by artefact rather than by risk, which is
how a check ends up guarding something nobody would ever break. Answer these
before adding one.

1. What does a person lose if this breaks? If the honest answer is nothing they
   would notice, it does not belong here.
2. Can it break quietly? Something that fails loudly the first time anyone runs
   it needs no guard. These checks earn their place against silent failure.
3. Is it a boundary or a behaviour? Shell owns boundaries: what ships, what gets
   written, what gets published, what gets overwritten. How the kit behaves in a
   conversation is judged by the scenario review, not here.
4. Does an existing check already build this fixture? Then add the assertion
   there. A new file is justified by a new fixture, not by a new topic.
5. Would it still be true after a rewrite? A check pinned to particular wording
   or an internal path fails when someone tidies up and teaches nobody anything.

An assertion that cannot be made to fail is not protecting anything.
`.agents/tests/mutate.sh` breaks one promise at a time and records which checks
noticed, which is how that gets settled with evidence rather than opinion. Run
it when the suite changes shape. Anything it shows to be unbreakable comes out
at the next release, and anything it breaks without being noticed is the gap to
close first.

## The pull request check

`.github/workflows/source-checks.yml` is private source machinery. Its
`source-kit-validation` job checks the generated adapters and runs
`validate-kit.sh` on pull requests. The `rehearsal` job runs
`.agents/tests/run-all.sh` once for the whole suite.

The runner continues after failures and names each one in its output and run
summary. It reads the test folder, so new rehearsals run when saved. Only
`mutate.sh` is excluded because it audits the suite. A rehearsal that cannot
run reports `could-not-run: <reason>` and exits 2; failures exit 1 and take
precedence. Locally, only failures make the suite exit non-zero. GitHub also
fails the job for incomplete rehearsals. `validate-kit.sh` checks the workflow
jobs, repository gate and call to `run-all.sh`.

The validator runs some of the rehearsals itself, so the hosted job repeats
them. Keep both runs; do not add a skip switch. The hosted duplication costs
about half a minute, while a check that passes without running can hide an
expensive fault.

The job installs Claude Code and the starter's pinned Node.js and database
tools. Claude plugin checks and `fake-github.sh` use a stand-in rather than a
GitHub account. The recipe workflow uses locked packages, a browser and a
disposable local database and web server; it calls no live service. The replay
suite is excluded because it needs a model and costs money.

## Keep it generic

Nothing in the released kit names a project, company or person; it becomes a
specific tool at founding. The workflows are gated to this repository and do
not ship.

Files in `.agents/skills/` outside
`.agents/skills/setup-hosting/recipes/` may not name a hosting, data or deploy
service. `validate-kit.sh` enforces this boundary. Documentation may name the
services used by current recipes. A skill that needs service-specific behaviour
reads the project's recipe, so its instructions stay the same whichever recipe
the project uses. The screen rules link to Vercel's interface guidelines, which
are a design reference rather than a service the tool runs on. The maintainer
stack-research skill names services to check their product changes.

A recipe awaiting its real run stays in `.agents/tests/recipes-awaiting-run/`,
which does not ship. Once its `PROVEN.md` records the run, move it with `git mv`
into `.agents/skills/setup-hosting/recipes/`. The rehearsal adds it to the menu
and fails if it remains in both locations. [RECIPES.md](RECIPES.md) owns the
recipe format and evidence requirements.

Open check for a future real run [CHECK]: on 16 October 2026, Supabase's [API key
guide](https://supabase.com/docs/guides/getting-started/api-keys) recommended
publishable keys for client code and described `anon` as their legacy
equivalent, due for deprecation by the end of 2026. The guide says to create a
publishable key when a project has none, but whether a new project has one by
default remains unconfirmed. The recipe names the publishable key and records
the legacy `anon` setting for `/maintain`. Check the default in a throwaway
project during a real run.

## When a release is cut

Follow these linked steps in order:

1. [Before the build](#before-the-build)
2. [Build and rehearse](#build-and-rehearse)
3. [Notes, stamp and preparation](#notes-stamp-and-preparation)
4. [Publish and verify](#publish-and-verify)
5. [After publication](#after-publication)

### Before the build

Run `.agents/maintainer-skills/review-public-docs/SKILL.md`. Fix each finding or
record the maintainer's acceptance.

Ask what an existing user must do to upgrade. Identify changes to commands,
features, records, labels and preconditions. Each breaking change needs a path
that preserves existing project work and a notice where the person will see it.
The migration scripts, chiefly `upgrade-check.py`, run on `/maintain` visits
and are idempotent. `risk_move.py` performs the risk-record migration with
approval. Name visible changes in the release notes and keep a migration while
an existing project may need it. Each update route brings the latest release.

If a breaking change lacks either a migration path or a notice, it is not ready
to ship. A release that only adds behaviour answers the upgrade question with
"nothing to do".

Before checking an upgrade, rebuild the older-release test bed with
`.agents/tests/replay/testbed.sh`. `--list` previews the four default projects
without a model; `--replace` rebuilds existing copies while keeping them in the
run archive. The [replay guide](../.agents/tests/replay/README.md#projects-founded-by-older-releases)
describes the cases and retained evidence. Do not use a real project unless the
maintainer names it for a migration test; use a copy without credentials or a
remote.

Run `.agents/tests/replay/testbed-update.sh` against those copies. Its `--list`
mode previews inputs without a model. Read each retained report for the offer,
project-check exits, leftovers, both visits and any live claims without fresh
evidence. The [replay guide](../.agents/tests/replay/README.md#updating-the-older-release-test-beds)
describes options and report locations. These runs leave the source test beds
unchanged.

Apply PHILOSOPHY.md's four questions to the existing kit and proposed changes.
A part that no longer passes a question it once passed has drifted; use the
method in [PHILOSOPHY.md](PHILOSOPHY.md) to decide what to change. Check
`docs/SOURCES.md` in the same review: add new borrowed ideas and remove credit
for work the kit no longer does.

Read every recipe and shared part with `stack-research` before release. It
checks upstream changes and runs `npm audit` with current advisory data, which
is not run in CI. Its ignored note records findings and proposals. Carry agreed
changes into the recipe and this guide with the versions and date checked. A
retired recipe keeps an approved route to a current recipe in
`maintain/references/recipe-move.md`.

Read `.agents/tests/scenarios.md` and confirm each scenario still resolves to
the risk record, evidence and route it names. The replay and seeded-product
reads are described in [Behaviour tests](#behaviour-tests-scenarios-replays-and-seeded-products).
Before releases touching founding or `/setup-hosting`, also follow
[Trying unreleased work as a person would](#trying-unreleased-work-as-a-person-would).

### Build and rehearse

Build the released kit into a new temporary folder with
`.agents/tools/build-release.sh <version> <folder>`. Only paths in
`release-manifest.txt` ship. Run `.agents/tests/release-builder.sh`,
`.agents/tests/starter-rehearsal.sh`, and `.agents/tools/validate-kit.sh`.
The release check verifies the archive boundary; the starter rehearsal proves
an installed kit can prepare a clean project with its founding record
templates. Neither checks the person's guided setup interview.

The builder writes the version without its leading `v` into the Claude plugin
manifest. Validate the folder with `claude plugin validate <folder> --strict`.
One warning is expected: Claude Code reports that a root `CLAUDE.md` is not
loaded by a plugin. The kit keeps the file for projects copied as a whole; fail
on any other warning. Then rehearse the plugin with an isolated
`CLAUDE_CONFIG_DIR`, covering marketplace discovery, the manual command
boundary, local installation, bootstrap, failed marketplace refresh,
successful update and removal. Do not use the maintainer's real Claude
configuration.

Run `.agents/tests/agent-plugin.sh`. It builds a release and checks the
assembled `agent-plugin` folder against the standard: manifest fields, skills
as immediate children, no nested skills, no maintainer-only writing skill, and
project stand-up from that folder alone.

Run `.agents/tests/release-publication.sh`. It rehearses draft preparation
against a GitHub stand-in, including a missing draft, wrong version, published
Release and repeated preparation. It checks that publication workflows cannot
push, that deleted-publisher names and extra credentials are absent, and that
each job has its own repository gate.

Run `.agents/tests/mutate.sh` and `.agents/tests/promises-list.sh`, then read
`docs/PROMISES.md` to confirm each promise still names its mechanism. Only
tracked files can enter an approved release folder.

Builds on a Windows mount record incorrect file modes because every file there
appears runnable. The mount can also hide a missing runnable bit. The validator
therefore reads the mode Git recorded for each script run by path.

### Notes, stamp and preparation

Each merge to `main` updates the draft Release with pull request titles since
the last publication and suggests a version. Features and enhancements suggest
a minor version; other changes suggest a patch. The `release-major`,
`release-minor` and `release-patch` labels select the highest matching increase.
If labels change after a merge, run `update release draft` from the Actions
page. Closing an unmerged pull request changes nothing.

Write the versioned notes file with
`.agents/maintainer-skills/release-notes/SKILL.md`. Keep one file in
`docs/release-notes/`; delete the previous release's file when drafting the
next. The file is required before stamping. The skill gives the format and
review steps. Pull request titles can appear in public notes, so write them for
readers. Review the draft, remove internal detail, correct misleading summaries
and state any action existing users must take. Use `skip-release-notes` only
when a merged pull request has no useful place in the project's public history.

Paste the notes file into the Release web page above the drafted changes. If
editing notes through the API, include `tag_name` and `target_commitish` with
every draft edit: a `PATCH /releases/{id}` that sends only `body` resets
`tag_name` to `untagged-...`.

Run `.agents/tools/stamp-version.sh vX.Y.Z` on a branch, open its pull request,
let checks pass and merge it. The script runs
`.agents/tools/check-release-notes.py` and refuses to stamp until the notes pass
machine-checkable rules and the latest review has no Critical or Major finding.
Then merge nothing else until publication, or the version will cover changes
the notes do not mention. The two plugin manifests and `maintain`'s `VERSION`
marker carry the version installations report.

When the draft is ready, start `prepare release` with its version, such as
`v0.1.0`. The workflow rejects an existing tag, validates `main`, confirms its
version and attaches the checked archive. If the Release Drafter draft is
missing, refresh it first. Native GitHub generated notes are not used because
they cannot omit private numbers. Review the version, archive and notes before
publishing. If another pull request merges after preparation, run `prepare
release` again so the archive matches the draft.

### Publish and verify

Publishing the draft is the release. The prepared repository is the one people
install from, so there is no second copy or credential to create.

`verify release` rebuilds the published version from its tag and compares it
with the reviewed archive. It accepts only a tag contained in reviewed `main`.
This catches a manually retargeted draft or a pull request merged between
preparation and publication. A fix to a release workflow affects the next
release because a `release` event runs the workflow from the tagged commit.

### After publication

On the next branch, run `.agents/tools/record-released-copies.py` with the
release archive. It adds whole-copy files to the record `/maintain` uses to
offer removal of untouched copies. If a release is missing from the record,
its files are listed rather than offered for removal.

The companion site deploys from `stable` after verification. See
[The companion site](#the-companion-site) for its publication path.

## The main and stable branches

Two of the three installation routes read the default branch, which is
`stable`; it determines the release a project receives. Only a verified
published release moves it. After `verify release`, a second job points it at
the verified commit; failed verification leaves the branch unchanged. The
promotion job is the only workflow that writes to a branch.
`.agents/tools/promote-stable.sh` defines its limits.

Because `stable` is the default branch, GitHub and `gh pr create` propose it as
a new pull request's base. Open source pull requests with
`gh pr create --base main`. The `pull request base` check fails a pull request
aimed at `stable` and explains how to retarget it. It is not required because a
required check on `stable` would reject the release job's update.

`main` requires a pull request and the `source-kit-validation` and `rehearsal`
checks; it rejects deletion and force-push. `stable` rejects deletion and
force-push but cannot require a pull request: the release job updates its ref
through the API, while a pull-request rule rejects any ref update.

An ordinary fast-forward push to `stable` by someone with write access is not
blocked. The ruleset's update restriction would also block the workflow token,
with no way to distinguish it from a person's push. The current rules prevent
deletions and rewrites; a stray push is corrected by publishing again.

Rulesets must name `main` and `stable` literally. A `~DEFAULT_BRANCH`
condition follows the default branch when it moves and removes protection from
the branch it covered. After changing the default branch, query both branches:

```
gh api repos/<owner>/<repo>/rules/branches/main --jq '[.[].type]'
gh api repos/<owner>/<repo>/rules/branches/stable --jq '[.[].type]'
```

If `stable` needs rebuilding, compare it with the published tag before creating
it by hand:

```
git fetch origin && git rev-parse origin/stable
git rev-list -n1 vX.Y.Z
```

The commits must match. To check a promotion remotely, compare the branch with
the lightweight tag:

```
git ls-remote origin refs/heads/stable refs/tags/vX.Y.Z
```

A lightweight tag has no `^{}` form, so querying
`refs/tags/vX.Y.Z^{}` returns nothing. The branch and tag commits must match.

## The companion site

`site/` is outside `release-manifest.txt`. After verification, the Pages
workflow builds from `stable` and deploys; a failed site build does not change
release preparation or verification. For wording fixes, the maintainer may
start the workflow by hand on `main`. Behaviour changes reach the site through
a release.

`release-publication.sh` allows `pages: write` and `id-token: write` only in the
`pages.yml` deploy job. Set the Pages source to **GitHub Actions** in repository
settings.

## Trying unreleased work as a person would

Do this before any release that touches founding or `/setup-hosting`. It checks what a
person sees, which no rehearsal reaches. It asks the person for one GitHub click
and one Supabase project. The Supabase Free plan allows two active projects, so
one of those two slots must be unused. Pick a number for the run and put it
wherever `N` appears.

1. Build a preview from a clean `main`. The builder copies the working tree, so
   run this in the checkout on `main`, not a worktree on another branch.

   ```
   touch ~/.abk-try-N-start
   git switch main
   git branch --show-current
   git status --short
   git pull --ff-only
   git rev-parse --short HEAD
   .agents/skills/setup-ai-build-kit/scripts/check-tooling.sh --recipe .agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel
   .agents/tools/build-release.sh v0.0.0-preview.N /private/tmp/abk-preview-N
   ```

   The first line leaves a marker file whose time is the start of the run, so
   teardown can find what the run made. The branch must print `main`, and the
   status must print nothing. Note the commit. Every line of the tooling report must read `ready`. The builder refuses a
   folder that already exists, so a second build takes the next number.

2. Install the preview twice, into two empty folders.

   ```
   mkdir /private/tmp/abk-try-N-claude && cd /private/tmp/abk-try-N-claude && git init -q -b main
   npx skills add /private/tmp/abk-preview-N -a claude-code -s '*' -y

   mkdir /private/tmp/abk-try-N-both && cd /private/tmp/abk-try-N-both && git init -q -b main
   npx skills add /private/tmp/abk-preview-N -a claude-code -a codex -s '*' -y
   ```

   The first puts the kit's skills in `.claude/skills/`, the second in
   `.agents/skills/` with links in `.claude/skills/`. In both, `setup-hosting/recipes/`
   contains the same recipes listed by `ls <kit checkout>/.agents/skills/setup-hosting/recipes/`.

   Each `skills-lock.json` now records `"sourceType": "local"`, with a path into
   `/private/tmp/abk-preview-N`. A project installed this way cannot update
   later, and a `/maintain` visit there can fail once that folder is gone.

3. Found a small internal tool in each folder: open Claude Code, run
   `/setup-ai-build-kit`, and ask for something small, such as a page where a
   team keeps short notes. When founding offers a GitHub repository, approve its creation and name it
   `abk-try-N` in the first folder. Decline in the second. Then
   check in each folder:

   - During the founding conversation, the kit showed the recipe menu, marked one
     recipe as recommended and reported that it would use it unless told otherwise.
   - `grep '^Recipe:' AGENTS.md` names one recipe folder.
   - `grep founding-menu .ai-build-kit-maintenance` names every recipe on the
     menu.

   A failed check is a finding. File it as an issue, and do not fix it in the
   throwaway project.

4. In the first folder only, run `/implement` on one ready piece and approve its merge, then run `/setup-hosting` once, asking for a Vercel project
   named `abk-try-N`. Without that name, `/setup-hosting` names the project
   after the tool. The person does two things:

   - On GitHub, Settings, Applications, Installed GitHub Apps, Configure beside
     Vercel. GitHub asks for a passkey or password before it shows that page.
     Add `abk-try-N` under Only select repositories, and save. The app may
     already be installed with other repositories selected. Add `abk-try-N` to
     that selection, and never replace or clear it.
   - In the Supabase dashboard, make a project named `abk-try-N`, and paste a
     password made and copied like this:

   ```
   mkdir -p ~/.config/abk-try-N
   (umask 077 && openssl rand -base64 48 | tr -d '/+=\n' | cut -c1-40 > ~/.config/abk-try-N/db.pw)
   pbcopy < ~/.config/abk-try-N/db.pw
   pbcopy < /dev/null
   ```

   The password is 40 letters and digits drawn at random, in mixed case, since the create form
   marks a lowercase hex password as not secure enough. Only this account can
   read the file, and no command prints the password. The last line empties
   the clipboard once the password is pasted. When the kit asks where the
   password is kept, give it the file's path. A secret never goes into the
   chat. When Chrome or an agent fills the form, it can show a stale "Password
   not secure enough" message and still create the project, so check the
   project list rather than the form.

5. Tear everything down.

   ```
   vercel project rm abk-try-N
   gh auth status
   gh auth refresh -h github.com -s delete_repo
   gh repo delete <owner>/abk-try-N --yes
   gh auth refresh -h github.com -r delete_repo
   trash /private/tmp/abk-try-N-claude /private/tmp/abk-try-N-both /private/tmp/abk-preview-N ~/.config/abk-try-N ~/Backups/abk-try-N
   ```

   Answer `y` when Vercel asks. `gh auth status` lists the token's scopes. If
   `delete_repo` is already there from an earlier run, skip the first refresh.
   The first refresh adds the scope that `gh repo delete` needs, and the second
   takes it off the token again. It takes the scope off on purpose, even when
   it was there before the run, since a token keeps no more reach than it
   needs. Each refresh waits for a confirmation in the browser, which an agent
   cannot give, so the person runs it.

   Delete the Supabase project in the dashboard, since
   `supabase projects delete` cancels its own confirmation without a real
   terminal. Deleting the repository also removes it from the selection of
   Vercel's GitHub app, so leave the app installed. Only if it was installed
   for this run, uninstall it under Installed GitHub Apps.

   `/setup-hosting` leaves two things on this computer. `~/Backups/abk-try-N` holds the
   database's roles, structure and data, and the `trash` line above takes it.
   The kit also writes temporary files in `/private/tmp`, such as restore-test
   folders and logs, whose names this section cannot know. List everything
   there that is newer than the marker from step 1, trash what the run made,
   and list again. Other sessions write there too. If you cannot tell who made
   an item, leave it. Trash the marker last, once the list shows nothing the
   run made:

   ```
   find /private/tmp -maxdepth 1 -newer ~/.abk-try-N-start
   trash ~/.abk-try-N-start
   ```

   The local folders go to the Trash, since a deletion with no undo is on the
   blocked list in `.agents/guard/blocked-commands.md`. Where `trash` is
   missing, `mv <folder> ~/.Trash/` does the same.

   Then check that each item is gone:

   ```
   vercel project ls
   gh repo view <owner>/abk-try-N
   ls /private/tmp/abk-*
   ls ~/.config/abk-try-N
   ls ~/Backups/abk-try-N
   ls ~/.abk-try-N-start
   ```

   `vercel project ls` does not list `abk-try-N`. `gh repo view` answers
   "Could not resolve". Every `ls` line finds nothing. The Supabase dashboard
   no longer lists the project.

6. Write a dated log: the preview version and the commit it was built from,
   each check and whether it passed, with its output, what the run
   created and how it was removed, and anything that surprised you. A failure
   found here is filed as an issue before the release, and the release waits
   until somebody decides what to do about it.

## House rules for writing

Anything written into this repository, by a person or an agent, follows these.
Most public documents are for people who do not read code, so they use plain,
adult prose. Maintainer documents are for people who work on the source and may
use technical language suited to their readers. A short form ships in the
project template, so a project built with the kit inherits its public-facing
writing guidance without carrying the full editorial framework. These rules
govern the kit's own documents.

Before saving prose, load
`.agents/maintainer-skills/writing-review/SKILL.md` and run its embedded mode. This
covers documentation, skills, pull request titles and descriptions, issues,
release notes, interface copy, error messages, and reader-facing comments. The
framework replaces any Simplified Technical English instruction for this
repository. The skill is the shared instruction for every supported coding
agent, and the rules below remain the kit's house style. Release notes also follow
`.agents/maintainer-skills/release-notes/SKILL.md` for their format and review.

Preserve the information and intended voice rather than the draft's sentence
shape. Never invent facts, names, figures, dates, quotations, or citations.
Leave code blocks, frontmatter, data, commands, and link targets untouched.
After the first edit, ask what still sounds generated and revise once more.
Technical and reference writing should stay neutral and plain; personality
belongs only where the subject and author's voice call for it.

- British spelling. No em dashes: a comma, colon, semicolon, or full stop is
  always available and always clearer.
- Precise and natural, not forced simple. Use the established term where it is
  the right word ("approval", not "your yes"; "configuration", "branch
  protection"). Define it once only where a reader who does not read code would
  not know it. Avoid jargon that a plainer standard term replaces.
- Plain does not mean elementary. Join closely related ideas into one sentence
  rather than a row of short ones, and write sentences that read naturally
  aloud rather than ones assembled from a template.
- Give each tool the verb that matches what it does. A check passes, fails,
  detects, reports, blocks or skips. A script enforces, rejects or records. A
  test fails on a fault and proves a mechanism works. None of them says, judges
  or decides. A check or script blocks or rejects an action. A person approves,
  confirms or declines.
- Claim only what the evidence shows. Keep each condition and limit beside the
  claim it narrows, and do not turn a narrow fix into a general promise.
- Banned: leverage, robust, comprehensive, seamless, crucial, foster, enhance,
  transformative, delve, navigate as a metaphor, empower, streamline, holistic.
- No contrastive reframes ("it's not X, it's Y"), no rhetorical triplets, no
  bulleted lists where each item opens with a bold header. Release notes are the
  one exception: their numbered items each open with a short bold name.
- Explain a concept where it lives, and link from everywhere else.
- One name per thing. This is a kit, and calling it a pack somewhere else only
  makes a reader wonder whether the two are different.
- Keep paragraphs to about 100 words. Long paragraphs hide the one sentence a
  reader needed.
- Vary the sentence shape. Almost every explanation wants to arrive as
  "statement: a, b, and c", and a document leaning on one device reads as a
  template however clear each instance is.
- Two house aphorisms earn their keep and were both badly overused: "X is how
  something good goes wrong", and "X, never Y". Two of each per document.

## One owner per concept

Each concept has one home; other documents link to it.

- The root `README.md` is the public front door: purpose, installation and
  positioning. The [website](../site/) owns the user guide and explains how the
  kit works.
- Root `AGENTS.md` owns source-maintainer rules. The foundation
  `AGENTS.md` template owns instructions and the capability profile for a
  project the kit founds.
- `docs/PHILOSOPHY.md` explains the kit's purpose and the test additions must
  pass. Read it before changing a skill's behaviour.
- `docs/COMPATIBILITY.md` owns the portable contract and per-agent details.
  This guide owns source maintenance.
- `docs/PROMISES.md` owns the promise register and the mechanisms behind each
  promise. `promises-list.sh` reads it.
- `docs/RECIPES.md` owns the recipe format and evidence required to prove one.
  Recipe folders in `.agents/skills/setup-hosting/recipes/` hold each recipe's
  implementation.
- `docs/SOURCES.md` records borrowed work and links to its source.
- Root `llms.txt` is a standalone summary for tools that read the repository;
  it may repeat the README.
- `CONTRIBUTING.md` and `SECURITY.md` are standalone public documents.
- `.agents/maintainer-skills/release-notes/SKILL.md` owns the notes format and
  process; `docs/release-notes/` holds the next draft.
- `.agents/skills/maintain/scripts/kit-released-copies.json` and `/maintain`
  own recognition and removal offers for untouched files copied by earlier
  releases.
- Website content files own their individual site pages.

Two concepts retain an internal name beside the name a person reads, because
changing the internal name would alter output without helping the reader. People
read “background skills”; inventory and check messages use “disciplines”. They
refer to the same 13 background skills listed in
`.agents/tools/kit-inventory.txt`. People read that an agent chooses a method;
`.agents/tests/scenarios.md` and `.agents/tests/replay/grader-prompt.md` call
that graded field “hidden technique”. Its name remains until a measurement is
no longer needed for comparison.

`/shape` names the command that turns an idea into a ready piece. The records
reference uses “shape” for what an issue must contain. The command produces
that shape, and its slash distinguishes the command. Always write the command
with its slash.

The stale-claim checks reject retired names for the commands. Before adding an
explanation, check its owner and link to it. If two documents disagree, edit
the one that does not own the concept.
