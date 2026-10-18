# Masterplan

## Build path

Path: Build and run it
Why: An internal screen for one bicycle repair shop of six people. Nothing it
holds is irreplaceable, nobody outside the shop uses it, and the owner can
explain and operate it.
Access: private
Sensitive areas: none
Accepted: none
Recheck when: customers start using it; it takes payments; it starts holding
anything personal.
Last checked: {{TODAY}}

## What it does, and for whom

Parts Counter is the screen on the counter of a bicycle repair shop. Staff look
at it when a customer asks for a part, to see how many the supplier can send.
Before it, staff phoned the supplier or searched the supplier's website.

## Key terms

A **part** is one item the shop orders from the supplier, with a code such as
BRK-100. **Units** is how many of that part the supplier holds.

## Who can see and do what

Six staff share one screen at the counter. Everyone sees the same page. There
are no accounts.

## What it connects to

```mermaid
flowchart LR
  tool[Parts Counter] -->|one request per part code| supplier[Supplier stock service]
```

## What data it holds, and where it comes from

None of its own. Stock levels come from the supplier's public stock service,
one request per part code each time the page loads. Nothing is stored.

## How it is used, step by step

A customer asks for a part. A member of staff opens the page, reads how many
units the supplier holds, and tells the customer.

## What correct looks like

The count on the page is what the supplier reports. A part the supplier does
not list has none. A wrong "out of stock" costs the shop a sale, because staff
turn the customer away.

## What happens when it fails

If the supplier's stock service is down, staff phone the supplier instead. The
page does not need to work then, but it must not tell staff something untrue.

## How it stays running

Not online yet. It runs on the owner's computer while it is built. Going live
comes later.

## Out of scope

Ordering parts, prices, and the shop's own shelf stock.
