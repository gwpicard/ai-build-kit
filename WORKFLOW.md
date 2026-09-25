# WORKFLOW.md: how this project runs

This is the reference card. When you are not sure what to type, read this page,
or type /what-now and let it tell you. Type a command as `/` and its name
(`/setup-ai-build-kit`, `/shape`, `/implement`, and so on), or ask for it by name. You can also
just say what you want done, in your own words, and the agent picks the command
and says which one. The Claude Code plugin
adds the prefix `ai-build-kit:`, so `/setup-ai-build-kit` becomes `/ai-build-kit:setup-ai-build-kit`.

## 1. Commands

Command names say when to use them.

| When | Type |
|---|---|
| I'm starting something | /setup-ai-build-kit |
| I want it to... (a new idea) | /shape |
| Build the next ready piece | /implement |
| I'm taking on several things | /queue |
| It's broken | /fix |
| I think it's ready | /ship |
| I'm done for today | /sync |
| It's been a while | /maintain |
| I'm lost | /what-now |

Two of them change the tool. /implement makes it do something new or different, and /fix brings it back to doing what it already should. /shape decides what to change next and turns it into a ready piece, without touching the tool yet. The other six are housekeeping around those.

You run /setup-ai-build-kit once. After that, start wherever you actually are. You can open a session with /fix as readily as with /implement, and neither needs the other to have run first. If you pick the wrong one it costs you nothing, because each checks what you typed against the masterplan and sends it down the right route.

You never choose the method either. The agent decides whether the request needs an interview, a prototype, research, a test, a review, or a person to look at one area.

## 2. The three records

The records are the project's memory. The agent forgets everything between sessions; these don't, and every piece of work starts by reading them.

Two of them are files you can open. The third, what's left to build, lives in your project's issues on GitHub, because that is what lets more than one person work without clashing over the same file. You never have to open it: `/what-now` tells you where things stand, recaps what the recent work was about, names anything broken or left unfinished, and tells you when a piece is waiting on something only you can do, such as opening an account or handing over a key, and a plain list is printed to `plan.local.md` on your own machine so you can always see it, even when GitHub cannot be reached. That printout is a photocopy. Nobody edits it, and changing a piece means telling the agent, not editing the file.

| Record | Purpose |
|---|---|
| masterplan.md | What the tool is, in the present tense. Its first part, the build-path section, records how careful this project needs to be. |
| the project's issues | What's left to build: one issue per piece, each with what done looks like, its evidence, and what it needs. `/what-now` reads them for you. |
| CHANGELOG.md | What happened, dated, in plain language, when work actually landed. |

`AGENTS.md` sits alongside the three records as the instruction file the agent reads to know how this repository works: the rules, the stack, the capability profile, the conventions.

The dividing rule: the masterplan describes the present, the plan holds the future, and the moment a sentence is about when, why, or how something was built, it belongs in the changelog.

You can work with the issues yourself, and nothing you do there will be undone. Open one and write it however you like, in as little as half a sentence. /shape settles what done means with you and marks the piece ready; /implement builds only ready pieces and never guesses past an open question. If a piece is not ready when you reach for /implement, it points you to /shape and takes the next ready piece instead.

A piece is written in two layers. The part you read stays in plain words, and it stays complete about anything that affects your product, so it never looks simpler than the work really is. The build detail the agent needs sits in a collapsed "under the hood" section you never have to open. Anything that affects the whole product is written into the masterplan instead, and anything technical that affects the whole project goes into AGENTS.md, so no fact is copied into two places.

A decision can say what it rests on, in one short line beside it. When /shape
uses that decision, or /sync checks the masterplan, the agent reads its support
again. If it has gone, you hear which decision has lost its ground and answer
in plain words. You never have to read a test or find a saved change yourself.

Assign yourself to claim a piece, or let the agent put your name on it when it starts; either way nobody else builds the same thing. Close an issue you have decided against and it stays closed. Labels of your own are left alone, and milestones and boards are ignored entirely, so you can use them however suits you.

A piece too big to build in one go is split into parts. You will see it marked "made of parts" with a count of how many are done. The agent builds the parts one at a time, and the whole piece closes itself when the last part is finished, so there is nothing for you to tick off.

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

Three more say it is waiting on a question rather than on a person: `needs-clarification` (talking it through settles it), `needs-prototype` (a throwaway is needed first to see what it should look like), and `needs-research` (a fact from outside the project is needed). Anything you jot down starts at `needs-clarification`; `/shape` settles it and marks the piece `ready`, and `/implement` builds only ready pieces. What settled it is written onto the piece before the label changes, so a month later you can see what was decided rather than only that something was.

## 3. The build path

Every project has exactly one build path at a time, set by the fit check and rechecked as the project changes character.

**Explore privately.** Nobody depends on it yet, data is disposable, and nothing it does is hard to undo. Manual checks are fine for visual and exploratory work, and a confirmed checkpoint commit is enough to save it.

**Build and run it.** The team's own tool, with a manual fallback and consequences that are limited and recoverable. Promised behaviour gets evidence, shared or behavioural changes go through a pull request, and named risky areas get an independent review before they go live.

**Build with care.** Some of the work touches a sensitive area: personal data, money, sign-in by outsiders, automatic action on people or other systems, irreplaceable live data, or a regulated decision. The masterplan names each area in your tool's own words, with the one caution that goes with it. The kit builds everything else the ordinary way, and in a named area the caution happens before that part goes live, or you accept skipping it on the record.

Each sensitive area also says where it lives in the tool. A check keeps that
list true: a moved place or a new part with no area stops the check and asks
you where it belongs. When a change reaches one of those places, the review
starts from what the change touched rather than from what the piece expected
to touch. The map exists only on Build with care.

An area can also name one boundary, such as "the ledger is only reached through
the charge step". At founding, and at the quarterly visit for a newly named
area, the agent offers once to have the check hold it. Say yes and put the rule
in your own words, and a change that crosses it turns the tick red with your
sentence beside it. Nothing is added or taken away without your yes, and a
language with no tool for it is told plainly that it has none.

None of these paths is the kit refusing to build. Build with care is where it says plainly what would normally prevent the harm, and you decide. That is the risk notice, in section 8.

## 4. Day one

Type /setup-ai-build-kit. It checks what the current tool can actually do, then tries to talk you out of building if something simpler would do the job. It makes that case once. If you still want the tool, that is your call, and it records the cheaper option and gets on with founding rather than asking again. It interviews you, one question at a time with its best guess attached, and runs the fit check to set the project's build path. From those answers it writes the masterplan, cuts the work into pieces on the plan, and stands the project up with one passing check, saved on your own computer with nothing uploaded. Where the work carries real exposure, it also has an independent method read the masterplan looking for holes before any of that flagged work goes ahead; for an ordinary internal tool it says it skipped that and why, rather than making you wait for it. Before it stands anything up it checks that every promise on the masterplan has a piece that builds it, and names the ones that do not, so you can add them while the plan is minutes old. Interrupt it anywhere; typing /setup-ai-build-kit again resumes where it stopped.

While it works, the conversation stays on project decisions and results you can
use. Routine searches, setup commands, retries, and waiting stay behind the
scenes unless they create a blocker or need a decision from you.

Before it stands the project up, it names the kind of tool you are building and
shows the recipes that fit, with one recommended. A recipe is one build stack
paired with one place to run it, which the kit knows well enough to check at
launch. For each one it says what the kit can check and what running it
involves, such as the accounts you will hold. You can bring your own stack
instead: it says once what it then cannot check, and records your choice. If
you do not answer, it takes the recommended recipe and carries on. Where no
recipe fits, such as a command-line tool, it says so in one line and picks a
conventional stack. The choice is written in AGENTS.md, in the stack section.

The coverage read includes who can see and do what, the data the tool holds,
and its outside connections. It names any gaps together and offers once to add
the missing work. You decide whether it belongs in the plan.

Already built something, in an app builder, a chat assistant, or an earlier attempt? /setup-ai-build-kit adopts it instead of replacing it: it reads what exists, interviews you about what the tool is supposed to do, writes the masterplan for what's actually there, and pins down current behaviour with tests before anything changes.

The masterplan carries a picture of everything outside the tool that it reaches: where it keeps your data, and each outside service. You confirm each one at founding, and the picture is redrawn whenever a piece adds or drops a connection, so a tool never quietly reaches something you did not agree to.

Already sketched, mocked, or written down what you want? Show it during the interview. /setup-ai-build-kit reads it, says back what it sees so you can correct it, records what that settles, and builds toward it. What the mock doesn't cover gets asked rather than guessed, and a mock never carries work past the fit check.

If the tool needs confidential files to work from, say so during the interview. /setup-ai-build-kit makes a folder for them that stays on each machine and never reaches GitHub, and writes the handling rules into AGENTS.md.

## 5. Day to day

Typed alone, /implement takes the next ready piece from the plan. It agrees with you in one sentence what the piece should do, chooses the evidence that piece needs, builds until that evidence holds, then stops so you can try it. Nothing is saved until you confirm it behaves. A piece that is not ready yet, still waiting on a question, goes to /shape first; /implement builds, it does not shape.

Before saving, the kit checks what else the change touches and runs the tests
that already cover those parts first. If it reaches another part of the tool,
you get one line naming that part and saying whether its tests passed. The
check is worked out afresh from the current code, so there is no map to keep up
to date. The full project check still runs before a pull request is ready.

It also compares the tool's structure before and after the build. You hear one
line only when the change made later work harder, such as two parts now looping
through each other or a named boundary being crossed. There is no score to
interpret. You can ask for the structure to be fixed before saving, or leave it
and have that choice recorded on the piece.

Before you try a piece, the kit takes out anything the change added that
nothing needs, such as a helper only one place uses or code nothing calls. It
only removes things or folds them into the one place that uses them, never
reshapes the code, and runs the tests after every step. Anything that would
need reshaping, such as a function grown hard to follow, is listed on the piece
for you to decide instead.

You hear one line, such as "I took out two things this change did not need.
They are listed on the piece.", or nothing when there was nothing to take out.
The removals are saved as their own step, so asking for one back undoes only
that step. /fix does the same for a repair.

If a build uncovers another piece of work, that new piece says "Found while
building the invoice list", using the title of the piece that surfaced it.
Both pieces link to each other, so you can follow where the work came from.
Parts of the same outcome stay together as parts; a different outcome keeps
its own piece.

When a piece is about the interface, or its files change a screen, the agent
applies the screen rules before your guided check. Your project's `DESIGN.md`,
design system, or component library comes first. The house rules cover forms,
tables, states, actions, words, keyboard use, contrast, and the familiar visual
defaults that coding agents reach for. The report says which rules were applied
and what still needs your eyes. It never claims the screen is accessible,
compliant, or good, and a piece with no screen sees none of this. If the result
is wrong, describe what happened and type /fix.

If the change touched an area the build path flags, the best independent method available reviews it first. It reports in plain language, sorted into what's worth stopping for and what's worth knowing.

/queue shows everything ready to build at once, and what is waiting on what. Type it when you are taking on several pieces rather than one, which is the only time you need it. It comes back with two lists. The first is everything ready, and those are safe to take on together, because a piece waiting on another piece is never in it. The second is what is waiting, each line saying which piece has to land first: "deposits cannot start until card payments is built". It changes nothing and builds nothing, so /implement is still what does the work. If the list looks out of date, type /queue again, since it is printed fresh from your project's issues every time.

/shape is how you bring anything new: "/shape add a filter to the board". You never sort your own request; the agent works out what kind of work it is. Clear and piece-sized becomes a ready piece, and /shape offers to build it now or leave it for /implement later. Vague gets a short interview.

Each piece says what it changes in the masterplan, and the masterplan says when
it was last checked. You see a line such as "When this lands, the masterplan
gains a weekly summary email", or "nothing" when it already covers the result.
A new rule you could check, such as a list now sorted by name, counts as a
change even when the masterplan already describes that list. /implement applies that change as it saves the work, so the page keeps up
without a separate /sync visit.

A question a conversation can't settle gets a disposable prototype, a source check, or a search for something that already does the job. Two of those need you there; the research does not, so you can tell /shape you're leaving and it settles what it can alone, then tells you which pieces are waiting on you. Type /shape with a piece's number to settle that one rather than the next in line.

Typing /shape is the choice to shape, so it starts on a question straight away. Before an interview or a prototype it says in one line that this takes a sitting, and you can say "later" at any point: the piece is filed with its question and your words, to come back to. If all you want is to note an idea, say so, for example "note this for later" or "just file this idea", and it is filed with nothing started. Nothing filed can be built until the question is answered, and /what-now tells you when enough pieces are waiting that the session is better spent planning than building.

Show a mock of what you want and it settles the question instead, with no throwaway built. A prototype comes back as one of two things: a single file you open and click through yourself, or three genuinely different versions to move between and pick from. If setup recorded a design tool, the agent may use its canvas before a real page exists or when you want to draw a redesign. The real page still wins wherever one exists, and without a recorded tool the ordinary coded throwaway stays the default.

Anything touching data, access, or money gets written into the masterplan first. If another piece already open would be built in the same place, /shape names it before the work starts, so you can decide whether to carry on, wait, or fold the two together.

If the request would change what kind of project this is, by bringing in outside users or real money or a promise to someone, the agent re-runs the fit check with you before building. A different build path needs different care before people rely on it.

/fix is for when something that should work doesn't: "/fix the board duplicates cards when I drag them". Paste the whole error if there is one. It builds the tightest repeatable check it can find for the exact symptom and works out the cause before touching code, driving the app in a browser or adding temporary logging when it needs to see what is actually going wrong. It resets failed attempts rather than stacking them, and finishes with evidence that keeps the bug from coming back.

Before repairing, it reads the changelog and finished pieces for the same part
of the tool. That keeps a failed repair from being tried as if it were new, and
lets an earlier cause lead the search. Existing covering tests run before a new
one is written. When there is a known time the behaviour worked, /fix searches
the saved changes for where it broke, then removes every temporary log before
the repair is saved.

After launch, /fix also reads the tool's own record of what each request did
alongside your report, so it can trace the failed step. You do not need to read
that record yourself.

If the same piece fails three rounds in a row, it stops patching and routes by what the failures revealed. That may mean another interview, a rebuild from the masterplan, a stop for missing access, or naming the area as sensitive so somebody who does that work for a living looks at it.

## 6. Evidence

Every promised behaviour gets evidence, in one of four forms:

- an automated behaviour check, for business rules, calculations, permissions, data changes, integrations, and bugs, where a machine can judge the result reliably;
- a guided manual check, for copy, layout, colour, and exploratory or subjective work;
- a source-backed fact, when correctness depends on something an external service or provider actually does;
- an operational rehearsal, for backups, restores, migrations, rollback, or anything else that only proves itself by being run.

The agent chooses the form the change actually needs; the report says what was proved and what remains a judgement call.

On Build with care, /implement can offer to break the changed code on purpose
to check whether its tests notice. /fix offers the same check for the test
that keeps a repaired fault from returning. It runs locally when the language
has a suitable tool, covers only the changed code, and is optional.

You get one line: "The tests were checked by breaking the code on purpose 40
times. They caught 37. The three they missed are listed on the piece." Misses
in a named sensitive area are worth stopping for; the rest are worth knowing.
You decide whether they matter. The kit records that choice, and only adds a
test to protect promised behaviour, never just to raise the count.

## 7. Saving work

Every piece saves through one of three routes. The checkpoint route commits, and that commit may stay local, so private, disposable exploration can be saved without pushing. The pull-request route pushes and opens a pull request, for shared, live, behavioural, data, access, integration, service, or operational changes. The flagged route does the same, and also attaches the condition the touched area requires; a piece that stops there, plan marked blocked and the condition on record, counts as finished until that condition is met or you carry on after the risk notice and your acceptance is recorded. When you are there and carry on at the notice, the piece is built and saved like any other.

Next to the merge button sits that check. It re-runs the project's real commands on a clean machine, so the pull request's claims get verified rather than trusted. Those commands include the mechanical checks your project's language offers, a type check and a linter wherever it has them, which catch a whole class of mistakes before anyone tries the tool. They use each tool's own default rules, so a red tick points at a real mistake rather than a matter of taste. The agent runs the same checks before it hands any work over. Green means the checks that exist really passed, which is a smaller promise than nothing being wrong: it covers the behaviour somebody thought to check and nothing else. Red means don't merge; say it to /fix, and the agent reads what failed itself. You never read the machine's logs, and you never merge over a red check.

A human decides whether to merge, always; after a merge, everyone pulls main. Flagged areas also get the review the build path names before the pull request is offered as ready. A direct push to `main` is blocked, so every change reaches it through a pull request, and each piece starts from an up-to-date `main`.

## 8. Sensitive areas, and the risk notice

Six areas count as sensitive, and the list is fixed: personal or sensitive data, money, sign-in and permissions, automatic action on people or other systems, irreplaceable live data, and regulated decisions. Each carries a default caution, which is what would normally prevent the harm: a person who did not build the tool reviews who can see what; a managed payment or sign-in service so the tool never holds card details or passwords; a person approves each automatic action until a live run has shown it right; a backup restored once and the change rehearsed on a copy; somebody qualified signs off a regulated rule. The build path's section names each area in your tool's own words, its caution, and whether the caution is done. Where the caution is a backup, a copy or a managed service, the kit does it. Where it is a person, the kit tells you so once, in the risk notice below, and the choice of whether to wait for them is yours. It keeps building everywhere else either way.

Before work in a named area goes ahead, you get a risk notice. It comes once, in full, in one reply. It says who is exposed, what happens to them if it goes wrong, what would normally prevent that, what you can do, and that the kit flags what it can recognise and will miss things. It names people rather than saying something is risky, because the exposure a tool creates usually lands on somebody else.

Then it is your call. You can have the caution done first, take the thing out of scope so the risk goes away, or carry on. Carrying on is accepting the risk: say go ahead in any words and the work goes ahead. You are not asked a second time, and nothing the notice named stays switched off waiting for the check you chose to skip. Saying nothing is not carrying on, and neither is asking a question. Nothing is refused and nothing stops you.

When you carry on, an acceptance is written into the build-path section before the work starts, as a dated line saying what was skipped, in your own words, with your name. It says the risk was accepted, never that the caution was done. Making a project less careful is a decision you record, not something the agent does on its own, and the accumulated lines are the honest answer to "what did we knowingly skip?" when somebody asks in six months.

What the agent may not do is take the notice back. Pushing back on the cost, the wait, or the fuss changes what you decide and changes nothing about who is exposed, so the notice stays put however many times it comes up. A named check cannot be quietly turned into something the agent does itself either: where the build path asks for another person's eyes, the agent reading its own work does not count, and neither does a passing test.

## 9. Shipping

/ship reads the build path first, and each path gets only the process it needs, not a shared ceremony trimmed after the fact.

**Explore privately.** /ship runs no production evidence or launch procedure; it only confirms the prototype stays disposable and private, and records what would have to change to graduate.

**Build and run it.** /ship runs the full evidence run, independent review, operational readiness, and the live transition. Off a recipe, readiness is a general list: a backup, a restored-backup rehearsal, a manual fallback, rollback, and a single caution if nobody receives alerts. Anything missing from it is a warning you hear once and find in the changelog, and the launch goes ahead.

**Build with care.** /ship ships everywhere outside a named sensitive area, does the caution it can do itself (a backup restored once, a rehearsal on a copy), and at a caution that is a person who has not looked, gives you the risk notice once. If you carry on, your acceptance is written down and that area goes live too. Where somebody outside the team is going to look, ask for the handover and /ship prepares it.

On a recipe, the recipe's own checks take the place of that list. /ship reads
the recipe your project's AGENTS.md names and works through its eight sections
in order, and each one gives you a plain line: preview up, live address updated,
rollback possible, backup present, restore works, no secret in the repo, logs
readable, health answers. The rollback line says a rollback is possible and
was not tried, because the kit does not roll back the live tool just to check.

The kit runs the checks it can reach. Where a check runs on a server the kit
cannot reach, you paste the result back and the kit reads it. Where only a
person can judge, you look and the kit writes down what you said. A check that
fails or cannot run is a warning, said once and written in the changelog, and
the launch goes ahead. The one thing a first launch waits for is its address,
because a tool with no recorded address is not live.

On both live paths, /ship checks that the tool keeps a plain record of what each
request did, without personal data, secrets or confidential file contents. If
it does not, you hear once: "The tool keeps no record of what each request did,
so a fault reported after launch cannot be traced. I have noted that in the
changelog, and adding the record is one piece whenever you want it." The
launch does not wait for it. A record that holds personal data, secrets or
confidential contents still gets repaired.

It also tells you once: "Once real people use this, the only record of what
went wrong will be the record the tool writes. If you want somebody to be told
when it breaks, that is a service somebody runs and pays for, and the kit does
not set one up." If the fit check already names who receives alerts, it does
not repeat this caution. Explore privately gets neither check nor caution.

When the tool will run on a server somebody else runs, the first launch needs
an address, and the kit never contacts that server. So /ship writes a hosting
request into the masterplan's "How it stays running" section and prints it for
you. It names the repository and branch, the lane (private network or
internet), the port, the names of the settings the tool needs, the folders that
must survive a restart, and the path that shows the tool is healthy. It also
says how the tool builds and which address it listens on, read from the code,
because the server builds and checks it from those two facts. It holds
names only, never a password or key. You take it to whoever runs the server,
and paste back what they send. On a later launch /ship reads the request back
rather than asking again.

After the first launch, shipping gets lighter: it re-checks what changed since the last ship and moves that over, rechecking the build path first if reliance or consequence has grown.

## 10. Autonomy: /implement auto and goal modes

Autonomy is earned. Once a project has three normal pieces built cleanly, no open review finding, and a plan made of ready pieces a machine can prove done, "/implement auto" can build several of them in a row without you between them. You approve the plan once, then it runs; the trade is that you check a batch at the end instead of each piece as it lands.

The run only picks up pieces whose done line names a check a machine can judge. Pieces that need your eyes stay in the plan for you. Every piece still gets its own evidence and its own saved snapshot. A piece that fails three attempts gets parked with a note on what it revealed, and the run moves on rather than grinding on it; anything touching a named sensitive area stops the run entirely.

You come back to a report of what was built, what got parked and why, and a checklist of things to try, riskiest first. Where the build path requires a pull request, that's how the batch arrives; work the checklist, then merge. If the run disappointed you, improve the documents rather than the code. Sharpen the done lines, add the missing rule to the masterplan, and run it again.

Some harnesses provide goal or long-run modes, such as Claude Code's `/goal`: "keep going until this condition holds". Same run, same rules: take the condition from a done line, a named sensitive area still stops it, and the result still lands through the save route the build path requires.

## 11. Team use

GitHub collaborators identify who has access. Invite someone under the repository's Settings, then Collaborators. They accept the email, open the repo in their own tool, and make their own .env from .env.example.

Nothing else changes when a second person arrives: naming a piece before starting it already stops two people building the same thing. Each of you gets your own printed list, so there is no shared file to clash over. Open pull requests show work in progress, and /what-now identifies conflicts and unfinished work rather than leaving you to read Git state yourself.

## 12. Sync and maintenance

Normal /implement and /fix completion updates the records directly; you don't need /sync after a piece that finished cleanly. /sync exists for interrupted work, work done outside the workflow, long sessions whose context went foggy, and handovers. A report-only reminder can optionally run at session end, where the tool supports it, but nothing writes to the records without a skill deciding to. /sync also re-reads the masterplan against your pieces, and says if a promise has lost the piece that builds it. Its corrections are saved the way a piece is saved, through the route your build path requires, so on a shared project they arrive as a pull request you decide to merge, and uncommitted work it finds on arrival is reported and left alone.

/sync also picks up changes a finished piece was meant to make to the
masterplan but never did. It checks what actually landed, applies what is still
missing and records where it checked up to. The monthly visit uses that point
to say how much work has since touched the tool's data, permissions or
connections. When there is any, it gives the count and offers /sync in one
line. That is a reason to check the page, not a claim that it is wrong.

The coverage read includes permissions, data and outside connections here too.
It also compares settled terms on every piece with the masterplan, even if a
piece was parked or reshaped. A missing or different meaning joins the same
list of gaps, with one offer to put the records right. Planning leaves the
term on its piece until it is carried across, so parking the work cannot lose
what you agreed.

When the core masterplan grows beyond roughly two pages, /sync says so once
and offers to move detail about individual pieces onto those pieces. It leaves
the page alone without your yes, and keeps the tool's present promises and
decisions on the masterplan.

/sync also reads the project's README, and any document AGENTS.md points at,
against the project itself. It names a file, link, command or setting a
document mentions that no longer exists, at the line it sits on, and offers to
correct just that name or to file it for later. A document that says less than
the project does is fine. It checks names only, so it cannot tell you whether a
described step still happens that way, and it says so. When every name still
points at something real, you hear nothing about it.

/sync names open pieces untouched for 30 days in one short list and asks once
whether each is still wanted, should be parked, or is done. It changes nothing
on that list without your yes. You can leave them as they are and carry on.

/maintain is the service visit: monthly and light for AI Build Kit updates,
project dependency updates, and anything the error alerts caught. Every visit
names two numbers, the version your project holds and the latest published AI
Build Kit, and says plainly when they differ. An update gives you that
published release and never work nobody has released yet. When a newer
kit is available, the agent shows the version and what changed, then waits for
approval. An update refreshes only the fourteen AI Build Kit skills and leaves
your tool, its records, and its own checks alone. It also adds any skill the
kit has renamed or added since, and says if the installation is short of the
fourteen. When the kit has renamed a command, the update also rewrites the
command list in your AGENTS.md, with your approval, so you are not left to
edit it by hand. A project founded from a whole copy of the kit also carries
the kit's own command files, which make each command show twice; the visit
offers to remove those and leaves anything you wrote yourself alone. A clean checkpoint comes first, so an interrupted update can
be recovered. The one update that split the
old `/build` into what are now `/shape` and `/implement` runs a one-time step that labels your
existing pieces so they can still be built, and offers to move any older
`plan.md` list into your project's issues; it says what it changed. The first
visit after the kit changed how it decides the build path offers to rewrite
the build-path section of your masterplan to the new shape, shows the old text
above the new, keeps every accepted risk word for word, and changes nothing
without your approval.

The standing instructions in AGENTS.md stay under 200 lines and hold what the
code cannot show, such as how work is saved and reviewed and which conventions
differ from the default. /maintain counts the lines every month and offers a
trim if the file reaches 200, or contains a folder layout, dependency list,
architecture overview or style rule an automatic check could enforce. You see
one line saying how long it is and what can go. Nothing is cut without your yes.

A project with no recipe may still be built much like one on the menu, with
the same framework and the same data service, even if it runs somewhere else or
lacks the recipe's Dockerfile and health route. That covers a project founded
before recipes existed and one founded on its own stack. The monthly visit then
offers the move once, and says what it gains: the launch checks /ship would run
on that recipe. It also says what the move would change. Nothing changes without
your yes. A yes becomes a piece, shaped and built like any other, and a no is
not asked again that visit. The move is never required. When no recipe is
close, you hear nothing.

/maintain also lists old branches whose work is already in your main branch,
on your computer and on GitHub, each with the command that removes it. It
keeps two kinds apart: the ones Git can confirm, and the ones only GitHub
records as merged. The second kind comes from a pull request that combined its
changes into one, which Git cannot check. It never removes a branch itself,
and it cannot tell whether somebody still plans to use one. When there are
none, you hear nothing.

/maintain writes the date of each visit into the project. When more than a month
has gone by, opening a session says so and names /maintain. A tool that cannot
run anything when a session opens says it when you type /what-now instead.
Nothing is blocked and nothing changes without a command.

The quarterly visit is fuller, with a hot-spot tidy-up and an ownership check
that can name a new sensitive area or, after a genuine redesign, take one off.
Its hot-spot read counts how widely the quarter's saved changes spread instead
of guessing from memory. Unless the project is a private exploration, it also
looks for code copied from one place to another, code nothing uses any more,
and dependencies nothing needs, using tools that read the project rather than
the agent's impression of it. Each finding names the file and line, and it
joins the same short list of at most three proposals. It finds copied code; it
does not find two pieces of code that do the same job written differently. When
it finds nothing, you hear nothing about it. It also compares the project's
structure with the last full visit and names any new place where two parts
have started to depend on each other in a circle. The earlier structure is read
again from the saved history each time rather than kept anywhere, so it cannot
go out of date. Most quarters nothing got worse, and you hear nothing. It also reads all
of the project's documents for bloat: a paragraph written out in full in two
places, and a document nothing mentions any more. Each one comes as an offer, to keep one copy
or to delete the page, and nothing changes without your yes. It finds copies,
not two documents that say the same thing in different words. /maintain also owns the ending,
when a tool's time is over: export the data, tell the team, revoke access, and
switch off the services.

## What stays yours

Two things no skill ever takes: saying clearly what you want going in (a real example, the output you expect, what done means), and trying the result before it's saved. The system automates the routine and never the judgement.
