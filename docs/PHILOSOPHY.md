# PHILOSOPHY.md: why this kit exists and what belongs in it

Read this before you add to the kit, change what a command does, or cut
something. It says what the kit is for, who it serves, and the test every rule
has to pass.

## The goal

The kit exists to push back the limit on what people who do not write code
can do with software on their own. It is measured by how far a person gets
with four things, without reading code and without moving into an
app-building platform:

- **Build**: turn an idea into a working, tested tool rather than a prototype.
- **Customise**: keep changing the tool safely after it exists.
- **Own**: keep the tool in accounts they or their organisation control.
- **Maintain**: come back months later and keep it healthy.

Every part of the kit serves one or more of these. A rule that stops a person
without protecting one of them makes the kit worse. Over-caution counts as a
failure, as unsafe action does, because both leave the person less able to do
the work themselves.

## The problem

People who do not write code can now get a working tool out of a coding agent
in an afternoon. Most of those tools are prototypes. They demo well, and six
weeks later nobody can change them safely, nobody knows where the data lives,
and nobody decided what happens when they break.

The usual answers each give something up. A hosted app builder is fast, but
the tool lives inside the platform and on its terms. A developer's skill kit
makes the work reliable, but it expects you to read code. The kit sits between
them: the speed of an agent, with a harness that lets a person who cannot read
the code still trust it, change it and keep it.

## Who it is for

The kit is for someone who is comfortable with technology and does not write
code: a team lead, an operations person, an analyst, a product manager, a
founder. They can create accounts and follow setup steps, and they want a tool
that still works next quarter. A developer new to agent-led work fits too.

They learn these ideas, at the moment each one first appears:

1. Accounts: GitHub, a host, and a database service, created once.
2. A repository: where the project and its history live.
3. Issues: tasks they agree to do, kept with the project on GitHub.
4. A pull request: a proposed change. They try it, then approve its merge.
5. Going live: after a merge, the host puts the change in front of users.

The kit is not for someone who wants an app in ten minutes and never wants to
see GitHub. A hosted builder serves them better.

## What people build with it

Most small firms run their processes on spreadsheets and email, not on a
product. The kit is at its best on three kinds of tool:

1. A tool that replaces a fragile spreadsheet or email process: approvals lost
   in threads, clashing copies of a sheet, no record of who changed what.
2. A tool built around a product the firm keeps: a reporting view across its
   systems, a narrow portal, an intake or approval form that writes back to the
   accounting system or CRM. The bought product keeps the records; the firm's
   tool does what the product will not.
3. A custom tool where the products fit badly: the per-seat bill grows with
   every hire, the firm pays for a suite to use one part, staff work around the
   product with side spreadsheets, the process is what sets the firm apart, or
   the data must stay inside the firm's own cloud account.

Some needs are better bought: payroll, tax and statutory records, moving money,
work that needs a formal certification, systems the business cannot run
without overnight, and standard processes a mainstream product already fits.
When a request has that shape, the kit says so once, in plain words, and the
person decides.

Every tool needs someone who owns it. Software without an owner decays, so the
kit asks "who owns this, and who takes over?" at the start, while the answer
can still shape the tool.

The focus is tools with access for people the owner names, such as a team or
invited clients. The proven stack keeps each tool private by default. A recipe
check is meant to show that only invited people can get in. Neither recipe's
access step has had a real run yet. Public-facing features are possible: the
person asks for that setting, the agent reports its risks once, and the person
records the choice. A tool that takes money from strangers is a public tool.

## What ownership means

The tool belongs to the person from the first day. The code is in their
repository, it runs on their host account, and the data is in their database
account. They can change coding agent, host, or developer later and lose
nothing.

Ownership is about control rather than location: the tool runs in accounts
the person or their organisation controls, on a
well-known stack that any developer can pick up, on the infrastructure their
situation calls for. A firm that works inside Microsoft's cloud should be able
to keep its tool there, with staff signing in through their company accounts.
A firm with no such constraint should be able to choose the simplest host.
Nobody should need an unusual stack to own their software, and the stack the
kit builds on stays deliberately boring for that reason.

## The harness

The kit's design effort goes into the harness: the mechanisms, checks and
loops that make an agent's work trustworthy to a person who cannot read it.
Three ideas run through it.

Recipes make it fast. A recipe pairs a build stack with a place to run it, and
settles in advance how the tool goes live, how it is backed up, and how it
rolls back to an earlier version. A recipe joins the menu only after a
recorded real run, and its record says which parts that run covered.

Mechanisms make it reliable. A rule that a machine can check is a hook, a
setting, or a script. It applies where that hook, setting or script runs.
Prose is kept for the judgements a machine cannot make.

Loops make it improve. A failed check, a repair that took three attempts, or a
review finding is information about the project. Where the kit can turn a
failure into a check that would catch it next time, it should, so the same
fault cannot return unnoticed. A project should become harder to break the
longer the kit works on it.

### The rule that settles arguments

The work never requires reading code. Every acceptance check is something a
person sees or tries, and every report lists what was tried and what happened.
A developer can read every change if they like. The kit never depends on it,
because a process that works only while somebody reads the code stops working
on the day nobody does.

### The backbone

Some promises apply in every project, so they do not depend on what the person
asks for. They are what make it safe to maintain a tool you cannot read. Each
needs an enforcement mechanism and a check that fails if the mechanism is
removed. The
[source repository's mechanism list](https://github.com/gwpicard/ai-build-kit/blob/stable/docs/MAINTAINING.md#the-backbone-and-its-mechanisms)
names each promise's mechanism, or marks it "none yet".

1. A person approves each merge, unless they chose auto-merge with its limits.
2. Nothing goes online without approval.
3. Secrets are never shown.
4. Checks pass before a merge.
5. A review matches the code it read. A review the kit cannot verify is
   recorded as unverified, in plain words.
6. On a proven recipe, `/setup-hosting` requires a confirmed backup and a named
   rollback step before recording a live address. Later runs also require an
   earlier build to return to. This cannot stop a host that deploys on merge.
7. An accepted risk is recorded as "accepted", never as "done".

An integrity check protects the backbone. It can stop the work, and it stops it
even if the person insists, because the person cannot judge from the outside
whether the promise holds. Everything else the person can judge, and the kit
leaves it to them.

A check has more than two outcomes: it passed, failed, did not run, could not
decide, or does not apply. A check that did not run is never shown as a pass.

### The kit builds deployable, shared tools

Every project is a tool that can go live and that a team can share. The kit has
no private-only mode and no throwaway track. A repository with issues switched
on, an agent session that can read and write those issues, and the tools named
by the chosen recipe are conditions of starting. A script checks them and
stops setup when one is missing. Host and database sign-in cannot yet be
checked, so setup reports those as unchecked. The person creates the accounts.
The kit never does.

Hosting follows the same reasoning. The kit offers it only on a proven recipe,
because a recipe is what makes the backbone's hosting promises apply. Outside a
recipe the kit reports plainly that it guarantees nothing, and it still helps.

## Limits, told once

The kit makes people aware of limits and leaves the decision with them. Where
a piece of work touches something that could hurt people, or where a developer
would normally take a look, the kit says so once, in plain words, and the
person decides.

The project carries a short record of what failure would cost: who is exposed
if the tool fails, what data it holds, what a wrong answer does, how the person
recovers, and which named risk areas the project touches. Setup fills it with
three plain questions, and the agent checks it again when the project changes.
The record lives in the masterplan, with a pointer from the project
instructions.

Each piece of work carries a "Risk areas" field. A piece with no risk area gets
no notice. A piece with one gets a notice once: who is exposed, and what would
normally prevent the harm. The person can have that caution done, remove the
work from the piece, or carry on. If they carry on, the kit records their
acceptance with the date and their words and continues the current command.
Acceptance clears that caution; it does not itself start building. Shaping
finishes with a ready piece, and building waits for `/implement`. The kit does
not ask for the same acceptance again.

Two limits apply whatever the person says. The kit does not withdraw a notice
because somebody pushes back. And where a caution names a person, such as a
reviewer who knows the law, no agent session stands in for them. A run with
nobody present stops at a risk area and never accepts on the person's behalf.

An impassable or confusing gate can be worse than one people understand and
accept: they may work around it by starting somewhere with no gate.

## Small is a reliability feature

The kit should be as small as it can be while it remains reliable. Every
sentence in a skill competes for the agent's attention, and an agent given more
rules skips some of them, and nobody can say in advance which. So a rule that
is not pulling its weight is not harmless. It makes the rules that matter less
likely to be followed.

Small also means fewer commands. Six commands, each named after a moment a
person reaches for. A new capability is new behaviour of an existing command.
A new command is a redesign, and so is a cut.

Small means the person can understand what protects them: a handful of things
are always enforced, and the rest is a short conversation.

## What earns a place

A rule earns its place in a skill only if it passes one of these:

1. A machine enforces it. Then it lives in a hook, a setting, or a script,
   and the skill says at most one line about it.
2. A measurement shows it changes the outcome: a replay with the rule
   behaves better than a replay without it.
3. It carries a judgement that only a person or the agent can make, such as
   whether a request is clear, whether a risk is present, or how to say it to
   the person.

A rule that came from one failed run is a hypothesis. It stays only once a
measurement backs it.

Every capability that passes also answers these, in writing:

- Which of build, customise, own and maintain does it extend, or protect?
- What does the person see, and when?
- Can it be said in one sentence at that moment?
- What does the person do when it goes wrong, without reading anything
  technical?
- Where does it apply: always, or only to a piece that touches a named risk
  area?

A capability with no answer to the first question does not belong. One with no
answer to the last becomes ceremony for everybody.

## Testing the kit

A test checks an outcome, never a sentence. A test that greps a skill for a
phrase proves the phrase is there. It does not prove the agent does the thing,
and it makes the prose harder to cut. Those tests do not belong here.

Two kinds of test do:

- Boundary checks in shell: what ships, what gets written, what a script
  decides, what a hook blocks. These run in seconds and fail loudly.
- Replays: a whole conversation in a throwaway project, graded on what the
  agent did and on what it left on disk. The result is a rate over several
  runs, and the rate is the measure of reliability.

A cut that keeps the replay rate is a good cut. A cut that lowers it comes
back, or the rule moves into a mechanism.

Most tests today measure restraint: whether the kit waited, warned and kept to
scope. They also need to measure reach: how far a person gets, whether a
finished tool can still be changed, whether it can move host, and whether a
person returning months later can bring it back to health. A kit that refused
everything would pass a test of restraint alone.

The kit rests on a claim that has not yet been proven: that a harness lets a
person who does not read code own and maintain software over years. No study
yet follows tools built this way over that span. The kit treats the claim as
something to measure, and says so.

## What the kit does not do

It is not a way to learn programming, and it does not replace a developer
where one is needed. It is at its best when it can say exactly which area needs
another pair of eyes, and hand that area over with nothing lost.

It runs no service of its own: no hosted scanning, no monitoring, no
dashboards, no stored records anywhere but the person's project. A kit that
installs into a folder cannot run those honestly, and claiming otherwise is the
kind of unbacked claim it exists to stop. Where a project needs one, the fit
check names it as a caution.

`/maintain` checks the project's setup and records, and offers the upkeep that
is due. It cannot repair badly written code.

For the rule on service names, see [Keep it generic](https://github.com/gwpicard/ai-build-kit/blob/stable/docs/MAINTAINING.md#keep-it-generic).

## Where the kit is heading

These directions are decided and not yet built. Each lands as its own piece of
work, and moves into the sections above once a check or a real run backs it.

- One build stack that runs on every common host: a TypeScript web app on plain
  Postgres, with sign-in, permissions, scheduled work and file handling inside
  the tool and reached through standard interfaces. A hosted database service
  becomes one choice of database, not the platform.
- Sign-in through a company's own Microsoft or Google accounts as a standard,
  tested option, locked to that company's directory and proved by a test that
  an outside account is refused.
- A separate host kit that reads a checked handover file from the project and
  puts the tool on the infrastructure the person chooses, including the major
  clouds and a rented server. The masterplan's hosting section is generated from
  that file.
- A short guided choice of host, based on the person's IT constraints and the
  work the tool does, in place of one default.
- A readiness check that confirms everything the person needs is installed,
  and help that explains each trade-off in a sentence.
- A named owner and successor for every tool, an update routine that proposes
  security and dependency updates in plain words, and a step for retiring a
  tool that exports its data.

## Keeping it honest

At each release, read every skill against "What earns a place". Anything that
no longer passes comes out. The kit should get smaller as often as it gets
bigger.
