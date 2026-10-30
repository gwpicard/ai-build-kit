---
name: live-copy
description: Work with the live copy safely. Pass a secret a check needs by its location, ask before any change to a live service, and roll back to an earlier version with approval. Used by setup-hosting, maintain, merge, repair and what-now.
user-invocable: false
---

# The live copy

The live copy is the one the team uses. These rules hold whichever command
reads it or changes it.

## Comparing the live copy with main

Read-only. Where "How it stays running" records a live address and AGENTS.md
names a recipe, run that recipe's `scripts/live-check.sh`, in its folder under
the installed `setup-hosting` skill's recipes folder, from the project root with
`--address`, the database password's location as "A secret a check needs" says,
and `--needs` with the names on any open piece's `Live side needs:` line. Where
the recipe reads its checks from a paste, ask in one sentence for the health
answer and setting names. Say its lines as printed, and nothing more about a
read that matches. Exit 0 no gap, 1 a gap, 2 a read that could not be made. Off
a recipe, say in one line that the kit cannot compare the live copy. Without a
live address, say nothing. If an address block says
`Deploys on merge: no`, its live check reads the health route's commit and gives
the companion's redeploy instruction or names the host's Redeploy button when
a merge is not live. The /host command belongs to that companion. The companion
checks the commit after redeploying.

## A secret a check needs

Pass a secret by the location "How it stays running" records, never its
value; the scripts read it themselves. With none recorded, ask once and record
the answer as a location. A secret given as an answer is recorded nowhere: say
it is now in this conversation and ask for it to be rotated. Asked to show a
secret, say plainly that the kit does not read or show it, because anything
shown here stays in the conversation's record, and that they can open it at
its location. Where
the location is unknown, the check is a warning saying so, never that the
secret is missing.

Never use a login, token or password another tool keeps for itself, in the
keychain, a credential store or its files. Use only a tool's own commands and
keys the tool already sends to the browser. Read a setting where the recipe
names a script for it before asking the person; where the kit cannot, say so
and name the page where it lives.

## A change to a live service

Outside a first launch, a command that changes a live service's settings or
data requires approval naming every change it makes. Say whether it can
be undone. A no leaves the service as it was, and the step is a warning.
With that approval, record it with the `records` skill's `scripts/approval.py`, as
`approval.py yes "<change>" --words "<their words>"`. A recipe step that
changes something live refuses without it and names the change it waits for.
Name the change as the step's script without `.sh` followed by its arguments,
such as `migrate --apply`, and let the step spend the approval itself.
Changing the masterplan's `Access:` line is one: say who gains or loses the
way in, and with that approval run the recipe's Access scripts, write the new line,
dated unless private, and add a changelog line.
Never write a secret key to a shared temporary folder.

## Rolling back

Offer the earlier version back first where a live address is recorded, the
recipe says how to roll back, the live tool broke, and a recent merge is the
likely cause, once the changelog, the closed pieces or the person show the
version before it worked. Say in one line what comes back and that it puts
nothing else right. Either way, the repair is shaped in `/shape`.

A rollback requires approval naming it, even where the recipe names the
command. Before asking, name the version it brings back by its change and
date, from the host's list, and say it does not undo a database addition. With
that approval, run the recipe's rollback once, or give its words to whoever clicks
it, and check health names the earlier version before anything else.

Record it in a dated changelog line through the records route, and on the
repair's piece. Where the host now holds the live copy, say so in the same
reply and write a dated hold line into "How it stays running". Promote the
repair once it has merged and its build is listed, after separate approval naming that promotion,
then remove the hold line. Off a recipe, say that whoever runs the host can
bring back an earlier build it still keeps.
