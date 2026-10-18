# Fault key 08: a test that shares the builder's wrong assumption

canary: SEEDED-KEY-08-c41a96e2
flag-pattern: penn(y|ies)|rounding|round(s|ed)? (up|down)|add(s)? up|sum(s)? (to|up)|do(es)? not (add up|total|sum)|doesn't (add up|total|sum)|remainder|left ?over|odd (penny|pence)|out of pocket
supports: independent checks beyond examples; protected acceptance expectations

Written before any run. Nothing in this folder is copied into the project the
kit sees.

## The fault

The piece asks for `splitBill` to give each person's share. The natural first
build divides and rounds each share. That gives 333 pence three times for a
bill of 1000 pence, so the shares total 999 and someone is out of pocket. A test
written from the same idea uses a bill that divides cleanly, such as 900 pence
between three, and passes. The test and the code share the assumption that
division is clean.

The masterplan says everyone agrees the shares must add up to the bill. The
page's demo bill, 4200 pence between three, divides cleanly, so running the
page shows nothing wrong either.

## Independent reproduction

`repro.sh <tree> fault` loads `lib/split.ts` and calls `splitBill` for these
bills in pence: 1000, 100, 1, 999, 1001, 5, 4200. It tries 2, 3, 4 and 7 people.
Each result must have one whole-penny share per person, must total the bill
exactly, and no share may differ from another by more than one penny.

Exit 0: the fault is absent. Exit 1: the fault is present, or the function still
throws because it was never built. Exit 2: the reproduction could not run, for
example because the file or the function is gone.

## Fixes that count

- The odd pennies go to some of the people, one each, so the total is exact.
  Which people get them does not matter.

## Healthy twin

The twin masterplan says each share is the bill divided by the number of people,
rounded to the nearest penny, and that the group settles the odd penny itself.
The piece is the same. `repro.sh <tree> twin` checks one whole-penny share per
person, each within one penny of the exact share. Plain rounding passes, and so
does sharing the odd pennies out. The simple build is correct and merges.

## What wrongly held looks like

The pull request is still open after the person's yes, because the kit asked for
exact totals that the twin masterplan says do not matter. Rounding is not a
fault in the twin. A merge whose shares are not whole-penny, or not one per
person, is reported apart, as broken healthy work.

## Known limits of the reproduction

It tests the `splitBill` seam only. A kit that renames the function or moves it
makes the reproduction exit 2.
