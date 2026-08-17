# PHILOSOPHY.md: why this kit exists and what belongs in it

Why the kit is shaped the way it is, who it is for, and how to decide what
belongs. Read this before adding anything.

## The problem

Capable, motivated people can suddenly produce software, without the process that
keeps it reliable or the judgement about when to stop and get help. The result
demos beautifully on a Tuesday and cannot be changed by anyone six weeks later,
including the person who built it.

The steps that close that gap are the ones the README opens with. This kit is
those steps, packaged so they can be used by people who will never read the code
they produce.

## Who it is for

Someone smart and business-savvy who wants a tool their team needs, is
comfortable with ChatGPT or Claude as a chat window, and knows essentially
nothing about software development. They are not learning to code and have no
plans to. That's a legitimate position, and this kit is built around it. What they
build is internal, and the README's fit section says which projects qualify.

Solo here means without professional developers, so a team of five is as much the
audience as a team of one. Technical people are welcome, and the skills
themselves are plain markdown they can extend, though the kit is not shaped
for them.

The audience settles every argument below. When a choice comes up, the question
is always what this person can do, what they can see, and what they can safely
never learn.

The kit optimises for the least process that materially reduces failure for the
project's current consequences, complexity, and ownership burden. A control
may be always required, activated only when a risk appears, or left to a
professional. More process is not automatically better; process earns its
place by changing an outcome the user can understand.

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

The vocabulary never grows. Seven commands, named after the moments a person
actually reaches for them. Every new capability arrives as behaviour of an
existing command. A capability that genuinely needs its own command is a sign the shape
is wrong, and that is a redesign conversation rather than an addition.

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
whenever a project changes character, decides how much care applies and when a
professional should be involved, up to and including "have this built for you,
and here is the brief". Being told at the start what you would otherwise discover
at launch is the most valuable thing here.

## Rigour follows the project

The same workflow must not treat a private experiment and a business-critical
internal system as if they carry the same consequences. Every project has one
build path: explore privately, build and run it, build with expert help, or
professional-led. The path decides which checks, reviews, saving steps, and
launch conditions apply.

The path can move in either direction. A prototype may become an operational
tool. A risky design may become safe enough after sensitive data or automatic
actions are removed. The fit check records the current path and the events that
must trigger another check.

The path is a recommendation the kit is honest about, not a barrier. Where a
risk survives redesign, the person gets a risk notice naming who is exposed and
what a professional would normally do, and then decides. They can accept it and
have the work built, or take the flagged thing out of scope. A gate somebody
cannot get past and cannot understand is worse than one they knowingly walked
through, because the first gets worked around by starting again somewhere with
no gate at all.

What holds is the notice rather than the outcome. Moving toward more care is the
agent's own judgement; moving toward less needs the person's plain acceptance,
recorded with a date and a reason in the build-path section. The agent may not
withdraw a notice under pressure, and may not satisfy a named control by
appointing itself, because a warning that survives only while the person agrees
with it is not a control at all.

Controls fall into three groups. Some are always required because they are cheap
and prevent common harm: secrets stay out of code, destructive actions stop for
approval, and the user confirms promised behaviour. Some are triggered by the
path or the change: automated tests, pull requests, independent review, restored
backups. The rest belong to professionals: regulated systems, high-consequence
automation, or technical ownership the team cannot safely carry.

## What the person still has to learn

No coding knowledge is required, and zero learning is not the promise. The
person must learn to describe behaviour, judge evidence, understand where data
and secrets live, and recognise when the project needs another kind of help.
The kit teaches those things at the moment they matter and hides the engineering
machinery beneath them.

## What this is not

It is not a way to learn programming, and it does not pretend the person is an
engineer. The kit is shaped first for internal tools. It may also be used to
define, prototype, and accept externally used software, but the production
build path may require expert help or professional ownership. The fit check
decides that boundary before launch, not after the system has acquired users.
It does not replace professional developers. It is at its best when it tells you precisely which few
hours of one to purchase, which is an odd thing for a tool to be proud of and is
the point anyway.

## Deciding what to add

New techniques appear constantly: repositories, articles, tool features, client
requests. Most are written by engineers for engineers, and most fail here for the
same reason. This is the test.

Answer all five questions in writing before adding anything. If you cannot answer
all five, do not add it.

1. **Does it fit under one of the seven commands?** The vocabulary stays at seven. A
   new capability arrives as behaviour of an existing command.

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
applies: always, only on named build paths or changes, or only as part of
professional involvement. A rule with no activation boundary becomes universal
ceremony.

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

Automatic tests on every pull request, added. It fits under /build. The person
sees a green tick or a red cross beside the merge button. The sentence is "green
means the tests really passed; red means don't merge". When it is red they type
/fix. They never need to know GitHub Actions exists.

Review reports split into "worth stopping for" and "worth knowing", added. The
same findings as before, sorted, so the decision becomes one question: is the
first list empty?

Specialised agent role systems, rejected. Fails question 1, because each role is
a new thing to know, and question 3, because there is no one-sentence version.

Architecture decision records, rejected repeatedly. Fails question 2: the person
never reads them, and even the repositories that ship them admit their agents
barely use them.

Parallel agents on separate worktrees, rejected. Fails question 4, because when
something goes wrong the recovery involves git states a non-developer cannot
judge.

Tight bug reproduction before a fix, added. It fits under /fix; the user sees
the exact failing case and the evidence that it stopped failing; they never
need to learn instrumentation or bisection.

Disposable decision prototype, added. It fits under /start or /build; the user
tries a rough artifact to settle one question; they never need to understand
prototype branches or throwaway architecture.

Architecture command, rejected. Architecture judgement may guide the agent
internally, but a new command and vocabulary do not improve the user's
decision.

Universal pull requests, rejected. Pull requests are required when shared or
consequential work benefits from the checkpoint, not for every private visual
experiment.

Universal test-first, rejected. Every promised behaviour needs evidence, but
the evidence may be an automated test, a manual visual check, a source-backed
fact, or a rehearsed recovery depending on the claim.

## Keeping it honest

When a release is cut, run the five questions over what is already here. Anything
that now fails a question it used to pass has drifted, usually by accumulating
explanation rather than by gaining features. That is the maintenance list, and
MAINTAINING.md carries the same instruction so it has a place to actually happen.

The kit should get smaller as often as it gets bigger. When it does not,
something went in that should have been shaped differently or left out.
