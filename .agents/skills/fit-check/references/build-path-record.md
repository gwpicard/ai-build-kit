# Write it down

The outcome goes in the masterplan's build-path section, which the agent reads
first in every session:

```md
## Build path

Path: <Explore privately | Build and run it | Build with care>
Why: <one or two sentences>
Access: <private | open address, invitation only (decided YYYY-MM-DD) | public (decided YYYY-MM-DD)>
Sensitive areas: <none, or one line per area beneath this one>
Accepted: <none, or one line per accepted risk>
Runs on its own: <off, or merge, queue, parallel 2, loop with the person's words and date>
Recheck when: <specific triggers>
Last checked: YYYY-MM-DD
```

Each area gets its own line under `Sensitive areas:`, indented two spaces:
the area, what in this tool touches it, its caution, and where the caution
stands (`not yet done`, `done` with the date, or `accepted` with the date of
the matching `Accepted:` line). On Build with care, the next line lists the
paths where the area lives, and a third may name one boundary it must not
cross, which the project check can hold once the person agrees, by the
`quality-checks` skill's `references/boundary-rules.md`. Every top-level source folder sits under an area or on a
`none:` line, so the shipped check refuses a new, unassigned folder. Leave the
map out on the other two paths.

```md
Sensitive areas:
  regulated decisions: the treatment recommendation; caution: a clinician signs off the protocol before nurses act on it; not yet done
    paths: src/recommendations/, src/rules/treatment.ts
    boundary: reached only through src/rules/treatment.ts
  irreplaceable live data: the maintenance history import; caution: a backup restored once and the import rehearsed on a copy; done 2026-08-12
    paths: src/imports/maintenance/
  none: src/reporting/
```

Read the paths back in plain words at founding: "Money is the refund button,
and it lives in the billing folder." Where the language is one Bearer covers,
offer its optional local scan for files that handle personal data; it is free
under the Elastic License 2.0 and is not open source. Update the map in the
same save as any code move; the foundation check names a listed path that has
gone or a new folder with no line, and is silent off Build with care.

Each accepted risk gets its own line, added and never replaced: the date, the
caution that did not happen, and the words the person carried on with, with
their name.

Autonomy stays off unless the person asks for it. Offer these options only on
Build and run it or Build with care. For merge, say: "If you turn this on, a
finished piece can go live before you try it. The check and a separate review
still hold it. But nobody looks at the screen before your users do. A piece
that touches <areas>, changes the database or needs a new setting still waits
for you. Say 'stop merging on your own' at any time." For parallel, say:
"Two pieces are built at once. Each waits for you as usual. Before the second
one merges, it is checked again against the first one." Queue and loop need
only a short explanation. Write the person's words and date on the
`Runs on its own:` line. The person adds the local Claude allow rule themselves:
`Bash(python3 *merge.py --auto *)`. On Explore privately, keep the line off
and do not offer the options. When the person turns an option off, update the
line on the next records save and tell them to remove the local allow rule.

```md
Accepted: 2026-08-12, review of who can see the client notes not done; Priya carried on after the notice: "we cannot pay for a review, build it"
```

An acceptance drops a caution. It does not move the path or remove the area,
since the exposure is still there; the area's line says `accepted 2026-08-12`.
The path moves only when the fit check runs again after a redesign has removed
the area.
