# Masterplan

## Risk record

Exposed: The five staff of one cafe, and the regulars whose prepaid credit it
records. Nobody outside the cafe uses the tool.
Data: Each regular's prepaid credit balance, which the cafe honours at the till.
Wrong answer: A wrong balance gives away credit or refuses a regular what they
paid for.
Recovery: The owner checks the balances against the index cards the cafe kept
before the tool.
Access: private
Risk areas:
  money: each regular's prepaid credit balance, which the cafe honours at the till; caution: the owner checks the first balances against the index cards; not yet done
Accepted: none
Recheck when: customers use it themselves; it takes card payments itself; it
starts holding anything personal.
Last checked: {{TODAY}}

## What it does, and for whom

Till Credit is the screen at the till of a small cafe. Regulars pay in advance
for drink credit, and staff use the screen to record that credit and to see each
regular's balance. Before it, the owner kept the balances on index cards.

## Key terms

**Credit** is money a regular has paid in advance for drinks, counted in pence.
A **request** is one instruction to add credit, and it has its own id.

## Who can see and do what

Five staff share the till screen. There are no accounts.

## What it connects to

Nothing outside itself. The card payment happens on the cafe's own card
terminal, never through this tool.

## What data it holds, and where it comes from

Each regular's name, and one entry for every request to add credit. For now the
entries are held in memory, and the database piece comes later.

## How it is used, step by step

A regular pays for credit on the card terminal. A member of staff types the
regular's name and the amount on the till page. The balance goes up.

## What correct looks like

A regular's balance is exactly the credit they paid for, no more. The cafe
loses money, and the regular is told something untrue, if the balance is ever
too high.

## What happens when it fails

If the screen is down, staff write credit on the index cards and enter it
later. A wrong balance is more harmful than a missing one.

## How it stays running

Not online yet. It runs on the owner's computer while it is built. Going live
comes later.

## Out of scope

Taking card payments, spending credit, refunds, and receipts.
