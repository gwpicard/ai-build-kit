# Document read

A README or a setup guide can go on naming a file, a command or a setting long
after the project stopped having it, and someone who does not read code cannot
tell. This read finds those names. It runs at every `/maintain` visit, on
every build path, in the truing, and it is the visit's one read for stale
names.

## Run the script

From the project root, run `python3` with this skill's
`scripts/document-claims.py`, passing `--since-visit`. It reads `README.md` and every
document AGENTS.md points at, and checks each file, link, `npm run`, `pnpm
run`, `yarn run` and `make` command, and environment variable they name. It
prints only names gone missing since the `last-light-pass` date, a document
changed longest ago first.

- Exit 0: every name still points at something real. Say nothing about it.
- Exit 1: each line is `document:line`, the kind, and the missing name.
- Exit 2: it could not run. Read the same documents for the same four kinds
  of name by hand, and say in the internal evidence that this was the
  fallback.

## Checking a finding

Open the document at the line and confirm the name is meant as a name in this
project. A name in an example of another project's setup is not a finding, and
nor is a name the document mentions only to say it does not exist. Look at the
open pieces too: a name already on one has been raised, so leave it.

## Saying it

Give at most three findings, in the script's order, each with its place:
"`README.md` line 7 names `scripts/deploy.sh`, which is no longer in the
project." Say how many more there are in one line, and offer to list them.
With any finding, say once: "This checks the names the documents use. It
cannot tell whether a described step still happens that way."

For each, offer to correct the name on the spot, changing that name and
nothing else in the sentence, or to file it as a piece. Never rewrite the
person's prose. A correction is saved with the truing's other corrections.
