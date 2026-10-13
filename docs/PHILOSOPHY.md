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

The kit is a paved road from an idea to a real tool. "Paved road" is a term
from platform engineering: a route that someone has already made safe, so the
people who use it do not decide everything again each time.

On the road you build fast, without reading code, and the result is real
software in your own accounts. Three things carry it.

Recipes make it fast. A recipe pairs a build stack with a place to run it,
and settles in advance how the tool goes live, how it is backed up, and how it
rolls back to an earlier version. A recipe joins the menu only after a recorded
real run. The person does not make those decisions, so they cannot get them
wrong.

Mechanisms make it reliable. A rule that a machine can check is a hook, a
setting, or a script. It holds on every model and every coding agent, and it
costs no words. Prose is kept for the judgements a machine cannot make.

Risk boundaries keep it honest. At the start, and again when the project
changes, the kit names anything that could hurt people: personal data, money,
sign-in, automatic actions, data that cannot be replaced, a regulated decision.
The person hears the risk once, in plain words, and decides. Their decision is
recorded with the date.

The tool belongs to the person from the first day. The code is in their
repository, it runs on their host account, and the data is in their database
account. They can change coding agent, host, or developer later and lose
nothing.

## Who it is for

The kit is for someone who is comfortable with technology and does not write
code: a team lead, an operations person, an analyst, a product manager, a
founder. They can create accounts and follow setup steps, and they want a tool
that still works next quarter. A developer new to agent-led work fits too.

They learn four ideas, at the moment each one first appears:

1. Accounts: GitHub, a host, and a database service, created once.
2. A repository: where the project and its history live.
3. A pull request: a proposed change. They try it, then say yes to merge it.
4. Going live: after a merge, the host puts the change in front of users.

The kit is not for someone who wants an app in ten minutes and never wants to
see GitHub. A hosted builder serves them better, and the README says so.

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
- Where does it apply: always, on one build path, or inside one sensitive area?

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

## Rigour follows the project

A private experiment and a tool that handles payroll do not carry the same
consequences, so they do not get the same process. Each project has one build
path:

| Path | When |
|---|---|
| Explore privately | Trying an idea with data you can throw away |
| Build and run it | An internal tool with a manual fallback |
| Build with care | Some of the work touches a sensitive area |

The path decides which checks, reviews, and launch conditions apply. It can
move either way as the project changes. Build with care applies to the named
sensitive areas, and everything outside them is built the ordinary way.

## Warn, then respect the decision

Where the person can judge a risk, the kit warns and does not block. A step
they could skip is offered with what it costs, once.

For a sensitive area the kit gives a risk notice: who is exposed, and what
would normally prevent the harm. The person can have that caution done, take
the work out, or carry on. If they carry on, the kit records their acceptance
with the date and their words, and builds. The area stays named, because the
exposure is still there.

Two limits hold whatever the person says. The kit does not withdraw a notice
because somebody pushes back. And where a caution names a person, such as a
reviewer who knows the law, no agent session stands in for them. A run with
nobody present stops at a sensitive area and never accepts on the person's
behalf.

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

A recipe is the one place that names services somebody else runs, because the
person's tool will run on them. The kit still runs none of them, and the person
holds the accounts. A hosting, data or deploy service is named in recipe files
and the README, and nowhere else.

## Keeping it honest

At each release, read every skill against "What earns a place". Anything that
no longer passes comes out. The kit should get smaller as often as it gets
bigger, and its size in words is reported with each release beside its replay
rates.
