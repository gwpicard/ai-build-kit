---
name: maintain
description: Make the project true and healthy. Runs routine records, live-copy, due upkeep, handovers and retirement. Use after outside work, before a handover, after time away, or when retiring a tool. A session that died part-way goes to what-now first. Do not use for building, repairing or planning.
---

# Maintain

Every visit makes the records true, compares the live copy with `main`, and
finishes any kit update. Monthly or quarterly work runs only when due. Report
findings before applying anything beyond routine updates.

In Codex, if a push, fetch or remote check fails with `unable to get password
from user`, run the installed `setup-ai-build-kit` skill's
`templates/foundation/codex-github-check.py` with python3 and `--message`.
Give its sentence and stop without signing in or retrying.

## Every visit

1. Load `references/truing.md` and follow it. It saves corrections before
   later steps. Keep the person's uncommitted work out of every commit. Report
   it and point to `/what-now`; clean-checkpoint steps, including kit updates,
   wait, while read-only steps continue.
2. Compare the live copy with `main` using the `live-copy` skill. Do not change
   the live service or changelog. Offer a later `/setup-hosting` run for
   backups, restores, previews or recipe checks.
3. Check `.ai-build-kit-maintenance`. Monthly work is due 30 days after
   `last-light-pass`, or founding if absent. Quarterly work is due 90 days
   after `last-full-pass`, at founding if absent, or when a handover is asked
   for. Either runs when requested. A records-only visit does only these
   every-visit steps. Say when skipped work falls due; each run saves its own
   changes.
4. Finish a kit update using `references/kit-update.md` on every visit; the
   monthly routine's first step does it instead. In Codex, offer its session-start
   GitHub check.

## Due routines

When monthly work is due, load `references/monthly.md` and follow it in order.
For quarterly work, also load `references/quarterly.md`.

## Handover and retirement

For a handover or retirement, load `references/handover-retirement.md`.

## Done when

Records match events; the upgrade check and live-copy gap are reported; due
work and approved changes are saved; and the person knows when the next visit
is due.
