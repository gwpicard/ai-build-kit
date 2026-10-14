---
name: fit-check
description: Choose the project's build path, name each sensitive area with its caution, and give the risk notice where one is due. Used at founding, when a request changes the project, before hosting, at the quarterly visit, and when a repair stalls.
user-invocable: false
---

# The fit check

The fit check chooses the project's **build path** and names each sensitive
area the work touches, with its caution. It runs during
/setup-ai-build-kit; when a request changes users, data, money, autonomy,
promises or reliance; before the first /setup-hosting; at the quarterly
/maintain; and before a handover.

## Who will use it

Ask this first. A tool for people the owner can name is private: only invited
people get in. Record `Access: private`. The other two settings are never
refused when the person asks for one:

- `open address, invitation only (decided YYYY-MM-DD)`: anyone can reach the
  address, and only invited people can sign in. It suits a group larger than
  the host's gate allows on its plan, and a server whose address anyone can
  reach. Each recipe's access section says when it applies. It adds no
  sensitive area.
- `public (decided YYYY-MM-DD)`: anyone can make an account. That is a yes to
  question 1, so record the sign-in and permissions area below. Its notice is
  the one warning about going public.

Once live, a change either way waits for a yes that names the effect, runs
the recipe's access change and check, and goes in the changelog.

## Consequence questions

Ask one at a time, with a best guess attached. These decide the path.

1. Will anyone outside the team sign in or rely on it?
2. Will real money move through it or be calculated for real decisions?
3. Does a contract, client promise, uptime expectation, or deadline depend on
   it?
4. Will it hold personal or sensitive data beyond ordinary work contact
   details?
5. Does it give or enforce regulated, legal, medical, financial, employment,
   or safety-related decisions?
6. Will it begin on data the team cannot afford to lose or corrupt?
7. Will it act automatically on another system, send consequential messages,
   change records, or do anything difficult to reverse?
8. If it stops or gives a wrong answer, does important work stop or
   meaningful harm follow?

## Ownership questions

9. Is there a manual fallback?
10. Can the team explain the main flows and permissions without reading code?
11. Can the team identify where data, credentials, service ownership, and
    bills live?
12. Is there a named person responsible for alerts, backups, access, and
    recovery?
13. Is the system still simple enough that a new agent could understand it
    from the records alone?
14. Are integrations, background jobs, permissions, and migrations limited
    enough for the team to operate confidently?

These never decide the path. A no becomes a founding task: a piece where there
is work to do (write down the manual fallback, name who reads the alerts), or a
line in the masterplan's "How it stays running" section where there is only a
fact to record. Founding carries on.

Those facts live only in "How it stays running"; the changelog records only
that the check ran and when. For a credential, the fact is where it lives (a
file path, a password manager entry's name, an environment variable's name),
never its value.

## The three build paths

Use these three names everywhere. Choose the first that matches, after
redesign has been considered.

### 1. Build with care

Some of the work touches a sensitive area. A yes to question 1, 2, 4, 5, 6 or
7 that redesign cannot remove puts the project here. The masterplan names each
area in the tool's own words with its caution. Everything outside those areas
is built as Build and run it. Inside one, the caution is done before merge or
activation, or the person accepts on the record.

### 2. Build and run it

People rely on the tool, no sensitive area is touched, consequences are
limited and recoverable, and the manual fallback is real. A yes to question 3
or 8 lands here: it says the tool is relied on, and asks for the operational
readiness /setup-hosting requires before first live use. This is the kit's
primary path.

### 3. Explore privately

Nobody relies on it, data is disposable, actions are reversible, and the work
exists to answer questions or learn.

## Sensitive areas

Six areas, fixed, each with a default caution. Name the area in the tool's own
words (the client notes, the refund button) and write the caution beside it.
Change a caution only where the tool's facts make another right, and say why.

| Area | What counts | Default caution |
|---|---|---|
| Personal or sensitive data | Facts about a person beyond ordinary work contact details: health, pay, home address, identity documents, anything a person would mind a colleague reading. | A person who did not build the tool reviews who can see what, before real data goes in. |
| Money | Real money moving through the tool, or figures people act on as if they were the bill. | A managed payment provider holds card details so the tool never sees them, and the owner of the money checks the first real figures against a case they know. |
| Sign-in and permissions | Anyone outside the team signing in, or rules that keep one person's things from another's. | A managed sign-in service so the tool never stores a password, and a person who did not build it reviews who can reach what, before outside users sign in. |
| Automatic action on people or other systems | The tool sends messages, changes records elsewhere, or does anything on its own that is hard to take back. | A person approves each action until a live run has shown it right, and one switch turns it off. |
| Irreplaceable live data | The only copy of something the team cannot recreate. | A backup taken and restored once, and the change rehearsed on a copy, before the original is touched. |
| Regulated decisions | Medical, legal, financial, employment, or safety decisions the tool gives or enforces. | Somebody qualified in that field signs off the rule before anyone acts on it. |

On a public tool, the sign-in and permissions notice also says that strangers
can reach the live address and make an account, and that a payment gateway or
similar may need a developer.

Where a caution is a person, "The notice holds" in
`references/risk-notice.md` applies. Where it is a backup,
a copy, a rehearsal, a managed service or an approval step, it is the kit's to
do as part of the work, with the result recorded on the area's line. Work
inside a named area is flagged work.

## Redesign before the notice

Before naming an area, ask whether the risk can be removed: use a copy instead
of live data, remove automated action, keep a human approval step, remove
regulated advice, reduce outside access, use a managed service, keep a manual
fallback, or narrow the promise. A redesign that really removes the area
changes the answers, so run the check again. One that keeps the surface and
drops the caution does not.


## Full and delta checks

Run every question in the situations at the top of this file, and when several
characteristics changed together. For a single change, run a delta check: ask
the consequence questions the change affects, name any area it touches and its
caution, recheck the ownership questions it affects, apply the decision order,
and update `Recheck when` and `Last checked`, adding an `Accepted:` line if a
risk was accepted. Run the full check when the affected area cannot be bounded.

## Where the rest lives

- `references/risk-notice.md`: the risk notice, why it holds, and what counts
  as carrying on. Load it before any flagged work goes ahead.
- `references/build-path-record.md`: how the outcome is written into the
  masterplan's build-path section, the map of areas, and an `Accepted:` line.
