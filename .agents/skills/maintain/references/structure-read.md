# Structure read

At the quarterly visit, on Build and run it and on Build with care, name the
places where two or more parts have started to depend on each other in a
circle since the last full visit. A change to one part of such a loop can
break the others, and none of them can be tested alone.

## Run the script

From the project, run `python3` with the `section-builder` skill's
`scripts/quality.py`, passing `loops --since-visit`. It reads the project as it was on
the `last-full-pass` date, again from Git history, and compares the loops
then and now. A loop that was already there is not printed.

- Exit 0: nothing got worse. Say nothing about structure.
- Exit 1: each `loop` line is one new loop, naming the line where each file
  imports the next. Those lines are the finding's place.
- Exit 2: the comparison could not happen. Say one line: "The structure
  comparison did not happen, because the project as it was at the last visit
  could not be read." Then carry on with the visit.

## Saying it

A new loop joins the other hot-spot inputs, under the cap of three proposals.
Rank it higher when it sits in an area the spread count or a repeated bug
already named. Say it in plain words:

"Since the last visit, `src/orders.js` and `src/invoices.js` have started to
depend on each other, at line 3 and line 1. A change to either can now break
the other."

## Reliability

No read here can tell whether the tool is reliable. That needs the tool
running under real failures. If a search of the code finds an outside call
with no time limit or no retry, say it as a missing pattern at a named place:
"`src/billing.js` at line 12 calls the payment service with no time limit
set." Never say the tool is reliable or unreliable.
