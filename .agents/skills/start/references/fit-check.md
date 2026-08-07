# The fit check

The fit check chooses the project's current **build path** and names the
condition for outside help, if any. It runs:

- during /start;
- when a request changes users, data, money, autonomy, promises, or reliance;
- before the first /ship;
- during quarterly /maintain;
- before a handover.

## Consequence questions

Ask one at a time, with a best guess attached.

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

## Decision order

Use the first matching outcome after redesign has been considered.

### 1. Professional-led

Choose when a professional-led trigger is central to the production system and
cannot be removed or isolated through redesign.

Examples:

- regulated or high-consequence decisions are central;
- irreplaceable live data cannot be isolated;
- high-harm autonomous action is central;
- the team cannot safely operate or recover the system;
- the production promise requires technical ownership the team cannot carry.

### 2. Build with expert help

Choose when a professional trigger exists in a named, bounded area, while the
team can still understand, operate, and recover the rest.

Professional ownership of one integration or risky area belongs here.
Professional leadership of the production system belongs under
Professional-led.

### 3. Build and run it

Choose when people rely on the tool, but the consequences remain limited and
recoverable, the manual fallback is real, and ownership is clear.

### 4. Explore privately

Choose only when nobody relies on it, data is disposable, actions are
reversible, and the work exists to answer questions or learn.

## The four build paths

Use these four names everywhere. Do not alternate between path, tier, level,
mode, verdict, or maturity class.

### Explore privately

Choose when:

- nobody depends on it;
- data is disposable;
- no consequential automatic actions exist;
- it is being used to answer questions or learn.

### Build and run it

Choose when:

- it is mainly internal;
- consequences are limited and recoverable;
- fallback and ownership are clear;
- the team can explain and operate it;
- no professional trigger applies.

This is the kit's primary target path.

### Build with expert help

Choose when one or more named areas require expertise but the team can still
own the rest.

Typical triggers:

- outside users;
- real money;
- sensitive data;
- complex permissions;
- operational criticality;
- autonomous actions;
- difficult live-data change;
- several integrations or background processes;
- repeated failure in one technical area.

The output must name the exact help level (advice, scoped review, supervised
change, or professional ownership) and scope.

### Professional-led

Choose when:

- regulation or high-consequence decisions are central;
- irreplaceable live data cannot first be isolated or copied;
- high-harm autonomous behaviour is central;
- a contract requires technical operational ownership;
- the team cannot explain, recover, or operate the system;
- complexity and consequence cannot be reduced enough by redesign.

## Redesign before escalation

Before moving to professional-led, ask whether the risk can be removed:

- use a copy instead of live data;
- remove automated action;
- keep a human approval step;
- remove regulated advice;
- reduce external access;
- use a managed service;
- keep a manual fallback;
- narrow the promise.

If the redesign materially changes the answers, run the check again.

## Full fit check

Run all questions:

- during /start;
- before the first operational /ship;
- quarterly during /maintain;
- before a handover;
- when several project characteristics changed together.

## Delta fit check

For a single change-triggered reassessment:

1. ask the consequence questions affected by the proposed change;
2. recheck manual fallback;
3. recheck named operational ownership;
4. recheck whether the team can still explain and recover the system;
5. apply the decision order;
6. update `Recheck when` and `Last checked`.

Run the full check instead when the affected area cannot be bounded confidently.

## Write it down

Whatever the outcome, it goes in the masterplan's build path section:

```md
## Build path

Path: <Explore privately | Build and run it | Build with expert help | Professional-led>
Why: <one or two sentences>
Required controls: <only the controls that apply>
Outside help: <none | advice | scoped review | supervised change | professional ownership>, for <scope>
Recheck when: <specific triggers>
Last checked: YYYY-MM-DD
```

The agent reads that section first in every session. This half page tells the
whole system how careful to be.
