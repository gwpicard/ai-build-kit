---
name: housekeeping
description: Find and clear what maintainer work on the kit left on this computer, such as run folders, mutation clones, worktrees, merged branches and old notes, with one approval and nothing deleted for good. For a maintainer after a release, after long test runs, or when the disk is filling. Load it by its path.
---

# Housekeeping

Kit work leaves copies behind. A test-bed update keeps about 2.7 GB per run,
`mutate.sh` keeps a full clone per run and never removes it, and Codex runs
leave package caches. `docs/MAINTAINING.md` lists where each tool writes, under
"Local leftovers". This skill clears them without losing evidence, unsaved work
or a key that still opens something online.

## Steps

1. Run `scripts/inventory.sh` from the repository root. It lists each place
   with its size, date and a note, and changes nothing.
2. Label every line CLEAR, KEEP or ASK by the rules below. For each, say what
   made it and what refers to it. Search the memory notes, open issues and
   pull requests (`gh issue list --search <name>`, `gh pr list --search
   <name>`), and the repository for the path or branch name.
3. Show the maintainer one list: CLEAR items with sizes and the total, KEEP
   items with the reason, and ASK items with what clearing each would cost.
   Ask once for the whole CLEAR list.
4. With approval, move each item to the Bin with `trash`. A deletion with no
   undo is on the blocked list. Delete a local branch only after checking it
   again at that moment. A branch on GitHub, an issue edit or an online
   project is the maintainer's to change; give the command.
5. Run the inventory again and report what moved, what stayed and why, and
   that the space returns when the Bin is emptied. Save the list in
   `.agents/tmp/housekeeping/<date>.md`.

## Rules

KEEP when any of these holds:

- a running process names the path (the inventory says "in use"), or another
  session is working in it;
- it has unsaved edits, or hand-made files that cannot be produced again;
- a memory note, open issue, open pull request, founding note or script names
  it;
- it is the latest run of its kind, or evidence for an open issue;
- it is a test bed, the current session's scratch folder, or the release-notes
  review for the next release.

CLEAR when all of these hold: a known kit tool or run made it, nothing above
applies, and a newer run of the same kind exists or the work it served is
closed. A local branch is CLEAR when `main` contains its last commit, or when
every commit subject on it is on `main`, and no worktree has it checked out.

ASK when the maker is unclear, when it is a backup branch, when another tool
owns it, or when it may hold a credential.

## Credentials

Never open a file that may hold a key, password or token. List its name only.
A folder with one is cleared after its online service is dealt with: check that
the matching project still exists with a read-only listing (`vercel project
ls`, `supabase projects list -o json`), and if it does, give the maintainer the
delete or rotate command first. A paused project can be resumed, so its keys
still count.

## Never

- Touch a project the maintainer works in, or any other project's folders,
  beyond reporting their size. Test beds and throwaway runs are the only
  projects in scope.
- Read any `.env` file.
- Clear anything in `~/.codex`, `~/.herdr` or another tool's home.
- Delete a branch from GitHub, or a branch an open issue or pull request still
  names.
