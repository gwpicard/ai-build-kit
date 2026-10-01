# Merging a pull request

The one merge step for every route. section-builder, `/implement`, `/fix`,
`/ship` and `/sync` load it whenever a pull request is ready to merge, and none
of them keeps its own copy of the rule. It covers the merge alone: the save that
opened the pull request is section-builder's step 8, and what happens to the
piece afterwards is its step 9.

## The yes that names it

A person decides whether to merge. Before a merge, name each pull request in
one plain line: its number, its title and what it changes for the person. Then
ask for a yes that names the merge, for example: "Say yes to merge 12, which
adds the invoice list." Merge only when the person's reply plainly covers that
merge.

A reply that names several pull requests, such as "merge 1, 2 and 4", counts
for each one it names and for none it leaves out. Where the person's own words
already named the merge, as in "merge both and put it live", that is the yes:
do not ask again. A yes to going live, to a hosting step, or to any question
asked before the merge was named does not cover it: ask again, and merge
nothing until they answer. A no leaves the pull request open.

## Before any merge

Merge only a pull request whose project check is green. Never merge over a red
check: say it is red, and take it to `/fix`.

A pull request that stacks on another piece's branch is never merged before its
base. Where the base is still open, say which to merge first, and merge the base
first when the person's yes names both. Once the base has merged, check that the
stacked pull request now aims at `main`, and change it with
`gh pr edit <number> --base main` where it does not, before you merge it.

## How the merge is made

Make an approved merge on the pull request itself, with `gh pr merge <number>`.
Never merge the branch on this computer and push `main`, and never delete the
branch yourself: the project's settings delete a merged branch. Where GitHub
cannot be reached, nothing merges. Say in one line that the merge waits, that
it can be asked for again once GitHub answers, and that the person can merge it
on GitHub themselves.

## When a merge goes live

The masterplan's "How it stays running" section records how the tool goes live
in its `Goes live:` line. `through /ship` is the kit's default: a merge reaches
a preview, and `/ship` promotes it to live. `on every merge` means the host puts
each merge to `main` live, so the merge is itself a launch.

Where the line is missing, read the going-live section of the project's recipe.
Where it says a change to `main` goes live, treat the merge as `on every merge`.
Otherwise ask, in the reply that asks for the merge, whether merging puts the
tool live, and treat it as going live until the person says it does not. Write
their answer into "How it stays running" as the `Goes live:` line, with the
merge's save or the next one, so the question is asked once for each project.

On `on every merge`, the ask says so, as "this goes live now": for example, "Say
yes to merge 12, which adds the invoice list. This goes live now." Where no live
address is recorded in "How it stays running", this merge is the first launch.
Before asking for it, load the `ship` skill and run its first-launch checks on
the current build path, up to going live. The merge is then that path's
going-live step, and `/ship` records what it found, the live address included,
so a later merge is not taken for a first launch. Where `/ship` itself makes the
merge, it has already run those checks, and the merge step does not run them a
second time.

## Pre-approval for a run

Before a run starts, the person may say that pieces which pass may be merged.
Write that as `merge_preapproved` in the run's state file. It holds for that run
alone and ends with it, so it never reaches a later run or a piece built outside
one. It covers merges that reach a preview. Nothing goes live without the
person's yes naming it, or `/ship`.

With pre-approval, merge a piece only when all six hold:

1. its project check is green;
2. its review found nothing worth stopping for;
3. its pull request flags no choice for the person to confirm, and names nothing
   the walk-through could not see;
4. it touches no sensitive area named in the build-path section, accepted or not;
5. the person has not opted in to check it: the piece has no `Waiting on you:
   try it` line, and `.ai-build-kit-maintenance` has no `check-myself|yes` line;
6. its merge would not go live: the `Goes live:` line says `through /ship`. Where
   it says `on every merge`, where the recipe says a change to `main` goes live,
   or where the route is not known, the merge would go live.

A piece that fails any of the six is not merged. It stays in `to check` for the
person, and the run's report names the condition it failed. The rule for a
stacked pull request holds under pre-approval too.
