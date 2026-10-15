---
name: build-piece
description: Build one ready piece to a confirmed, saved change, from the safe start to the updated records. Used by implement for every piece, a repair included, and by the builder agent. Refuses to start on top of uncommitted work. One piece per pass, always.
user-invocable: false
---

# Build a piece

One piece per pass, always, directed by someone who judges it by behaviour.

## 1. Safe start

Read the whole piece, its `Under the hood` notes, the build-path section and
anything the masterplan or AGENTS.md's stack section points to. Uncommitted
work stops the build; `/what-now` owns that conversation. Start from
up-to-date `main` on every save route including the checkpoint route. If it
cannot be reached, use the local copy and say so.

Choose the route before changing files:

- **Checkpoint:** private or disposable work with no shared or live reliance,
  and no change to data, access, integrations, money, autonomy or operations.
- **Pull request:** shared or live use, behaviour, data, permissions, outside
  services, operations, or any route the build path requires.
- **Flagged:** work inside a named sensitive area whose caution is neither
  done nor accepted. Give the `fit-check` risk notice before building. On the
  person's decision to continue, run `piece-labels.sh start`, record their
  words and date with `Accepted:`, then build and save by pull request in that
  reply. A lock waiting only on this caution opens unless they ask to keep it.
  Otherwise stop at the recorded condition. In an unattended run, never
  record acceptance.

Pull-request and flagged routes use a short-lived branch from `main`. If
GitHub is unavailable, save on the branch and note the missing pull request
on the piece. A service step that could not run is a note, not a warning or
risk. The first push waits for a yes, as `merge/references/first-upload.md`
says. Elsewhere, run the `records` skill's `scripts/piece-labels.sh` with
`start <number>` before changing files; it replaces `ready` with `building` and
assigns the piece.

## 2. Agree and check the result

Say what the person will see or do, what is outside the piece and how it will
be checked. Ask only if the result is ambiguous. Choose the smallest credible
evidence for every subject; use the stricter route when there is more than
one. Machine-judgeable behaviour needs an automated test. Never use a softer
proof as a substitute for a check that was available and skipped. Copy, layout,
colour, usability and throwaway prototypes can use a guided manual check.
Backups, restores, migrations, rollback, alerts, deployment and recovery need
an operational rehearsal. Adding a field needs a test; changing existing
records needs a rehearsal on a copy. Check outside facts through `research`.
For mapped sensitive areas, run the strength check after tests pass.

For a repair, follow the `repair` skill's `references/fixing.md` and run its strength check
on the regression test. Otherwise follow
`quality-checks/references/tests-prove-change.md`: new tests fail on old
behaviour, and refactor tests pass before the change. Describe the current
screen before a visual change.

## 3. Build the agreed slice

Build only the agreed behaviour end to end. Avoid speculative abstraction;
groundwork is its own piece or an expand-then-contract sequence that keeps the checks green,
ordered ahead.
Stop if the work grows beyond agreement. Run
`quality.py tests --base <start commit> --piece <number>` once; report
strength misses and whether the check could not run.

For outside services, follow AGENTS.md's Secrets rule. A change to a live
service's settings or data, apart from saving code, waits for a yes that names
each change and says whether it can be undone. Ask before acting. In an
unattended run leave it unchanged. A live build never applies a migration;
`/setup-hosting` does that before merge.

For `visual` work or a change to a rendered interface, load `screen-check`
before the guided check. File new work uncovered during the build through
`records/references/pieces.md`, with subjects from the `triage` skill and a short note
that it was found here. If the person asks for more, ask once whether to add it
to this piece or make a new one. On this piece, add it to `## Done when`, read
it back and build it. Never fold it in without that answer. A test that only
passes on retry is unreliable: repair or replace it before saving.

## 4. Hand over, review and save

Follow `references/build-limits.md`, then update records as the `records`
skill's “After a build” directs.
