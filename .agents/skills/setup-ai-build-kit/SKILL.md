---
name: setup-ai-build-kit
description: Begin a new project, or resume a beginning that was interrupted. Use when the user types /setup-ai-build-kit or asks to start or set up a new tool. Runs once per project; if the founding documents already exist and are complete, say so and point at /implement. Do not use for new features on an existing project (that is shape) or for repairs (that is fix). Type this command when you want it; it never starts on its own.
disable-model-invocation: true
---

# Start

You take a team from an idea to a project ready to build: interviewed,
assessed, documented, stood up. You write no feature code in this skill. It is
resumable: read what already exists, say plainly which step you are resuming
from, and carry on.

## Conversation contract

`/setup-ai-build-kit` guides the person through project decisions. Speak when they need to
answer a question, make a decision, approve an action, understand a blocker,
or see a result that changes what they can do next. Finishing an internal step
is not a user-facing result by itself. Routine reading, research, setup, and
checking happen quietly.

Ask every question in the shape clarify's "How to ask" section describes,
whichever step you are on. A short and complete set of answers may be offered
as choices; anything the person would answer in their own words is asked as a
plain question.

Do not narrate commands, search queries, package or version selection, retries,
waiting, terminal output, or internal technical reasoning. Record technical
choices in AGENTS.md. Name a tool or service in the conversation only when the
person must choose it, pay for it, create or own its account, grant it access,
or understand a limit that affects the product. When you name one, say what it
is in one plain sentence at the same moment, so the person can decide without
already knowing the word.

A harness may show its own command or status text. Do not repeat that text or
translate each line as it appears. If the harness requires an update during a
long operation, say only which visible outcome is still being checked and
whether anything has changed.

Give the plain permission explanation once, immediately before a real
confirmation box. Do not announce that a confirmation might appear later. If
the action and its boundaries were already explained, refer back to that
explanation instead of repeating the full checklist.

## Founding ends with something stood up

Every step below wants something from the person. None of them is a gate. This
skill is finished when the project exists and a checkpoint is saved, and that
outcome outranks any answer still outstanding.

An answer you would like but do not need becomes an open question in the
masterplan, your best guess recorded beside it, and founding carries on. Ask it
later, once there is a project to change.

A step that tells you to check something is a check, not an interview question.
Where a step says to answer from the masterplan, answer from the masterplan. A
gap found that way becomes a setup task or an open question, and the person is
told what was recorded rather than asked to fill it in.

A person who says to get on with it has answered everything outstanding at once.
Take the guesses, say in one line what you assumed, and stand the project up.

Founding that stops with nothing stood up has helped nobody, whatever it was
waiting for. There is no answer worth more than a saved project, because every
answer can still be changed afterwards and an unfounded project cannot.

## 0. Resume safely

First, run `scripts/bootstrap-project.sh` from this installed skill folder in
the project root. It creates only missing project foundation files and leaves
anything already there untouched. If the harness cannot run the script, copy
the missing files from `templates/foundation/` to the paths named by the
script. Never replace an existing file during this preparation. When an
existing `AGENTS.md` lacks the installed-skill load rule, preserve its project
instructions and add the smallest compatible rule before continuing.

The same script works when a coding agent runs this skill from a plugin, in
Claude Code or through the Agent Plugins format. If it reports that the
project has both a plugin and a separate AI Build Kit skill installation, stop
before preparing the project. Keep the plugin when one coding agent runs the
project, or keep the shared skills installation when the project uses more
than one coding agent. Never leave both active.

A folder holding the kit and nothing else is the normal place to found a
project, not a reason to stop. A fresh installation leaves `README.md`,
`WORKFLOW.md`, `docs/`, `.agents/skills/` and `agent-plugin/` in the project
root, which reads exactly like the kit's own source code, and the answer is not
to guess from how it looks. Look for `.ai-build-kit-version`: every release
carries it and the kit's source never does. Where it is there, this is an
installation waiting for a project, so found here without asking.

The kit's own source is the one place founding does not belong, and it says so
plainly: `release-manifest.txt`, `.agents/tests/` and `docs/MAINTAINING.md` sit
at its root and reach no release. Only where those are present is stopping
right, and then say which of them you found rather than describing the folder.

Never make a location the thing founding waits on. Where the person meant a
different folder they will say so, and a project founded in the wrong place
costs a move; a project never founded costs everything that was said to get
there.

Read the repository's current state before doing anything else. Check whether
masterplan.md and CHANGELOG.md already exist, whether the project's pieces
exist as issues, and whether any of them look complete or
half-written. Check for unfinished setup: a placeholder still in
`.github/workflows/checks.yml`, an uncommitted change, an open question left
in the changelog. Say plainly where the process is resuming from. Never
overwrite an existing record without saying so and getting agreement first.

Look for `.agents/tmp/setup-notes.md` in that read. It holds the answers agreed
so far when an earlier session stopped before masterplan.md existed. Where it
exists and masterplan.md does not, say you are carrying on from those answers,
read them back as one short list, and wait for a yes. Handle a correction the
way you handle a wrong guess: the person says what changed, and you update the
file.

## 1. Orientation

Before any technical action, say what is about to happen, close to: "First
I'll help turn your idea into a small plan. Then I'll prepare a private
working version, check that it opens, and save a checkpoint. Nothing will be
published or shared unless I explain that separately and you approve it."
When step 3 finds an existing project to adopt, replace "turn your idea into
a small plan" with something about understanding what already exists before
anything changes. Say nothing about GitHub or shared setup here; it is
set up later, at the step that creates the pieces, not now. Skip
repeating this when a resumed session already covered it in step 0.

## 2. Capability check

First run `scripts/check-tooling.sh` from this installed skill folder. It reports
whether Git, the GitHub command line tool, and python3 are ready and signed in,
so a missing one is caught here rather than at the later step that creates the
issues. If the harness cannot run the script, work through
references/required-tools.md by hand. When a tool is missing, guide the install
following references/manual-setup.md before going on.

Load references/capability-check.md and work through it. Record the result in
AGENTS.md under Capability profile: harness name when known, file read/write,
shell, Git, local save identity, online repository, online account access,
online authentication, available test/runtime commands, browser or preview
access, independent-review options, hook support, subagent support. Choose a
fallback for anything missing. Do not make the user configure an optional
feature before the interview; a missing capability becomes a setup task or a
reduced-automation fallback, decided later at the step that needs it.

## 3. Fresh project, or adopting something that exists?

Ask whether code already exists: an app built in an all-in-one builder, a
tool living inside a chat assistant, an earlier attempt. If yes, follow
references/adopting.md, which reshapes the steps below around what exists;
the one-line summary is read first, interview against reality, pin down
behaviour before changing it. If starting fresh, continue here.

## 4. Test the need for software

Test the idea against the ladder, cheapest first: a process change, a feature
in something the team already pays for, a spreadsheet or database view, an
off-the-shelf product, an automation inside an existing service, a configured
AI chat, an agent skill, a lightweight form or no-code workflow, custom
software. Ask the four questions: will it keep records that build up over
time? Will other people use it without the person who made it? Should it act
on its own? Must it enforce rules? Where custom software does not provide
material value over something cheaper, say so once, plainly, and say what would
do instead. Saving the team a project is a good outcome.

Say it once, and do not stop to ask. The case is made in one reply, at this
step, and the same reply carries straight on into the next one. Do not end the
turn on it, do not ask which way they want to go, and do not wait for an answer:
a person who wanted the cheaper thing will say so unprompted, and one who did
not has lost nothing. Naming a product they might already have is enough. Do not
tell them to go to whoever administers it, because that turns a remark into an
errand.

If they want the tool anyway, that is their decision and not a fault to be
corrected: record the cheaper option and the choice in the masterplan, and carry
on founding. Do not ask the question again, do not hold the interview open until
it is answered, and never make an answer a condition of founding.

## 5. Founding interview

Run the clarify skill for the founding interview. During it: resolve
overloaded terms rather than letting them pass; use concrete examples to
settle ambiguity; invoke source research when an answer depends on an
external fact; settle a visual or behavioural question with a mock or
sketch the person already has, or a disposable decision prototype where they
have none; keep open questions visible
rather than quietly guessing past them. It ends when your guesses keep being
right.

Write each answer into `.agents/tmp/setup-notes.md` as it is agreed, before
asking the next question, so a long conversation cannot lose it. Plain
sentences under the question they answer, no template. Before that first write,
check `.gitignore` carries `.agents/tmp/` and add the line when it is missing,
so the notes stay out of every commit. Say nothing about the file: it is
housekeeping rather than a decision the person makes.

## 6. Fit check and build path

Go through references/fit-check.md: the consequence and ownership questions,
one at a time, guesses attached like the interview. Record the result in the
same working notes as it is settled: which of the four build paths, why, the
required controls, any outside help and its scope, the recheck triggers, and
today's date. Before settling on build with expert help or professional-led,
work through the redesign options in fit-check.md; if a redesign changes the
answers, run the check again. Where a
trigger survives that, give the risk notice fit-check.md describes before any of
the flagged work goes ahead.

## 7. Write the masterplan

Create masterplan.md from templates/masterplan.md, filled from the interview,
present tense throughout. The build-path section goes first: the fit check's
result. Create CHANGELOG.md from its template, empty; it has to exist before
the next step writes its first line to it. Create `.ai-build-kit-maintenance`
from `templates/maintenance-record` and put today's date on its `founded` line.
Leave the two pass lines empty, because `/maintain` fills those in. Do not
mention that small file to the person. Do not create team.md; it no
longer exists. Fill in AGENTS.md's project line and the capability profile
from step 2. Replace README.md's project-name and purpose placeholders with a
short description taken from the masterplan.

Where README.md holds no such placeholders, it is somebody's real file: an
installation that arrived as a whole copy of the kit leaves the kit's own
read-me at that path, and an adopted project has its own. Leave it exactly as it
is. Say in one line that the description is going into masterplan.md and
AGENTS.md instead, and carry on. Never overwrite it, and never stop to ask which
the person would prefer. A read-me is the cheapest thing in the project to
change later and the founding is the most expensive thing to lose.

Fill the masterplan from the working notes as well as from the conversation,
then delete `.agents/tmp/setup-notes.md` in this same step. The masterplan
carries everything the notes held, so nothing is lost by clearing them.

Draw the connections section from what the interview found, then read the
picture back in plain words and let the team confirm each outside connection
before going on: that it should reach their email, their calendar, whatever the
picture shows. A connection nobody meant to agree to is cheapest to catch here.

If docs/MAINTAINING.md exists, delete it as part of this same commit. Current
starter releases exclude that source-only file, but older direct clones
may still contain it. Do this yourself rather than asking the user to remember.

If the project needs a `.env`, copy `.env.example` to `.env` now, confirm
`.env` is listed in `.gitignore`, and never print its contents back to the
user.

## 8. Review the masterplan

Who this is for decides whether it runs. On build with expert help and
professional-led paths, the masterplan is read before flagged work continues,
because somebody other than the builder is going to be relied on and the plan is
what they will be relied on against. On Build and run it, skip it: an ordinary
internal tool has no exposure for a reviewer to find, and a review nobody needed
costs the person a wait they did not ask for. Say in one line that it was
skipped and why, and record that in the changelog, so a project that later moves
up a build path knows this never happened.

Where it does run, use the best independent method recorded in the capability
profile: an independent subagent, a clean separate session, or a user-opened
clean chat with a prepared instruction. A same-session fallback is permitted
only for Explore privately, and must be labelled plainly as not independent.

Where no independent method exists at all, say so, record it in the changelog as
a setup gap to close before flagged work continues, and carry on founding. Do
not wait for one to appear. This step used to stop until the review had
happened, which in a session with nobody else to ask is a wait that never ends,
and it cost two measured runs their whole founding. A masterplan nobody has read
is a gap worth naming; a project that was never stood up is not worth trading
for it.

When resuming, look for the review's note in the changelog.

## 9. Ownership check

Answer from the masterplan alone, no memory allowed: can the team explain the
main flow? Can it explain who can see and change what? Can it identify where
important data, secrets, and service accounts live? Can it recover or
continue manually if the tool stops? Is somebody responsible for alerts,
backups, bills, and access? A "no" to any of these becomes a setup task before
build starts, or moves the build path upward if the gap cannot be closed
here. Note the result in the changelog.

## 10. Cut the plan

Pieces sized for one sitting, and small enough for a fresh session to hold
whole, in the order they unblock each other, each cutting vertically through the
whole tool so the unknowns surface early: what the user can do or see when the
piece is complete, its evidence, and its genuine dependencies. Do not split one
user capability into separate "database", "API", and "UI" pieces.

Each piece becomes an issue, written to the shape in references/pieces.md. This
needs a GitHub repository and the GitHub command line tool signed in; where that
is not yet in place, guide the person through it now, following
references/manual-setup.md, because the pieces live as issues and there is no
file-based substitute. A private repository keeps issues just as well as a
public one, so a project that wants to stay private still uses one. Do this without narrating it: create the
label set, delete the labels GitHub made by itself, copy
templates/foundation/piece-issue.yml to `.github/ISSUE_TEMPLATE/piece.yml`, open
one issue per piece, label each shaped piece `ready` (or the matching `needs-`
label where it still holds an open question for `/shape` to settle), and link the
ones that genuinely block each other using GitHub's blocked-by relationship.
Then run `.agents/tools/plan-refresh.sh` once, so the person has their list
before they need it.

Set the repository to delete a merged pull request's branch automatically, so
the branch list does not fill with finished piece branches
(`gh api -X PATCH repos/OWNER/REPO -F delete_branch_on_merge=true`), and say in
one line that you did. That is the whole of the pull-request hygiene the kit sets
up on the repository. A direct push to `main` is blocked by the guard in
references/blocked-commands.md rather than by a branch protection rule.

The labels GitHub creates on a new repository are `bug`, `documentation`,
`duplicate`, `enhancement`, `good first issue`, `help wanted`, `invalid`,
`question` and `wontfix`. Delete every one that is still there. This is safe here
and only here, because founding happens before any issue exists to be wearing one.

Say which ones went, in one line, rather than deleting them silently. Where the
account cannot delete a label, say which stayed and carry on: a leftover label
is untidy rather than harmful. Anything a person added themselves is left alone
under the ordinary rule.

An idea that did not make the cut becomes a closed issue labelled `parked`, with
the reason in the body.

With the pieces created, load references/coverage-read.md and run the coverage
read against the masterplan. This is the cheapest moment in the project's life
to find a promise nobody planned to build.

Where the person cannot complete the GitHub setup in this session, save the
masterplan and everything else, and say plainly that the pieces cannot be
created until the GitHub command line tool is signed in. Name that as the one
remaining step. Do not invent a file in its place; the pieces live as issues,
and this step is only finished once they exist.

## 11. Stand the project up

Ask two questions: will the team use this in a browser, and does it need to
work when your machine is off? Set up accordingly. One established,
conventional stack, because the agent is strongest where the conventions run
deepest. Managed services for anything storing sign-ins, payments, or files;
those never get hand-built, however capable you feel, unless a professional
explicitly owns a different design. Use references/manual-setup.md for any
step only a human can complete. If hosting is needed, arrange it so day-to-day
pushes land at a preview address and only /ship changes the address the team
uses.

Choose routine technical parts quietly and record them under AGENTS.md's stack
section. In the conversation, describe what the setup lets the person do. Name
a product or service only when it creates a choice, cost, account, access step,
ownership duty, or product limit that the person needs to understand.

If the interview surfaced confidential working files, create their folder
now, add it to .gitignore, and record the handling rules in AGENTS.md. If the
tool keeps a list of files to carry into a working copy, add the folder there
too; in Claude Code that list is .worktreeinclude.

Wire the project check according to the build path. If
`.github/workflows/checks.yml` is missing, copy it from
`templates/foundation/checks.yml`. Explore privately needs a
local test or smoke command, and the remote pull-request check stays
optional; build and run it, and build with expert help, both need the remote
check working before any shared or live behavioural work; professional-led
needs enough to support prototype and specification work, with the
professional owner confirming production checks later.

Configure only `jobs.project-check`.

Inside that job, replace the placeholder `Install and test` commands with the
project's real install and check commands.

An older project may still carry the legacy `source-kit-validation` job and
its repository conditions. Leave that job and its conditions unchanged. Edit
only `jobs.project-check` in either layout.

Do not replace the entire workflow file from memory. Edit only the
placeholder step unless the project genuinely requires a broader workflow
change.

Say one sentence about it when done: "green means the tests really passed;
red means don't merge, tell /fix."

Before starting the unfinished project to prove it runs, explain the action
using the rule in AGENTS.md, close to: "I'm going to start the unfinished
tool briefly and check that its main page opens at the recorded address. It
will run only on this computer, nothing will be published, and I'll stop it
again once the check is done." Where the harness allows it, treat starting,
checking the page, confirming the address, and stopping as one understandable
operation rather than several unrelated technical approvals, then give
AGENTS.md's warning that a technical confirmation box may appear next.

Before the first checkpoint, check whether the project already has a
suitable save name and email configured. Never invent a real identity, and
never copy the latest commit's author: that person may be the kit's own author,
an earlier collaborator, or someone with no connection to whoever is sitting
here now.

Where none is configured, do not stop for one. Save under a project-only
neutral label, "Local project user", applying only inside this project, and say
in one line that the checkpoint carries that label, that it can be changed, and
that no online account was created and nothing was uploaded. Record the real
identity as an open question in the masterplan.

A neutral label is not an invented identity, which is what that rule protects
against, and it is the same fallback this step already offered a disposable
experiment. Waiting for an answer here costs the whole founding, and a label on
a checkpoint is among the cheapest things in the project to change afterwards.

When the setup is ready to save, say so before saving, close to: "The
initial setup is ready to save. I'm going to save a checkpoint inside this
project so this working state can be recovered later. Nothing will be
uploaded."

Finish with: one command that proves the project starts, one small passing
behaviour or smoke check, a recorded preview or local run path, and the initial
state saved as a checkpoint on this computer. Load
references/completion-report.md and report the result in its shape.

The founding save is always the checkpoint route, whatever the tool will grow
into. It stands an initial state up rather than changing anything anybody
relies on, so there is nothing yet for a reviewer to compare against and nothing
live to protect. Do not push it, do not open a pull request for it, and do not
read a remote being reachable as a reason to use one. Founding already told the
person "Nothing will be uploaded", and that has to stay true.

section-builder chooses between the checkpoint, pull-request and flagged routes
for each piece built afterwards, on what that piece touches. That choice is
about the work, not about this. A tool the whole team will share still founds
locally, and its first piece takes whichever route it earns.

## Done when

The build path is recorded, the records exist (masterplan.md, CHANGELOG.md, and
the pieces as issues), AGENTS.md contains the capability profile and project
commands, the masterplan has had whatever review its build path called for or a
changelog line saying why none ran, the initial state is saved as a local
checkpoint, the plan is made of visible pieces each labelled `ready` or with its
open question, one check passes, and the user has received the plain-language
completion report, which ends on a clean cut naming `/implement` and `/shape`
rather than an offer to build in this session.
