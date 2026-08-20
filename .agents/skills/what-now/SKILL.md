---
name: what-now
description: Orientation for a lost or returning user. Trigger when someone asks what to do next, has been away a while, feels lost, or a session died in the middle of something. Reads the documents and the git state and says where the project stands and what to do next. Never builds, fixes, or changes anything. Type this command when you want it; it never starts on its own.
disable-model-invocation: true
---

# What now

You are the safety net under the other six commands. Someone who forgets everything else and remembers this one is fine.

## Read

masterplan.md (build-path section first), the project's pieces, the recent
changelog, the capability profile in AGENTS.md, git status, and any open pull
requests.

Refresh the printout with `.agents/tools/plan-refresh.sh` and read
`plan.local.md`. If GitHub cannot be reached, work from the printout and say when
it was written, because an old list a person can see beats no list at all. Note
whether the project has launched (the changelog says), whether work sits
half-done (git status says), whether a finished piece is waiting for its
merge click (an open pull request says), whether any check is failing,
whether an earlier review left an unresolved finding, whether flagged work is
still waiting, what the build-path section's `Accepted:` lines say the project
has knowingly given up, whether a manual setup step was left mid-way, whether Git
shows a merge or rebase conflict, whether a check-up is overdue, taken from
`.ai-build-kit-maintenance` when that file exists and from the changelog dates
when it does not, and whether anything on the build path's recheck-when list has
happened.

## Say

Open with where the build stands, in one line, then which command comes next and
why, in a few sentences of plain language.

Before the first ship, count: "you are four pieces in with three left, nothing
blocked and nothing half done". Once the project is live, drop the counts and
describe the state instead: "nothing is blocked and nothing is half done, three
things are waiting". A count reads as progress towards a finish line, and a live
project's list never empties.

Anything labelled `broken` comes first, before the counts. A thing that used to
work and no longer does outranks a thing that was never built: "the booking
confirmation is broken, so /fix comes before anything else". Name what is broken
rather than saying a piece is labelled.

Say how many entries are still notes rather than pieces, when any are, in the
words a person would use: "two things on the list are still just notes, so I
will ask you about them before building them". The printout marks them. Knowing
that before a build session is worth more than meeting it during one.

Where a waiting piece says why it is waiting, pass the reason on rather than the
label: one needs a few questions, one needs a throwaway build before anybody can
decide, one needs a fact somebody has to go and find. A person who knows which
of the three it is can often supply the answer on the spot.

Say piece names, never issue numbers. Say dependencies as sentences: "deposits
cannot start until card payments are set up", never "blocked by #9". Name at
most three things; if more apply, say how many and name the nearest. More than
three stops being orientation and becomes a report. Match where the project is in its life. Still building toward the first launch: the answer is usually /implement for the next ready piece, /plan to shape a new one, or /ship when the plan has run dry. Live and running: the answer is usually "say what you want to /plan", /fix for the thing that broke, or the /maintain that the recorded check-up dates show is overdue.

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

### Flagged work waiting

State the blocked area, the help it's waiting on, where its brief lives, and
which work can keep going safely in the meantime. Say that the wait ends either
way: when that help happens, or when they accept the risk and it goes on the
record.

### Accepted risks

Where the build-path section carries `Accepted:` lines, say what the project has
given up, in one line each and in the words the person would use. This is a
reminder rather than a reopened argument: name what it was, when, and who
accepted it, and say plainly that it can be revisited by asking for the check
that was skipped. Do not ask again unasked.

## Done when

The next command is clear, the reason for it is said, nothing half-done or blocked is lying around unacknowledged, and no technical recovery decision has been pushed onto the user.
