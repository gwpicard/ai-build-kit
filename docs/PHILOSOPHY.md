# PHILOSOPHY.md: why this kit exists and what belongs in it

Read this before you add to the kit, change what a command does, or cut
something. It says who the kit is for, what makes it different, and the test
every rule has to pass.

## The problem

People who do not write code can now get a working tool out of a coding agent
in an afternoon. Most of those tools are prototypes. They demo well, and six
weeks later nobody can change them safely, nobody knows where the data lives,
and nobody decided what happens when they break.

The usual answers each give something up. A hosted app builder is fast, but
the tool lives inside the platform and on its terms. A developer's skill kit
makes the work reliable, but it expects you to read code. The kit sits between
them.

## What the kit is

The kit takes an idea to a real tool without asking the person to read code.

On the road you build fast, without reading code, and the result is real
software in your own accounts. Three things carry it.

Recipes make it fast. A recipe pairs a build stack with a place to run it,
and settles in advance how the tool goes live, how it is backed up, and how it
rolls back to an earlier version. A recipe joins the menu only after a recorded
real run, and its record says which parts that run covered. The person does not make those decisions, so they cannot get them
wrong.

Mechanisms make it reliable. A rule that a machine can check is a hook, a
setting, or a script. It holds on every model and every coding agent, and it
costs no words. Prose is kept for the judgements a machine cannot make.

Risk boundaries keep it honest. At the start, and again when the project
changes, the kit names anything that could hurt people: personal data, money,
sign-in, automatic actions, data that cannot be replaced, a regulated decision.
The person hears the risk once, in plain words, and decides. Their decision is
recorded with their words and the date.

The tool belongs to the person from the first day. The code is in their
repository, it runs on their host account, and the data is in their database
account. They can change coding agent, host, or developer later and lose
nothing.

## Who it is for

The kit is for someone who is comfortable with technology and does not write
code: a team lead, an operations person, an analyst, a product manager, a
founder. They can create accounts and follow setup steps, and they want a tool
that still works next quarter. A developer new to agent-led work fits too.

They learn these ideas, at the moment each one first appears:

1. Accounts: GitHub, a host, and a database service, created once.
2. A repository: where the project and its history live.
3. Issues: tasks they agree to do, kept with the project on GitHub.
4. A pull request: a proposed change. They try it, then say yes to merge it.
5. Going live: after a merge, the host puts the change in front of users.

The focus is a simple way to build and run internal tools, with access for
people the owner names, such as a team, a club, a family or invited clients.
The proven stack keeps each tool private by default. A recipe check is meant
to show that only invited people can get in. Neither recipe's access step has
had a real run yet. Public-facing features are possible. The
person asks for that setting, hears its risks once, and records the choice. A
tool that takes money from strangers is a public tool.

The kit is not for someone who wants an app in ten minutes and never wants to
see GitHub. A hosted builder serves them better.

## The rule that settles arguments

The work never requires reading code. Every check is something a person sees
or tries, and every report says what was tried and what happened. A developer
can read every change if they like. The kit never depends on it, because a
process that works only while somebody reads the code stops working on the day
nobody does.

## Small is a reliability feature

The kit should be as small as it can be while it still holds. Every sentence
in a skill competes for the agent's attention, and an agent given more rules
skips some of them, and nobody can say in advance which. So a rule that is not
pulling its weight is not harmless. It makes the rules that matter less likely
to be followed.

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
3. It carries a judgement that only a person or the agent can make, such as whether a
   request is clear, whether a risk is present, or how to say it to the person.

A rule that came from one failed run is a hypothesis. It stays only once a
measurement backs it.

Every capability that passes also answers these, in writing:

- What does the person see, and when?
- Can it be said in one sentence at that moment?
- What does the person do when it goes wrong, without reading anything
  technical?
- Where does it apply: always, or only to a piece that touches a named risk
  area?

A capability with no answer to the last question becomes ceremony for
everybody.

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

## The kit builds deployable, shared tools

Every project is a tool that can go live and that a team can share. The kit has
no private-only mode and no throwaway track. A repository, issues switched on,
an agent session that can read and write those issues, and access to the host
and the database are conditions of starting, and a script checks them. If one
is missing, setup stops and says which step to take. The person creates the
accounts. The kit never does.

Hosting follows the same reasoning. The kit offers it only on a proven recipe,
because a recipe is what makes the guarantees below hold. Outside a recipe the
kit says plainly that it guarantees nothing, and it still helps.

## The backbone

Some promises hold in every project, so they do not depend on what the person
asks for. Each one needs a mechanism, which is a machine that makes it true,
and a check that fails when the mechanism is removed. `docs/MAINTAINING.md`
lists each promise with its mechanism, or says "none yet".

1. A person approves each merge, unless they chose auto-merge with its limits.
2. Nothing goes online without a yes.
3. Secrets are never shown.
4. Checks pass before a merge.
5. A review matches the code it read. A review the kit cannot verify is
   recorded as unverified, in plain words.
6. On a proven recipe, every launch has a way back and a backup.
7. Records say "accepted", never "done".

Two kinds of check follow from this. An integrity check protects the backbone.
It can stop the work, and it stops it even if the person insists, because the
person cannot judge from the outside whether it holds. A judgement risk is
different. It belongs to one piece of work, and the person is the one who can
judge it. The kit warns once, and the person decides.

A check has more than two outcomes. It passed, it failed, it did not run, it
could not decide, or it does not apply. A check that did not run is never shown
as a pass.

## The risk concept

The project carries a short record of what failure would cost. It holds who is
exposed if the tool fails, what data it holds, what a wrong answer does, how the
person recovers, and which named risk areas the project touches. Setup asks
three plain questions to fill it. They are: who is exposed if this fails, what
data does it hold, and how would you recover from a failure. The record lives
in the masterplan, with a pointer from the project instructions. The agent
writes it with the person at setup and checks it again when the project
changes.

Each piece of work then carries a "Risk areas" field, naming the areas it
touches. A piece with no area gets no notice. A piece with one gets the notice
once.

## Warn, then respect the decision

Where the person can judge a risk, the kit warns and does not block. A step
they could skip is offered with what it costs, once.

For a risk area the kit gives a risk notice: who is exposed, and what would
normally prevent the harm. The person can have that caution done, take the work
out, or carry on. If they carry on, the kit records their acceptance with the
date and their words, and builds. The area stays named, because the exposure is
still there. After the acceptance the kit does not refuse, ask again, or hold
the work back.

Two limits hold whatever the person says. The kit does not withdraw a notice
because somebody pushes back. And where a caution names a person, such as a
reviewer who knows the law, no agent session stands in for them. A run with
nobody present stops at a risk area and never accepts on the person's behalf.

A gate that nobody can get past or understand is worse than one they walked
through knowingly, because people work around the first by starting again
somewhere with no gate at all.

## What the kit does not do

It is not a way to learn programming, and it does not replace a developer
where one is needed. It is at its best when it can say exactly which area needs
another pair of eyes, and hand that area over with nothing lost.

It runs no service of its own: no hosted scanning, no monitoring, no
dashboards, no stored records anywhere but the person's project. A kit that
installs into a folder cannot run those honestly, and claiming otherwise is the
kind of unbacked claim it exists to stop. Where a project needs one, the fit
check names it as a caution.

`/maintain` is the reset. It brings the project's kit setup back to the kit's
defaults and gives the next session a fresh starting point. It cannot repair
badly written code.

A recipe is the one place that names services somebody else runs, because the
person's tool will run on them. The kit still runs none of them, and the person
holds the accounts. A hosting, data or deploy service is named in recipe files
and the README, and nowhere else.

## Keeping it honest

At each release, read every skill against "What earns a place". Anything that
no longer passes comes out. The kit should get smaller as often as it gets
bigger, and its size in words is reported with each release beside its replay
rates.
