---
name: fit-check
description: Fill the project's risk record, name each risk area with its caution, and give the risk notice where one is due. Used at founding, when a request changes the project, before hosting, at the quarterly visit, and when a repair stalls.
user-invocable: false
---

# The fit check

Fill the risk record and name each risk area with its caution. Run at founding,
when a request changes users, data, money, autonomy, promises or reliance,
before first `/setup-hosting`, quarterly `/maintain`, and before a handover.

## The three questions

Ask one at a time, with a best guess:

1. Who is exposed if this fails, including people outside the team or anyone
   whose contract, promise or deadline depends on it?
2. What data does it hold, and what can the team not afford to lose?
3. How would you recover from a failure?

The answers fill `Exposed:`, `Data:`, `Wrong answer:` and `Recovery:` in the
risk record, by `references/risk-record.md`. Then check for a manual fallback,
known locations for data, credentials, services and bills, owners for alerts,
backups, access and recovery, and records a new agent can follow. Gaps become
tasks or masterplan facts in "How it stays running". Record credential
locations, never values.

## Access

Record `Access: private` for invited users, `open address, invitation only
(decided YYYY-MM-DD)` if anyone can reach the address but only invited people
can sign in, or `public (decided YYYY-MM-DD)` if anyone can make an account.
Never refuse an open setting. A live change requires approval naming its effect,
then follows the recipe's access change and check and goes in the changelog.

## Risk areas

Consider redesign first. Name each area the answers or the request touch that
survives it, in the tool's own words, and put its caution beside it. Change a
default only when the tool's facts justify it, and record why.

| Area | What counts | Default caution |
|---|---|---|
| Personal or sensitive data | Health, pay, home address, identity documents or other personal facts. | Independent access review before real data. |
| Money | Real payments or figures used as bills. | Managed service keeps card details out of the tool; owner checks first figures against a known case. |
| Sign-in and permissions | Outside sign-in or separated access. | Managed sign-in keeps passwords out of the tool; independent access review before outside use. |
| Automatic action | Hard-to-reverse messages, changes or actions. | Person approves until a live run proves it; provide an off switch. |
| Irreplaceable live data | The only copy of data the team cannot recreate. | Back up, restore and rehearse on a copy before changing the original. |
| Regulated decisions | Medical, legal, financial, employment or safety decisions. | Qualified person signs off before anyone acts. |

For a public tool, the sign-in notice also says strangers can reach the address
and create accounts, and a payment service or similar may need a developer.
For the full notice and acceptance rules, load `references/risk-notice.md`.

## Rechecks and going live

Keep an area's caution while exposure remains. Run the full check at founding,
after several changes, before hosting or handover, and quarterly. For a bounded
change, check affected questions and update `Recheck when` and `Last checked`;
if unclear, run it all.

At launch, complete the caution and record `done`, or give the full notice. On
acceptance, record the person's words and date as `Accepted:` and mark the area
`accepted`. If a named reviewer is unavailable, `/maintain` offers a handover
once. For automatic-work settings, follow `references/own-run.md`.

## References

- `references/risk-notice.md`: notice and acceptance rules.
- `references/risk-record.md`: masterplan fields and area records.
- `references/own-run.md`: opt-in automatic merge and parallel work.
