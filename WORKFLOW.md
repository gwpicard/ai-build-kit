# WORKFLOW.md: how this project runs

This is the reference card. When you are not sure what to type, read this page,
or type /what-now and let it tell you. Type a command as `/` and its name
(`/start`, `/build`, and so on), or ask for it by name. The Claude Code plugin
adds the prefix `ai-build-kit:`, so `/start` becomes `/ai-build-kit:start`.

## 1. Commands

Command names say when to use them.

| When | Type |
|---|---|
| I'm starting something | /start |
| Keep going, or: I want it to... | /build |
| It's broken | /fix |
| I think it's ready | /ship |
| I'm done for today | /sync |
| It's been a while | /maintain |
| I'm lost | /what-now |

Only two of them change the tool. /build makes it do something new or different. /fix brings it back to doing what it already should. The other five are housekeeping around those two.

You run /start once. After that, start wherever you actually are. You can open a session with /fix as readily as with /build, and neither needs the other to have run first. If you pick the wrong one it costs you nothing, because each checks what you typed against the masterplan and sends it down the right route.

You never choose the method either. The agent decides whether the request needs an interview, a prototype, research, a test, a review, or outside help.

## 2. The three records

The records are the project's memory. The agent forgets everything between sessions; these don't, and every piece of work starts by reading them.

Two of them are files you can open. The third, what's left to build, lives in your project's issues on GitHub, because that is what lets more than one person work without clashing over the same file. You never have to open it: `/what-now` tells you where things stand in a sentence, and a plain list is printed to `plan.local.md` on your own machine so you can always see it, even when GitHub cannot be reached. That printout is a photocopy. Nobody edits it, and changing a piece means telling the agent, not editing the file.

Some projects keep a simple `plan.md` file instead, and nothing above applies to them. A project you are only trying out, with no GitHub repository, is one. So is a project that has a repository but was set up on a computer not signed in to GitHub's command line tool, the small program the kit uses to create the issues, because there was no way to make them at the time. Either way the kit says so when it happens and will not push you to create an account. If you later want the pieces moved into issues, ask, and the agent will do it with you.

| Record | Purpose |
|---|---|
| masterplan.md | What the tool is, in the present tense. Its first part, the build-path section, records how careful this project needs to be. |
| the project's issues | What's left to build: one issue per piece, each with what done looks like, its evidence, and what it needs. `/what-now` reads them for you. |
| CHANGELOG.md | What happened, dated, in plain language, when work actually landed. |

`AGENTS.md` sits alongside the three records as the instruction file the agent reads to know how this repository works: the rules, the stack, the capability profile, the conventions.

The dividing rule: the masterplan describes the present, the plan holds the future, and the moment a sentence is about when, why, or how something was built, it belongs in the changelog.

You can work with the issues yourself, and nothing you do there will be undone. Open one and write it however you like, in as little as half a sentence. The agent settles what done means with you before it builds anything, and if you would rather not be asked at that moment, say "not now" and it takes the next ready thing instead.

Assign yourself to claim a piece, or let the agent put your name on it when it starts; either way nobody else builds the same thing. Close an issue you have decided against and it stays closed. Labels of your own are left alone, and milestones and boards are ignored entirely, so you can use them however suits you.

Each piece is labelled with what it is about. The labels are not decoration: they decide how carefully the agent has to prove the work.

| Label | The piece is about |
|---|---|
| `visual` | the interface |
| `how it works` | the rules and logic |
| `data` | information the tool stores |
| `accounts and permissions` | who can get in |
| `finance` | charging, refunds, pricing |
| `external service` | somebody else's system |
| `background automation` | anything that runs on its own |

A piece often carries two, because a checkout is finance and an outside service at once. More labels means more proof and a more careful save.

Four labels say where a piece stands instead: `building` when somebody is on it, `blocked` when something outside the project holds it up, `parked` on something you decided against, and `broken` for a repair, which sends it to `/fix`.

Three more say it is waiting on a question rather than on a person. `needs-clarification` means talking it through will settle it. `needs-prototype` means somebody has to build a throwaway first to see what it should look like. `needs-research` means somebody has to go and find a fact the project cannot see. Anything you jot down starts at `needs-clarification`. When /build reaches a piece waiting on a question, it settles that question first, a few questions, a quick throwaway, or a lookup, and then builds the piece, rather than building past the open question.

To see where things stand, type `/what-now`. The printed list in `plan.local.md` is there too, though it is only a photocopy of the issues.

## 3. The build path

Every project has exactly one build path at a time, set by the fit check and rechecked as the project changes character.

**Explore privately.** Nobody depends on it yet, data is disposable, and nothing it does is hard to undo. Manual checks are fine for visual and exploratory work, and a confirmed checkpoint commit is enough to save it.

**Build and run it.** The team's own tool, with a manual fallback and consequences that are limited and recoverable. Promised behaviour gets evidence, shared or behavioural changes go through a pull request, and named risky areas get an independent review before they go live.

**Build with expert help.** One or more named areas, such as sign-in, payments, or personal data, need a professional's involvement even though the team can still own the rest. The kit keeps building everywhere else, and at the named boundary it tells you what could go wrong and who it lands on.

**Professional-led.** The core risk, regulation, irreplaceable live data, or a scale of consequence the team cannot safely carry, can't be designed away. The kit's job becomes producing the specification, the prototype, and the brief a professional needs to build the production system.

None of these paths is the kit refusing to build. The top two are where it says plainly what a professional would normally do, and you decide. That is the risk notice, in section 8.

## 4. Day one

Type /start. It checks what the current tool can actually do, then tries to talk you out of building if something simpler would do the job. It interviews you, one question at a time with its best guess attached, and runs the fit check to set the project's build path. From those answers it writes the masterplan, has the best available independent method read that page looking for holes, cuts the work into pieces on the plan, and stands the project up with one passing check. Interrupt it anywhere; typing /start again resumes where it stopped.

While it works, the conversation stays on project decisions and results you can
use. Routine searches, setup commands, retries, and waiting stay behind the
scenes unless they create a blocker or need a decision from you.

Already built something, in an app builder, a chat assistant, or an earlier attempt? /start adopts it instead of replacing it: it reads what exists, interviews you about what the tool is supposed to do, writes the masterplan for what's actually there, and pins down current behaviour with tests before anything changes.

If the tool needs confidential files to work from, say so during the interview. /start makes a folder for them that stays on each machine and never reaches GitHub, and writes the handling rules into AGENTS.md.

## 5. Day to day

Typed alone, /build takes the next piece from the plan. It agrees with you in one sentence what the piece should do, chooses the evidence that piece needs, builds until that evidence holds, then stops so you can try it. Nothing is saved until you confirm it behaves.

If the change touched an area the build path flags, the best independent method available reviews it first. It reports in plain language, sorted into what's worth stopping for and what's worth knowing.

Typed with words after it, /build is how you bring anything new: "/build add a filter to the board". You never sort your own request; the agent works out what kind of work it is. Small and clear gets built right away. Vague gets a short interview. A question conversation can't settle gets a disposable prototype or a source check. Anything touching data, access, or money gets written into the masterplan first.

If the request would change what kind of project this is, by bringing in outside users or real money or a promise to someone, the agent re-runs the fit check with you before building. A different build path needs different care before people rely on it.

/fix is for when something that should work doesn't: "/fix the board duplicates cards when I drag them". Paste the whole error if there is one. It builds the tightest repeatable check it can find for the exact symptom, works out the cause before touching code, resets failed attempts rather than stacking them, and finishes with evidence that keeps the bug from coming back.

If the same piece fails three rounds in a row, it stops patching and routes by what the failures revealed. That may mean another interview, a rebuild from the masterplan, a stop for missing access, or scoped expert help.

## 6. Evidence

Every promised behaviour gets evidence, in one of four forms:

- an automated behaviour check, for business rules, calculations, permissions, data changes, integrations, and bugs, where a machine can judge the result reliably;
- a guided manual check, for copy, layout, colour, and exploratory or subjective work;
- a source-backed fact, when correctness depends on something an external service or provider actually does;
- an operational rehearsal, for backups, restores, migrations, rollback, or anything else that only proves itself by being run.

The agent chooses the form the change actually needs; the report says what was proved and what remains a judgement call.

## 7. Saving work

Every piece saves through one of three routes. The checkpoint route commits, and that commit may stay local: private, disposable exploration needs no remote or GitHub authentication to complete. The pull-request route pushes and opens a pull request, for shared, live, behavioural, data, access, integration, service, or operational changes. The flagged route does the same, and also attaches the condition the touched area requires; a piece that stops there, plan marked blocked and the condition on record, counts as finished until that condition is met or you accept the risk instead.

Next to the merge button sits that check. It re-runs the project's real commands on a clean machine, so the pull request's claims get verified rather than trusted. Green means the checks that exist really passed, which is a smaller promise than nothing being wrong: it covers the behaviour somebody thought to check and nothing else. Red means don't merge; say it to /fix, and the agent reads what failed itself. You never read the machine's logs, and you never merge over a red check.

A human decides whether to merge, always; after a merge, everyone pulls main. Flagged areas also get the review the build path names before the pull request is offered as ready.

## 8. Outside help, and the risk notice

When the build path names outside help, it's one of four levels: a short advice conversation to validate a choice, a scoped review of one named area, a supervised change for one risky event, or professional ownership of the build. The build path's section says which level, for what scope, and what the review or the professional must confirm. The kit keeps building unflagged areas while it waits.

Before that work goes ahead, you get a risk notice. It says who is exposed, what happens to them if it goes wrong, what a professional would normally do about it, and that the kit flags what it can recognise and will miss things. It names people rather than saying something is risky, because the person building a tool is the one creating the exposure and the exposure often lands on somebody else.

Then it is your call. You can accept the risk and have the thing built, or take it out of scope so the risk goes away. Nothing is refused either way.

An acceptance is written into the build-path section as a dated line saying what was skipped and who accepted it. Making a project less careful is a decision you record, not something the agent does on its own, and the accumulated lines are the honest answer to "what did we knowingly skip?" when somebody asks in six months.

What the agent may not do is take the notice back. Pushing back on the cost, the wait, or the fuss changes what you decide and changes nothing about who is exposed, so the notice stays put however many times it comes up. A named check cannot be quietly turned into something the agent does itself either: where the build path asks for another person's eyes, the agent reading its own work does not count, and neither does a passing test.

## 9. Shipping

/ship reads the build path first, and each path gets only the process it needs, not a shared ceremony trimmed after the fact.

**Explore privately.** /ship runs no production evidence or launch procedure; it only confirms the prototype stays disposable and private, and records what would have to change to graduate.

**Build and run it.** /ship runs the full evidence run, independent review, operational readiness (alerts, backup, a restored-backup rehearsal, a manual fallback, rollback), and the live transition.

**Build with expert help.** /ship ships everywhere outside the named scope and stops at the flagged boundary until its condition is met or you accept the risk on the record.

**Professional-led.** /ship performs no production launch; it produces or refreshes the masterplan, the plan, acceptance criteria, evidence gathered so far, and the brief a professional needs.

After the first launch, shipping gets lighter: it re-checks what changed since the last ship and moves that over, rechecking the build path first if reliance or consequence has grown.

## 10. Autonomy: /build auto and goal modes

Autonomy is earned. Once a project has three normal pieces built cleanly, no open review finding, and a plan made of pieces a machine can prove done, "/build auto" can build several of them in a row without you between them. You approve the plan once, then it runs; the trade is that you check a batch at the end instead of each piece as it lands.

The run only picks up pieces whose done line names a check a machine can judge. Pieces that need your eyes stay in the plan for you. Every piece still gets its own evidence and its own saved snapshot. A piece that fails three attempts gets parked with a note on what it revealed, and the run moves on rather than grinding on it; anything touching a flagged area or an expert scope stops the run entirely.

You come back to a report of what was built, what got parked and why, and a checklist of things to try, riskiest first. Where the build path requires a pull request, that's how the batch arrives; work the checklist, then merge. If the run disappointed you, improve the documents rather than the code. Sharpen the done lines, add the missing rule to the masterplan, and run it again.

Some harnesses provide goal or long-run modes, such as Claude Code's `/goal`: "keep going until this condition holds". Same run, same rules: take the condition from a done line, the flags and expert scopes still stop it, and the result still lands through the save route the build path requires.

## 11. Team use

GitHub collaborators identify who has access. Invite someone under the repository's Settings, then Collaborators. They accept the email, open the repo in their own tool, and make their own .env from .env.example.

Nothing else changes when a second person arrives, because the agent already puts your name on a piece before starting it, and that is what stops two people building the same thing. Each of you gets your own printed list, so there is no shared file to clash over. Open pull requests show work in progress, and /what-now identifies conflicts and unfinished work rather than leaving you to read Git state yourself.

## 12. Sync and maintenance

Normal /build and /fix completion updates the records directly; you don't need /sync after a piece that finished cleanly. /sync exists for interrupted work, work done outside the workflow, long sessions whose context went foggy, and handovers. A report-only reminder can optionally run at session end, where the tool supports it, but nothing writes to the records without a skill deciding to.

/maintain is the service visit: monthly and light for AI Build Kit updates,
project dependency updates, and anything the error alerts caught. When a newer
kit is available, the agent shows the version and what changed, then waits for
approval. An update refreshes only the eleven AI Build Kit skills and leaves
your tool, its records, and its own checks alone. A clean checkpoint comes
first, so an interrupted update can be recovered.

/maintain writes the date of each visit into the project. When more than a month
has gone by, opening a session says so and names /maintain. A tool that cannot
run anything when a session opens says it when you type /what-now instead.
Nothing is blocked and nothing changes without a command.

The quarterly visit is fuller, with a hot-spot tidy-up and an ownership check
that can move the build path in either direction. /maintain also owns the ending,
when a tool's time is over: export the data, tell the team, revoke access, and
switch off the services.

## What stays yours

Two things no skill ever takes: saying clearly what you want going in (a real example, the output you expect, what done means), and trying the result before it's saved. The system automates the routine and never the judgement.
