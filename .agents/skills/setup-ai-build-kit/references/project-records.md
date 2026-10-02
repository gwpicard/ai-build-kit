# Project record routes

New founding writes `<!-- ai-build-kit:records:v1 -->` once in `masterplan.md`.
The overview holds purpose, brief architecture, useful shared-rule summaries and
pointers. All visible words count towards its 500-word ceiling, including every
heading and link label. Markdown punctuation, comments and link destinations
are not words. Use `templates/foundation/project-records.py validate --root
<project>` from this installed skill, or the project's copied
`.agents/tools/project-records.py`. Both use the same counter. No placeholder,
build-path detail, task history or `Trued against:` stamp survives founding.

## One authoritative home

The format marker selects these homes, even if a conflicting old field exists:

- `docs/working-rules.md`: the build-path block, sensitive-area map, accepted
  cautions and project-specific build/review requirements. Only the fit check
  changes the path. Preserve team rules, including a named person's review.
- `docs/operations.md`: the How it stays running section, including `Goes live:`,
  `Sample data:`, secret locations, accounts, access owners, alerts, billing,
  backup, recovery and hosting requests. Read locations; never read secret values.
- Indexed `docs/<concept>.md`: authoritative product intent, permission rules,
  data and origins, connections and their picture, journeys, correct results,
  failure behaviour and settled terms. `docs/README.md` names what each owns.
  Keep current behaviour distinct from future promises and declined scope.

A mention of the masterplan's build path or How it stays running in another
instruction means the corresponding owner above on this format. It never means
copying a field into the overview. Before build/review/path decisions read working
rules; before launch, secret or operational decisions read operations. Product
work reads its named concept documents. This routing adds no context-selection
skill and removes no existing safety control.

Without the marker, keep the legacy masterplan route, fields and stamp. Reading
never migrates or rewrites an old project. Unknown/repeated markers, missing
owners or duplicate fields are record gaps; never silently combine copies.
`project-records.py owner <field>` and `field <field>` resolve the chosen owner.
The founding date and plan-helper recognition still use `masterplan.md`.

## Updates and review

Every piece names the authoritative concept documents it will update in its
existing Masterplan change field. The overview changes only when its purpose,
architecture, useful summary or pointers change. Mechanical or unrelated work
leaves it byte-for-byte alone. On an update over 500 words, move detail to its
owned concept, preserve every rule, and check links and summaries again. Never
trim by discarding a decision or making closed issues its only home.

Only a completed /sync document review writes
`records-review|<full saved commit>|complete` in `.ai-build-kit-maintenance`.
Founding, builds and merges never advance it. A checkpoint records the saved
state actually reconciled, before the records correction commit. Finish all
coverage, concept, working-rule and operations reads before saving it; an
interruption or unresolved record gap leaves it unchanged. Do not copy the old
per-change stamp into this file. /maintain reports drift and never resets it.

For new records /sync captures `git rev-parse HEAD` on the shared branch, reviews
that saved state, then runs `project-records.py save-review <captured commit>
--complete` only after completing the review. Pre-existing unsaved work, changed HEAD,
missing or invalid checkpoints, an unrelated checkpoint and incomplete history
are gaps, never evidence of freshness. The helper refuses an unsafe save. Pre-existing unsaved documents also leave
the checkpoint unchanged; only this review's own record corrections are saved.
`review-gap` counts later landed code changes along first-parent history once,
excluding records-only saves. Review their affected data, permissions and
connections before reporting subject counts. A missing checkpoint requires a
full current-state review with complete history before a starting point is saved.
