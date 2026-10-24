# Pieces

A piece is a one-sitting change, recorded as an issue.

## Issue shape

Title: name the change precisely; put technical detail under the hood.

```md
## So that
<outcome>

## Done when
- D1: <checkable condition>

## Evidence
<automated | manual | fact | rehearsal>

## Masterplan change
<change, or "nothing">

## Not in this piece
<scope boundary>

## Decided
<settled choice>

## Waiting on you
<where, what to do, what to bring back>

Live side needs: <required secret, setting or service, by name>

Risk areas: <the risk areas this piece touches, or "none">

<details><summary>Under the hood</summary>
<approach and dependencies>

Reaches: <files, routes, tables, tests, or "new files only">
</details>
```

Name the risk areas from the masterplan's risk record that the piece touches,
or `none`. The `fit-check` skill's `references/risk-notice.md` gives the notice
once.

Number `Done when` conditions D1, D2, etc. End judgement with `(try it)`;
put intent in `So that`. Name and read back the changed masterplan section;
[masterplan-changes.md](masterplan-changes.md) applies it.

Omit unused sections. Mark an unchanged-behaviour refactor `Kind: refactor`;
tests compare before/after. Never put secrets in `Waiting on you`; name where they
go. Migrations need no `Live side needs:`. A decision may cite support in a
"rests on" clause. Check before relying: missing or contradicted support no
longer holds; unreachable is unconfirmed. Lost support alone does not reverse
the decision.

## Labels

A piece carries every subject label that fits it.

| Subject | Covers |
|---|---|
| `visual` | interface |
| `how it works` | behaviour |
| `data` | stored information |
| `accounts and permissions` | access |
| `finance` | money |
| `external service` | outside systems |
| `background automation` | unattended work |

State labels:
- `building`, work under way;
- `blocked`, outside hold or repeated failure;
- `parked`, closed by choice;
- `broken`, repair;
- `needs-clarification`, person answers;
- `needs-prototype`, person reacts to a mock;
- `needs-research`, agent research.

Unsized notes start at `needs-clarification`. Record the answer in `Decided`
before removing it. `ready`, when the piece is shaped, means waiting to build.
`mark-ready.sh` and `piece-labels.sh` validate and update labels.

The kit leaves other labels alone. Founding removes GitHub's nine defaults.
After founding they are somebody's to keep. If a label cannot be created,
carry on and say which.

## Ownership, order and the local plan

Open means to build; closed means built. Same outcome means a sub-issue; a different outcome
that must come first means blocked-by. Parents share `So that` and finish when
parts do. `/implement` builds their parts.

Link found work as "Found while building <title>"; add only true dependencies.

## An issue somebody typed by hand

An issue with no `## Done when` has not been sized: it is a request.
`/shape` labels it `needs-clarification`; refining preserves the original
words.

## When somebody acts on GitHub

A person's action wins. Absence is not a decision. The agent says what it found.
Assigns somebody else: skip it. Leave manual `building` alone; keep manually
closed issues closed; reopening removes `parked`. Keep personal labels and meet each subject's needs; ask `/shape` to
classify a missing one. Puts two subject labels: meet both. Uses milestones or a project board: ignore both.
Deletes an issue: let it go; `/maintain` names
branches.

`plan.local.md` is a git-ignored view. The issues are the only record of what is left.
Refresh with `sh .agents/tools/plan-refresh.sh`; if missing, use the installed
setup helper and say `/maintain` adds it. Never sort by hand. Name fresh `To
build` entries marked `(ready)`. Follow `AGENTS.md` on failure; offline, give
the date. Plan changes wait; current work may continue.
