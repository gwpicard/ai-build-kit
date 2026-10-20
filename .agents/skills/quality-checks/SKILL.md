---
name: quality-checks
description: Run the kit's quality reads by script and act on their exit codes. The reach check, the trim, test strength, the check floor, boundary rules, and the structure, waste, document and old-branch reads.
user-invocable: false
---

# Quality checks

Every quality check is run by a script or by the project check, and decided
by an exit code: 0 nothing to do, 1 findings, 2 could not run. The agent acts
on what the script prints. The person hears a finding only when it asks
something of them, and never needs to read one to keep the tool working.

## Where each check runs

| Check | Runs | How |
|---|---|---|
| Type check and lint | Project check on every pull request, and before hand-over | `references/check-floor.md` |
| Risk-area map and boundary rules | Project check on every pull request | `check-sensitive-areas.sh`, `references/boundary-rules.md` |
| Trim | Every build, before the person tries it | `references/trim.md` |
| A trim left the tests alone | Every trim commit, and the project check on every pull request | `trim-commit.sh`, `check-tests.sh`; `place-trim-check.py` brings the step to an older project |
| Reach | Shape and every build | `quality.py reach`; act on its exit code |
| Tests stay frozen | Every project check on a pull request | `check-tests.sh` in the project template |
| Tests prove the change | Every build, after behaviour is built | `quality.py tests --base --piece` |
| Structure, one change | Every build, before the save | `quality.py loops --base`, as "During a build" says |
| Tests notice a breakage | A change inside a mapped risk area | `quality.py strength --base`; repairs include the regression test |
| Stale document names | Every `/maintain` visit | `references/document-read.md` |
| Old branches | Monthly visit | `references/stale-branches.md` |
| Waste, structure, document bloat | Quarterly visit | `references/waste-read.md`, `references/structure-read.md`, `references/document-bloat.md` |

Check a boundary with sentrux or dependency-cruiser where present, or by
reading the changed imports.

A build's structure check compares with the commit the piece started from,
read again from Git history. A visit's reads leave out what an earlier visit
offered, which `.ai-build-kit-maintenance` records, finding by finding. A
finding that never reached the person comes back.

The tests read runs once after the build. See
`references/tests-prove-change.md` for its report lines and exit codes.

## During a build

Run `python3` with this skill's `scripts/quality.py`, passing `loops --base
<start commit>`. Exit 0: say nothing. Exit 1: say "This change added a loop
between <part> and <part>." A boundary crossing gets "This change crossed the
boundary around <area>." Exit 2: note it internally. Never show a score. The
person may fix it or leave it; record the choice on the piece.

## Acting on findings

1. Exit 2 means some part of the read could not run, and a `not-checked` line
   names each one. Act on any findings it printed. Then read the code directly
   for each part it names. That reading is the last resort, so say in the
   internal evidence that it was the fallback, and for which part.
2. Before a fetched engine is trusted, check that its repository is still
   maintained. If it has been archived, say so in one line and leave that
   check to the fallback.
3. Order findings by what they cost the person, and show no more than the
   read's cap. The quarterly visit's cap of three proposals holds across every
   read that feeds it. Summarise the rest in one line.
4. Nothing new is a complete answer. Say nothing, or one line if the person
   asked for the read.
5. No score, grade or percentage reaches the person, and no read introduces a
   term they have to be taught.

## What a read may never claim

A read says what it checked and what it found. It never says the rest of the
project is fine, because nothing checked the rest. Whether a retry survives a
real failure, whether two pieces of code written differently do the same job,
and whether a described flow has quietly changed shape are beyond every read
here. Say so when the person asks.
