# The fit check

The fit check chooses the project's **build path** and names each sensitive
area the work touches, with its caution. It runs during
/setup-ai-build-kit; when a request changes users, data, money, autonomy,
promises or reliance; before the first /setup-hosting; at the quarterly
/maintain; and before a handover.

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

These never decide the path. A no becomes a founding task: a piece where there
is work to do (write down the manual fallback, name who reads the alerts), or a
line in the masterplan's "How it stays running" section where there is only a
fact to record. Founding carries on.

Those facts live only in "How it stays running"; the changelog records only
that the check ran and when. For a credential, the fact is where it lives (a
file path, a password manager entry's name, an environment variable's name),
never its value.

## The three build paths

Use these three names everywhere. Choose the first that matches, after
redesign has been considered.

### 1. Build with care

Some of the work touches a sensitive area. A yes to question 1, 2, 4, 5, 6 or
7 that redesign cannot remove puts the project here. The masterplan names each
area in the tool's own words with its caution. Everything outside those areas
is built as Build and run it. Inside one, the caution is done before merge or
activation, or the person accepts on the record.

### 2. Build and run it

People rely on the tool, no sensitive area is touched, consequences are
limited and recoverable, and the manual fallback is real. A yes to question 3
or 8 lands here: it says the tool is relied on, and asks for the operational
readiness /setup-hosting requires before first live use. This is the kit's
primary path.

### 3. Explore privately

Nobody relies on it, data is disposable, actions are reversible, and the work
exists to answer questions or learn.

## Sensitive areas

Six areas, fixed, each with a default caution. Name the area in the tool's own
words (the client notes, the refund button) and write the caution beside it.
Change a caution only where the tool's facts make another right, and say why.

| Area | What counts | Default caution |
|---|---|---|
| Personal or sensitive data | Facts about a person beyond ordinary work contact details: health, pay, home address, identity documents, anything a person would mind a colleague reading. | A person who did not build the tool reviews who can see what, before real data goes in. |
| Money | Real money moving through the tool, or figures people act on as if they were the bill. | A managed payment provider holds card details so the tool never sees them, and the owner of the money checks the first real figures against a case they know. |
| Sign-in and permissions | Anyone outside the team signing in, or rules that keep one person's things from another's. | A managed sign-in service so the tool never stores a password, and a person who did not build it reviews who can reach what, before outside users sign in. |
| Automatic action on people or other systems | The tool sends messages, changes records elsewhere, or does anything on its own that is hard to take back. | A person approves each action until a live run has shown it right, and one switch turns it off. |
| Irreplaceable live data | The only copy of something the team cannot recreate. | A backup taken and restored once, and the change rehearsed on a copy, before the original is touched. |
| Regulated decisions | Medical, legal, financial, employment, or safety decisions the tool gives or enforces. | Somebody qualified in that field signs off the rule before anyone acts on it. |

Where a caution is a person, "The notice holds" applies. Where it is a backup,
a copy, a rehearsal, a managed service or an approval step, it is the kit's to
do as part of the work, with the result recorded on the area's line. Work
inside a named area is flagged work.

## Redesign before the notice

Before naming an area, ask whether the risk can be removed: use a copy instead
of live data, remove automated action, keep a human approval step, remove
regulated advice, reduce outside access, use a managed service, keep a manual
fallback, or narrow the promise. A redesign that really removes the area
changes the answers, so run the check again. One that keeps the surface and
drops the caution does not.

## The risk notice

The kit refuses nothing, and it does not stop where the person can judge the
risk. A notice is due only where work touches a sensitive area that survives
redesign and whose caution has not been done: personal or sensitive data,
money, sign-in and permissions, automatic action on people or other systems,
irreplaceable live data, or a regulated decision. Say so before that work goes
ahead, on any build path. Work outside every named area gets no
notice, no acceptance, and no recorded exception, whatever its path. Most work
on most projects is like this. Build and run it, the primary path, is defined
by no sensitive area applying, so it has nothing to notice.

A notice says five things:

- who is exposed, named as people rather than as a risk;
- what happens to them when it goes wrong;
- what would normally prevent that;
- what the person can do: have that done first, take the flagged thing out of
  scope, or carry on, in which case you record that they accepted the risk and
  the work goes ahead;
- that you flag what you can recognise and will miss things.

"This is risky" is not a notice. Naming a cost, a delay, or a rule of the kit's
own is not a notice either. Say who gets hurt.

Give it once, in full, in one reply. Do not spread it across several replies,
and do not repeat it in every reply after. A notice given when the work was
first scoped, with no acceptance recorded since, is given again when the work
is actually built, because that is the moment it can still change what the
person decides. Once an acceptance is recorded for an area, do not give the
notice for that area again; say in one line what was accepted and when.

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
and that is recorded, or they have not and the person carries on past the
notice, with the acceptance on the record. Saying an in-project method already covers it is the recast this rule
exists to refuse, and it is the form the recast actually takes: not a refusal to
review, but a redefinition of what the review was.

An acceptance is never the caution done. The area's line says `accepted`, not
`done`, and the launch report says which caution did not happen.

Pushback is not evidence about the risk. Cost, a deadline, the size of the team,
the person's own willingness to be responsible, and what other tools are said to
allow all change what the person decides. None of them changes who is exposed.

Never propose a relaxation and act on it in the same breath. An area is named
as sensitive on your own judgement. Its caution is dropped only when the person
carries on after hearing the notice.

### Carrying on is accepting

Once the full notice has been given, any instruction to go on with the flagged
work is the person accepting the named risk. "Go ahead", "build it anyway",
"try it again", and "it is on me, build it" all count. Do not ask
a second question to get a cleaner yes, and do not turn an answer down because
it does not repeat the notice back. The person has heard who is exposed, and
the choice is theirs.

Three things are not carrying on:

- silence, or a reply that does not ask for the flagged work, such as a
  question, a change of subject, or "I am not sure";
- an instruction given before the notice. A person who has not been told
  cannot have accepted. Give the notice in full in that reply, and build when
  they carry on after it;
- an instruction about other work. Going on with the work outside the area is
  not going on with the area.

Where no notice was due, there is nothing to accept and nothing to record.
Agreement to a plan is not acceptance of a risk. An `Accepted:` line written
against an ordinary decision makes the record meaningless, so do not write one.

Before you write anything, find the notice in one of your own replies: the
reply that named who is exposed and what happens to them. Remembering that you
meant to give it is not finding it. Where you cannot point to that reply, the
person has not been told, so give the notice in full now and build when they
carry on after it.

When the person carries on, write the `Accepted:` line in the masterplan's
build-path section, described under "Write it down" below, with the date and
their own words, and change the area's own line to `accepted` with the date.
Add both before the flagged work starts, not after it lands. Read the
build-path section back, and let the line being there decide whether the work
starts. Then build what was asked for, without asking again.

All of this happens in the reply that answers the person carrying on: write
the line, read it back, and start the work. Do not end that reply on a
question that asks their permission again, such as whether they are sure,
whether it should really switch on, or whether they want the version that
waits for the check after all. Each of those is the second question in other
words, and a person who has to answer it has been stopped. A real question
about scope, whose answer changes what gets built, may still be asked.

The acceptance reaches what that notice named, in that area, and nothing else.
It does not switch on anything the notice did not name, and it does not settle
another area's caution, which needs its own notice. Where the plan holds a lock
whose only purpose is to wait for this caution, such as a rule that stays off
until a named person signs it, the acceptance opens that lock. Change the plan
in the same reply and say so in one line. Do not keep the lock and ask for a
further yes to open it. Keep it only if the person asks you to. The named
person has still not looked, and the record still says accepted, never done.


## Full and delta checks

Run every question in the situations at the top of this file, and when several
characteristics changed together. For a single change, run a delta check: ask
the consequence questions the change affects, name any area it touches and its
caution, recheck the ownership questions it affects, apply the decision order,
and update `Recheck when` and `Last checked`, adding an `Accepted:` line if a
risk was accepted. Run the full check when the affected area cannot be bounded.

## Write it down

The outcome goes in the masterplan's build-path section, which the agent reads
first in every session:

```md
## Build path

Path: <Explore privately | Build and run it | Build with care>
Why: <one or two sentences>
Sensitive areas: <none, or one line per area beneath this one>
Accepted: <none, or one line per accepted risk>
Recheck when: <specific triggers>
Last checked: YYYY-MM-DD
```

Each area gets its own line under `Sensitive areas:`, indented two spaces:
the area, what in this tool touches it, its caution, and where the caution
stands (`not yet done`, `done` with the date, or `accepted` with the date of
the matching `Accepted:` line). On Build with care, the next line lists the
paths where the area lives, and a third may name one boundary it must not
cross, which the project check can hold once the person agrees, by
`boundary-rules.md`. Every top-level source folder sits under an area or on a
`none:` line, so the shipped check refuses a new, unassigned folder. Leave the
map out on the other two paths.

```md
Sensitive areas:
  regulated decisions: the treatment recommendation; caution: a clinician signs off the protocol before nurses act on it; not yet done
    paths: src/recommendations/, src/rules/treatment.ts
    boundary: reached only through src/rules/treatment.ts
  irreplaceable live data: the maintenance history import; caution: a backup restored once and the import rehearsed on a copy; done 2026-08-12
    paths: src/imports/maintenance/
  none: src/reporting/
```

Read the paths back in plain words at founding: "Money is the refund button,
and it lives in the billing folder." Where the language is one Bearer covers,
offer its optional local scan for files that handle personal data; it is free
under the Elastic License 2.0 and is not open source. Update the map in the
same save as any code move; the foundation check names a listed path that has
gone or a new folder with no line, and is silent off Build with care.

Each accepted risk gets its own line, added and never replaced: the date, the
caution that did not happen, and the words the person carried on with, with
their name.

```md
Accepted: 2026-08-12, review of who can see the client notes not done; Priya carried on after the notice: "we cannot pay for a review, build it"
```

An acceptance drops a caution. It does not move the path or remove the area,
since the exposure is still there; the area's line says `accepted 2026-08-12`.
The path moves only when the fit check runs again after a redesign has removed
the area.
