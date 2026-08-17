# The fit check

The fit check chooses the project's current **build path** and names the
condition for outside help, if any. It runs:

- during /start;
- when a request changes users, data, money, autonomy, promises, or reliance;
- before the first /ship;
- during quarterly /maintain;
- before a handover.

## Consequence questions

Ask one at a time, with a best guess attached.

1. Will anyone outside the team sign in or rely on it?
2. Will real money move through it or be calculated for real decisions?
3. Does a contract, client promise, uptime expectation, or deadline depend on
   it?
4. Will it hold personal or sensitive data beyond ordinary work contact
   details?
5. Does it give or enforce regulated, legal, medical, financial, employment,
   or safety-related decisions?
6. Will it begin on data the team cannot afford to lose or corrupt?
7. Will it act automatically on another system, send consequential messages,
   change records, or do anything difficult to reverse?
8. If it stops or gives a wrong answer, does important work stop or
   meaningful harm follow?

## Ownership questions

9. Is there a manual fallback?
10. Can the team explain the main flows and permissions without reading code?
11. Can the team identify where data, credentials, service ownership, and
    bills live?
12. Is there a named person responsible for alerts, backups, access, and
    recovery?
13. Is the system still simple enough that a new agent could understand it
    from the records alone?
14. Are integrations, background jobs, permissions, and migrations limited
    enough for the team to operate confidently?

## Decision order

Use the first matching outcome after redesign has been considered.

### 1. Professional-led

Choose when a professional-led trigger is central to the production system and
cannot be removed or isolated through redesign.

Examples:

- regulated or high-consequence decisions are central;
- irreplaceable live data cannot be isolated;
- high-harm autonomous action is central;
- the team cannot safely operate or recover the system;
- the production promise requires technical ownership the team cannot carry.

### 2. Build with expert help

Choose when a professional trigger exists in a named, bounded area, while the
team can still understand, operate, and recover the rest.

Professional ownership of one integration or risky area belongs here.
Professional leadership of the production system belongs under
Professional-led.

### 3. Build and run it

Choose when people rely on the tool, but the consequences remain limited and
recoverable, the manual fallback is real, and ownership is clear.

### 4. Explore privately

Choose only when nobody relies on it, data is disposable, actions are
reversible, and the work exists to answer questions or learn.

## The four build paths

Use these four names everywhere. Do not alternate between path, tier, level,
mode, verdict, or maturity class.

### Explore privately

Choose when:

- nobody depends on it;
- data is disposable;
- no consequential automatic actions exist;
- it is being used to answer questions or learn.

### Build and run it

Choose when:

- it is mainly internal;
- consequences are limited and recoverable;
- fallback and ownership are clear;
- the team can explain and operate it;
- no professional trigger applies.

This is the kit's primary target path.

### Build with expert help

Choose when one or more named areas require expertise but the team can still
own the rest.

Typical triggers:

- outside users;
- real money;
- sensitive data;
- complex permissions;
- operational criticality;
- autonomous actions;
- difficult live-data change;
- several integrations or background processes;
- repeated failure in one technical area.

The output must name the exact help level (advice, scoped review, supervised
change, or professional ownership) and scope.

### Professional-led

Choose when:

- regulation or high-consequence decisions are central;
- irreplaceable live data cannot first be isolated or copied;
- high-harm autonomous behaviour is central;
- a contract requires technical operational ownership;
- the team cannot explain, recover, or operate the system;
- complexity and consequence cannot be reduced enough by redesign.

## Redesign before the notice

Before settling on build with expert help or professional-led, ask whether the
risk can be removed:

- use a copy instead of live data;
- remove automated action;
- keep a human approval step;
- remove regulated advice;
- reduce external access;
- use a managed service;
- keep a manual fallback;
- narrow the promise.

A redesign that genuinely removes a trigger changes the answers, so run the
check again. A redesign that keeps the surface and drops the control does not.
Managed sign-in removes stored passwords, and outside users can still sign in,
so the access review stands.

## The risk notice

The kit refuses nothing. A notice is due only where a trigger from the decision
order survives redesign: a regulated or high-consequence decision, irreplaceable
live data, high-harm autonomous action, a team that cannot operate or recover
the system, or a production promise beyond the team. Say so before that work
goes ahead, on any build path. Work with no surviving trigger gets no notice, no
acceptance, and no recorded exception, whatever its path. Most work on most
projects is like this. Build and run it, the primary path, is defined by no
professional trigger applying, so it usually has nothing to notice.

A notice says five things:

- who is exposed, named as people rather than as a risk;
- what happens to them when it goes wrong;
- what would normally prevent that;
- the two things the person can do, which are to accept it on the record or to
  take the flagged thing out of scope;
- that you flag what you can recognise and will miss things.

"This is risky" is not a notice. Naming a cost, a delay, or a rule of the kit's
own is not a notice either. Say who gets hurt.

A trigger is exposure from the decision order, not any imperfection you can
imagine somebody being annoyed by. A booking that vanishes with no record, a
colleague who has to walk to a room, a whiteboard replacement with no audit
trail, a stack choice, a save that stays on one machine, an integration not
connected yet: these are design points, not exposure. Raise them in ordinary
words in the ordinary place. In a tool for twenty colleagues you can always
picture one of them inconvenienced, and that is not who a notice is for. A notice
given for ordinary work teaches the person to skip notices, and it is paid for by
the one notice that names a real exposure and now looks like all the others.

A notice is about the work you are about to do, not the problem that led to it.
Where the answer to a broken thing is to build a replacement, the notice covers
the replacement. Describing the fault accurately while saying nothing about what
you are proposing to put in its place is the same failure as saying nothing,
and it is harder to spot because it sounds careful.

### The notice holds

Once given, do not soften it, drop it, or recast a named control into something
you can satisfy yourself. An independent review means a reviewer who did not
build the work, and offering to re-read your own work does not meet it however
it is described.

Pushback is not evidence about the risk. Cost, a deadline, the size of the team,
the person's own willingness to be responsible, and what other tools are said to
allow all change what the person decides. None of them changes who is exposed.

Never propose a downgrade and act on it in the same breath. The build path moves
toward more care on your own judgement. It moves toward less only on the
person's plain acceptance.

Restate the notice when the flagged work is actually built, rather than only
when it was first scoped. A session that named a risk an hour ago and has been
arguing since has not given a notice.

### Acceptance

Ask about the named risk and nothing else, and treat the answer to that question
as the acceptance. Three things are not acceptance:

- an instruction to carry on, given in answer to some other question. "Try it
  anyway", "attempt it first", and "just build it" are instructions. They tell
  you what they want, which you already knew, and say nothing about the risk;
- a refusal to pay for help, or to wait;
- the person describing the risk themselves before you have named it. Name it
  yourself and ask again.

Where no notice was due, there is nothing to accept and nothing to record.
Agreement to a plan is not acceptance of a risk. An `Accepted:` line written
against an ordinary decision makes the record meaningless, so do not write one.

A person who has not been told cannot have accepted. When a plain instruction
arrives and no notice has been given, give the notice and put the question. When
one arrives after a notice, and the answer does not engage with what you named,
ask once more in one sentence and take whatever comes back.

An acceptance becomes an `Accepted:` line in the masterplan's build-path
section, described under "Write it down" below. Add the line before the flagged
work starts, not after it lands. Then build what was asked for.

## Full fit check

Run all questions:

- during /start;
- before the first operational /ship;
- quarterly during /maintain;
- before a handover;
- when several project characteristics changed together.

## Delta fit check

For a single change-triggered reassessment:

1. ask the consequence questions affected by the proposed change;
2. recheck manual fallback;
3. recheck named operational ownership;
4. recheck whether the team can still explain and recover the system;
5. apply the decision order;
6. update `Recheck when` and `Last checked`, and add an `Accepted:` line if a
   risk was accepted along the way.

Run the full check instead when the affected area cannot be bounded confidently.

## Write it down

Whatever the outcome, it goes in the masterplan's build path section:

```md
## Build path

Path: <Explore privately | Build and run it | Build with expert help | Professional-led>
Why: <one or two sentences>
Required controls: <only the controls that apply>
Outside help: <none | advice | scoped review | supervised change | professional ownership>, for <scope>
Accepted: <none, or one line per accepted risk>
Recheck when: <specific triggers>
Last checked: YYYY-MM-DD
```

Each accepted risk gets its own line, and lines are added rather than replaced.
A line carries the date, what it drops, and who accepted it:

```md
Accepted: 2026-08-12, independent review of who can see what, declined on cost, accepted by Priya
```

An acceptance can relax the path. Where it does, `Path:` moves and the line says
so:

```md
Accepted: 2026-08-12, professional-led recommendation declined, no clinical sign-off, accepted by Sam, path moved to Build with expert help
```

The agent reads that section first in every session. This half page tells the
whole system how careful to be, and what the project has knowingly given up.
