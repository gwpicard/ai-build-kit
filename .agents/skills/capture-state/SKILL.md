---
name: capture-state
description: Reconcile the documents backward against what's actually in the repo. Trigger at the end of a working session, after any work done outside the skills, when a long session has gone foggy, or before handing work to a teammate. Do not use to build or fix anything.
---

# Capture the state

The documents are supposed to describe reality. Your job is to make that true again by reading what actually happened and correcting the records, not by trusting what the records claim. You change documents only, never code.

## The routine

1. Read what happened: the commits and diffs since the last CHANGELOG.md entry, plus the tool's actual behaviour where it's cheap to check.
2. Write the missing changelog entries, dated, grouped under Added, Changed, Fixed, Removed, with the why where it isn't obvious.
3. Reconcile masterplan.md: flip feature statuses that reality has overtaken, correct any section the work has made untrue, prune planned items that are clearly dead, and fold shipped behaviour into the description. Edit in place; the document describes the present and stays about a page. Flag it if it passes roughly 120 lines.
4. Check AGENTS.md against how the project actually works now (commands, conventions); correct what drifted.
5. Anything you cannot reconcile, a diff that contradicts the masterplan, behaviour you can't explain, gets listed as a plain question for the team rather than guessed at.
6. Summarise in a few sentences where the project now stands and what's in flight, so a fresh session pointed at the documents can continue cleanly. Commit the document updates with the message "capture state".

This is the way out of a foggy session: capture, then start fresh pointed at the documents.
