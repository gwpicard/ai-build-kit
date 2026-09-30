# Running a plan

Loaded when `/implement` is given several issue numbers, or `queue`, which is
the command for a plan of ready pieces built with nobody watching. `auto` is
another name for `queue`. The discipline of a single build is unchanged: each
piece goes through section-builder, step by step. What changes is that nobody
is present between the pieces, so the rules below carry the quality, the state
file carries the memory, and everything gets a cap.

## Capability rule

Assume nothing beyond ordinary sequential agent work: no native goal mode, no
background agents, no worktrees. A run works in one checkout, one piece after
another, in the way a person would run them by hand. Where the coding agent can
start a session that did not build the piece, use it for the readiness check
and the independent review, as those steps already say.

## Which pieces a run may take

Eligibility is decided piece by piece, never earned by the project. A piece is
eligible when all of these hold:

- it carries `ready`, and nothing open holds it up that is not built earlier in
  this run;
- it meets the bar: a `## Done when` section, and a `## Readiness` section whose
  first line says Ready;
- it is self-sufficient enough to build without a person present: its `Under
  the hood` notes carry what the build needs;
- it has no `## Waiting on you` step other than `try it`;
- it lies outside every sensitive area named in the build-path section, unless
  that area carries an `Accepted:` line covering it.

A piece in a sensitive area without a recorded acceptance is never taken. A run
never writes an acceptance on the person's behalf, because nobody is there to
carry on after the risk notice. On Explore privately, a run takes only
disposable work whose Done when lines a machine can check.

A ready piece with no `## Readiness` section was shaped before the check
existed. Run the readiness check on it before claiming it, as
the `shape` skill's `references/readiness-check.md` says, through a session
that did not shape it. Ready lets the run take it. Not ready sends it back to shaping with
each blocking gap written on it,
`gh issue edit <number> --add-label shaping --add-label needs-clarification --remove-label ready`,
using the `needs-` label the check names, and the run moves on.

A piece the person opted in to check, with a `Waiting on you: try it` line or a
`check-myself|yes` line in `.ai-build-kit-maintenance`, is taken and built. It
stops at `to check` with a line in its pull request saying it waits for the
person's try, and it is never merged under pre-approval.

A piece that is not eligible stays where it is. The report says why.

## Before the run starts

Check that Git is clean, as section-builder's step 1 does. Refresh the
printout. The plan is the pieces the person named, or with `queue` every piece
under `To build` marked `(ready)`. Order it by the blocked-by links, so a piece
comes after every piece it depends on, and by number where the links leave a
choice. The parts of one parent sit together in that order.

Say the plan once: each piece in order, whether it is eligible and why not
where it is not, and which pieces will stack on another. Then ask once whether
pieces that pass may be merged during the run, as the `section-builder` skill's
`references/merge.md` describes. The person approves the plan and answers that
question, and then the run goes on with nobody in between.

## The run state

A run keeps its state in `.agents/runs/<run name>/`, where the run name is the
date and time it started, `<YYYY-MM-DD>-<HHMM>`. Git ignores the folder. Where
the project's `.gitignore` has no `.agents/runs/` line, write a `.gitignore`
holding `*` inside `.agents/runs/` before anything else, so the folder ignores
itself and nothing tracked changes.

`state.json` is the record a new session resumes from:

```json
{
  "run": "2026-09-30-2215",
  "merge_preapproved": false,
  "pieces": [
    {
      "number": 12,
      "state": "to check",
      "branch": "12-invoice-list",
      "base": "main",
      "pull_request": 31,
      "attempts": 1,
      "flags": ["Sorted the list newest first; the piece did not say."],
      "reason": ""
    }
  ]
}
```

- `merge_preapproved` is the person's answer before the run: `true` or
  `false`. It holds for this run alone.
- `pieces` lists every piece in the plan, in the order the run takes them.
- `state` is one of `waiting` (not started), `building`, `to check`, `merged`,
  `parked`, `shaping` (sent back with a question) or `skipped` (not eligible,
  or backed off).
- `branch` is the piece's branch, and `base` is the branch it was cut from:
  `main`, or the branch of the piece it stacks on.
- `pull_request` is the number of its pull request, or `null` before one opens.
- `attempts` counts the failed attempts at its build.
- `flags` holds each easy-to-undo choice the builder made alone, one line each.
- `reason` says why a piece was parked, sent back, skipped, or not merged under
  pre-approval, naming the condition it failed in
  the `section-builder` skill's `references/merge.md`.

Write the state file after every step that changes a piece, before the next
step starts, so it always says where the run stands. `progress.md`, beside it,
is a short log: one line for each step, with the time, the piece and what
happened. Neither file ever holds a key, a password or a person's data.

Wherever the coding agent can publish a page, publish a live progress page from
the state file when the run starts, and update it each time the state file
changes. It shows each piece's title, state and pull request link, and nothing
else. Where the page cannot be published, say so once, and carry on with the
state file as the record.

## For each piece

Take the pieces in the plan's order. For each one:

1. **Claim it.** Read the piece first. A piece that already carries `building`
   is being built somewhere else: the claim refuses it, so skip it. Otherwise
   make section-builder's one-step claim, and add a comment naming this run,
   `Claimed by run <run name>`. Then read the claim back with
   `gh issue view <number> --json labels,assignees,comments`. Where it shows an
   assignee other than this run's, or a claim comment from another run, back
   off that piece: take your own assignee off with
   `gh issue edit <number> --remove-assignee @me`, leave the label, mark it
   `skipped` with the reason, and take the next piece. A piece that cannot be
   claimed is never started.
2. **Branch it.** Cut its branch from the up-to-date `main`, or from the
   branch of the piece it stacks on. Record `branch` and `base`.
3. **Run the start ritual.** Read the run state, start the tool, and run a smoke
   check: the tool starts and its first screen or command answers. Then confirm
   each of the piece's Relies on lines still holds, by reading what it names.
4. **Write the checks first**, as section-builder's step 4 says, and show that
   they fail.
5. **Build it**, as section-builder's step 5 says, and verify it with the
   checks the change needs.
6. **Walk through it** with sample data, as section-builder's step 6 says.
7. **Run the independent review**, as section-builder's step 7 says. Where the
   trigger names a person, the review is theirs, and the pull request says it
   is still owed.
8. **Open its pull request**, as section-builder's step 8 says, aimed at the
   piece's `base`. Put every flagged choice in it under `## Flagged for
   confirmation`, one line each.
9. **Write its changelog file**, as section-builder's step 9 says.
10. **Move it to `to check`.** Where `merge_preapproved` is true, merge it only
    when the `section-builder` skill's `references/merge.md` allows; otherwise
    it waits for the person.
11. **Update the run state** and the live page, and add the step to
    `progress.md`.

A Relies on line that no longer holds is an open choice of the hard kind below.
A smoke check that fails on `main` ends the run, because every later piece
relies on it. One that fails on a stacked branch parks the pieces on that
stack.

## Stacks and parts

A piece that depends on one built earlier in this run and not yet merged stacks
on it. Its branch is cut from that piece's branch, its pull request aims at
that branch, and the pull request says which to merge first, so the stack
merges cleanly in order. A piece whose blocker is open and not in this run is
not eligible.

The parts of one parent share one branch and one pull request. The first part
built cuts the branch, named after the parent, and each later part continues
on it. The pull request opens once the last part in the run is built. It
closes each part it carries with its own `Closes #<number>` line, and each
part writes its own changelog file.

## An open choice met while building

A piece can meet a choice its Done when and `Decided` lines do not settle. Split
it by how hard it is to undo.

A hard choice, about the shape of stored data, how records sync, or what leaves
the tool, stops that piece. Write the question on the piece, keep the branch,
and send it back to shaping,
`gh issue edit <number> --add-label shaping --add-label needs-clarification --remove-label building`.
Mark it `shaping` in the state file.

An easy choice, one a later change can undo without touching stored data, takes
the most reversible option. Record it in `flags` and in the pull request's
`## Flagged for confirmation` list. A flagged piece is never merged under
pre-approval.

Either way the run moves on to the next unblocked piece.

## When a piece fails

Retry within the piece, up to three attempts, the same number fix uses. After
the third, park it: move it from `building` to `parked` in one step,
`gh issue edit <number> --add-label parked --remove-label building`, with one
line on what kept failing, and take the next piece. Never let one piece consume
the run. Route the parked piece further when the failure points somewhere
specific: send it back to `/shape`, which settles a missing decision, chases a
missing external fact, or reassesses a shape the team could not safely own,
rather than a fourth attempt. A piece stacked on a parked piece is skipped,
and stays `ready` for a later run.

A blocking failure never stops the whole run unless it touches something every
later piece relies on: the smoke check on `main`, a GitHub that cannot be
reached, so no piece can be claimed, or anything that would change the build
path. A piece stops at any touch of a named sensitive area that carries no
recorded acceptance, even one the plan did not expect: section-builder's
flagged route parks it at the condition, and the run takes the next piece.
Never guess to keep a run going.

## Resuming

A new session resumes from the state file, never from memory. A run is
unfinished while any piece in its state file is `waiting` or `building`.
`/implement` typed alone or with `queue`, `/what-now` and `/sync` each notice
an unfinished run and offer to resume it.

Resuming is the same run, so its `merge_preapproved` stands. Read `state.json`
and `progress.md`, and take the pieces from where they stand. A piece shown as
`building` continues from its last commit: check out its branch, read what its
commits already hold, run its checks, and carry on from the first step not
done. Read its claim back first. Where the claim is no longer this run's, back
off it as step 1 says.

`/sync` removes a run's folder once every piece in it is merged, closed or
parked, counting a piece the run skipped or sent back to shaping as closed to
the run, since the run holds nothing more of it.

## When the run ends

The run ends when no eligible piece is left to take. That includes the moment
every remaining piece is held up, parked or skipped: the run ends at once with
its report, and never waits for something to change.

The report, in plain words, is one list and a merge order:

- what was parked and why, and what went back to shaping with its question,
  first;
- each piece with its pull request and its state, in the merge order, bases
  before the pieces stacked on them;
- under each piece, its flagged choices, and what the walk-through could not
  see;
- where `merge_preapproved` was true, which pieces were merged, and for each
  piece that was not, the merge condition it failed, in the words of
  the `section-builder` skill's `references/merge.md`;
- what was not eligible, and why.

The person answers with the pull requests to merge, and each merge follows the
`section-builder` skill's `references/merge.md`.

When a run disappoints, the fix is in the documents rather than in the code by
hand: sharpen the done lines that let weak work through, add the missing rule
to the masterplan, then run it again. Hand-editing what a run wrote turns a
readable project into a mystery.

## Goal modes

Some tools ship a /goal feature: state a condition and the agent keeps going
until a separate model judges it met. Treat it as a run wearing the tool's
clothes, under the same rules: the condition comes from a done line or a plan
area's done lines, read aloud; sensitive areas stay stop conditions the goal
may not cross; the three-attempt parking rule still applies per piece; the
state file is kept the same way; and each piece still lands through the save
route the build path requires. Any merge follows the `section-builder` skill's
`references/merge.md`, however long the machine ran: on a yes that names it,
or on the person's pre-approval given before the run.
