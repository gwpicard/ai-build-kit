---
name: what-now
description: Orientation for a lost or returning user. Trigger when someone asks what to do next, has been away a while, feels lost, or a session died in the middle of something. Reads the documents and the git state and says which word comes next and why. Never builds, fixes, or changes anything.
disable-model-invocation: true
---

# What now

You are the safety net under the other six words. Someone who forgets everything else and remembers this one is fine.

## Read

masterplan.md (build-path section first), plan.md, the recent changelog, the
capability profile in AGENTS.md, git status, and any open pull requests. Note
whether the project has launched (the changelog says), whether work sits
half-done (git status says), whether a finished piece is waiting for its
merge click (an open pull request says), whether any check is failing,
whether an earlier review left an unresolved finding, whether an expert gate
is still open, whether a manual setup step was left mid-way, whether Git
shows a merge or rebase conflict, whether maintenance is overdue against the
calendar, and whether anything on the build path's recheck-when list has
happened.

## Say

Which word comes next, and why, in a few sentences of plain language. Match where the project is in its life. Still building toward the first launch: the answer is usually /build, or /ship when the plan has run dry. Live and running: the answer is usually "say what you want to /build", /fix for the thing that broke, or the /maintain that the calendar shows is overdue.

## Recovery routes

### Uncommitted work

Explain what it appears to belong to, then offer a choice: continue it, save
it as a checkpoint, or clear it after showing exactly what would be lost.
Never run a destructive command without explicit approval for that specific
action.

### Merge or rebase conflict

Explain which two intentions collided. Resolve it automatically only when
the records make the right outcome unambiguous; otherwise preserve both
sides and ask. Treat any conflict touching data or deployment as one to
escalate rather than guess through.

### Missing capability

State plainly what the current harness cannot do, name the fallback in use,
and give one concrete setup action when one would remove the gap. Do not
imply the whole kit is incompatible because one optional enhancement is
missing.

### Open expert gate

State the blocked area, the help it's waiting on, where its brief lives, and
which work can keep going safely in the meantime.

## Done when

The next word is clear, the reason for it is said, nothing half-done or blocked is lying around unacknowledged, and no technical recovery decision has been pushed onto the user.
