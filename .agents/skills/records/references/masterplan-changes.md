# Keeping the masterplan current

Each piece carries its change to the
masterplan as [pieces.md](pieces.md) describes. The masterplan keeps its
sections and describes the present.

## Apply a piece's change

At save time, apply the piece's `## Masterplan change` to the named section,
checked against what was actually built. "Nothing" leaves the prose alone.
Where the result differs from the piece, correct the piece first. A safely
blocked capability stays described as waiting, never as live.

When recovering work, read the changes on pieces whose work landed, closed ones
included, and apply only what the page still lacks, in landing order. Never add
a line twice or restore something a later piece removed. An open or parked
piece is not proof its work landed. A piece with no such section has its change
recovered from the saved work.

## Record what was checked

One `Trued against: <full commit hash>` line sits beside the masterplan's
title. It names a saved state checked against the page, and only the agent
reads it. A new masterplan starts with `Trued against: not yet checked`, and
founding writes its first checkpoint's hash there in a records-only commit.
Nothing else ever goes on that line.

Never move the mark past work that has not been checked, or past uncommitted
work. The `records` skill's `scripts/trued-mark.sh` says whether the
mark can be used: exit 0 prints its commit, any other exit says why not. An
unusable mark is set only by the truing, after comparing the whole page with
the code. A build leaves it, says in one line that /maintain checks the whole
masterplan against the code, and carries on.

`/implement` applies the change, saves the code, then writes that saved commit
into the mark and saves it in a records-only commit on the same route. Both
belong to the piece's pull request, and the merge keeps them, since a squash
would leave the marked commit outside `main`. The truing writes the commit it
has just reconciled. Neither writes the hash of the commit that holds the
mark.

## Read the gap at each visit

Every /maintain visit reads this in its truing, before anything moves the
mark. Read the mark with `scripts/trued-mark.sh`. Count later landed code
changes along the first-parent history, each merge once, leaving out
records-only commits and unmerged work. Count how many touched the subjects of
the masterplan's data, permissions or connections sections, following renamed
paths and using the risk-area map where one exists.

When any count is above zero, say one line with the total and the subjects
touched, then check the page: "Eleven changes have landed since the masterplan
was last checked, and four touched what data it holds; I will check whether
the page still matches." Stay quiet when all three are zero.

Where the mark cannot be used, do not invent a count or reset it. Say the last
check cannot be established, and compare the whole page with the code. The
count never moves the mark; only the truing does, once it has checked the
page.
