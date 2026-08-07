# WORKFLOW.md: how this project runs

The reference card. When in doubt about what to type, start here, or just type
/what-now and let it tell you. Skills are invoked by typing `/` and the name as
a slash command (`/start`, `/build`, …), or by asking for them by name. The
Claude Code plugin adds the prefix `ai-build-kit:`, such as
`/ai-build-kit:start`. The older `$name` form still works too.

## 1. The seven words

| The moment | Type |
|---|---|
| I'm starting something | /start |
| Keep going, or: I want it to... | /build |
| It's broken | /fix |
| I think it's ready | /ship |
| I'm done for today | /sync |
| It's been a while | /maintain |
| I'm lost | /what-now |

Underneath the seven sit exactly two kinds of work. /build makes the tool do something new or different. /fix brings it back to doing what it already should. Everything else is housekeeping around those two.

You never need to choose the hidden technique. The agent decides whether the moment needs an interview, a prototype, research, a test, a review, or outside help.

## 2. The three records

The records are the project's memory. The agent forgets everything between sessions; these don't, and every piece of work starts by reading them.

| Record | Purpose |
|---|---|
| masterplan.md | What the tool is, in the present tense. Its first part, the build-path section, records how careful this project needs to be; the agent reads that part first, always. |
| plan.md | What's left to build: the pieces, in order, each with what done looks like, its evidence, its class, and what it needs. It churns constantly, and that is its job. |
| CHANGELOG.md | What happened, dated, in plain language, when work actually landed. |

`AGENTS.md` sits alongside the three records as the instruction file the agent reads to know how this repository works: the rules, the stack, the capability profile, the conventions.

The dividing rule: the masterplan describes the present, the plan holds the future, and the moment a sentence is about when, why, or how something was built, it belongs in the changelog.

## 3. The build path

Every project has exactly one build path at a time, set by the fit check and rechecked as the project changes character.

**Explore privately.** Nobody depends on it yet, data is disposable, and nothing it does is hard to undo. Manual checks are fine for visual and exploratory work, and a confirmed checkpoint commit is enough to save it.

**Build and run it.** The team's own tool, with a manual fallback and consequences that are limited and recoverable. Promised behaviour gets evidence, shared or behavioural changes go through a pull request, and named risky areas get an independent review before they go live. This is the path most projects here end up on.

**Build with expert help.** One or more named areas, such as sign-in, payments, or personal data, need a professional's involvement even though the team can still own the rest. The kit keeps building everywhere else and stops at the named boundary until the recorded help condition is met.

**Professional-led.** The core risk, regulation, irreplaceable live data, or a scale of consequence the team cannot safely carry, can't be designed away. The kit's job becomes producing the specification, the prototype, and the brief a professional needs to build the production system.

## 4. Day one

Type /start. It checks what the current tool can actually do, then tries to talk you out of building if something simpler would do the job. It interviews you, one question at a time with its best guess attached, and runs the fit check to set the project's build path. From those answers it writes the masterplan, has the best available independent method read that page looking for holes, cuts the work into pieces on the plan, and stands the project up with one passing check. Interrupt it anywhere; typing /start again resumes where it stopped.

While it works, the conversation follows project decisions and results you can
use. Routine searches, setup commands, retries, and waiting stay behind the
scenes unless they create a blocker or require a decision. Your agent tool may
still display its own technical activity, but the agent does not repeat it.

Already built something, in an app builder, a chat assistant, or an earlier attempt? /start adopts it instead of replacing it: it reads what exists, interviews you about what the tool is supposed to do, writes the masterplan for what's actually there, and pins down current behaviour with tests before anything changes. Your earlier build was the right first step; this is what graduating looks like.

If the tool needs confidential files to work from, say so during the interview. /start makes a folder for them that stays on each machine and never reaches GitHub, and writes the handling rules into AGENTS.md.

## 5. Day to day

Typed alone, /build takes the next piece from the plan. It agrees with you in one sentence what the piece should do, chooses the evidence that piece needs, builds until that evidence holds, then stops so you can try it. Nothing is saved until you confirm it behaves.

If the change touched an area the build path flags, the best independent method available reviews it first, in order: an independent subagent, a clean separate session, or a user-opened clean chat with a prepared instruction, with a same-session fallback only for private exploration, clearly labelled as such. It reports in plain language, sorted into what's worth stopping for and what's worth knowing.

Typed with words after it, /build is how you bring anything new: "/build add a filter to the board". You never sort your own request; the agent works out what kind of work it is. Small and clear gets built right away. Vague gets a short interview. A question conversation can't settle gets a disposable prototype or a source check. Anything touching data, access, or money gets written into the masterplan first.

If the request would change what kind of project this is, by bringing in outside users or real money or a promise to someone, the agent re-runs the fit check with you before building. A different build path needs different care before people rely on it.

/fix is for when something that should work doesn't: "/fix the board duplicates cards when I drag them". Paste the whole error if there is one. It builds the tightest repeatable check it can find for the exact symptom, works out the cause before touching code, resets failed attempts rather than stacking them, and finishes with evidence that keeps the bug from coming back.

If the same piece fails three rounds in a row, it stops patching and routes by what the failures revealed: grilling for an unclear requirement, a stop for missing access or environment, a rebuild from the masterplan for a clear requirement that keeps failing unreliably, scoped expert help for one technical area failing repeatedly, a maintenance finding when no testable boundary exists, or professional ownership for a rebuilt piece that still fails.

You can't misfile work by picking the wrong word. Both check your request against the masterplan first and re-route politely if you guessed wrong.

## 6. Evidence

Every promised behaviour gets evidence, in one of four forms:

- an automated behaviour check, for business rules, calculations, permissions, data changes, integrations, and bugs, where a machine can judge the result reliably;
- a guided manual check, for copy, layout, colour, and exploratory or subjective work;
- a source-backed fact, when correctness depends on something an external service or provider actually does;
- an operational rehearsal, for backups, restores, migrations, rollback, or anything else that only proves itself by being run.

The agent chooses the form the change actually needs; the report says what was proved and what remains a judgement call.

## 7. Saving work

Every piece saves through one of three routes. The checkpoint route commits, and that commit may stay local: private, disposable exploration needs no remote or GitHub authentication to complete. The pull-request route pushes and opens a pull request, for shared, live, behavioural, data, access, integration, service, or operational changes. The expert-gated route does the same, and also attaches the expert gate the touched area requires; a piece that stops there, plan marked blocked and the gate condition on record, counts as finished until that condition is met.

Next to the merge button sits that check. It re-runs the project's real commands on a clean machine, on top of whatever the pull request's summary claims, so the claim gets verified rather than trusted. Green means the check really passed: safe to merge. Red means don't merge; say it to /fix, and the agent reads what failed itself. You never read the machine's logs, and you never merge over a red check.

A human decides whether to merge, always; after a merge, everyone pulls main. Flagged areas also get the review the build path names before the pull request is offered as ready.

## 8. Outside help

When the build path names outside help, it's one of four levels: a short advice conversation to validate a choice, a scoped review of one named area, a supervised change for one risky event, or professional ownership of the build. The build path's section says which level, for what scope, and what the review or the professional must confirm before the flagged work can go live. The kit keeps building unflagged areas while it waits.

## 9. Shipping

/ship reads the build path first, and each path gets only the process it needs, not a shared ceremony trimmed after the fact.

**Explore privately.** /ship runs no production evidence or launch procedure; it only confirms the prototype stays disposable and private, and records what would have to change to graduate.

**Build and run it.** /ship runs the full evidence run, independent review, operational readiness (alerts, backup, a restored-backup rehearsal, a manual fallback, rollback), and the live transition.

**Build with expert help.** /ship ships everywhere outside the named scope and stops at the gate until its condition is met.

**Professional-led.** /ship performs no production launch; it produces or refreshes the masterplan, the plan, acceptance criteria, evidence gathered so far, and the brief a professional needs.

After the first launch, shipping gets lighter: it re-checks what changed since the last ship and moves that over, rechecking the build path first if reliance or consequence has grown.

## 10. Autonomy: /build auto and goal modes

Autonomy is earned. Once a project has three normal pieces built cleanly, no open review finding, and a plan made of pieces a machine can prove done, "/build auto" can build several of them in a row without you between them. You approve the plan once, then it runs; the trade is that you check a batch at the end instead of each piece as it lands.

The run only picks up pieces whose done line names a check a machine can judge. Pieces that need your eyes stay in the plan for you. Every piece still gets its own evidence and its own saved snapshot. A piece that fails three attempts gets parked with a note on what it revealed, and the run moves on rather than grinding on it; anything touching a flagged area or an expert scope stops the run entirely.

You come back to a report: what got parked and why, what was built and passed, what waits for your eyes, and a checklist of things to try, riskiest first. Where the build path requires a pull request, that's how the batch arrives; work the checklist, then merge. If the run disappointed you, improve the documents rather than the code. Sharpen the done lines, add the missing rule to the masterplan, and run it again.

Some harnesses provide goal or long-run modes, such as Claude Code's `/goal`: "keep going until this condition holds", judged by a separate model. Same run, same rules: take the condition from a done line, the flags and expert scopes still stop it, and the result still lands through the save route the build path requires.

## 11. Team use

GitHub collaborators identify who has access; invite someone under the repository's Settings, then Collaborators, and they accept the email, open the repo in their own tool, and make their own .env from .env.example. plan.md gains an Owner column once more than one person is building; claim your piece by name there before starting, so two people don't build the same thing twice. Open pull requests show work in progress, and /what-now identifies conflicts and unfinished work rather than leaving you to read Git state yourself.

## 12. Sync and maintenance

Normal /build and /fix completion updates the records directly; you don't need /sync after a piece that finished cleanly. /sync exists for interrupted work, work done outside the workflow, long sessions whose context went foggy, and handovers. A report-only reminder can optionally run at session end, where the tool supports it, but nothing writes to the records without a skill deciding to.

/maintain is the service visit: monthly and light for AI Build Kit updates,
project dependency updates, and anything the error alerts caught. When a newer
kit is available, the agent shows the version and what changed, then waits for
approval. The shared skills installer refreshes only the eleven AI Build Kit
skills recorded for this project. It leaves the tool, its records, its standing
instructions, environment files, and its own checks alone. Projects from an
older release register their existing skills with the installer once, then use
the same update route. A clean checkpoint comes first, so an interrupted update
can be recovered without asking the person to inspect installation details.

The quarterly visit is fuller, with a hot-spot tidy-up and an ownership check
that can move the build path in either direction. /maintain also owns the ending,
when a tool's time is over: export the data, tell the team, revoke access, and
switch off the services.

## What stays yours

Two things no skill ever takes: saying clearly what you want going in (a real example, the output you expect, what done means), and trying the result before it's saved. The system automates the routine and never the judgement.
