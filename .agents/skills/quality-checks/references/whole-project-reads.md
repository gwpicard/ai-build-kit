# Code quality checks

Every quality check is run by a script or by the project check, and decided
by an exit code: 0 nothing to do, 1 findings, 2 could not run. The agent acts
on what the script prints. The person hears a finding only when it asks
something of them, and never needs to read one to keep the tool working.

## Where each check runs

| Check | Runs | How |
|---|---|---|
| Type check and lint | Project check on every pull request, and before hand-over | `check-floor.md` |
| Sensitive-area map and boundary rules | Project check on every pull request | `check-sensitive-areas.sh`, `boundary-rules.md` |
| Trim | Every build, before the person tries it | the `quality-checks` skill's `references/trim.md` |
| A trim left the tests alone | Every trim commit, and the project check on every pull request | `trim-commit.sh`, `check-trim.sh`; `place-trim-check.py` brings the step to an older project |
| Structure, one change | Every build, before the save | `quality.py loops --base` |
| Tests notice a breakage | Offered on a Build with care build; too slow for the project check | the `quality-checks` skill's `references/test-strength.md` |
| Stale document names | Every `/maintain` visit | the `quality-checks` skill's `references/document-read.md` |
| Old branches | Monthly visit | the `quality-checks` skill's `references/stale-branches.md` |
| Waste, structure, document bloat | Quarterly visit | the `quality-checks` skill's `references/waste-read.md`, `structure-read.md`, `document-bloat.md` |

A build's structure check compares with the commit the piece started from,
read again from Git history. A visit's reads leave out what an earlier visit
offered, which `.ai-build-kit-maintenance` records, finding by finding. A
finding that never reached the person comes back.

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
