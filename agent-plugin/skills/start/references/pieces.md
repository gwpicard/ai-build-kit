# Pieces

A piece is one small, visible, end-to-end change, sized for a single sitting and
small enough for a fresh session to hold the whole of it. It lives as a GitHub
issue.

The project's issues are the only record of what is left to build. Keeping the
pieces there needs a GitHub repository and the GitHub command line tool signed
in, which the kit sets up when a project is founded; `capability-check.md`
records it in the capability profile.

Issues are the agent's memory rather than the person's reading material. They
can carry as much context as a piece deserves, because nobody reads them all at
once. What the person reads is `/what-now`, and a local printout of the open
issues that never becomes a source of truth.

## What an issue carries

The title says what the person will be able to do, in their words. Not a task
for the agent.

```md
## So that
<the outcome this exists for, in one line>

## Done when
- <a condition somebody can check>
- <another>

## Evidence
<automated behaviour check | guided manual check | source-backed fact |
operational rehearsal>

## Not in this piece
<the nearest things this is not, so scope does not creep in later>

## Decided
<only when a decision was actually made that would otherwise be re-argued>

<details><summary>Under the hood</summary>

<the build approach, the seams, code-level dependencies, any groundwork: the
technical context a builder needs and the person never has to open>

</details>
```

`## Done when` is written as conditions somebody can check rather than a
description. If a line cannot be answered yes or no by trying the tool, it
belongs in `## So that`.

`## Decided` is left out entirely on the pieces that had no argument behind
them, which is most of them. A section of thin prose repeated on every issue
teaches a reader to skip all of them.

## The two layers of a piece

The five sections above are the surface. They stay in plain words, and they stay
comprehensive about anything that affects the product, so a simple read is never
a false one. A fact belongs on the surface when it would change a product
decision: put it in `## Decided`, or name it as a dependency, in words the person
would use. A fact belongs under the hood when it only affects how the code gets
written.

`Under the hood` is a collapsed section for that build context: the approach, the
seams, code-level dependencies, any groundwork. The person never has to open it,
and `section-builder` always reads it before building. Most short pieces need
none of it. This is the same principle the issue already follows, that an issue
is the agent's memory and carries as much context as a piece deserves.

Context that reaches past one piece does not live here. A decision that affects
the whole product goes in the masterplan, in plain words. A technical convention
that affects the whole codebase goes in AGENTS.md's stack section. The piece
holds only what is particular to it.

## Labels

A piece carries every subject label that fits it, from the same small vocabulary
the consequence classification uses. Most pieces have one:

| Label | What the piece is about |
|---|---|
| `visual` | the interface, what people see and click |
| `how it works` | the rules and logic |
| `data` | information the tool stores |
| `accounts and permissions` | who can get in and what they can see |
| `finance` | charging, refunds, pricing, invoices |
| `external service` | somebody else's system that this piece needs |
| `background automation` | something that runs on its own, with nobody watching |

A subject label is not a description of the piece. Each one decides evidence and
a save route, so `section-builder` reads the labels rather than re-deriving them.
Where a piece carries more than one, its evidence is everything those subjects
demand between them, and its save route is the strictest of the ones present.

Ticking every subject that fits, rather than the closest single one, stops the
kit dropping a true fact about a piece: a checkout is `finance` and
`external service`, and picking one would lose the evidence the other requires.

Four more labels carry state that open and closed cannot:

- `building`, while somebody is working on it;
- `blocked`, when something outside the project holds it up;
- `parked`, on a closed issue, for an idea deliberately left out;
- `broken`, when the piece is repairing something that used to work.

`broken` sends the work to `/fix` rather than to `/implement`, and it sits
alongside the subjects rather than replacing them, because a broken thing is
still about something.

Three more say the piece is waiting on a question rather than on a person:

- `needs-clarification`, when talking it through will settle it;
- `needs-prototype`, when only a throwaway build will settle it;
- `needs-research`, when it needs a fact from outside the project.

Anything nobody has sized starts at `needs-clarification`. The interview swaps
that for one of the other two once it finds what is actually in the way. All
three mean the same thing to `/implement`: not ready, and here is why.

One more is the positive counterpart to those three:

- `ready`, when the piece is shaped and waiting to be built.

`/plan` adds `ready` once a piece is fully shaped: it has a `## Done when` line
and waits on no question. `/implement` takes the lowest-numbered `ready` piece,
swaps the label for `building` at pickup, and the merged pull request closes it.
A piece never carries `ready` and a `needs-` label at the same time; settling
the question is what moves it from one to the other.

Those fifteen are the only labels the kit owns. Any other label on an issue
belongs to somebody else, so the kit reads past it and never removes it.

The nine labels GitHub puts on a new repository are the one exception, and only
at founding. `bug`, `documentation`, `duplicate`, `enhancement`, `good first
issue`, `help wanted`, `invalid`, `question` and `wontfix` were nobody's
decision: they were there before anybody arrived. `/start` deletes them and says
which ones went. After founding they are somebody's to keep, so the ordinary
rule applies again and the kit leaves them alone.

A label is created when it is first needed. Where the person's account cannot
create one, because they are a collaborator without write access, the work
carries on without the label and the agent says which one is missing. A piece
that cannot be labelled is still a piece.

## Status, owner, and order

Open and closed already mean "to build" and "built". Do not add labels that
repeat them.

The assignee is who is building it. This works the same whether one person or
five are on the project, so nothing changes on the day a second person arrives.

Dependencies use GitHub's own blocked-by relationship, not a line of prose. A
piece that needs another names it there, and the agent reads it rather than
parsing a body.

A piece with parts uses GitHub's own sub-issue relationship. The two
relationships answer different questions, and the answer decides which to use. A
sub-issue is a part of the same outcome: it shares the parent's `## So that`, and
the parent is not done until its parts are. A blocked-by piece is a different
outcome that must land first. Same outcome means a sub-issue; a different outcome
that has to come first means blocked-by. A piece too big to hold whole in a fresh
session is split into sub-issues, each a vertical slice of its own.

`/implement` takes the lowest-numbered `ready` issue whose blockers are all closed
and whose subjects the current build path all permit. A parent with open children
is a container rather than a buildable slice: `/implement` builds the children,
and the parent closes when they all close. This is what keeps the two ways of
being not-ready apart. A blocker is a different piece that must land first; an
open child is a part of this piece still to build. Issue numbers give a stable
creation order and the two relationships give the structure, so nothing extra is
maintained by hand.

## An issue somebody typed by hand

Anybody can open an issue, from a phone, in half a sentence. That is a request
rather than a piece, and it cannot be built or proved as it stands.

Shape is what decides, not who wrote it or whether anyone remembered to mark it.
An issue with no `## Done when` has not been sized. Label it
`needs-clarification` the first time you see one, so somebody reading the list on
GitHub can tell which entries are still notes. The label is there for people; the
agent goes by shape, so an unlabelled note is still a note.

If the interview finds that talking will not settle it, swap the label for the
`needs-` label that says why (see Labels above), and say which you moved it to
and why, because a label change nobody explained reads as the agent losing track.

Refining one produces the shape above. Keep what the person originally typed
underneath rather than replacing it, because their words are what a refinement
can be checked against and what to return to when it reads wrong.

## When somebody acts on GitHub

The issues are shared, so people assign, close, label and edit them by hand.
Three rules settle nearly every case.

A person's action wins. The agent never undoes something somebody did on
purpose. It can say what it found, and then it works with what is there.

Absence is not a decision. A piece carrying no subject label is unclassified
rather than assumed to be `how it works`. Several subject labels are not excess,
because a piece is allowed to be about more than one thing.

The agent says what it found. It does not quietly reshape a project back into
the form it expected.

| What the person does | What the kit does |
|---|---|
| Assigns themselves | Treats the piece as theirs, and `/implement` will not hand it to anyone else. Assignment says whose it is; `building` says work is under way now |
| Assigns somebody else | `/implement` skips it and says who has it, rather than quietly taking it |
| Adds `building` | Treats the piece as under way and leaves it alone |
| Closes an issue by hand | It stays closed. `/sync` may say that no changelog line matches it, and ask whether it was done or dropped |
| Reopens a closed issue | Treats it as work again, and takes off a `parked` label, because reopening is the decision to unpark it |
| Edits the body so `## Done when` is gone | Treats it as a request rather than a piece, and refines it before building |
| Adds labels of their own | Leaves them alone |
| Puts two subject labels on one piece | Takes both, and satisfies what each one demands |
| Leaves the subject off | change-triage classifies it when the piece is refined |
| Uses milestones or a project board | Ignores both, and neither reads nor writes them |
| Deletes an issue | Lets it go. If a branch still refers to it, `/sync` says so |
| Fills the issue form in properly | Nothing special. It is a piece, and it gets built |

## The local printout

`plan.local.md` is a printout of the open issues and nothing else. It is
gitignored, so it is one person's view of a shared record and can never collide
with anyone else's.

Information flows one way: issues are the record, and the printout is made from
them, never read back. A change to a piece goes to the issue, and the printout is
made again with `.agents/tools/plan-refresh.sh`, so if it looks stale, refresh
it. Run the refresh when reading or changing the plan rather than on every
session start, so a session that never touches the plan stays light.

It carries the time it was written, which is what makes it safe when GitHub is
unreachable. The agent can say "here is your list as of 18:40, and I cannot
reach GitHub to confirm it is current" rather than leaving somebody with
nothing. Work that would change the plan waits until GitHub is back, because
the agent will not update issues it cannot see. The piece already in hand
carries on.

One call to GitHub covers the whole backlog. The issue list carries a
dependency summary, so whether a piece is held up by another is known without
asking about each one. Only the pieces that are actually blocked need a second
call, to name what is holding them.

## Parked ideas

An idea deliberately left out becomes a closed issue labelled `parked`, with the
reason in the body. Closed, so it never reads as work waiting to be done.

Before accepting a request as new, search closed issues too. The reason exists
so the same idea does not come back around and get built by accident.
