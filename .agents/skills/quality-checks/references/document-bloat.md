# Document bloat

At the quarterly visit, on Build and run it and on Build with care, look for
documents that repeat each other or that nobody reaches any more. Two copies
of one instruction drift apart, and a person who does not read code cannot
tell which is current.

## Run the script

From the project root, run `python3` with this skill's
`scripts/document-bloat.py`, passing `--skip-offered`. It reads every Markdown
document the project saves, apart from the records, the kit's own files and
anything in a folder starting with a dot. It leaves out each finding an
earlier visit offered.

- Exit 0: nothing to offer. Say nothing about it.
- Exit 1: `repeated` names a paragraph of forty words or more that appears
  word for word in two documents, at both places. `unreferenced` names a
  document no other file mentions. A README is never one.
- Exit 2: it could not run. Read the documents for the same two kinds by
  hand, and say in the internal evidence that this was the fallback.

A stale name inside a document is the document read's, not this one's.

## Saying it

Open each document the finding names and confirm it. A document nothing names
can still be wanted, such as a note somebody opens by hand, so each finding is
only an offer. Findings join the other hot-spot inputs, under the cap of three
proposals:

- "The release steps are written out in full in both `README.md` and
  `docs/release.md`. Keep them in one place and point to it from the other?"
- "Nothing in the project mentions `docs/scratch.md`. Delete it, or leave it?"

Change nothing without a yes, and keep the person's own words in the copy that
stays. With any finding, say once: "This finds copied and unused documents. It
cannot find two documents that say the same thing in different words."

Record what the person was offered, and only that: pipe the line of each
finding you named to the same script with `--record-offered`, exactly as
printed. A finding you did not name comes back at the next visit.
