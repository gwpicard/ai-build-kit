# Finish the piece and keep its limits

Run tests, the named type check and linter. Run the
`quality-checks` skill's `references/trim.md` and give its one line. Tell the person the action to try, expected result, known limits and
evidence. Give one address; stop previews you started after they try it, and
never use a browser tab they are using. Confirm behaviour where judgement is
needed. For work with no visible screen, run a made-up case and show output.
Describe failures as expected versus actual and fix the cause.

Run the reach check and its named tests, boundary check and loops read as
`quality-checks` directs. Run
`check-sensitive-areas.sh --change <base>` and report each area. Exit 1 means
the caution remains open and holds the pull request. Each pull-request piece
gets a fresh review; a person named by a caution must review it.

Apply `## Masterplan change` and update the comparison mark using
`records/references/masterplan-changes.md`. Move the mark to the saved build
even when the piece says `nothing` and the page stays as it is. If
`trued-mark.sh` does not exit 0,
leave the mark, say `/maintain` checks the masterplan against the code, and
continue.

- **Pull request:** update records, commit, then run `merge/scripts/upload-piece.py`
  with the piece's title in `--title` and `--body-file` holding a plain summary and
  `Closes #<number>`. If stopped, report the script's cause; say the person
  declined only when they did. Then run project
  checks. Use `gate.py brief`, send its packet for fresh review, refute each
  stopping finding and record findings with `gate.py record`. It writes review
  boxes and drops findings without evidence. Do not call it ready before checks
  pass. Read and fix a red check before pushing again. The `merge` skill handles
  the merge and recovery when checks did not start, including the
  [billing fallback](../../../../WORKFLOW.md#7-saving-work).
- **Flagged without acceptance:** take the pull-request route to the recorded
  condition, record it and that `/maintain` prepares a handover on request,
  label the piece `blocked`, name continuing work, and say the capability is
  not ready or live. This is a complete pass.

## Limits during a build

- Urgency does not remove the need for evidence.
- Small does not permit hidden scope.
- Visual work does not need a fake automated test.
- Work is not downgraded because setup is inconvenient.
- A review finding does not authorise unrelated cleanup, and the trim does not
  authorise a restructure.
