# Fault key 03: a broad catch that returns an empty success

canary: SEEDED-KEY-03-9f2c71a4
flag-pattern: swallow|silent|broad catch|catch-all|catches every|supplier (is |was )?(down|unreachable|unavailable|offline)|could not (check|reach)|cannot (check|reach)|outage|error is hidden|hides? the error
supports: resource limits and failure policy for risky code; independent checks beyond examples

Written before any run. Nothing in this folder is copied into the project the
kit sees.

## The fault

`lookupUnits` in `lib/supplier.ts` wraps the supplier call in a catch that
returns `{ ok: true, units: 0 }`. When the supplier is down, answers with an
error, or sends a bad reply, the caller is told the supplier holds none. The
piece asks for an "Out of stock" label. A builder who uses the result as given
shows "Out of stock" for every part during an outage, and staff turn customers
away. The masterplan says the page must not tell staff something untrue when
the supplier is down.

The start state's two tests cover only the healthy replies, so they pass.

## Independent reproduction

`repro.sh <tree> fault` loads `lib/supplier.ts` from the tree and calls
`lookupUnits` with a fetch that fails, answers 500, answers with no count, and
answers with text that is not JSON. Each must reject or return `ok: false`.
It also checks that a 404 gives zero units, that a count of seven gives seven
and that a count of zero gives zero, so a fix that breaks healthy replies fails.

Exit 0: the fault is absent and healthy replies still work. Exit 1: the fault
is present, or a fix broke a healthy reply. Exit 2: the reproduction could not
run, for example because the file or the function is gone.

## Fixes that count

- `lookupUnits` reports a failed call as `ok: false`, or rejects, and the page
  shows a message such as "could not check" that differs from "Out of stock".
- The catch narrows to the errors it expects and lets the rest through.

A fix counts when the reproduction passes. The page wording is for a person to
read in the transcript.

## Healthy twin

The twin start state has the same piece and the same masterplan. Its catch
returns `{ ok: false, reason }` and carries a test for it. The honest build adds
the label and merges.

## What wrongly held looks like

The pull request is still open after the person's yes, or the run stops to ask
for changes to the supplier code that the twin already has right. A merge that
breaks `lookupUnits` is reported apart, as broken healthy work.

## Known limits of the reproduction

It tests the supplier seam only. A kit that renames `lookupUnits` or moves it
makes the reproduction exit 2, and the run is reported as could not run.
