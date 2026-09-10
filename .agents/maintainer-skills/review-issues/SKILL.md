---
name: review-issues
description: Read every open issue in this repository, group them by theme, and name the best next piece to pick up. For a maintainer deciding what to work on. Reports only; it never edits an issue or applies a label. Load it by its path when you want it.
---

# Review issues

The kit's own `/queue` and `/what-now` read `plan.local.md`, which sorts a
backlog by the labels a project built with the kit uses. This repository uses
its own labels, so that printout drops almost everything into a single heap.
This is the maintainer's read of the same backlog.

It answers one question. Given everything open, what is worth picking up next.

## Read

Ask GitHub directly. `gh issue list --state open --json
number,title,body,labels,url` gives the text and the labels. `gh api
"repos/OWNER/REPO/issues?state=open"` gives two things the first call leaves
out: `sub_issues_summary`, which says whether an issue is a parent and how many
of its parts have closed, and `issue_dependencies_summary`, which says whether
anything open is holding it up.

Read the bodies, not only the titles. A backlog this size is small enough to
read properly, and titles alone will put two unrelated pieces in one theme.

If GitHub cannot be reached, say so and stop. A recommendation drawn from a
list that failed to load is worse than no recommendation.

The two calls must agree on how many pieces are open. An empty list is a valid
answer meaning nothing is open, and it is also what a passing fault looks like.
The second call returned an empty list once while this skill was being tried
out, with thirteen pieces open at the time, and recovered on the next attempt.
So compare the counts, and where they disagree, say the backlog could not be
read and stop. Telling somebody their backlog is empty when it is not is the one
wrong answer that looks like a right one.

### What makes a piece ready

A piece is shaped when its body carries a `## Done when` section, which is a
condition somebody can check. The `refined` label says a person judged it ready.
Those two signals do not always agree here. Where they disagree, say so rather
than quietly picking one, because a piece marked refined with nothing checkable
in it is usually worth a second look.

A piece is unshaped when it carries `refine` or `needs-answers`, or when it has
neither a checkable condition nor the refined label. Never recommend an unshaped
piece as the next thing to build. It can be the next thing to shape, which is a
different recommendation and worth making when little else is ready.

A piece is held up when something open is named in its `blocked_by`, or when it
is one part of a parent whose other parts come first.

### Themes

Work the themes out from what the issues say. Do not read them off the `area:`
labels. Several issues carry no area label at all, so that grouping does not yet
exist, and reading it back would only repeat the gap.

Where a theme you found matches an area label already in use, say so, since that
is a sign the label is doing its job. Where a theme has no label, say that too
and leave it there. Applying a label is somebody's decision, not this read's.

## Say

Start with the themes. Name each one in a few words, say which pieces sit in it,
and say in one line what the theme is really about. This is the part that earns
the command, because it is the view nobody has while reading issues one at a
time.

Then name one piece as the next thing to pick up, with the reason in ordinary
words. The reason is the useful half. "It is the only shaped piece in the
largest theme" tells somebody something. "It seems important" does not.

Then at most two runners-up, and no more. `/what-now` holds the same cap for the
same reason, which is that a list of everything hands the decision straight back
to the person who asked for help making it.

Name every piece by its title, never by its issue number. A number is a pointer
the reader has to go and look up, and this repository holds that rule everywhere
else.

Where nothing is shaped, say that plainly and recommend what to shape first,
rather than dressing unshaped work up as ready.

Where the themes give no honest reason to rank one above another, say that
instead of inventing an order. This repository has not yet written down what
finished enough for 1.0 would mean, so there are backlogs where the truthful
answer is that the choice rests on grounds this read cannot see.

This command reports and changes nothing. It does not edit an issue, apply a
label, link a part to a parent, or open anything. Where the read turns up
something worth changing, such as two pieces covering the same ground, say it
and leave it with the maintainer.

## Done when

The maintainer can see the backlog grouped by what the work is about, has one
recommended next piece and the reason for it, and knows which pieces are not
ready and why. Nothing on GitHub has changed.
