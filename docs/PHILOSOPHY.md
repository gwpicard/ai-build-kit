# PHILOSOPHY.md: why this kit exists and what belongs in it

Why the kit is shaped the way it is, who it is for, and how to decide what
belongs. Read this before adding anything.

## The problem

Capable, motivated people can suddenly produce software, without the process that
keeps it reliable or the judgement about when to stop and get help. The result
demos beautifully on a Tuesday and cannot be changed by anyone six weeks later,
including the person who built it.

The steps that close that gap are the ones the README opens with. This kit is
those steps, packaged so that nobody has to read the code they produce to
follow them.

## Who it is for

Someone who already builds with an AI coding agent and wants what it builds to
still work six weeks later. Two kinds of person reach for that. One is a
developer new to agent-led work, who finds their usual discipline either too
heavy for it or quietly skipped. The other came to software from another job.
They run a team, a product, an operation or a dataset, and they now have some
practice at directing an agent and getting a working tool out of it. Both want
the reliability of a real process. Neither wants to carry the process by hand.

The kit rests on one rule: the workflow never requires reading code. None of the
nine commands asks anyone to open a file of code, and every check is something a
person sees or tries. The rule describes the process and leaves the person
alone. A developer can read every diff if they like. The kit never depends on
it, because a process that only works while somebody reads the code stops
working the day nobody does.

That rule settles every argument below. When a choice comes up, the question is
always what this person can see, what they can try, and what they can safely
leave to the machinery.

Solo here means without a professional development team behind the project, so
a team of five is as much the audience as a team of one. The skills are plain
markdown, and a technical person can read and extend them. What people build
with the kit is mostly internal, and the README's fit section says which
projects qualify.

The kit optimises for the least process that materially reduces failure for the
project's current consequences, complexity, and ownership burden. A control
may be always required, activated only when a risk appears, or carried by a
sensitive area as its caution. More process is not automatically better;
process earns its place by changing an outcome the user can understand.

## What follows from that

Every check is behavioural. Verification is something the person clicks or sees:
a real input and the output they expected, a green tick beside a button, a
plain-language report saying what was tried and what happened. Nothing in the
workflow asks anyone to read a diff.

The documents are the asset and the code is their current expression. Three
records hold the project's present, future, and history. `AGENTS.md` carries
the standing instructions for how work happens. The agent forgets everything between sessions and they do not. This is
why a piece that resists fixing is routed by what the failure revealed
rather than patched a fourth time, often ending in a rebuild from the
documents, and why a disappointing autonomous run is answered by sharpening
the plan instead of hand-editing whatever it produced.

The vocabulary stays small and grows only by deliberate redesign. Nine commands,
each named after a moment a person actually reaches for, and every new
capability arrives as behaviour of an existing command wherever it can. A
capability that genuinely needs its own command is a sign a command was carrying
two jobs at once, and splitting it is a redesign conversation, not a casual
addition. The count has moved twice, both times for that reason. Seven became
eight when `/build` was found to be both planning and building, and the planning
half became its own command, now `/shape`. Eight became nine when `/what-now`
was found to be both orientation and overview: it names at most three things
because somebody lost cannot use more, and somebody taking on several pieces at
once needs the whole list, so that half became `/queue`.

A name can also be forced from outside. Where the coding agent the kit runs inside takes a command
name for itself, the person either cannot reach the kit's command or loses the
agent's own, and renaming the kit's command is the repair. That is a rename
rather than a redesign, so the count stays where it is. `/plan` became `/shape`
on those grounds.

Where the person can judge a risk, the kit suggests and warns rather than
blocks. These readers have built things before, and once a cost is named in a
line they can weigh it. So a step they could skip is offered with what it
costs, a warning says what could go wrong, and the choice stays with them. A
risk the person cannot judge alone is what the build path and its cautions are
for, as the next sections describe.

Machinery stays invisible until it matters. Nobody needs to know a review
skill exists until the agent says a change touched sign-in and a fresh
session is checking it. Nobody needs to know what a continuous integration runner
is to understand that green means the tests really passed.

Trust becomes mechanism wherever it can. A claim that can be checked
automatically gets checked automatically, and the result shows up as something
visible. Instructions ask. Machinery guarantees, and it guarantees exactly what
it checks and nothing beyond that, which is why the kit says what a check
covers rather than letting a green tick stand for everything.

And the kit is honest about its own limits. A fit check at the start, and again
whenever a project changes character, decides how much care applies and names
each part of the work that touches something sensitive, with the one caution
that goes with it. Being told at the start what you would otherwise discover at
launch is the most valuable thing here.

## Rigour follows the project

The same workflow must not treat a private experiment and a business-critical
internal system as if they carry the same consequences. Every project has one
build path: explore privately, build and run it, or build with care. The path
decides which checks, reviews, saving steps, and launch conditions apply. It is
decided by what the work touches. Build with care means some of the work sits
in a sensitive area: personal data, money, sign-in, automatic action,
irreplaceable live data, or a regulated decision. The masterplan names each
area in the tool's own words with the caution beside it, and everything
outside those areas is built the ordinary way.

The path count has moved once too, and the other way. Four became three when
the two most careful paths were found to be asking the wrong question. Both
asked who should own the build, one for a single named area and one for the
whole thing, and a person who had already decided to build it themselves heard
either as a refusal wearing a different name. What the kit needed to know was
what the work touches. So the two became build with care, which names each
sensitive area and the one caution that goes with it, and the ownership
answers became founding tasks rather than a path. A path that changes how
carefully a thing is built has to be about the thing.

The path can move in either direction. A prototype may become an operational
tool. A risky design may become safe enough after sensitive data or automatic
actions are removed. The fit check records the current path and the events that
must trigger another check.

The path is a recommendation the kit is honest about, not a barrier. Where a
sensitive area survives redesign, the person gets a risk notice naming who is
exposed and what would normally prevent the harm, and then decides. They can
accept it and have the work built, or take the flagged thing out of scope. A
gate somebody cannot get past and cannot understand is worse than one they
knowingly walked through, because the first gets worked around by starting
again somewhere with no gate at all.

What holds is the notice rather than the outcome. Naming an area as sensitive
is the agent's own judgement; dropping its caution needs the person's plain
acceptance, recorded with a date and a reason in the build-path section, and
the area stays named because the exposure is still there. The agent may not
withdraw a notice under pressure, and may not satisfy a named control by
appointing itself, because a warning that survives only while the person agrees
with it is not a control at all.

Controls fall into three groups. Some are always required because they are cheap
and prevent common harm: secrets stay out of code, destructive actions stop for
approval, and the user confirms promised behaviour. Some are triggered by the
path or the change: automated tests, pull requests, independent review, restored
backups. The rest are the cautions a sensitive area carries, done before the
area goes live or accepted on the record, and where a caution is a person, no
session stands in for them.

## What the person still has to learn

No coding knowledge is required, and zero learning is not the promise. The
person must learn to describe behaviour, judge evidence, understand where data
and secrets live, and recognise when the project needs another kind of help.
The kit teaches those things at the moment they matter and hides the engineering
machinery beneath them.

## What this is not

It is not a way to learn programming. It does not assume the person is an
engineer, and it does not need them to be one. The kit is shaped first for
internal tools. It may also be used to define, prototype, and accept externally
used software, and the fit check names what that touches before launch, not
after the system has acquired users. It does not replace a developer where one
is wanted. It is at its best when it can say precisely which one area needs
another pair of eyes, and hand that area over with nothing lost, which is an
odd thing for a tool to be proud of and is the point anyway.

It also holds nothing that needs a service somebody else runs: no hosted
scanning, no remote browser testing, no production monitoring, no vulnerability
feed, no stored assurance records, no trust badges, no compliance dashboard, no
expert marketplace, and nothing that compares one project against another.

Each of those needs a person to run it, watch it and pay for it. A workflow that
installs into a folder cannot provide any of them honestly, and a kit that
pretended otherwise would be making exactly the kind of unbacked claim it exists
to stop. Where a project genuinely needs one, the fit check says so and names
it as a caution, in the same way it names a person who has to look.

That line is about who runs a thing, not about what the kit is allowed to look
at. The kit reads the work it produced and reports in plain words, and it may get
better at that over time. What it will not do is claim there is a service behind
it.

The one exception is a recipe: one build stack paired with one place to run it.
A recipe names services somebody else runs, because the person's tool will run
on them. The kit still runs none of them, and the person holds the accounts. What
the kit holds is a written account of how that pair handles the eight things a
live tool needs, from preview to health, each with a way to check it, and the
record of one real run that proved it. A service a tool runs on, meaning its
hosting, its data or its deploy, is named inside recipe files and the README,
and nowhere else in the kit.

## Deciding what to add

New techniques appear constantly: repositories, articles, tool features, client
requests. Most are written by engineers for engineers, and most fail here for the
same reason. This is the test.

Answer all five questions in writing before adding anything. If you cannot answer
all five, do not add it.

1. **Does it fit under one of the commands?** The vocabulary stays small. A new
   capability arrives as behaviour of an existing command, and a new command is
   a rare, deliberate redesign rather than the default answer.

2. **What does the person actually see, and when?** Name the concrete thing on
   their screen and the moment it appears. If the honest answer is "nothing",
   that is fine and often ideal; it means the feature improves quality invisibly.

3. **Can it be taught in one sentence, at the moment it first appears?** If it
   needs a paragraph, a diagram, or a manual, it is the wrong feature or the
   wrong version of it.

4. **What does the person do when it goes wrong?** Stated as an action they can
   take without reading anything technical. "Type /fix" is an answer. "Check the
   logs" is not.

5. **What can they never need to learn?** Name it explicitly. That is the value
   of the feature, so it should be easy to state.

Every capability that passes the five questions must also declare where it
applies: always, only on named build paths or changes, or only inside a named
sensitive area. A rule with no activation boundary becomes universal ceremony.

Two more rules for the ones that pass. The system sorts things for the person
rather than handing them raw judgement: where it can classify (which kind of work
a request is, which findings should block a merge, which pieces a run can safely
take), it classifies, and hands over a decision the person can actually make. A
list of ten findings with "you decide" looks respectful and is not.

And the story gets told in three places or it is not finished. WORKFLOW.md
carries the plain explanation, the skill carries the line the agent says out loud
at the moment it matters, and the thing on screen carries the rest. A feature
that lives in the machinery but is missing from one of those is one the person
cannot use.

### Worked examples

Automatic tests on every pull request, added. It fits under /implement. The person
sees a green tick or a red cross beside the merge button. The sentence is "green
means the tests really passed; red means don't merge". When it is red they type
/fix. They never need to know GitHub Actions exists.

Review reports split into "worth stopping for" and "worth knowing", added. The
same findings as before, sorted, so the decision becomes one question: is the
first list empty?

`/queue`, the whole ready list at once, added as a ninth command. It failed
question 1 under every existing command, which is the answer that mattered:
`/what-now` was doing orientation and overview at once, and the cap that keeps
orientation usable is what squeezed the overview out. The person sees two lists
when they type it, what can be built together now and what is waiting on what.
The sentence is "it shows everything ready to build at once, and what is waiting
on what". When the list looks wrong they type it again, since it is printed from
the issues and never edited. They never need to learn that a piece can depend on
another piece.

Specialised agent role systems, rejected. Fails question 1, because each role is
a new thing to know, and question 3, because there is no one-sentence version.

Architecture decision records, rejected repeatedly. Fails question 2: the person
never reads them, and even the repositories that ship them admit their agents
barely use them.

Parallel agents on separate worktrees, rejected. Fails question 4, because when
something goes wrong the recovery involves git states the person should never
have to untangle.

Tight bug reproduction before a fix, added. It fits under /fix; the user sees
the exact failing case and the evidence that it stopped failing; they never
need to learn instrumentation or bisection.

Disposable decision prototype, added. It fits under /setup-ai-build-kit or /shape;
the user tries a rough artifact to settle one question. What they get is chosen
by the question: one file they open and drive themselves when the question is
whether something behaves right, or three genuinely different arrangements to
move between when the question is what shape it should take. When it is the
wrong thing, they say so and the question gets split. They never need to
understand prototype branches or throwaway architecture.

A piece written in two layers, added. It fits under /shape and /implement. The
person sees a plain surface that stays comprehensive about anything affecting the
product, so a simple read is never a false one; the build detail sits in a
collapsed "under the hood" section they never have to open. The sentence is "you
read the plain part; the agent reads the rest". When it goes wrong, the surface
missed something that changed a product decision, and /shape puts it back on the
surface. They never need to read the build notes, but nothing that affects their
product is hidden from them. This answers the question a workshop raised: a ready
piece must carry enough to build without fresh research, which matters most when
/implement runs a batch with nobody watching. Context that reaches past one piece
is not duplicated onto it: a whole-product decision lives in the masterplan, a
whole-codebase convention in AGENTS.md, so each concept keeps one home.

Universal test-first, rejected. Every promised behaviour needs evidence, but
the evidence may be an automated test, a manual visual check, a source-backed
fact, or a rehearsed recovery depending on the claim. Where a machine can check
the claim, that check comes first and must pass; the other three are for the
claims a machine cannot judge, not a way around one it could.

A wiki, rejected. Each file under `docs/` owns one concept and sits beside the
source it describes. A wiki would carry the record away from the work it must
stay true to, and give one concept two homes. This is today's position rather
than a permanent ban; a later cycle may revisit it.

Sub-issues for a piece made of parts, added. GitHub already models a
parent/child relationship, so the kit uses it rather than inventing one. It fits
under /shape, which splits a piece too big to hold whole, and under /implement,
which builds the parts and lets the parent close on its own. The person sees a
piece that is "made of parts", nothing more. The line that keeps it from becoming
a second way to be blocked is the outcome: a part shares the parent's outcome,
while a blocked-by piece is a different outcome that must come first. Without that
line, a piece would have two kinds of not-ready and /implement would not know
which it was looking at, which is the mistake an earlier investigation warned about.

Recipes, added. A recipe pairs a build stack with a place to run it, and for
each part of a launch it says how that part is checked and who runs the check:
the kit, a companion or the person with the result read back, or a person
looking. It fits under /setup-ai-build-kit, which offers a short menu with one
recommended, and under /ship, which works through the recipe's checks. The person sees the menu once, at
founding, and after that a launch that says what it checked. The sentence is
"this is a stack the kit has run for real, so it can check your launch as well
as warn about it". When a check fails they type /fix. A person who wants their
own stack says so, and the kit carries on with fewer promises.

They never need to learn how the place they run on does a rollback or where its
backups live, because the recipe carries that. It applies only to a project
that chose a recipe. On its own stack a project gets the general checks, and
those are warnings too: a check not done is said once and written in the
changelog, and the launch goes ahead. The one thing /ship waits for is the
address, since a tool with no recorded address is not live. Recipes make the
kit bigger, and that should be said plainly. What they take away is the
question /ship used to put to every project, how a backup, a rollback and a
restore would work, which a person on a recipe no longer has to invent. The menu
stays short because a pair joins it only after a real run.

## Keeping it honest

When a release is cut, run the five questions over what is already here. Anything
that now fails a question it used to pass has drifted, usually by accumulating
explanation rather than by gaining features. That is the maintenance list, and
MAINTAINING.md carries the same instruction so it has a place to actually happen.

The kit should get smaller as often as it gets bigger. When it does not,
something went in that should have been shaped differently or left out.
