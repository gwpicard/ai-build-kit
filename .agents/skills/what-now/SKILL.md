---
name: what-now
description: Orientation for a lost or returning user. Trigger when someone asks what to do next, has been away a while, feels lost, or a session died in the middle of something. Reads the documents and the git state and says where the project stands and what to do next. Never builds or repairs anything, and changes nothing unless the person chooses a recovery step it offers.
---

# What now

You are the safety net under the other five commands. Someone who forgets everything else and remembers this one is fine.

## Read

Read masterplan.md (build-path section first), the recent changelog, the
capability profile in AGENTS.md, git status, recent commits, merged and open
pull requests. Refresh the printout with `sh .agents/tools/plan-refresh.sh`
and read `plan.local.md`; the `setup-ai-build-kit` skill's `references/pieces.md` says
what to run where the helper is missing. Never sort the pieces by hand. If
GitHub cannot be reached, work from the printout and say when it was written.

Note: whether the project is live (the changelog says), half-done work, a
finished piece waiting for its merge, a failing check, an open pull request
whose body lists `Worth stopping for`, flagged work waiting, the `Accepted:`
lines, a manual setup step left mid-way, a merge or rebase conflict, a
check-up overdue by `.ai-build-kit-maintenance` (or the changelog dates when
that file is missing), and anything on the recheck-when list that has
happened.

Run two checks from the project root and keep only their exit codes. Both read
and change nothing:

- `python3` with the `maintain` skill's `scripts/upgrade-check.py`. Exit 1
  means a kit update is unfinished.
- `sh` with the `setup-ai-build-kit` skill's `scripts/trued-mark.sh`. Any exit
  other than 0 means the masterplan's mark cannot be used.

## Say

Open with where the build stands in one line, then which command comes next
and why, in a few plain sentences.

Order:

1. Anything labelled `broken`, by what is broken: "the booking confirmation is
   broken, so repairing it comes first". A reproduced repair marked ready goes
   to /implement; one not yet reproduced goes to /shape. Where the live tool
   broke after a recent merge, follow the `setup-hosting` skill's "Rolling
   back" first.
2. A failing check, an unsettled review finding, or a setup step left
   half-done. Say each plainly. None sits under "nothing is blocked".
3. The counts. Before the first launch: "four pieces in, three left, nothing
   blocked, nothing half done". Once live, describe the state instead, since
   a live project's list never empties.

Say how many entries are still notes rather than pieces, when any are: "two
things on the list are still just notes, so I will ask you about them before
building them".

For a waiting piece, pass on why it waits: a few questions, a throwaway build
to react to, or a fact the agent can confirm alone. The first two need the
person; the third does not. Where more pieces wait on a question than are
ready, say this session is better spent planning, and give the counts as the
reason. A piece waiting on the person is named as their own step, in the
piece's words, with where it happens.

Say piece names, never issue numbers, and dependencies as sentences:
"deposits cannot start until card payments are set up". Name at most three
things; if more apply, say how many and name the nearest. /implement shows the
whole ready list.

Before launch the answer is usually /implement, /shape, or /setup-hosting once
people should use it. Once live it is usually /shape for a new wish or a
fault, or /maintain when a check-up is due.

Where the update check exited 1, say one line before the recap: "The kit
update is not finished. /maintain finishes it." Where the mark check failed,
/maintain is one of the three things: "The masterplan has not been checked
against the code yet. /maintain checks it."

End with a short recap of where the tool has got to: what the last stretch of
work was about and whether anything is on the go, from the changelog, commits
and merged pull requests. Leave out what was already named. When nothing has
happened lately, leave the recap out.

## Recovery routes

### Uncommitted work

This is the one home for work an interrupted session left behind. Say what it
appears to belong to, then offer: continue it, save it as a checkpoint, or
clear it after showing exactly what would be lost. Never run a destructive
command without a yes for that action.

### Merge or rebase conflict

Say which two intentions collided. Resolve it only when the records make the
outcome plain; otherwise keep both sides and ask. A conflict touching data or
deployment is escalated, never guessed.

### Missing capability

Say what this harness cannot do, the fallback in use, and one setup action that
would close the gap. One missing extra does not make the kit incompatible.

### Flagged work waiting

Name the area, the help it waits on, where its brief lives, and what can carry
on meanwhile. The wait ends when that help happens, or when the person carries
on after the notice and the acceptance is recorded.

### A step only you can do

Name the step, where it happens, what to bring back, and what starts moving
once it is done. Never repeat a key, password or token, and never ask for one
in a message.

### Failing check

Name the check and what it catches, in plain words, such as the test that
stops a booking being taken twice. A red check on an open pull request belongs
to that piece's build, so /implement. A red check on `main` is a fault, so
/shape. Never show its output or logs.

### Unsettled review finding

Name it in the review's words and the piece it belongs to. It holds that
piece's merge until settled, so /implement.

### Unfinished setup step

Name the step, say it is unfinished, give the one action that finishes it, and
say what stays unavailable until then.

### Accepted risks

Say each `Accepted:` line in one line of plain words: what was given up, when
and by whom, and that asking for the skipped check reopens it. Do not ask again
unasked.

## Done when

The next command is clear, the reason for it is said, nothing half-done or blocked is lying around unacknowledged, and no technical recovery decision has been pushed onto the user.
