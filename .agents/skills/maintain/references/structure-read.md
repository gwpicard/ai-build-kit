# Structure read

At the quarterly visit, on Build and run it and on Build with care, name the
places where two or more parts depend on each other in a circle. A change to
one part of such a loop can break the others, and none of them can be tested
alone.

## Run the script

From the project, run `python3` with the `section-builder` skill's
`scripts/quality.py`, passing `loops --skip-offered`. It prints each loop in
the project that no earlier visit offered.

- Exit 0: nothing to offer. Say nothing about structure.
- Exit 1: each `loop` line is one loop, naming the line where each file
  imports the next. Those lines are the finding's place.
- Exit 2: the read could not happen. Say so in one line, then carry on with
  the visit.

Record what the person was offered, and only that: pipe the line of each loop
you named to `quality.py offered loops`, exactly as printed. A loop you did
not name comes back at the next visit.

## Saying it

A new loop joins the other hot-spot inputs, under the cap of three proposals.
Rank it higher when it sits in an area the spread count or a repeated bug
already named. Say it in plain words:

"`src/orders.js` and `src/invoices.js` depend on each other, at line 3 and
line 1. A change to either can break the other."

## Reliability

No read here can tell whether the tool is reliable. That needs the tool
running under real failures. If a search of the code finds an outside call
with no time limit or no retry, say it as a missing pattern at a named place:
"`src/billing.js` at line 12 calls the payment service with no time limit
set." Never say the tool is reliable or unreliable.
