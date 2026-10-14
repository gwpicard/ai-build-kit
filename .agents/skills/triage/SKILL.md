---
name: triage
description: Sort a request written in plain words before any work happens. Understand it, classify its intent and consequence, find open pieces it overlaps, and choose one route. Used by shape for every request, by implement for work found mid-build, and by maintain for an alert or a bill that becomes a piece.
user-invocable: false
---

# Triage

You sort the request; the person never does, and the masterplan is the
referee. Work through these steps before any work happens. Say the route you
chose and why, in one line. Route the same request the same way each time it
arrives.

## 1. Understand the request

Compare it with the masterplan, the open pieces, the recent changelog, and
existing behaviour where that is cheap to check. Does it already exist under
another name? Was it parked or rejected before? A parked idea is a closed issue
labelled `parked`, so search closed issues too. Is it a misunderstanding or a
setup problem rather than a gap? Does it contradict a rule in the masterplan?

A report that something is broken, in whatever words, loads the
`repair` skill's `references/reproduce.md` and runs its checks first. Shaping
changes no file the project saves.

## 2. Classify intent

One of: repair of promised behaviour; new behaviour; copy or presentation
change; setup or operational task; a decision that needs the `clarify` skill, a
prototype, or source research; a change to the build path or a sensitive area.

## 3. Classify consequence

Every consequence that applies, stored on the piece as subject labels. The
build reads them and never reclassifies:

| Consequence | Subject |
|---|---|
| presentation-only | visual |
| behaviour | how it works |
| data | data |
| access | accounts and permissions |
| money | finance |
| integration or service | external service |
| automatic action, operational reliance | background automation |

An irreversible action takes the subject of what it cannot undo, usually
`data`. Store every row that applies: a checkout is `finance` and `external
service`. A dropped subject takes its evidence with it.

Then read the titles and `## So that` lines of open pieces sharing a subject,
and anything labelled `building`. Where one would plainly be built in the same
place, name it and what the two share. Nothing waits; the person decides
whether to carry on, hold this, or fold the two. Say nothing when the only
thing in common is the project.

## 4. Route

Routes: a repair, shaped by reproducing it; a ready piece; clarify; a decision
prototype; a source check; a search for existing work; a step only the person
can do; update the masterplan first; rerun the fit check; prepare the
handover; the risk notice.

Too vague to size runs the `clarify` skill. A question rather than a ready
piece goes on the issue as its `needs-` label, so the next reader sees why it
waits.

Bigger than a piece goes into the masterplan first and is cut into pieces,
order confirmed with the person. The `records` skill's `references/pieces.md`,
under "Status, owner, and order", says
when parts become sub-issues and when separate pieces are linked by
blocked-by.

A step only the person can do is written as the piece's `## Waiting on you`.
Do it yourself where you can.

A repair takes `broken` beside its subjects, and is ready once reproduced.

A request that touches stored data, who can see or do what, or money updates
the masterplan first, and you say what changed before routing further. A
change to the shape of real data the tool already holds is flagged territory:
a backup first, a rehearsal on a copy, then the real change.

A request that changes what kind of project this is (outside users, real
money, a promise to someone, a new kind of data about people, autonomous
action) stops here: rerun the fit check, record the new build path, then
route.

Where that check leaves a sensitive area standing, give the risk notice
described in the `fit-check` skill before
routing the flagged work, and hold it. Nothing is refused: if the person
carries on after the notice, record the acceptance as that skill says and
route the work. The notice never quietly goes away, and pushback never lets
you decide it no longer applies.
