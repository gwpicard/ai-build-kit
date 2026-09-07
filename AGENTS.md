# AGENTS.md

Standing instructions for maintaining AI Build Kit itself. The project
foundation carries different instructions in
`.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md`.

## What this repository is

This is the maintainer source. It contains the canonical skills, compatibility
fixtures, checks, maintainer notes, and the machinery that assembles the
installable public kit. It never becomes a project built with the kit.

The project records `masterplan.md` and `CHANGELOG.md` do not exist
here by design. They are created inside a user's project by `/setup-ai-build-kit`.

## Before any work

Read `docs/MAINTAINING.md`. Read `docs/PHILOSOPHY.md` before changing what a
skill does or adding a capability. Check the current branch and unsaved work
before editing. Never run the project-founding `/setup-ai-build-kit` process in this
repository.

## Source and starter boundary

- `.agents/skills/` is the single source of truth for the nine commands and
  four internal background skills. Nothing else belongs in it.
- `.agents/maintainer-skills/` holds the Humanizer writing skill, which only
  the kit's own maintainers use. it sits there rather than beside the thirteen
  because a shared skills installer reads `.agents/skills/` and
  `.claude/skills/` and offers whatever it finds in either, so a folder in one
  of those is a skill somebody installs. Being outside both is the whole
  boundary, and a maintainer skill gets no generated adapter for the same
  reason.
- `.claude/`, `.cursor/`, and `.gemini/` are generated adapters. Change the
  canonical skill, then run `.agents/tools/build-adapters.sh`. The Claude
  plugin exposes the nine generated command files and four hidden background
  skills. Shared installations use the adapters their coding agents need.
- `.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md` creates a project's
  root instructions.
- The root is the kit's own. `README.md` is what somebody deciding whether to
  use the kit reads, and it ships as the public README unchanged. This file is
  what somebody working on the kit reads. `CONTRIBUTING.md`, `SECURITY.md` and
  `.github/ISSUE_TEMPLATE/` are the public route for problems and suggestions,
  and ship as they are. No file at the root means two things.
- `.claude-plugin/` is the Claude plugin and marketplace metadata. It selects
  generated adapters rather than duplicating a skill.
- `agent-plugin/plugin.json` is the Agent Plugins manifest. The release
  allowlist rebases the thirteen canonical skills under `agent-plugin/skills/`,
  so the plugin folder is assembled at release time and this repository keeps
  one copy of each skill.
- `release-manifest.txt` is the full allowlist for the public kit. A file absent
  from that list does not ship.
- An installation records where its skills came from, in `skills-lock.json` or
  in Claude's plugin record, and updates through that route.
- `docs/MAINTAINING.md`, `.agents/tests/`, the source validator, and the release
  builder stay in this repository only.
- `.claude/settings.json` here is the maintainer's own. A project's copy comes
  from `.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json`, which
  carries the session-start wiring this repository must never have.

Never edit the released starter repository directly. A numbered release
generates it from this source.

## How changes are made

Build one agreed, visible slice at a time on a short-lived branch. Every
promised behaviour needs evidence. Stable rules and repairs use an automated
check when a machine can judge them; visual or exploratory work uses a guided
manual check; operational claims need a rehearsal.

When a written instruction and an automatic check disagree about the same
thing, trust the check. It tests the real work, and an instruction can fall out
of date. Follow the check, and say plainly that the two disagree rather than
following the stale instruction in silence.

When a skill changes, answer the five questions in `docs/PHILOSOPHY.md`, record
any borrowed idea in `docs/SOURCES.md`, update the owned explanation where
needed, regenerate adapters, and run the kit validator. Generated files are
committed with their canonical change.

Shared changes are reviewed and arrive through a pull request. A human decides
whether to merge. Reports describe behaviour, evidence, and uncertainty in
plain language rather than asking the person to read code or logs.

## Referring to work

Issue and pull request numbers belong in issues, in pull requests, and in a
changelog. Never in a tracked file. A number in a document or a comment is a
pointer the reader cannot follow, and once the material is public it points at
an unrelated issue in whatever numbering that repository happens to have.

Say the thing instead. Where a comment needs the reason behind a rule, write the
reason. "The contradiction this check exists to hold shut" survives a move and a
rename; a number does not.

`validate-kit.sh` fails on a number in any tracked file.

## Maintainer checks

- `.agents/tools/validate-kit.sh` checks the source and generated adapters.
- `.agents/tests/run-all.sh` runs every rehearsal in `.agents/tests/` and
  names each one that failed. It reads the folder rather than a written-out
  list, so a new rehearsal runs from the moment it is saved, and it carries
  on past a failure so that one cannot hide another. The hosted check runs
  the rehearsals through it, in a single job.
- `.agents/tests/rehearsal-runner.sh` checks that runner against stub
  scripts: that a failure at the very start does not stop the ones after
  it, that every failure is named rather than only the first, that a
  passing rehearsal is not reported as failed, that `mutate.sh` is
  skipped, and that a copy of either the runner or `mutate.sh` is skipped
  too. That guarantee lives in a shell loop rather than in the workflow,
  where a validator could read it off the file, so only running it settles
  whether it holds. The copy matters because this folder is watched by a
  sync daemon: a copy of the runner that gets run runs the whole suite
  again and reaches its own copy again, so the run hangs rather than
  fails, and a hosted job is billed for every minute of it.
- `.agents/tests/release-builder.sh` checks the assembled public release boundary.
- `.agents/tests/starter-rehearsal.sh` checks that installed skills can prepare
  a clean, independently saved project with founding records.
- `.agents/tests/release-publication.sh` rehearses first and later publication
  against a disposable local destination.
- `.agents/tests/claude-plugin.sh` rehearses the Claude command boundary, an
  isolated install, project bootstrap, failed and successful updates, and
  removal.
- `.agents/tests/agent-plugin.sh` checks the assembled Agent Plugins folder
  against the standard and rehearses a project stand-up from it.
- `.agents/tests/session-start.sh` rehearses the check-up cadence and proves
  this repository never receives a reminder.
- `.agents/tests/fake-github.sh` checks the replay harness's stand-in for the
  GitHub CLI: the commands it answers, and the ones it still refuses on purpose.
- `.agents/tests/plan-printout.sh` runs the printout against a fixed set of
  issues and reads what it wrote: which group each piece lands in, whether a
  waiting piece says why, whether a shaped piece says it is ready, and whether a
  held-up piece names the piece holding it rather than its number. It also holds
  the invariant `/queue` rests on, that a piece with an open blocker never
  reaches the buildable group while a piece whose blocker has closed does.
- `.agents/tests/queue-groups.sh` guards what `/queue` may call safe to build
  together. The rule that matters is that it reads the printout's grouping rather
  than working safety out again, since the printout is where the guarantee comes
  from. It also guards the blocker being named rather than numbered, a waiting
  question keeping a piece out of both groups, the command reporting and never
  building, and `/what-now` keeping its cap of three things, because a
  `/what-now` that grew the whole list would undo the split that earned the ninth
  command.
- `.agents/tests/gated-turns.sh` checks the rule that decides when a scripted
  replay turn is due: that a turn with no precondition still fires by position,
  that one with a precondition waits until the kit has said the thing it
  answers, and that a precondition nothing will ever match gives up after two
  fillers and sends the line anyway, so the gate can cost tokens but can never
  fail a run that would otherwise have passed.
- `.agents/tests/grader-recovery.sh` checks that the replay grader recovers a
  transcript missing only its final brace, and still refuses one that was cut
  off partway.
- `.agents/tests/replay-state.sh` checks that the replay harness grades the
  world a run leaves behind: it builds end-states by hand and proves the
  acceptance-record assertion catches a masterplan that recorded the acceptance
  the contract names, a kit that wrote nothing, and an acceptance invented where
  none was due, that the save-route assertion catches a founding that saved
  no checkpoint or pushed one it should have kept local, that the
  issue-invariants assertion catches a parked idea reopened or moved into
  building, that the route assertion catches a piece that got the label its
  work promised without the work: a `needs-` label taken off with nothing
  recorded, `ready` sitting beside an open question, and a note marked ready
  without ever being sized, and that the split assertion catches a request cut
  up the wrong way: a part wanting a different outcome from its parent, two
  pieces waiting on each other for one outcome, and a part named for a layer
  rather than a slice.
- `.agents/tests/check-tooling.sh` runs the setup tooling report against a set of
  throwaway PATHs and reads when it stops: a missing tool or a signed-out account
  blocks founding, while issues switched off or a read-only account do not.
- `.agents/tests/completion-report-shape.sh` guards the source of the /setup
  completion report, which is watched by hand rather than replayed: it proves
  completion-report.md still leads with what is ready, keeps technical state out
  of the lead, ends on a clean cut pointing at /implement, and it fails on a copy
  with any of those rules removed.
- `.agents/tests/setup-notes.sh` guards the working notes the founding
  interview keeps: that the /setup skill still writes each agreed answer before
  the next question, keeps those notes out of every commit, resumes from them,
  and clears them once the masterplan holds the same answers. It also proves in
  a throwaway project that a file under `.agents/tmp/` stays untracked.
- `.agents/tests/empty-fields.sh` guards the two words a scenario uses for a
  field with nothing in it, and their opposite meanings: `none is due` says the
  kit must not do the thing, `unaffected` says the scenario does not judge it.
  It guards the contract header where a scenario author reads them and the
  grader prompt where they are applied, since a word defined in one and unknown
  to the other is what let a grader improvise. `check-parser.sh` refuses a third
  wording mechanically.
- `.agents/tests/founding-carries-on.sh` guards the ending of the step that
  tries to talk the person out of building: that the cheaper option is still
  named and the case still made, but made once, and that a person who wants the
  tool anyway gets it recorded and founding carried on rather than the question
  asked again, and without the case itself ending the turn. It guards the wider
  rule that a question founding does not need becomes an open question in the
  masterplan instead of a gate, since otherwise the next stall just happens on a
  different question. It also guards the read-me step, where an installation
  that arrived as a whole copy of the kit leaves no placeholders to fill in, so
  the file is left alone and said to be left alone rather than founding stopping
  to ask. It guards the founding save, which is always the checkpoint route
  however shared the tool will become, since a reachable remote once had a
  founding pushed and a pull request opened against a promise that nothing would
  be uploaded. And it guards the masterplan review, which the build path decides
  and which records a missing reviewer as a gap rather than waiting for one,
  because the wait had no exit and cost two measured runs their whole founding.
- `.agents/tests/coverage-read.sh` guards the read that compares the masterplan
  against the pieces: the rules that keep it honest, that /setup and /sync both
  still run it, and that WORKFLOW.md explains it for founding and for sync. It
  fails on a copy with any one of those removed.
- `.agents/tests/plan-research.sh` guards the two research steps that share the
  `needs-research` label: the rules that keep an existing-work search honest
  about maintenance, licence, cost, data, and removal, that /plan offers both
  steps and says which it ran, and that change-triage, pieces.md, and
  WORKFLOW.md all describe the label as covering both.
- `.agents/tests/triage-overlap.sh` guards the warning that another open piece
  would be built in the same place: what change-triage compares, that it names
  the clash before the routing step rather than after it, that it blocks
  nothing, and that it stays quiet when no piece shares a subject.
- `.agents/tests/existing-artifact.sh` guards the route that lets a mock the
  person already has settle a question: the ten rules that keep it safe, that
  clarify, /plan, and the decision prototype all check for one before building a
  throwaway, and that /setup and WORKFLOW.md name it.
- `.agents/tests/wiring-picture.sh` guards the masterplan's picture of what the
  tool reaches outside itself: the drawing rules, that the example draws nothing
  internal, that founding reads it back for confirmation, and that a piece
  changing a connection redraws it rather than letting it go stale.
- `.agents/tests/manual-step.sh` guards the step only the person can do: the
  rules for a piece's `Waiting on you` section, that `blocked` keeps the two
  meanings it already has, that /implement neither builds such a piece nor skips
  it in silence, and that /what-now names it as the person's own to-do without
  ever asking for a key in a message.
- `.agents/tests/settled-is-recorded.sh` guards the record a settled question
  has to leave: that what settled it is written into the piece before the label
  comes off, and that the piece is read back to decide whether the label goes
  rather than the order simply being followed. Doing the steps in sequence is
  what a run believes it did; reading the piece back is what tells it whether it
  did, and this is the one defect a transcript cannot show.
- `.agents/tests/named-reviewer-is-a-person.sh` guards what a named review can
  be met by. The rule against recasting one was never the part that failed: the
  definition beside it said an independent review means a reviewer who did not
  build the work, and a clean separate session did not build the work, so by
  those words a session qualified. It guards the definition in fit-check.md and
  in the project's own AGENTS.md, and asserts that second-opinion still draws
  the same line, since one phrase meaning two jobs is what let the kit reach for
  the cheaper one.
- `.agents/tests/acceptance-is-earned.sh` guards what has to be true before
  flagged work is built. Measured runs gave the notice correctly and then built
  on an instruction to carry on: "try something else" is a decision about the
  work rather than about the risk, and the recording step said to do things in
  order, which a run believes it did. So it guards a read-back of the
  `Accepted:` line and a definition of what counts as accepting, not the order.
- `.agents/tests/who-can-settle.sh` guards which waiting pieces need the person:
  that the three labels each say who can answer, that /plan never answers a
  person-present question itself, that it can be pointed at one piece and can
  clear the research alone, and that /what-now stops calling that research the
  person's errand.
- `.agents/tests/plan-later.sh` guards the choice between settling a piece's
  question now and filing it to come back to: the rules that keep the offer an
  offer rather than a reluctance, that change-triage agrees a routed question
  does not start the step there and then, that pieces.md says roughly what each
  waiting label costs to settle, and that /what-now calls a planning session when
  more pieces are waiting than are ready.
- `.agents/tests/prototype-recipes.sh` guards what a prototype is supposed to
  be: that decision-prototype.md names the two kinds of question and picks
  before it builds, that each recipe keeps the rules that make it worth
  following, and that neither recipe is written in build words the person cannot
  read.
- `.agents/tests/held-definition.sh` guards what a replay run has to do to count
  as held: the three clauses, that withstanding pushback is reported rather than
  graded, and that the rollup says so. It drives the rollup with graded runs
  built by hand, so a withdrawn notice is proved not to cost a run its pass while
  flagged work built with nothing on the record still fails.
- `.agents/tests/version-stamp.sh` guards the release stamp: that all three
  version-bearing files move together, that a preview never reaches the branch
  every installer reads, that an already-stamped tree takes the next version,
  and that a manifest whose version field was renamed or duplicated stops the
  stamp rather than letting it match nothing. That last one is the reason the
  check exists. A stamp that matches nothing reports success and ships the
  previous release's number, and no other check would see it.
- The checks that guard a rule written as prose share
  `.agents/tests/lib/rule-shape.sh`: declare the rules, and it asserts each one
  and proves it is load-bearing by removing it and requiring the check to fail.
  `validate-kit.sh` finds that family by the helper they source, so a new one is
  covered from the moment it is written.
- `.agents/tools/build-release.sh <version> <new-folder>` assembles a local
  public release outside this repository without changing or deleting an existing
  folder.
- `.agents/tools/preflight-cutover.sh` asserts everything that has to be true
  before this repository's tree is pushed into the public one, each item with an
  expected answer rather than a list somebody reads and judges. A checklist you
  interpret is a checklist you pass. Run it immediately before the push, not
  once in advance, and with nothing else working in the repository: a review
  agent or an editor saving a file makes the tree momentarily dirty, and it
  reports that as a failure. It should. A false alarm costs a re-run, and the
  reverse mistake costs a push nobody can take back.
- `.agents/tools/rehearse-merged-tree.sh` copies every tracked file into a fresh
  one-commit repository outside this one and runs the adapter drift check, the
  validator and the whole rehearsal suite against it. That is what the public
  repository will hold after consolidation, and the push that puts it there
  cannot be undone, so run this before it rather than finding out afterwards. It
  is not in `.agents/tests/` because it calls `run-all.sh`, and a rehearsal that
  runs the suite from inside the suite reaches its own copy and hangs.

## Secrets and external changes

Keys, passwords, and tokens live in local or GitHub-protected settings and
never in a tracked file. Never print or commit one. Publishing a release,
renaming a repository, changing the public starter, or modifying online access
requires the person's explicit approval at that step.

Before a technical confirmation appears, explain what the person will notice,
why it is needed now, whether anything leaves this computer, whether the action
is temporary or saved, and what remains unconfirmed if they decline. Say that a
technical confirmation box will appear next.

Preserve existing work. Never discard, overwrite, or delete unsaved material
to make a check pass. Ask before any irreversible action or anything that
changes data, access, money, automatic actions, or an online service.

The commands in `.agents/guard/blocked-commands.md` are off limits. Save a
checkpoint before sweeping changes.

## Writing

Use British spelling and plain language. Do not use em dashes. Keep paragraphs
short. The audience does not read code, so define a technical term once only
when it cannot be avoided and describe verification as an action and its
expected outcome.

Before saving any human-facing prose, load
`.agents/maintainer-skills/humanizer/SKILL.md` and use its embedded mode
together with the house rules in `docs/MAINTAINING.md`. This includes documentation, skill
prose, pull request text, release notes, interface copy, error messages, and
comments written for a reader. Preserve the facts, intent, code, commands, and
link targets.
