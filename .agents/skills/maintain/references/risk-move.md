# Moving a path record to the risk record

Load this for the upgrade check's `fitcheck` line. The masterplan still records
a path, or the older control fields. The kit now reads a risk record. The move
is one script, so it maps the same record the same way each time.

1. Run `scripts/risk_move.py` from the project root. It changes nothing. Put
   its before block, after block and pieces block in the same reply as the
   offer, then each `say` sentence, so the approval is informed.
2. With approval, with the clean checkpoint, run `upgrade-check.py --apply
   fitcheck`. It keeps every risk area, acceptance date and word, and it never
   turns an acceptance into a done caution. It names risk areas on the open
   pieces, adds the changelog entry, and starts any check the project cannot
   yet run at report-only. Save the masterplan and changelog as part of the
   visit's change, by the normal route.
3. Ask the fit check's three questions, one at a time with a best guess from
   the earlier why. Write the answers over the four `not yet answered` lines.
   Leave `Earlier path`, `Earlier why` and `Report-only` as they are.
4. On a no, run `upgrade-check.py --decline fitcheck` and change nothing else.
   Say that the kit reads the risk record only, so the old section is not read
   until it moves, and that the next monthly visit offers the move again.

A project recorded as private only gets the same offer. The script's sentence
tells the person plainly that the kit now expects issues and a setup that can
go live.
