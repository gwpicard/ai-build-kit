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
| I want something changed, new or broken | /shape |
| Build what's ready | /implement |
| I want people to use it | /setup-hosting |
| It's been a while | /maintain |
| I'm lost | /what-now |

Two of them carry the day-to-day work. /shape decides what to change next, a new idea or something broken, and turns it into a ready piece, without touching the tool yet. /implement builds a ready piece, whether it makes the tool do something new or brings it back to doing what it already should. It shows you the result and, by default, waits for your yes before merging. Automatic merging is an opt-in. Once the tool is live, a merge is the release.

The other four sit around those two. /setup-ai-build-kit founds the project once. /setup-hosting sets up how the tool runs live, and checks it later. /maintain makes the records true again and checks the live copy against your project, runs the upkeep when it is due, prepares a handover, and switches a tool off at the end. /what-now tells you where things stand when you are lost.

You run /setup-ai-build-kit once. After that, start wherever you actually are. You can open a session with /shape as readily as with /implement, and neither needs the other to have run first. If you pick the wrong one it costs you nothing, because each checks what you typed against the masterplan and sends it down the right route.

The agent decides whether the request needs an interview, a prototype, research, a test, a review, or a person to look at one area. You can also opt in to queue, parallel builds, a short loop or automatic merging, recorded with its limits in `Runs on its own:`.

## 2. The three records

The records are the project's memory. The agent forgets everything between sessions; these don't, and every piece of work starts by reading them.

Two of them are files you can open. The third, what's left to build, lives in your project's issues on GitHub, because that is what lets more than one person work without clashing over the same file.

You never have to open it. `/what-now` tells you where things stand, recaps what the recent work was about, names anything broken or left unfinished, and tells you when a piece is waiting on something only you can do, such as opening an account or handing over a key. A plain list is printed to `plan.local.md` on your own machine so you can always see it, even when GitHub cannot be reached. That printout is a photocopy. Nobody edits it, and changing a piece means telling the agent, not editing the file.

If refreshing the plan fails, you see the GitHub error with credentials masked
and a recovery step. The last printout stays as it was, with the time it was written.
For a Codex session that cannot reach GitHub or use its stored login, follow the
[GitHub access guidance](docs/COMPATIBILITY.md#github-access-in-codex).
The kit carries a launcher for a fresh Codex session to use your existing login
without saving the credential. It runs from an ordinary terminal and gives Git
the same access for that session. A failed sign-in in Codex shows the exact
restart command; signing in again in that session does not help.

Founding also warns when your GitHub login needs permission to upload the
automated checks. Run `gh auth refresh -h github.com -s workflow` in your
own terminal; it opens the browser once. Founding carries on, and
`/implement` checks again before asking to upload your code for the first
time. In Codex, quit and restart through the launcher afterwards so the new
session uses the updated login. The same command is shown if GitHub refuses
an upload for this reason. Where the permissions cannot be read, the kit
makes no claim that one is missing.

In Codex projects, a check at session start stays silent when GitHub works.
When it cannot authenticate, it shows the restart sentence and starts no work.
Codex asks you to trust the project and review the hook with `/hooks`; until
then, the project's instructions ask the agent to run the same check first.
`/maintain` offers to add it to an older project on your yes.

Founding on a Mac offers once to make typing `codex` use the launcher in kit
projects. The offer names your shell settings file and the marked block you
can remove to undo it. Nothing changes without your yes, and a no is recorded.
Outside a kit project, typing `codex` works as usual. The function uses the
current project's installed skill, so a later project uses its own launcher.

| Record | Purpose |
|---|---|
| masterplan.md | What the tool is, in the present tense. Its first part, the risk record, says who is exposed if the tool fails, what data it holds and how you would recover. |
| the project's issues | What's left to build: one issue per piece, each with what done looks like, its evidence, and what it needs. `/what-now` reads them for you. |
| CHANGELOG.md | What happened, dated, in plain language, when work actually landed. |

`AGENTS.md` sits alongside the three records as the instruction file the agent reads to know how this repository works: the rules, the stack, the capability profile, the conventions.

The dividing rule: the masterplan describes the present, the plan holds the future, and the moment a sentence is about when, why, or how something was built, it belongs in the changelog.

You can work with the issues yourself, and nothing you do there will be undone. Open one and write it however you like, in as little as half a sentence. /shape settles what done means with you and marks the piece ready; /implement builds only ready pieces and never guesses past an open question. If a piece is not ready when you reach for /implement, it points you to /shape and takes the next ready piece instead.

A piece is written in two layers. The part you read stays in plain words, and it stays complete about anything that affects your product, so it never looks simpler than the work really is. The build detail the agent needs sits in a collapsed "under the hood" section you never have to open. Anything that affects the whole product is written into the masterplan instead, and anything technical that affects the whole project goes into AGENTS.md, so no fact is copied into two places.

A decision can say what it rests on, in one short line beside it. When /shape
uses that decision, or /maintain checks the masterplan, the agent reads its support
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

Four labels say where a piece stands instead: `building` when somebody is on it, `blocked` when something outside the project holds it up, `parked` on something you decided against, and `broken` for a repair, which /implement builds before anything new.

Three more say it is waiting on a question rather than on a person: `needs-clarification` (talking it through settles it), `needs-prototype` (a throwaway is needed first to see what it should look like), and `needs-research` (a fact from outside the project is needed). Anything you jot down starts at `needs-clarification`; `/shape` settles it and marks the piece `ready`, and `/implement` builds only ready pieces. What settled it is written onto the piece before the label changes, so a month later you can see what was decided rather than only that something was.

## 3. The risk record

Every project carries a short risk record at the top of its masterplan. Setup fills it from three plain questions: who is exposed if this fails, what data does it hold, and how would you recover from a failure. The fit check rechecks it as the project changes character.

The care is the same everywhere. Every change goes through a pull request, the project check and an independent review. By default, a person says yes to each merge. Automatic merging is an opt-in recorded in `Runs on its own:`. What differs from piece to piece is the risk areas it touches.

The record names the risk areas the project touches: personal data, money, sign-in by outsiders, automatic action on people or other systems, irreplaceable live data, or a regulated decision. It names each in your tool's own words, with the one caution that goes with it. Each piece carries a `Risk areas:` line naming the areas it touches, or `none`. A piece with `none` is built the ordinary way. A piece in a named area gets one risk notice, and the caution happens before that part goes live, or you accept skipping it on the record.

Each risk area also says where it lives in the tool. A check keeps that
list true: a moved place or a new part with no area stops the check and asks
you where it belongs. When a change reaches one of those places, the review
starts from what the change touched rather than from what the piece expected
to touch. The map exists once a risk area is named.

An area can also name one boundary, such as "the ledger is only reached through
the charge step". At founding, and at the quarterly visit for a newly named
area, the agent offers once to have the check hold it. Say yes and put the rule
in your own words, and a change that crosses it turns the tick red with your
sentence beside it. Nothing is added or taken away without your yes, and a
language with no tool for it is told plainly that it has none.

The risk record's `Access:` line says who can get in:
private by default, and checked on each launch and each /maintain visit.

None of this is the kit refusing to build. Where a risk area is named, it says plainly what would normally prevent the harm, and you decide. That is the risk notice, in section 8.

## 4. Day one

Type /setup-ai-build-kit. It checks what the current tool can actually do, then tries to talk you out of building if something simpler would do the job. It makes that case once. If you still want the tool, that is your call, and it records the cheaper option and gets on with founding rather than asking again. It interviews you, one question at a time with its best guess attached, and runs the fit check, which fills the project's risk record.

From those answers it writes the masterplan and cuts the work into pieces. Each piece becomes an issue in your GitHub repository, which can be private.

Before it opens the first one, it says in one line what it is about to do there: open the pieces as issues, replace GitHub's default labels with its own, and switch on removing a branch once it merges. It names the repository and says whether it is public. On a public repository it warns that the plan will be public to anyone and carries on. You can ask it to stop at any point; issues it already opened stay readable to anyone who saw them.

It then stands the project up with one passing check, saved on your own computer. Founding uploads no code. If none of your code is online yet, it stays there until your first build asks you before putting it online. Interrupt it anywhere; typing /setup-ai-build-kit again resumes where it stopped.

Where the work carries real exposure, it also has an independent method read the masterplan looking for holes before any of that flagged work goes ahead; for an ordinary internal tool it says it skipped that and why, rather than making you wait for it. Before it stands anything up it checks that every promise on the masterplan has a piece that builds it, and names the ones that do not, so you can add them while the plan is minutes old.

While it works, the conversation stays on project decisions and results you can
use. Routine searches, setup commands, retries, and waiting stay behind the
scenes unless they create a blocker or need a decision from you.

Before it stands the project up, it asks whether the team will use the tool in
a browser and whether it must work when your computer is off, unless the
interview already said.

Then it names the kind of tool you are building and
shows the recipes that fit, with one recommended. A recipe is one build stack
paired with one place to run it, which the kit knows well enough to check at
launch. For each one it says what the kit can check and what running it
involves, such as the accounts you will hold. If the tool is for work and a
recipe's free plan is for personal use only, it tells you once which plan a
work team needs; a personal project does not hear it.

When only one recipe
fits, you still see it the same way, recommended and named the default. You can bring
your own stack instead: it says once what it then cannot check, and records
your choice. If you do not answer, it takes the recommended recipe and carries
on. It then checks this computer for the tools that recipe's launch checks use,
and the completion report says whether any is missing.

Where no
recipe fits, such as a command-line tool, it says so in one line and picks a
conventional stack. The choice is written in AGENTS.md, in the stack section,
and the kit notes which recipes were on the menu, so a later check-up can offer
one added since. Section 9 says what each recipe does once you go live.

The coverage read includes who can see and do what, the data the tool holds,
and its outside connections. It names any gaps together and offers once to add
the missing work. You decide whether it belongs in the plan.

Already built something, in an app builder, a chat assistant, or an earlier attempt? /setup-ai-build-kit adopts it instead of replacing it: it reads what exists, interviews you about what the tool is supposed to do, writes the masterplan for what's actually there, and pins down current behaviour with tests before anything changes.

The masterplan carries a picture of everything outside the tool that it reaches: where it keeps your data, and each outside service. You confirm each one at founding, and the picture is redrawn whenever a piece adds or drops a connection, so a tool never quietly reaches something you did not agree to.

Already sketched, mocked, or written down what you want? Show it during the interview. /setup-ai-build-kit reads it, says back what it sees so you can correct it, records what that settles, and builds toward it. What the mock doesn't cover gets asked rather than guessed, and a mock never carries work past the fit check.

If the tool needs confidential files to work from, say so during the interview. /setup-ai-build-kit makes a folder for them that stays on each machine and never reaches GitHub, and writes the handling rules into AGENTS.md.

## 5. Day to day

Typed alone, /implement takes the next ready piece from the plan. It agrees with you in one sentence what the piece should do, chooses the evidence that piece needs, builds until that evidence holds, then stops so you can try it. Nothing is saved until you confirm it behaves, and the merge is asked for only after you have tried it, unless you have opted in to automatic merging. You get one address to try it on, the agent checks the page in a tab of its own rather than yours, and it stops its previews once you are done. If you ask for more while it builds, it first asks whether that belongs in this piece, which then says so, or in a new one. A piece that is not ready yet, still waiting on a question, goes to /shape first; /implement builds, it does not shape.

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
that step. That step is refused if it changed a test, and the check on the
pull request goes red if one ever does. A project set up before the check
had that step is offered it at the next /maintain visit. A repair gets the
same.

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
is wrong, describe what happened and type /shape.

The best independent method available reviews every change before it merges. It reports in plain language, sorted into what's worth stopping for and what's worth knowing.

When more than one piece is ready, /implement shows you the whole set before it builds anything, and asks which to take. It comes back with two lists. The first is everything ready, and those are safe to take on together, because a piece waiting on another piece is never in it. The second is what is waiting, each line saying which piece has to land first: "deposits cannot start until card payments is built". Nothing is built until you choose, unless you have opted in to queue or parallel builds.

A repair that is ready comes first, above both lists, since something that used to work outranks anything new. To see the lists without building, ask for them in your own words, such as "what can I build in parallel?". If the list looks out of date, type /implement again, since it is printed fresh from your project's issues every time. /what-now still names at most three things, so the whole list lives here.

/shape is how you bring anything new: "/shape add a filter to the board". You never sort your own request; the agent works out what kind of work it is. Clear and piece-sized becomes a ready piece, and /shape offers to hand it to /implement, best in a fresh session, or to leave it for later. /shape itself never builds: answering one of its questions is never a yes to building, and the build starts only when you ask for it. Vague gets a short interview.

Each piece says what it changes in the masterplan, and the masterplan says when
it was last checked. You see a line such as "When this lands, the masterplan
gains a weekly summary email", or "nothing" when it already covers the result.
A new rule you could check, such as a list now sorted by name, counts as a
change even when the masterplan already describes that list. /implement applies that change as it saves the work, so the page keeps up
without waiting for a /maintain visit. Where the masterplan's last check against the
code cannot be found, /implement says in one line that /maintain does that
check, and carries on, and /what-now names /maintain until it has. Founding
records that first check itself, so a new project starts with one.

A question a conversation can't settle gets a disposable prototype, a source check, or a search for something that already does the job. Two of those need you there; the research does not, so you can tell /shape you're leaving and it settles what it can alone, then tells you which pieces are waiting on you. Type /shape with a piece's number to settle that one rather than the next in line.

Typing /shape is the choice to shape, so it starts on a question straight away. Before an interview or a prototype it says in one line that this takes a sitting, and you can say "later" at any point: the piece is filed with its question and your words, to come back to.

If all you want is to note an idea, say so, for example "note this for later" or "just file this idea", and it is filed with nothing started. Nothing filed can be built until the question is answered, and /what-now tells you when enough pieces are waiting that the session is better spent planning than building.

Show a mock of what you want and it settles the question instead, with no throwaway built. A prototype comes back as one of two things: a single file you open and click through yourself, or three genuinely different versions to move between and pick from. If setup recorded a design tool, the agent may use its canvas before a real page exists or when you want to draw a redesign. The real page still wins wherever one exists, and without a recorded tool the ordinary coded throwaway stays the default.

Anything touching data, access, or money gets written into the masterplan first. If another piece already open would be built in the same place, /shape names it before the work starts, so you can decide whether to carry on, wait, or fold the two together.

If the request would change what kind of project this is, by bringing in outside users or real money or a promise to someone, the agent re-runs the fit check with you before building. A change in who relies on it needs different care before they do.

When something that should work doesn't, tell /shape: "/shape the board duplicates cards when I drag them". Paste the whole error if there is one. A bug is a piece like any other. /shape first checks that the behaviour was promised, since a new wish is new work rather than a repair. Then it makes the problem repeat reliably, cuts it down to the smallest case that still fails, and writes that case into the piece as its done line.

The piece is ready once the fault is reproduced, and /implement builds a ready
repair before anything new.

A small, clear fault, such as a typo or a wrong label, needs no long sitting.
/shape marks it ready at once and offers to build it in the same session.

If the live tool broke just after a change went live, you are offered the
earlier version back first, whatever you typed. The kit names the version it
would bring back and runs the rollback only after your yes. Then it shapes the
repair as usual. Some hosts stop putting new changes live after a rollback
until a newer version is put live by hand. The kit says so at the time, and
/setup-hosting puts the repair live after your yes. With no recipe, the kit
guarantees no rollback, and says what one would need.

After launch, /shape also reads the tool's own record of what each request did
alongside your report, so it can trace the failed step. You do not need to read
that record yourself.

Building the repair, /implement works out the cause before touching code,
driving the app in a browser or adding temporary logging when it needs to see
what is actually going wrong. It resets failed attempts rather than stacking
them, and finishes with evidence that keeps the bug from coming back.

Before repairing, it reads the changelog and finished pieces for the same part
of the tool. That keeps a failed repair from being tried as if it were new, and
lets an earlier cause lead the search. Existing covering tests run before a new
one is written. When there is a known time the behaviour worked, it searches
the saved changes for where it broke, then removes every temporary log before
the repair is saved.

If the same fault survives three attempts, it stops patching and routes by what the failures revealed. That may mean another interview, a rebuild from the masterplan, a stop for missing access, or naming the area as a risk area so somebody who does that work for a living looks at it. In the same reply you get the risk notice: whoever relies on that behaviour is still getting wrong results. If you carry on after it, the next attempt goes ahead and your acceptance is recorded.

## 6. Evidence

Every promised behaviour gets evidence, in one of four forms:

- an automated behaviour check, for business rules, calculations, permissions, data changes, integrations, and bugs, where a machine can judge the result reliably;
- a guided manual check, for copy, layout, colour, and exploratory or subjective work;
- a source-backed fact, when correctness depends on something an external service or provider actually does;
- an operational rehearsal, for backups, restores, migrations, rollback, or anything else that only proves itself by being run.

The agent chooses the form the change actually needs; the report says what was proved and what remains a judgement call.

Where a change touches a mapped risk area, /implement can offer to break the changed code on purpose
to check whether its tests notice. A repair gets the same offer for the test
that keeps a repaired fault from returning. It runs locally when the language
has a suitable tool, covers only the changed code, and is optional.

You get one line: "The tests were checked by breaking the code on purpose 40
times. They caught 37. The three they missed are listed on the piece." Misses
in a named risk area are worth stopping for; the rest are worth knowing.
You decide whether they matter. The kit records that choice, and only adds a
test to protect promised behaviour, never just to raise the count.

## 7. Saving work

Every piece saves through a pull request: the agent pushes a short-lived branch and opens it, and by default you decide whether to merge.

A piece in a risk area whose caution is neither done nor accepted takes the flagged route. It does the same, and also attaches the condition the touched area requires; a piece that stops there, plan marked blocked and the condition on record, counts as finished until that condition is met or you carry on after the risk notice and your acceptance is recorded. When you are there and carry on at the notice, the piece is built and saved like any other.

The first time anything pushes your project's code online, the agent asks you first, naming the repository and whether it is public or private. It asks once for each project: once the code is on GitHub, it does not ask again.

If you say no, or nobody is there to answer, the piece is still built and checked, and it waits on its own branch on your computer until you say yes. If the repository already holds something that is not your project, or still points at the kit's own repository, nothing is pushed and the agent asks you what to do.

Next to the merge button sits a check. It re-runs the project's real commands on a clean machine, so the pull request's claims get verified rather than trusted. Those commands include the mechanical checks your project's language offers, a type check and a linter wherever it has them, which catch a whole class of mistakes before anyone tries the tool. They use each tool's own default rules, so a red tick points at a real mistake rather than a matter of taste. The agent runs the same checks before it hands any work over.

Green means the checks that exist really passed, which is a smaller promise than nothing being wrong: it covers the behaviour somebody thought to check and nothing else. Red means don't merge; say it to /implement, which takes that piece's build back up, and the agent reads what failed itself. You never read the machine's logs, and you never merge over a red check. Sometimes GitHub will not start the check at all, for example when the account's billing stops it. That is not red. The merge waits until GitHub runs the check. You can re-enable the check or merge on GitHub yourself. The check is switched off only if you ask, and /maintain reminds you while it stays off.

A human decides whether to merge by default. Automatic merging is an opt-in. When it is off, once the check is green, /implement tells you what to try and where, such as the preview address, then names the pull request in one plain line and asks for a yes that names the merge. Saying "put it live" or "save it" before any merge was named is not that yes, so it asks again; saying "merge it" is, and it does not ask twice.

It makes an approved merge on the pull request itself, never by merging on your computer and pushing `main`. In Claude Code a box asks before a named approval merge, where the project's settings carry that question. A project founded before the kit added it gets no box until /maintain adds it, and /implement says so rather than promising one. If GitHub cannot be reached, the merge waits, and you can merge it on GitHub yourself. With automatic merging off, nobody there to answer means the pull request waits. After a merge, everyone pulls main. Every pull request gets its review before it is offered as ready, and a flagged area also gets the review its caution names.

Once the tool is live, a merge is a deploy: the host builds `main` and the team's copy follows.

So before asking, /implement checks the live side. A change that adds to the database waits until /setup-hosting has applied that addition, which only adds, so the version live now keeps working. A piece whose `Live side needs:` line names a new secret or service waits until /setup-hosting reports it present. So does a piece whose branch adds a setting to `.env.example`, even with no such line, since a piece shaped before the line existed has none. A piece in a risk area waits until its caution is done or your acceptance is recorded.

Where your recipe runs a check on this computer before the merge, a check that runs and fails holds the merge as a red check does, and the piece goes back to its build until it passes. A required check that cannot run also holds the merge.

After the merge, /implement reads one line from the live copy: "The live copy now runs this change", or "The live copy did not update" with the next step. It changes nothing live, so if you ask it to put the change out again, it checks first and leaves any further deploy to /setup-hosting. The project's push guard refuses changes straight to `main` and pushes that replace remote work, whichever coding agent runs them. Each piece starts from an up-to-date `main` and reaches it through a pull request.

## 8. Risk areas, and the risk notice

Six areas count as risk areas, and the list is fixed: personal or sensitive data, money, sign-in and permissions, automatic action on people or other systems, irreplaceable live data, and regulated decisions.

Each carries a default caution, which is what would normally prevent the harm: a person who did not build the tool reviews who can see what; a managed payment or sign-in service so the tool never holds card details or passwords; a person approves each automatic action until a live run has shown it right; a backup restored once and the change rehearsed on a copy; somebody qualified signs off a regulated rule.

The risk record names each area in your tool's own words, its caution, and whether the caution is done. Each piece lists the areas it touches, and the notice comes once for that piece. Where the caution is a backup, a copy or a managed service, the kit does it. Where it is a person, the kit tells you so once, in the risk notice below, and the choice of whether to wait for them is yours. It keeps building everywhere else either way.

Before work in a named area goes ahead, you get a risk notice. It comes once, in full, in one reply. It says who is exposed, what happens to them if it goes wrong, what would normally prevent that, what you can do, and that the kit flags what it can recognise and will miss things. It names people rather than saying something is risky, because the exposure a tool creates usually lands on somebody else.

Then it is your call. You can have the caution done first, take the thing out of scope so the risk goes away, or carry on. Carrying on is accepting the risk: say go ahead in any words and the work goes ahead. You are not asked a second time, and nothing the notice named stays switched off waiting for the check you chose to skip. Saying nothing is not carrying on, and neither is asking a question. Nothing is refused and nothing stops you.

When you carry on, an acceptance is written into the risk record before the work starts, as a dated line saying what was skipped, in your own words, with your name. It says the risk was accepted, never that the caution was done. Making a project less careful is a decision you record, not something the agent does on its own, and the accumulated lines are the honest answer to "what did we knowingly skip?" when somebody asks in six months.

What the agent may not do is take the notice back. Pushing back on the cost, the wait, or the fuss changes what you decide and changes nothing about who is exposed, so the notice stays put however many times it comes up. A named check cannot be quietly turned into something the agent does itself either: where a caution asks for another person's eyes, the agent reading its own work does not count, and neither does a passing test.

## 9. Going live

/setup-hosting is for the moment you want people to use the tool. Its first run takes what is already on `main` live and sets the host up so that each later merge to `main` reaches the team's copy. From then on a merge is a deploy, and /implement waits for your yes by default, unless automatic merging is on, so /setup-hosting never merges your code. Run it again whenever you want the live copy checked against `main`, or moved to another host or recipe.

/setup-hosting reads the risk record first. It runs the full evidence run, independent review, operational readiness, and the live transition. With a recipe, hosting follows its checks. With no recipe, the kit says once that it guarantees no way back, backup or checked launch, records your words and the date, and still helps you set the host up by hand.

For a risk area, /setup-hosting does the caution it can do itself (a backup restored once, a rehearsal on a copy), and at a caution that is a person who has not looked, gives you the risk notice once. If you carry on, your acceptance is written down and that area goes live too. Where somebody outside the team is going to look, ask for the handover and /maintain prepares it.

On a recipe, /setup-hosting reads the recipe your project's AGENTS.md names, and
a script runs its nine checks in order. Each one gives you a plain line, in
the same words every time: preview up, live address updated,
rollback possible, backup present, restore works, no secret in the repo, logs
readable, health answers, access as recorded. The rollback line says a rollback is possible and
was not tried, because the kit does not roll back the live tool just to check.

The kit runs the checks it can reach. Where a check runs on a server the kit
cannot reach, it asks you in fixed words to paste the result back, and a
script reads what you paste. Where only a
person can judge, you look and the kit writes down what you said. On a recipe,
a live launch is held if the backup check does not pass, if the recipe names
no rollback on a first launch, or if a later launch cannot confirm an earlier
build to return to. Other checks that fail or cannot run are reported as
warnings. A first launch also waits for its address, because a tool with no
recorded address is not live. With no recipe, the kit gives one notice that it
guarantees nothing, records the person's choice and helps with setup by hand.

Before the launch review asks you to look up a setting, the kit reads it itself
where it can: from an address the service answers in public, with the key your
tool already sends to the browser, or through the commands of a tool it is
already signed in to. It asks you only about a setting it cannot read, and says
why it cannot.

The kit never takes a login another tool keeps for itself, such as one stored
in your computer's keychain. That login can reach everything on your account,
not only this tool. Once the kit has told you it cannot read a setting, it does
not then read it some other way. It asks you, and names the page where the
setting lives.

A command that changes a live service's settings or data, other than saving
code through the save route, waits for your yes, in /implement and in /setup-hosting
alike. The kit first names everything the command will change, not only the
setting it meant to change, and says whether it can be undone. A real build
once pushed a whole settings file to change one thing, and switched off a live
setting it then could not switch back on. The commands your project's recipe
names are the launch you asked for, and need no second yes.

A later run is
different: nobody asked for a launch, so each repair it makes waits for a yes
that names it.

/setup-hosting never merges your code. A finished piece waiting in a pull
request is merged by /implement, on a yes that names the merge. When a deploy's
result is unclear, /setup-hosting checks whether it went live before it tries
again. A second deploy of the same version leaves nothing older to roll back
to, and /setup-hosting says so before running one. A warning you have already
heard is not repeated in the same run.

The records /setup-hosting writes, such as its changelog entries and a
colleague later saying the new version is live, take the same save route as a
piece.

On a shared project they go on one branch and one pull request for each
run, never straight to `main`, and merging that pull request needs its own yes,
made on the pull request itself. Where your host builds every change to
`main`, /setup-hosting tells you that merging it starts one more build and
moves the rollback target, and offers to leave it for the next change. Work of
yours that is not saved yet is left where it is, kept out of the records and
never thrown away.

Some checks need a secret, such as a database password kept in a file on your
computer. When you tell the kit where one lives, in any session, it writes down
where, never the secret itself, in the masterplan's "How it stays running"
section. A later /setup-hosting reads that line before the backup, restore or database
check. If nothing is recorded, it asks you once. If you cannot say, the warning
says the kit does not know where the secret is kept, and never that it is gone.

On every launch, /setup-hosting checks that the tool keeps a plain record of what each
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
not repeat this caution.

When the tool will run on a server somebody else runs, as on the Coolify
recipe, the first launch needs an address, and the kit never contacts that
server. So /setup-hosting writes a hosting request into the masterplan's "How
it stays running" section and prints it for you.

It names the repository and branch, the lane (private network or
internet), the port, the names of the settings the tool needs, the folders that
must survive a restart, and the path that shows the tool is healthy. It also
says how the tool builds and which address it listens on, read from the code,
because the server builds and checks it from those two facts.

It holds
names only, never a password or key. You take it to whoever runs the server,
and paste back what they send. On a later launch /setup-hosting reads the request back
rather than asking again. The README names a hosting companion that can turn the
request into a running address.

Some launch checks reach your data. On a recipe, the restore check copies the
live database onto this computer and stops the local database while it runs.
Where the database plan keeps no backups of its own, the kit takes one after
each launch into a dated folder outside the repository. Each pull request's
preview is meant to use a separate database kept for previews. Where the plan
has no room for a second one, a recipe may point previews at the live data
instead, and the kit says so once. The recorded recipe trials shared one
database between previews and the live copy, so they have not proved that
separate preview data stays separate.

Keys and passwords never go in a file Git tracks. On this computer they live
in files Git ignores, such as `.env`, and the live values sit in the host's own
settings, entered by name.

After the first launch, a later /setup-hosting compares the live copy with `main` and tells you each gap in one plain line: whether the live copy runs the latest merge, whether it is held on an earlier version since a rollback, whether a database change has not been applied, whether a secret or setting is missing on the host, and whether health answers. It then runs the recipe's checks again, the backup and the restore included.

It repairs each gap only after a yes that names it. It rechecks the risk record first if reliance or consequence has grown. A warning the changelog already holds comes back as one line pointing to it, so anything given in full is new. Every later run leaves one dated entry in the changelog, even when it finds nothing to repair, with its rollback line, such as "Rollback possible, not tried". That entry arrives as a records pull request with its own merge question, and where your host builds every change, that merge is one more build. Moving to another host or recipe is a later run too: the old live copy keeps serving until the new one answers.

You can also ask /setup-hosting for a rollback outright. It reads the host's list of builds, names the version it would bring back by the change it carried and its date, and waits for a yes that names it. It runs the rollback once, or tells you where to click when the host offers nothing the kit can run, and checks that the live copy now reports the earlier version.

A rollback does not undo a database addition, which is why database changes only add. With no recipe the kit guarantees no rollback, and says what one would need.

### What the launch trials proved

Each recipe was tried on a throwaway app before it joined the menu. Both trials
proved the preview, launch, rollback, secrets, logs and health steps on a live
deployment. The backup and restore steps are shared and were run for real once.
The recipe for your own server was tried on a private network and on the public
internet. Its preview for an app without a domain ran on the server but had no
address the person could open. Each recipe's trial record, with the results
and their limits, is the `PROVEN.md` in its folder, which the
[README's recipe links](README.md#going-live) lead to.

The kit runs a rollback itself where the recipe provides a command. Otherwise
you use the host's page and paste back the result. The host may keep only the
build before the live one, and may hold new merges off the live copy after a
rollback until you approve putting the repair live. The recipe says which
applies. Confirming an earlier build exists does not prove a rollback works;
launch checks do not try one on a working live tool.

## 10. Autonomy

The longer-running options are off by default. To turn one on, record the person's words, date and chosen options in `Runs on its own:` in the masterplan. `/implement auto` also needs the person's approval before it starts.

The options are `queue`, `parallel N`, `loop` and `merge`. Queue takes the next ready, unblocked and unassigned piece after each merge, up to five pieces in one sitting. Without the `merge` option, it stops when an open pull request blocks the next piece. Parallel builds use one worktree per piece, default to two builders and never exceed three; a shared file, table, migration, risk area or project setting holds the parallel pair. The short loop counts three attempts per piece, including a repair. A fourth attempt marks the piece `blocked`; a repair or an unaccepted risk area cannot loop unattended. Automatic merging requires three earlier merges through `--approved`, a branch up to date with `main`, passing checks and review, and no repair, risk area, migration, setting, live requirement or `(try it)` item. A pending check waits up to 15 minutes; any red, missing or still-pending check holds the merge.

At the end, the evidence-run report gives what passed, failed or was not checked, the remaining human judgements, and whether anything in the risk record still blocks shipping. Automatic merges name each piece merged. If the main or live check fails after one, automatic merging pauses and reports the failure. It stays paused until you resume it. A person can turn any option off in their own words.

## 11. Working as a team

Several people can work on one project, through GitHub's ordinary pull requests. GitHub collaborators identify who has access. Invite someone under the repository's Settings, then Collaborators. They accept the email, open the repo in their own tool, and make their own .env from .env.example.

Nothing else changes when a second person arrives: naming a piece before starting it already stops two people building the same thing. /implement puts your name on a piece when it starts, skips a piece somebody else has, and says who has it. If that person is no longer around, it offers to take the piece over and leaves the choice to you. Each of you gets your own printed list, so there is no shared file to clash over.

When you shape a request, /shape names any other open piece that would be built in the same place, before the work starts. You can carry on, wait, or fold the two together. Open pull requests show work in progress.

On a shared project, each piece starts from an up-to-date `main` and arrives as its own pull request, and by default a person decides each merge. When two pieces change the same lines, GitHub shows a merge conflict on the pull request that came second.

Before /implement asks for that merge, it reads whether GitHub can make it. On a conflict it says so in one line, and offers to resolve it the ordinary way: merge the newest `main` into that piece's branch, settle the conflict, and push the branch again, never with a force push. It does that only on your yes, then runs the check again before asking for the merge.

Once a merge is under way on your computer, /what-now explains a conflict it finds and says which two intentions collided. It settles the conflict itself only when the records make the right outcome plain. Otherwise it keeps both sides and asks you. A conflict that touches data or how the tool goes live is never guessed through. You never have to read Git's own state to follow any of this.

The kit is built for one person or a small team. It is not optimised for large teams or many agents building the same project in parallel. By default, each session builds one piece at a time. Parallel builds are an opt-in, and a person decides each merge by default.

## 12. Maintenance

/maintain makes the project true and healthy, and you can type it at any time.
Every visit starts by checking the records against what really happened.
Normal /implement completion already updates them, so after a piece that
finished cleanly there is little to correct. The check catches the rest: work
done outside the workflow, a long session whose context went foggy, an
imported branch, or a handover coming up. A report-only reminder can
optionally run at session end, where the tool supports it, but nothing writes
to the records without a skill deciding to.

If a session stopped part-way, start with /what-now. It says what the leftover
work belongs to and offers to continue it, save it or clear it. /maintain's
corrections are saved the way a piece is saved, so they arrive as a pull
request you decide to merge, and uncommitted work it finds on arrival is reported and left alone.
That work stays out of every save the visit makes, and the kit update waits
until it is dealt with.

Once your tool is live, every visit also compares the live copy with your
project, and changes nothing while it does. It names each difference in one
line, such as the live copy running an older version or missing a setting, and
offers /setup-hosting to put it right. The backup, restore and preview checks
stay in /setup-hosting, since they can touch the live side or need you. The monthly and quarterly upkeep further
down runs only when it is due. A visit in between does the checks in this
part and tells you when the next upkeep falls due.

Each visit re-reads the masterplan against your pieces, and says if a promise
has lost the piece that builds it. It also picks up changes a finished piece
was meant to make to the masterplan but never did. It checks what actually
landed, applies what is still missing and records where it checked up to.
Before that, each visit uses the last such point to say how much work has
since touched the tool's data, permissions or connections, when there is any.
That is a reason to check the page, not a claim that it is wrong.

The coverage read includes permissions, data and outside connections here too.
It also compares settled terms on every piece with the masterplan, even if a
piece was parked or reshaped. A missing or different meaning joins the same
list of gaps, with one offer to put the records right. Planning leaves the
term on its piece until it is carried across, so parking the work cannot lose
what you agreed.

When the core masterplan grows beyond roughly two pages, /maintain says so once
and offers to move detail about individual pieces onto those pieces. It leaves
the page alone without your yes, and keeps the tool's present promises and
decisions on the masterplan.

Each visit also reads the project's README, and any document AGENTS.md points at,
against the project itself. It names a file, link, command or setting a
document mentions that no longer exists, at the line it sits on, and offers to
correct just that name or to file it for later. A document that says less than
the project does is fine. It checks names only, so it cannot tell you whether a
described step still happens that way, and it says so. When every name still
points at something real, you hear nothing about it.

/maintain names open pieces untouched for 30 days in one short list and asks once
whether each is still wanted, should be parked, or is done. It changes nothing
on that list without your yes. You can leave them as they are and carry on.

The monthly upkeep is light: AI Build Kit updates, project dependency
updates, and, once the tool is live, anything the error alerts and the bills
show. Each monthly visit names two numbers, the version your project holds and
the latest published AI Build Kit, and says plainly when they differ. An update
gives you that published release and never work nobody has released yet. When
a newer kit is available, the agent shows the version and what changed, then
waits for approval.

An update refreshes only the AI Build Kit skills and leaves your tool, its
records, and its own checks alone. It also adds any skill the kit has renamed
or added since, and says if the installation is missing one.
When the kit has renamed a command, the update also rewrites the command list
in your AGENTS.md, with your approval, so you are not left to edit it by hand.

A project founded from a whole copy of the kit also carries the kit's own
command files, which make each command show twice; the visit offers to remove
those and leaves anything you wrote yourself alone.

After an update, start a new session (or type /reload-plugins in Claude
Code) and type /maintain again. The session that ran the update still follows
the instructions of the release it replaced, so the next visit is the one that
finishes it. Every /maintain visit, on any day, runs one check of what an
update left behind, and that check changes nothing by itself. Until it finds
nothing left, /what-now and /implement each say one line: the kit update is
not finished, and /maintain finishes it.

That check also looks at the small helper that prints your list of pieces to
`plan.local.md`. A project founded before every installation carried it, or
holding an older copy, gets the current one on that visit, so the kit reads
what is ready from that list rather than working it out by hand. A clean
checkpoint comes first, so an interrupted update can be recovered.

A project founded while the kit had a single `/build` command has no `ready`
label on GitHub, so /implement would build none of its pieces. The check reads
the project's issues rather than its installed skills, so every install route
is covered. It labels each shaped piece `ready`, leaves a piece still waiting
on a question for /shape, and says how many it marked. The visit also says
once what an old command became: /build is now /shape and /implement, /start
is now /setup-ai-build-kit, and /plan is now /shape.

Any monthly visit that finds a `plan.md` holding the kit's old list of pieces
says they are not picked up until they move into your project's issues, and
offers to move them. A no is not recorded, so the next monthly visit offers
again while the file is there. Any visit that finds a line in AGENTS.md or the
masterplan pointing at a skill's file by a folder your installation may not
have offers to name the skill instead, changing only those lines, and only on
your yes.

A masterplan whose fit-check section still uses the fields from before the risk
record is offered a rewrite to today's shape. It shows the old section above the new one, copies each accepted risk
word for word, and changes nothing else in the masterplan without your yes.

A project installed before the kit had six commands still offers the old
ones after its update. The first /maintain after the update says so in one
line: /fix and /queue are part of /shape and /implement, /sync is part of
/maintain, and /ship is now /setup-hosting. Nothing you built changes. It
offers to remove the old skills, to rewrite the command list in your
AGENTS.md, and to correct the one sentence the kit itself wrote into your
masterplan about the hosting request. A project founded from a whole copy of
the kit is also offered the removal of the kit's own files it carries, such
as its WORKFLOW.md, but only where they match a released copy exactly. None of
it happens without your yes.

Your changelog keeps its old mentions, since it records what happened. A line
of your own in AGENTS.md or the masterplan that names an old command, such as
a note of when you run one, is named once for you to change, and never
rewritten. Once everything is removed and rewritten, the next visit finds
nothing and says nothing. An offer you declined is mentioned in one line on
each visit and offered in full again on the monthly visit. A command list
written in your own words gets the same offer: /maintain shows the old lines
and a replacement, keeps your own sentences, and applies it on your yes. The
update stays unfinished until the old command names are gone or you decline.
You never need to edit the list by hand.

The standing instructions in AGENTS.md stay under 200 lines and hold what the
code cannot show, such as how work is saved and reviewed and which conventions
differ from the default. /maintain counts the lines every month and offers a
trim if the file reaches 200, or contains a folder layout, dependency list,
architecture overview or style rule an automatic check could enforce.

You see one line saying how long it is and what can go. Nothing is cut without
your yes. A newly founded project starts well under the limit, with room left
for what founding writes into the file.

A project with no recipe may still be built much like one on the menu, with
the same framework and the same data service, even if it runs somewhere else or
lacks the recipe's Dockerfile and health route. That covers a project founded
before recipes existed and one founded on its own stack. The monthly visit then
offers the move once, and says what it gains: the launch checks /setup-hosting would run
on that recipe. It also says what the move would change.

Nothing changes without your yes. A yes becomes a piece, shaped and built like
any other, and the offer does not come back while that piece is open. A no is
recorded, and the offer comes back only when the menu or your stack has
changed since. The move is never required. When no recipe is close, you hear
nothing.

If you chose your own stack, founding noted which recipes were on the menu. A
close recipe that joined the menu after you founded the project is offered
once, even if your stack has not changed. A project founded before that note
existed treats every close recipe as new, once.

/maintain also lists old branches whose work is already in your main branch,
on your computer and on GitHub, each with the command that removes it. It
keeps two kinds apart: the ones Git can confirm, and the ones only GitHub
records as merged. The second kind comes from a pull request that combined its
changes into one, which Git cannot check. It never removes a branch itself,
and it cannot tell whether somebody still plans to use one. When there are
none, you hear nothing.

The push guard founding installs stops changes straight to `main` and pushes
that replace remote work.
A tool that rewrites Git hooks can switch the guard off until the next upload
switches it back on, and GitHub's own protection of `main` covers that gap
where your plan allows it.
Claude Code's settings protect that guard, refuse
forced deletes and ask you before any merge.
A project that already had its own Claude Code settings when it was founded
keeps them, and the next /maintain visit offers the missing safety rules.

When a later release catches more ways of writing one of those, the
next visit names the new rules and offers to add them to
`.claude/settings.json`, once. The same offer removes the kit's retired push
text rules, which can stop a safe upload; the push guard still protects main
and remote work. Nothing changes without your yes, and your own rules stay.
A no is recorded, and the offer comes back only when a release changes it.

/maintain writes the date of each visit into the project. When more than a month
has gone by, opening a session says so and names /maintain. A tool that cannot
run anything when a session opens says it when you type /what-now instead.
Nothing is blocked and nothing changes without a command. If you ask a visit to
leave kit updates alone, it does not add that reminder either, and says so.

The quarterly visit is fuller, with a hot-spot tidy-up and an ownership check
that can name a new risk area or, after a genuine redesign, take one off.
Its hot-spot read counts how widely the quarter's saved changes spread instead
of guessing from memory.

It also looks for code copied
from one place to another, code nothing uses any more, and dependencies nothing
needs, using tools that read the project rather than the agent's impression of
it. Each finding names the file and line, and it joins the same short list of
at most three proposals. A finding you were offered at an earlier visit is not
raised again. One that did not fit on the list, or that a visit could not
check, comes back at the next visit. It finds copied code; it does not find
two pieces of code that do the same job written differently. When it finds
nothing, you hear nothing about it.

It also names any place where two parts depend on each other in a circle, the
same way: one you were offered before is not raised again. Most quarters there
is nothing new, and you hear nothing.

It also reads all of the project's documents for bloat: a paragraph written
out in full in two places, and a document nothing mentions any more. Each one
comes as an offer, to keep one copy or to delete the page, and nothing changes
without your yes. One you were offered at an earlier visit is not raised
again. It finds copies, not two documents that say the same thing in
different words.

/maintain also prepares a handover when you ask for one: a document for
somebody outside the team who will look at one risk area, or take the
whole build on. It holds no secrets, says where access is granted, and says
what it does not cover. Everything outside that area carries on either way.

/maintain also owns the ending, when a tool's time is over: export the data,
tell the team, revoke access, and switch off the services. The export is read
back first. Each step that revokes access, deletes a credential, switches a
service off or archives the repository waits for your yes, and says first
whether it can be undone.

## Configuration

| What you can change | Where |
|---|---|
| Project rules the agent must follow | Your project's `AGENTS.md` |
| Keys, passwords and tokens | Files Git ignores, such as `.env`, made from `.env.example`; live values belong in the host's settings |
| The risk record and accepted risks | The risk record in `masterplan.md` |
| The recipe the project runs on | The `Recipe:` line in the stack section of `AGENTS.md` |
| Commands the agent may not run | The kit's [blocked-command list](.agents/guard/blocked-commands.md) and your agent's own settings |

Keep project rules in `AGENTS.md`. Update the installed skills with `/maintain`
rather than editing their folders. An update replaces those files, while your
application code, records, environment files and project checks stay yours.
[Compatibility](docs/COMPATIBILITY.md#update-the-installed-skills) explains
how each installation route updates.

## What stays yours

Two things no skill ever takes: saying clearly what you want going in (a real example, the output you expect, what done means), and trying the result before it's saved. The system automates the routine and never the judgement.
