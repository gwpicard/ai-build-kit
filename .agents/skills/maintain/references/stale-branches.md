# Old branches

Once a branch's work has reached the default branch, the branch has done its
job, but nothing removes it, and a long list hides the few still in use. At
every monthly visit, on every build path, name the branches that can go and
the command that removes each one. Never remove a branch.

## Run the script

Read the project's AGENTS.md and masterplan for any branch they say stays,
such as one a release is published from. Never set a branch aside by its name
alone.

From the project, run `python3` with this skill's `scripts/stale-branches.py`,
adding `--keep <name>` for each branch the records say stays. It reads this
computer and GitHub, keeps them apart, and keeps the branches Git confirms
apart from the ones only GitHub records as merged. It sets aside the default
branch, any branch checked out, any with an open pull request, and any GitHub
protects from deletion. It changes no branch.

- Exit 0: no branch qualifies and nothing was set aside. Say nothing.
- Exit 1: pass its report on as it stands. Never run a command in it. The
  person runs each one, and chooses which.
- Exit 2: it could not find the default branch. Say the branch check did not
  run, and carry on with the visit.

## What it cannot tell

Merged work is the only sign it reads. It cannot tell whether somebody still
means to use a branch, whether a later change undid part of a squash-merged
one, or anything about a copy on a teammate's computer. Say so if the person
asks.
