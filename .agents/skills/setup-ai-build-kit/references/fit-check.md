# The fit check

The fit check chooses the project's current **build path** and names each
sensitive area the work touches, with the caution that goes with it. It runs:

- during /setup-ai-build-kit;
- when a request changes users, data, money, autonomy, promises, or reliance;
- before the first /ship;
- during quarterly /maintain;
- before a handover.

## Consequence questions

Ask one at a time, with a best guess attached. These decide the path.

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

These decide setup tasks, never the path. A no to any of them becomes a
founding task: a piece on the plan where there is work to do (write down the
manual fallback, name who reads the alerts), or a line in the masterplan's
"How it stays running" section where there is only a fact to record. Founding
carries on. A team that cannot yet explain or recover its tool has a gap to
close, which is a different thing from work that touches a sensitive area.

## The three build paths

Use these three names everywhere, and do not alternate between path, tier,
level, mode, verdict, or maturity class. Choose the first that matches, after
redesign has been considered.

### 1. Build with care

Some of the work touches a sensitive area: personal or sensitive data, money,
sign-in and permissions, automatic action on people or other systems,
irreplaceable live data, or a regulated decision. A yes to question 1, 2, 4,
5, 6 or 7 that redesign cannot remove puts the project here. The masterplan
names each area in the tool's own words and the caution beside it. Everything
outside those areas is built exactly as Build and run it. Inside one, the
caution is done before merge or activation, or the person accepts on the
record.

### 2. Build and run it

People rely on the tool, no sensitive area is touched, consequences are
limited and recoverable, and the manual fallback is real. A yes to question 3
or 8 lands here rather than above: it says the tool is relied on, not what it
touches, and what it asks for is the operational readiness /ship requires
before first live use. This is the kit's primary target path.

### 3. Explore privately

Nobody relies on it, data is disposable, actions are reversible, and the work
exists to answer questions or learn.

## Sensitive areas

Six areas, fixed. Each carries a default caution, which is what would normally
prevent the harm. The fit check names the area in the tool's own words (the
client notes, the refund button, the nurses' protocol) and writes the caution
beside it. Change a caution only where the tool's own facts make a different
one right, and say why.

| Area | What counts | Default caution |
|---|---|---|
| Personal or sensitive data | Facts about a person beyond ordinary work contact details: health, pay, home address, identity documents, anything a person would mind a colleague reading. | A person who did not build the tool reviews who can see what, before real data goes in. |
| Money | Real money moving through the tool, or figures people act on as if they were the bill. | A managed payment provider holds card details so the tool never sees them, and the owner of the money checks the first real figures against a case they know. |
| Sign-in and permissions | Anyone outside the team signing in, or rules that keep one person's things from another's. | A managed sign-in service so the tool never stores a password, and a person who did not build it reviews who can reach what, before outside users sign in. |
| Automatic action on people or other systems | The tool sends messages, changes records elsewhere, or does anything on its own that is hard to take back. | A person approves each action until a live run has shown it right, and one switch turns it off. |
| Irreplaceable live data | The only copy of something the team cannot recreate. | A backup taken and restored once, and the change rehearsed on a copy, before the original is touched. |
| Regulated decisions | Medical, legal, financial, employment, or safety decisions the tool gives or enforces. | Somebody qualified in that field signs off the rule before anyone acts on it. |

Where a caution is a person, the rule under "The notice holds" applies
unchanged: that person looks, or the risk is accepted on the record. Where a
caution is a backup, a copy, a rehearsal, a managed service, or an approval
step, it is the kit's to do. Do it as part of the work, or check it was done,
and record the result on the area's line. Work inside a named area is flagged
work, and that word keeps its meaning in every skill.

## Redesign before the notice

Before naming a sensitive area, ask whether the risk can be removed:

- use a copy instead of live data;
- remove automated action;
- keep a human approval step;
- remove regulated advice;
- reduce external access;
- use a managed service;
- keep a manual fallback;
- narrow the promise.

A redesign that genuinely removes the area changes the answers, so run the
check again. A redesign that keeps the surface and drops the caution does not.

## The risk notice

The kit refuses nothing. A notice is due only where work touches a sensitive
area that survives redesign and whose caution has not been done: personal or
sensitive data, money, sign-in and permissions, automatic action on people or
other systems, irreplaceable live data, or a regulated decision. Say so before
that work goes ahead, on any build path. Work outside every named area gets no
notice, no acceptance, and no recorded exception, whatever its path. Most work
on most projects is like this. Build and run it, the primary path, is defined
by no sensitive area applying, so it has nothing to notice.

A notice says five things:

- who is exposed, named as people rather than as a risk;
- what happens to them when it goes wrong;
- what would normally prevent that;
- the two things the person can do, which are to accept it on the record or to
  take the flagged thing out of scope;
- that you flag what you can recognise and will miss things.

"This is risky" is not a notice. Naming a cost, a delay, or a rule of the kit's
own is not a notice either. Say who gets hurt.

A sensitive area is exposure from the list above, not any imperfection
somebody might be annoyed by. A vanished booking, a stack choice, a save that
stays on one machine, an integration not connected yet: these are design
points, so raise them in ordinary words in the ordinary place. A notice given
for ordinary work teaches the person to skip notices, which is paid for by the
one that names a real exposure and now looks like all the others.

When the answer to a broken thing is to build a replacement, the notice covers
the replacement, not the fault. Describing the fault accurately while saying
nothing about what replaces it is the same failure as saying nothing.

### The notice holds

Once given, do not soften it, drop it, or recast a named control into something
you can satisfy yourself. Offering to re-read your own work does not meet it
however it is described.

Where the notice names who should look, that is a person: the owner of the thing
at risk, or somebody who does that work for a living. No session meets it. Not a
fresh one, not a clean one, not a separate one, not a subagent, and not the
project's own review method however independent that method is of the builder.
Those exist so that work is not reviewed by the thing that wrote it, which is a
different job from the one a named reviewer was named for, and the two are not
interchangeable because they happen to share the word review.

The kit does not decide it has satisfied this. Either the named person has looked
and that is recorded, or they have not and the person accepts the risk on the
record. Saying an in-project method already covers it is the recast this rule
exists to refuse, and it is the form the recast actually takes: not a refusal to
review, but a redefinition of what the review was.

Pushback is not evidence about the risk. Cost, a deadline, the size of the team,
the person's own willingness to be responsible, and what other tools are said to
allow all change what the person decides. None of them changes who is exposed.

Never propose a relaxation and act on it in the same breath. An area is named
as sensitive on your own judgement. Its caution is dropped only on the
person's plain acceptance.

Restate the notice when the flagged work is actually built, rather than only
when it was first scoped. A session that named a risk an hour ago and has been
arguing since has not given a notice.

### Acceptance

Ask about the named risk and nothing else, and treat the answer to that question
as the acceptance. Three things are not acceptance:

- an instruction to carry on, given in answer to some other question. "Try it
  anyway", "attempt it first", and "just build it" say what they want, not
  whether they accept the named risk;
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
section, described under "Write it down" below, and the area's own line says
`accepted` with the date. Add both before the flagged work starts, not after
it lands. Then build what was asked for.

## Full fit check

Run every question, in the situations listed at the top of this file, and
whenever several project characteristics changed together.

## Delta fit check

For a single change-triggered reassessment:

1. ask the consequence questions affected by the proposed change;
2. name any sensitive area the change touches, and its caution;
3. recheck the ownership questions the change affects, and record a new no as
   a founding task;
4. apply the decision order;
5. update `Recheck when` and `Last checked`, and add an `Accepted:` line if a
   risk was accepted along the way.

Run the full check instead when the affected area cannot be bounded confidently.

## Write it down

Whatever the outcome, it goes in the masterplan's build path section:

```md
## Build path

Path: <Explore privately | Build and run it | Build with care>
Why: <one or two sentences>
Sensitive areas: <none, or one line per area beneath this one>
Accepted: <none, or one line per accepted risk>
Recheck when: <specific triggers>
Last checked: YYYY-MM-DD
```

Each named area gets its own line under `Sensitive areas:`, indented two
spaces. A line carries the area, what in this tool touches it, its caution,
and where the caution stands: `not yet done`, `done` with the date, or
`accepted` with the date of the matching `Accepted:` line. On Build with care,
the next line lists the paths where that area lives. A third line may name one
boundary the area must not cross. Every top-level source folder is listed under
an area or on a `none:` line, so the shipped check can refuse a new, unassigned
folder. Keep this map absent on the other two build paths.

```md
Sensitive areas:
  regulated decisions: the treatment recommendation; caution: a clinician signs off the protocol before nurses act on it; not yet done
    paths: src/recommendations/, src/rules/treatment.ts
    boundary: reached only through src/rules/treatment.ts
  irreplaceable live data: the maintenance history import; caution: a backup restored once and the import rehearsed on a copy; done 2026-08-12
    paths: src/imports/maintenance/
  none: src/reporting/
```

Read the paths back in plain words at founding. For example: "Money is the
refund button, and it lives in the billing folder." Where the project uses a
language Bearer covers, offer its local data scan to find files that handle
personal data. Bearer is free to run under the Elastic License 2.0 and is not
open source. The scan is optional; the map and its check are not.

Write the map in the same save as any code move that changes it. The foundation
check fails when a listed path has gone or a new top-level source folder has no
area or `none` line. It says which path or folder needs a decision. The check is
silent on Explore privately and Build and run it.

Each accepted risk gets its own line, and lines are added rather than replaced.
A line carries the date, what it drops, and who accepted it:

```md
Accepted: 2026-08-12, review of who can see the client notes, declined on cost, accepted by Priya
```

An acceptance drops a caution. It does not move the path or take the area off
the list, because the exposure is still there; the area's own line changes to
`accepted 2026-08-12` so the two point at each other. The path moves only by
running the fit check again, when a redesign has removed the area.

The agent reads that section first in every session.
