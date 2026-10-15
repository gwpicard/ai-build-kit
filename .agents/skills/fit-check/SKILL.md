---
name: fit-check
description: Choose the project's build path, name each sensitive area with its caution, and give the risk notice where one is due. Used at founding, when a request changes the project, before hosting, at the quarterly visit, and when a repair stalls.
user-invocable: false
---

# The fit check

Choose the path and name each sensitive area with its caution. Run at founding,
when a request changes users, data, money, autonomy, promises or reliance,
before first `/setup-hosting`, quarterly `/maintain`, and before a handover.

## Access

Record `Access: private` for invited users, `open address, invitation only
(decided YYYY-MM-DD)` if anyone can reach the address but only invited people
can sign in, or `public (decided YYYY-MM-DD)` if anyone can make an account.
Never refuse an open setting. A live change waits for a yes naming its effect,
then follows the recipe's access change and check and goes in the changelog.

Read `references/path-questions.md` for the questions and ownership check.

## Choose the path

Consider redesign first, then choose the first matching path:

### 1. Build with care

A yes to questions 1, 2, 4, 5, 6 or 7 leaves a
   sensitive area after redesign. Name it and its caution in the masterplan.
   Complete the caution before merge or activation, or record the person's
   acceptance. Work outside named areas follows Build and run it.

### 2. Build and run it

People rely on the tool, no sensitive area applies,
   consequences are recoverable and a manual fallback exists. A yes to 3 or 8
   also requires `/setup-hosting` readiness before first live use. This is the
   primary path.

### 3. Explore privately

Nobody relies on it, data can be thrown away, actions
   are reversible, and the work is for learning or testing an idea.

## Sensitive areas

Name each area in the tool's own words and put its caution beside it. Change a
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

First ask whether a redesign removes the area. Keep its caution while exposure
remains. Run the full check at founding, after several changes, before hosting
or handover, and quarterly. For a bounded change, check affected questions and
update `Recheck when` and `Last checked`; if unclear, run it all.

At launch, complete the caution and record `done`, or give the full notice. On
acceptance, record the person's words and date as `Accepted:` and mark the area
`accepted`. If a named reviewer is unavailable, `/maintain` offers a handover
once. For live-path autonomy settings, follow `references/own-run.md`.

## References

- `references/risk-notice.md`: notice and acceptance rules.
- `references/build-path-record.md`: masterplan fields and area records.
- `references/path-questions.md`: consequence and ownership questions.
- `references/own-run.md`: opt-in automatic merge and parallel work.
