# The risk record

The masterplan's `## Risk record` section holds the project's risk facts. The
agent reads it first in every session.

```md
## Risk record

Exposed: <who is hurt if the tool fails, inside and outside the team>
Data: <what it holds, and which of it cannot be replaced>
Wrong answer: <what a wrong answer does>
Recovery: <how the person recovers from a failure>
Access: <private | open address, invitation only (decided YYYY-MM-DD) | public (decided YYYY-MM-DD)>
Risk areas: <none, or one line per area beneath this one>
Accepted: <none, or one line per accepted risk>
Runs on its own: <off, or merge, queue, parallel 2, loop with the person's words and date>
Recheck when: <specific triggers>
Last checked: YYYY-MM-DD
```

For `merge`, the line follows the order the merge script reads: `merge`, then
`decided YYYY-MM-DD`, then the person's words in double quotes. For example:
`Runs on its own: merge, decided 2026-10-20, "merge on your own once checks pass"`.

Each area gets its own line under `Risk areas:`, indented two spaces: the
area, what in this tool touches it, its caution, and where the caution stands
(`not yet done`, `done` with the date, or `accepted` with the date of the
matching `Accepted:` line). The next line lists the paths where the area lives.
A third may name one boundary it must not cross, which the project check can
hold once the person agrees, by the `quality-checks` skill's
`references/boundary-rules.md`. Every top-level source folder sits under an
area or on a `none:` line, so the shipped check refuses a new, unassigned
folder. Read the paths back in plain words at founding: "Money is the refund
button, and it lives in the billing folder." Update the map in the same save as
any code move. Where the language is one Bearer covers, offer its optional
local scan for files that handle personal data. It is free under the Elastic
License 2.0 and is not open source.

```md
Risk areas:
  regulated decisions: the treatment recommendation; caution: a clinician signs off the protocol before nurses act on it; not yet done
    paths: src/recommendations/, src/rules/treatment.ts
    boundary: reached only through src/rules/treatment.ts
  irreplaceable live data: the maintenance history import; caution: a backup restored once and the import rehearsed on a copy; done 2026-08-12
    paths: src/imports/maintenance/
  none: src/reporting/
```

Each accepted risk gets its own line, added and never replaced: the date, the
caution that did not happen, and the words the person carried on with, with
their name.

```md
Accepted: 2026-08-12, review of who can see the client notes not done; Priya carried on after the notice: "we cannot pay for a review, build it"
```

An acceptance drops a caution. It does not remove the area, since the exposure
is still there; the area's line says `accepted 2026-08-12`. An area leaves the
record only when the fit check runs again after a redesign has removed it.

A project moved from an older path record may also carry `Earlier path:` and
`Earlier why:` as history, and a `Report-only:` line naming the checks it
cannot yet run. Leave all three as they are. Moving a check to enforced is the
person's decision, saved with the date.

A piece names the areas it touches on its own `Risk areas:` line, or `none`.
The notice rules are in `risk-notice.md`.
