# Pieces

A piece is one small, visible, end-to-end change, sized for one sitting. It
lives as a GitHub issue. The issues are the only record of what is left to
build. They are the agent's memory, so they can carry as much context as a
piece deserves; the person reads `/what-now` and the local printout instead.

## What an issue carries

The title says what the person will be able to do, in their words.

```md
## So that
<the outcome this exists for, in one line>

## Done when
- <a condition somebody can check>
- <another>

## Evidence
<automated behaviour check | guided manual check | source-backed fact |
operational rehearsal>

## Masterplan change
<what the masterplan gains, changes or loses when this lands, or "nothing">

## Not in this piece
<the nearest things this is not, so scope does not creep in later>

## Decided
<only when a decision was actually made that would otherwise be re-argued>

## Waiting on you
<only when the work cannot go further until the person does something the agent
cannot: where to go, what to do there, and what to bring back>

Live side needs: <only when the live copy must gain a new secret, setting or
outside service before this can go live: each by name, never a value>

<details><summary>Under the hood</summary>

<the build approach, the seams, code-level dependencies, any groundwork: the
technical context a builder needs and the person never has to open>

</details>
```

`## Done when` holds conditions answered yes or no by trying the tool. Anything
else belongs in `## So that`.

`## Masterplan change` names the section and what it gains, changes or loses.
Read each `## Done when` line against the masterplan alone, and write "nothing"
only when the masterplan already says it. A rule the person could check, such
as an order, a limit, a default or a message, is a change even when it narrows
an existing promise: putting a list in alphabetical order gains that rule in
`What correct looks like`. Writing it does not apply it;
[masterplan-changes.md](masterplan-changes.md) says when it is applied.

`## Decided`, `## Waiting on you` and `Live side needs:` are left out unless
they apply. `## Waiting on you` never carries the secret it asks for: say where
the key goes. It is not `blocked`, and the piece keeps its labels. A database
migration needs no `Live side needs:` line, since `/implement` finds it in the
change.

A decision in `## Decided`, or a decided line in the masterplan, may carry a
one-line "rests on" clause naming what supports it: a test, a piece, a source,
or a person's answer with its date. Never invent support. Before relying on a
clause, read what it names against the current branch or source. Missing or
contradicted support no longer holds; unreachable support is unconfirmed. Say
which in one plain line, such as "The rule that a job closes once rested on a
test that no longer exists." Keep the decision until it is settled through the
usual route; lost support is not permission to reverse it.

## The two layers of a piece

The surface stays plain and names every fact that would change a product
decision, so a simple read is never a false one. `Under the hood` is collapsed
build context the person never has to open and `/implement` always reads. Most
short pieces need none. Context reaching past one piece goes to the masterplan
(a product decision) or AGENTS.md's stack section (a codebase convention).

## Labels

A piece carries every subject label that fits it:

| Label | What the piece is about |
|---|---|
| `visual` | the interface, what people see and click |
| `how it works` | the rules and logic |
| `data` | information the tool stores |
| `accounts and permissions` | who can get in and what they can see |
| `finance` | charging, refunds, pricing, invoices |
| `external service` | somebody else's system that this piece needs |
| `background automation` | something that runs on its own, with nobody watching |

Each subject decides evidence and a save route. With several, the evidence is
everything they demand between them and the save route is the strictest.

State labels:

- `building`, while somebody is working on it;
- `blocked`, when something outside the project holds it up, or after repeated failure;
- `parked`, on a closed issue, for an idea deliberately left out, with the reason in the body;
- `broken`, when the piece repairs something that used to work. It sits beside the subjects.

Waiting on a question, each saying who can answer it:

- `needs-clarification`, when talking it through will settle it. The person has to be there.
- `needs-prototype`, when only something to look at will settle it. The person has to be there.
- `needs-research`, when it needs a fact or existing work from outside the project. The agent settles it alone.

Anything nobody has sized starts at `needs-clarification`. Settling one writes
what settled it into `## Decided` before the label comes off.

- `ready`, when the piece is shaped and waiting to be built.

`/shape` adds `ready` through `mark-ready.sh`, which refuses without `## Done
when` and, after a `needs-` label, without `## Decided`. `/implement` swaps
`ready` for `building` when it starts and takes both off after the merge. A
piece never carries `ready` and a `needs-` label together.

Those are the only labels the kit owns. It reads past any other label and
never removes it. The one exception is founding, which deletes the nine labels
GitHub puts on a new repository. After founding they are somebody's to keep.
Where an account cannot create a label, carry on without it and say which is
missing.

## Status, owner, and order

Open and closed mean "to build" and "built". The assignee is who is building
it. Dependencies use GitHub's blocked-by relationship, never prose.

Same outcome means a sub-issue; a different outcome that has to come first
means blocked-by. A sub-issue shares the parent's `## So that`, and the parent
is done when its parts are. A piece too big to hold whole is split into
sub-issues, each a vertical slice. A parent with open parts is a container:
`/implement` builds the parts.

Work found during a build becomes a new piece with "Found while building
<piece title>" on its surface, linked both ways. It gains a blocked-by link
only if one piece really must land first.

## An issue somebody typed by hand

An issue with no `## Done when` has not been sized. It is a request, not a
piece. Label it `needs-clarification` the first time you see one, so people can
see it is still a note; the agent goes by shape either way. Refining it keeps
the person's original words underneath.

## When somebody acts on GitHub

A person's action wins. The agent never undoes something somebody did on
purpose. Absence is not a decision: a piece with no subject label is
unclassified, not `how it works`. The agent says what it found. It works with
what is there.

| What the person does | What the kit does |
|---|---|
| Assigns themselves | Treats the piece as theirs |
| Assigns somebody else | `/implement` skips it and says who has it |
| Adds `building` | Treats the piece as under way and leaves it alone |
| Closes an issue by hand | It stays closed. `/maintain` may ask whether it was done or dropped |
| Reopens a closed issue | Treats it as work again and takes off `parked` |
| Edits the body so `## Done when` is gone | Treats it as a request again |
| Adds labels of their own | Leaves them alone |
| Puts two subject labels on one piece | Takes both, and satisfies what each one demands |
| Leaves the subject off | `/shape` classifies it when the piece is refined |
| Uses milestones or a project board | Ignores both, and neither reads nor writes them |
| Deletes an issue | Lets it go. If a branch still refers to it, `/maintain` says so |

## The local printout

`plan.local.md` is a git-ignored printout of the open issues, made with
`sh .agents/tools/plan-refresh.sh` and never read back as a record. Refresh it
when reading or changing the plan. Where a project has no copy of the helper,
run the same file from the installed setup-ai-build-kit skill's
`templates/foundation/plan-refresh.sh` from the project root, and say the next
`/maintain` adds it. Never sort pieces by reading the issues by hand: the
printout keeps a piece with an open blocker out of `To build`.

A command naming what to build next names only a piece under `To build`
marked `(ready)` in a printout it has just refreshed. With none, say nothing
is ready and what the rest wait on.

When a refresh fails, follow [required tools](required-tools.md), "When
GitHub access fails". The printout carries the time it was written, so with
GitHub unreachable say "here is your list as of 18:40". Work that would change
the plan waits until GitHub is back; the piece in hand carries on.
