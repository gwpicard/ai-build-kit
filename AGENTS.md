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

Read `docs/MAINTAINING.md`. Read `docs/PHILOSOPHY.md` before changing what one
of the fourteen canonical skills does, or adding a capability. Check the current
branch and unsaved work
before editing. Never run the project-founding `/setup-ai-build-kit` process in this
repository.

## Source and starter boundary

- `.agents/skills/` is the single source of truth for the nine commands and
  five internal background skills. Nothing else belongs in it.
- `.agents/maintainer-skills/` holds the skills only the kit's own maintainers
  use. There are three: the Humanizer writing skill; `review-issues`, which
  reads the open issues, groups them by theme and names the next piece worth
  picking up; and `stack-research`, which reads what changed upstream for the
  products the recipes name and writes a dated note proposing changes, or
  none. They sit there rather than beside the fourteen because a shared
  skills installer reads `.agents/skills/` and `.claude/skills/` and offers
  whatever it finds in either, so a folder in one of those is a skill somebody
  installs. Being outside both is the whole boundary, and a maintainer skill
  gets no generated adapter for the same reason. Nothing offers one as a
  command, so load it by its path. To decide what to work on next, load
  `.agents/maintainer-skills/review-issues/SKILL.md`. To check the recipes
  against their products before a release, load
  `.agents/maintainer-skills/stack-research/SKILL.md`. Its note goes to
  `.agents/tmp/stack-research/`, which git ignores, so it never ships.
- `.agents/migration/` holds the one-off tooling for replacing the public
  repository with one whose history carries no AI attribution. It is not part of
  the kit, it gets no adapter, and it reaches nobody who installs the kit. It
  lives here rather than outside the repository because `docs/MIGRATION.md` is
  the plan and these are the scripts that plan runs, and a runbook whose tools
  sit somewhere else is a runbook that stops working. Read `docs/MIGRATION.md`
  before running any of them.
- `.claude/`, `.cursor/`, and `.gemini/` are generated adapters. Change the
  canonical skill, then run `.agents/tools/build-adapters.sh`. The Claude
  plugin exposes the nine generated command files and five hidden background
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
  allowlist rebases the fourteen canonical skills under `agent-plugin/skills/`,
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

When one of the fourteen canonical skills changes, answer the five questions in
`docs/PHILOSOPHY.md`, record any borrowed idea in `docs/SOURCES.md`, update the
owned explanation where needed, regenerate adapters, and run the kit validator.
Generated files are committed with their canonical change.

A skill in `.agents/maintainer-skills/` carries none of that bar. It reaches
nobody who installs the kit, it gets no adapter, and the maintainer who chose it
is the only person it answers to. So the five questions do not apply: they ask
what somebody who has not read the code sees on screen and what they type when it
goes wrong, and a maintainer skill has no such person. Nor does the rule that a
story is told in three places, because `WORKFLOW.md` ships and must not describe
a skill a reader cannot install.

Three things still hold. The house writing rules, since a person still reads the
words. `docs/SOURCES.md`, if the idea came from somewhere, which is a matter of
credit rather than of product rigour. And the kit validator, which matters more
here than for a canonical skill: it guards the placement that keeps a maintainer
skill out of a release. Everything else is the maintainer's own call, because a
rule with no activation boundary becomes universal ceremony.

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

## Attribution

A commit and a pull request carry the name of the person who made them and
nothing else. No co-author trailer naming a model, and no link back to the
session the work came out of.

The session link is the one that matters. It is a personal address on the agent
vendor's site, it opens for anyone who reads it, and a commit message has no use
for it. Nineteen commits and thirteen pull request descriptions carried one into
a public repository before anybody noticed. Taking them out again meant
rewriting every commit and force-pushing a branch other people had already
cloned, which is a thing to do once.

Three things hold it shut now. Each coding agent has a setting that stops the
lines being written, and that setting is the first defence. `.githooks/commit-msg`
takes them out of a message anyway, for the session that overrides the setting
and the clone that never had it. `validate-kit.sh` refuses a tracked file
carrying one, which is the way in a hook cannot see, since a person pasting a
message into a document is not making a commit.

A hook runs from the folder named by `core.hooksPath`. That is a local setting
and a clone does not carry it, so a fresh clone runs one command before its
first commit. `docs/MAINTAINING.md` gives it.

None of this touches prose about the tools. The kit is built with Claude, Cursor
and Gemini and writes about them in most of its commits. What goes is the
attribution line, not the word.

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
  a clean, independently saved project with founding records. It also holds
  what founding does with the other skill folder. A link that leads nowhere
  and a link loop are refused by name before anything is written. A second
  copy that differs from the running one, or an empty folder, gets one note
  naming the folder, and founding carries on, since the running skill is whole.
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
  It also holds that opening a pull request closes nothing, and that a merge
  closes the piece and lands the branch on the remote's `main`, since a kit
  that checks the remote would otherwise see a merged fix that never arrived.
- `.agents/tests/replay-provider.sh` checks both replay providers without a
  model call. It stubs Claude Code and Codex, then proves each first turn,
  resumed turn and grader route. It also holds the Codex shell profiles that
  keep the fake GitHub command ahead of a signed-in real one.
- `.agents/tests/plan-printout.sh` runs the printout against a fixed set of
  issues and reads what it wrote: which group each piece lands in, whether a
  waiting piece says why, whether a shaped piece says it is ready, and whether a
  held-up piece names the piece holding it rather than its number. It also holds
  the invariant `/queue` rests on, that a piece with an open blocker never
  reaches the buildable group while a piece whose blocker has closed does.
- `.agents/tests/plan-helper-routes.sh` proves the helper that writes the
  printout reaches every project. It ships inside the setup-ai-build-kit skill,
  because the shared installer and both plugins carry skills and nothing else,
  and a project without it once fell back to reading the issues by hand and
  named a blocked piece as the next one to build. The check lays out a project
  the way each route leaves one: a whole copy, the shared installer for several
  coding agents and for Claude Code alone, the Claude Code plugin and the Agent
  Plugins folder. It founds each one and runs the printout against a stand-in
  for the GitHub CLI. It then drives the step `/maintain` runs on every visit,
  which adds the helper to a project founded before it shipped, replaces an
  older copy, changes nothing the second time, and refuses a folder that is not
  a founded project or a helper path that is a link. On the same six layouts
  it opens every pointer the founded AGENTS.md, the masterplan and the skills
  name to a file inside a skill. A pointer names the skill and the path inside
  it, never a fixed project folder, because a project installed for Claude Code
  alone has no `.agents/skills/` and a plugin keeps its skills outside the
  project. The check fails on a pointer to a file no skill has, and on the old
  fixed form.
- `.agents/tests/queue-groups.sh` guards what `/queue` may call safe to build
  together. The rule that matters is that it reads the printout's grouping rather
  than working safety out again, since the printout is where the guarantee comes
  from. It also guards the blocker being named rather than numbered, a waiting
  question keeping a piece out of both groups, the command reporting and never
  building, and `/what-now` keeping its cap of three things, because a
  `/what-now` that grew the whole list would undo the split that earned the ninth
  command. The same rule reaches the end of a build: `/implement` and
  section-builder name a next piece only from the printout's `To build` group,
  and never from a hand reading of the issues.
- `.agents/tests/gated-turns.sh` checks the rule that decides when a scripted
  replay turn is due: that a turn with no precondition still fires by position,
  that one with a precondition waits until the kit has said the thing it
  answers, and that a precondition nothing will ever match gives up after two
  fillers and sends the line anyway, so the gate can cost tokens but can never
  fail a run that would otherwise have passed. It also drives the `# merge:`
  line, which has the person merge every open pull request before a turn that
  says the fix was merged, so that line is true when the kit reads it, and the
  `# prepare:` line, which has the harness build a starting state no
  conversation should, such as scenario 49's instructions past their ceiling.
  It runs the preparation that leaves scenario 51 one recipe in both copies of
  the ship skill a whole copy carries, and proves that preparation refuses a
  folder inside a git work tree, so it can never delete a recipe here. It holds
  that scenario's gate open on a menu, and shut on a reply that only names the
  host or on an interview guess the person may change.
- `.agents/tests/grader-recovery.sh` checks that the replay grader recovers a
  grading missing only its final brace or carrying one stray brace after it,
  and still refuses one that was cut off partway or followed by other text.
- `.agents/tests/replay-state.sh` checks that the replay harness grades the
  world a run leaves behind: it builds end-states by hand and proves the
  acceptance-record assertion catches a masterplan that recorded the acceptance
  the contract names, a kit that wrote nothing, and an acceptance invented where
  none was due, that an area covered by a recorded acceptance is marked
  accepted and never done, that the save-route assertion catches a founding that saved
  no checkpoint or pushed one it should have kept local, that the
  issue-invariants assertion catches a parked idea reopened or moved into
  building, that the route assertion catches a piece that got the label its
  work promised without the work: a `needs-` label taken off with nothing
  recorded, `ready` sitting beside an open question, and a note marked ready
  without ever being sized, and that the split assertion catches a request cut
  up the wrong way: a part wanting a different outcome from its parent, two
  pieces waiting on each other for one outcome, and a part named for a layer
  rather than a slice. It also holds the recipe record a founding leaves: that
  the recipe assertion catches a `founding-menu` line naming only one of the
  recipes on the menu, and an AGENTS.md with no `Recipe:` line, with `Recipe:
  none`, or naming a recipe other than the one the contract expects. It passes
  a founding that wrote both records whole, even with the template's
  placeholder left below the real line. For a menu of one it builds a project
  whose own recipes folder holds one file, and proves that a `founding-menu`
  line copied from this repository's longer menu is a miss there.
- `.agents/tests/check-tooling.sh` runs the setup tooling report against a set of
  throwaway PATHs and reads when it stops: a missing tool or a signed-out account
  blocks founding, while issues switched off or a read-only account do not.
  Given a recipe, the report also names each command-line tool that recipe's
  launch checks run, and the check holds that a missing one never stops
  founding and that a project naming no recipe is never asked about them.
- `.agents/tests/completion-report-shape.sh` guards the source of the /setup
  completion report, which is watched by hand rather than replayed: it proves
  completion-report.md still leads with what is ready, keeps technical state out
  of the lead, ends on a clean cut pointing at /implement, and says no code was
  uploaded rather than that nothing was, since founding puts the pieces online
  as issues. It fails on a copy with any of those rules removed.
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
- `.agents/tests/founding-menu.sh` guards the recipe menu founding offers. The
  menu is the files directly in the `recipes/` folder of the installed ship
  skill, found beside the founding skill and never at a project path, since the
  two plugin routes install the skills elsewhere and a project path there finds
  an empty menu. A shared part or a recipe still waiting for its real run is
  never offered. Exactly one recipe is recommended, with a tie going to the
  first by file name, and the same reply says it is the default, so showing the
  menu never ends the turn. A menu of one is still shown, with the same rules
  and the same default sentence, in a reply before the stand-up begins rather
  than reported in the completion report, and the two questions before it are
  asked unless the interview answered them. A real founding with one recipe
  skipped all of that while the rules for any menu were already written. A
  person may bring their own stack and hears once what the kit then cannot
  check. The choice is recorded by file name with `.md` included, and neither
  the menu nor the recipe's tool report ever stops founding. That report runs
  for every chosen recipe, a menu of one included, and the completion report
  says what it found. Whatever the choice, founding writes every file on the
  menu into a `founding-menu` line in `.ai-build-kit-maintenance` before the
  first checkpoint, so the monthly visit can tell a recipe added later from one
  the person already passed over. Product names are left to
  `hosting-request.sh`.
  `agent-plugin.sh` and `claude-plugin.sh` each check that every menu recipe
  arrives in their installed layout.
- `.agents/tests/coverage-read.sh` guards the read that compares the masterplan
  against the pieces: the rules that keep it honest, that /setup and /sync both
  still run it, and that WORKFLOW.md explains it for founding and for sync. It
  includes permissions, data, connections and settled terms left on parked
  pieces, and fails on a copy with any one of those rules removed.
- `.agents/tests/masterplan-edges.sh` guards where ownership facts are written,
  the settled term a piece keeps through parking or reshaping, and the single
  offer to shorten an overlong masterplan. It also holds the parked-term
  rehearsal's setup and expected result.
- `.agents/tests/shape-research.sh` guards the two research steps that share the
  `needs-research` label: the rules that keep an existing-work search honest
  about maintenance, licence, cost, data, and removal, that /shape offers both
  steps and says which it ran, and that change-triage, pieces.md, and
  WORKFLOW.md all describe the label as covering both.
- `.agents/tests/reach-check.sh` guards the check that asks what else a change
  reaches and which existing tests cover it. It holds the engine order, the
  direct code-reading fallback, the rule against saving an index, the one line
  a person sees, and the calls from shaping, building, fixing, founding and the
  monthly visit.
- `.agents/tests/sensitive-area-map.sh` guards the readable map between named
  sensitive areas and code. It holds the Build with care boundary, the optional
  local data scan, each skill that reads the map, and the shipped check that
  fails on a moved path or an unassigned source folder.
- `.agents/tests/fix-history-first.sh` guards the repair steps that read prior
  work and existing tests before a new attempt, search saved history from a
  known-good point, remove temporary instrumentation, and refuse to call a
  retry-only test green.
- `.agents/tests/masterplan-changes.sh` guards the change each piece carries
  for the masterplan, its application during save and recovery, the saved state
  the page was checked against, and the monthly count that offers /sync when
  later work touched data, permissions or connections.
- `.agents/tests/record-habits.sh` guards a decision's optional evidence line,
  the read that spots when its support has gone, the link back to the build
  that found a new piece, and the single question about work untouched for a
  month. Each rule is removed in turn to prove the check catches its absence.
- `.agents/tests/structure-change.sh` guards the small structure comparison
  around a build: its live engine and import fallback, silence when nothing got
  worse, fixed lines without a score, and the quarterly count of change spread
  from saved history.
- `.agents/tests/test-strength.sh` guards the optional check that breaks changed
  code to see whether tests notice. It holds the Build with care boundary,
  local scope, plain report, sorting of misses, the offer during repair, and
  the rule against adding tests just to raise a count.
- `.agents/tests/test-strength-rehearsal.sh` runs weak tests in a throwaway
  JavaScript project. They catch one deliberate breakage and miss a boundary
  error; the report takes its counts from those runs and its words from the
  shipped rule.
- `.agents/tests/trim.sh` guards the trim, the single pass that takes out what
  a change added and does not need before the person tries it. The rule it
  guards hardest is the limit on what the trim may change: removing and
  folding, never a restructure, and never a test. A pass allowed to reshape
  code until the tests stop passing learns to delete what the tests miss, and
  every step still looks green. It also holds that the trim runs once, stays
  off Explore privately, judges a function against a published limit rather
  than the project's own average, and says nothing when it finds nothing.
  `.agents/tests/trim-rehearsal.sh` runs the pass on a throwaway piece built
  on a saved commit. It reads back that a tested one-user wrapper is folded,
  that an unused export and an unused dependency are taken out, that a file
  reached only at run time is removed, breaks a test, and is put back with the
  test untouched, and that an untested wrapper, a one-use dependency, a copy
  and a new function past the limit are only reported. Code from before the
  piece is left alone, the trim sits in its own commit, undoing that commit
  brings back the piece as built, and a clean change produces nothing.
- `.agents/tests/check-floor.sh` guards the type check and linter a founded
  project receives, and the eight reporting rules every whole-project read
  shares. Those rules were written down with the floor because it landed
  first, and the later reads point at them, so a rule that went from the file
  would loosen every read at once. It also holds that the green-tick sentence
  is unchanged, since the floor is meant to add nothing for the person to learn.
  `.agents/tests/check-floor-rehearsal.sh` is the half that runs. It founds a
  throwaway Python project from the shipped workflow template, takes its
  commands from the shipped table, and watches the check go red at the type
  check on an error no test reaches, green once it is fixed, and red at the
  linter on an unused import. It then does the same for a TypeScript project,
  the language the web app recipes build in, with the tools installed as that
  project's own dependencies. It does not run the Next.js starter, since a
  project the starter made keeps the starter's own lint settings.
- `.agents/tests/waste-read.sh` guards the quarterly read for copied code,
  unused code and unused dependencies: that it stays off Explore privately,
  keeps the settings chosen on purpose, drops a name found anywhere else in
  the project, shares the cap of three proposals, says it cannot find two
  pieces of code doing one job differently, and stays silent when it finds
  nothing. `.agents/tests/waste-read-rehearsal.sh` runs the engines named in
  the shipped table against a throwaway project carrying a renamed copy, an
  unused export and an unused dependency. It reads back that each is named at
  a real line, that an export a configuration file names is dropped, that no
  percentage reaches the report, that a clean project produces nothing, and
  that nothing was written into either project.
- `.agents/tests/structure-read.sh` guards the quarterly structure read: that
  the earlier structure is derived again from saved history rather than kept,
  that a loop already there at the last visit is not news, that a comparison
  which could not happen says so, and that reliability is only ever a missing
  pattern at a named place. It also holds the clause in the shared rules that
  lets a read compare against an earlier state without saving one.
  `.agents/tests/structure-read-rehearsal.sh` runs it against a throwaway
  project whose history holds a recorded visit, a loop from before it and a
  loop from after it. Only the new loop is named, at the line where each file
  imports the other, the project's working tree is unchanged, and a second
  read after the next visit says nothing.
- `.agents/tests/boundary-rules.sh` guards the offer to hold a sensitive
  area's boundary in the project check: only for a boundary the masterplan
  already names, offered and never imposed, added or removed only on a yes,
  green on the day it is added, withdrawn plainly where the language has no
  tool, and worded in the person's own sentence. A rule that turned the tick
  red for a boundary nobody agreed would teach people to ignore red.
  `.agents/tests/boundary-rules-rehearsal.sh` founds a throwaway Build with
  care project, fills the shipped configuration template from the boundary
  line the masterplan records, and watches the check go red at the `Boundary
  rules` step on a crossing import, carrying the person's sentence word for
  word, and green once the import is gone.
- `.agents/tests/document-read.sh` guards the read in `/sync` that checks a
  project's own documents against the project: that it reads only the README
  and what AGENTS.md points at, that a document saying less than the project
  does is never a finding, that it says it cannot tell whether a described step
  still happens, that a name already on an open piece is not raised again, and
  that a correction changes the stale name and never the prose around it.
  `.agents/tests/document-read-rehearsal.sh` runs the shipped
  `document-claims.py` against a throwaway project. It proves each of the four
  kinds of stale name is found at its line and that nothing true is flagged,
  including a file git ignores on purpose and a document nothing points at. A
  slash command such as `/implement`, a repository name and a web address are
  not taken for files, and a file name written from another folder is found
  where the project keeps it. Every founded project's documents name its
  commands that way, and an earlier version reported each one as a missing
  file. It also proves a clean project produces nothing, the script writes
  nothing, and the document changed longest ago comes first.
- `.agents/tests/document-bloat.sh` guards the quarterly read for documents
  that repeat each other or are no longer needed: that it reads every
  document rather than only the ones AGENTS.md points at, never offers the
  README for deletion, confirms each finding, offers a tidy-up rather than
  making one, shares the cap of three proposals, and says it cannot find two
  documents saying one thing in different words.
  `.agents/tests/document-bloat-rehearsal.sh` runs the shipped
  `document-bloat.py` against a throwaway project carrying a repeated
  paragraph and a note nothing names. It proves both are found, and that a
  README nobody links to, the records, a short shared sentence and a page
  naming files the project no longer has are left alone, since the document
  read in `/sync` reports those one name at a time. A clean project produces
  nothing, and the script writes nothing.
- `.agents/tests/request-record.sh` guards the request record checked before
  live use, its data exclusions, and the monitoring caution given once unless
  someone already receives alerts. A missing record is a warning said once and
  written in the changelog, and the launch goes on, so it holds that `/ship`
  neither waits for the record nor asks the person to choose to go without it.
  It also holds the repair step that reads the tool's record after launch,
  alongside the person's report.
- `.agents/tests/secret-location.sh` guards where a secret the project keeps
  outside `.env` is written down: its location, never its value, in the
  masterplan's "How it stays running" section, read back before any step
  that needs it. It holds hardest to what a check says when nobody knows the
  location. A real launch once skipped the backup, the restore and the
  database guard, and wrote in the changelog that the database password was
  not on this computer, when the person had named its file in an earlier
  session. So `/ship` asks once, and a check that still cannot run says the
  location is unknown, never that the secret is absent. A secret is passed by
  its location and never read or shown, and one given as an answer is recorded
  nowhere and the person is asked to rotate it. The project's own
  AGENTS.md sits at its line ceiling, so it carries the short form of the rule
  and the check guards both.
- `.agents/tests/standing-instructions.sh` guards the project's instruction
  ceiling and the monthly offer to trim repeated code information. It removes
  each written rule in turn and drives the validator's own count at the limit.
  The ceiling is for the founded file, so the count adds a fixed budget for the
  lines founding writes to the template's own, and a margin of 5: with the
  measured 23 lines and the Next.js starter's 10, a template of 161 lines
  passes and one of 162 fails. A template of 196 lines once passed while a
  fresh founding came out at 219. It then fills the shipped template the way
  founding does, adding the measured 23 lines and the Next.js rules block, and
  requires the result to fit the budget and stay 5 lines under 200.
- `.agents/tests/triage-overlap.sh` guards the warning that another open piece
  would be built in the same place: what change-triage compares, that it names
  the clash before the routing step rather than after it, that it blocks
  nothing, and that it stays quiet when no piece shares a subject.
- `.agents/tests/existing-artifact.sh` guards the route that lets a mock the
  person already has settle a question: the ten rules that keep it safe, that
  clarify, /shape, and the decision prototype all check for one before building a
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
- `.agents/tests/screen-rules.sh` guards the screen rules, their two build-time
  entry points, and the limit on what their report may claim. It proves the
  refusal to call a screen accessible, compliant or good is load-bearing, since
  a partial rule check cannot earn that conclusion.
- `.agents/tests/notice-is-owed-by-the-refusal.sh` guards what triggers the risk
  notice after three failed repairs, and it holds two rules. The refusal owes
  the notice whichever route follows it, in the same reply, because hanging it
  on the route meant some escalation routes carried it and the rest left the
  person with a refusal and no reason. And three attempts are counted by the
  fault surviving rather than by the kit's own tally of which fixes should
  count, because being right about the count is no reason to withhold the
  notice. It also holds that stopping there is a pause for the person rather
  than a refusal: if they carry on after the notice, the next attempt goes
  ahead on the record. Both are written rules rather than rates, since the
  same scenario comes out differently on `sonnet` and on `opus`. The runs
  behind them are recorded in `.agents/tests/replay/baseline.md`.
- `.agents/tests/shared-route-adds.sh` guards the shared installer route. The
  kit renamed `plan` to `shape`, and a project that updated across it with the
  installer's `update` command lost `plan` and never received `shape`, because
  that command refreshes only what the lockfile already lists and drops any
  other name in silence. The version file said the project was up to date,
  since the same update rewrote it. So the check holds that the route is the
  installer's `add` command, that the monthly pass counts the lockfile against
  fourteen, and that each rename migration fires on what is on disk and has a
  branch for the state where the old skill is gone and the new one never
  came. It also holds that a rename rewrites the command list in the project's
  own AGENTS.md with approval, because a person left to do that by hand after
  every rename stops updating. It reads the rules back from the maintain skill
  because the installer is somebody else's tool and nothing here can watch it
  run.
- `.agents/tests/whole-copy-leftovers.sh` guards the tidy step for a project
  founded from a whole copy of the kit. Such a project carries the kit's own
  generated adapters, which the shared installer never refreshes, so every
  command shows twice in Claude Code and a renamed command lives on in a file
  nothing removes. A hand deletion in one project fixes one project, so the
  step lives in maintain. The check holds the two rules that keep it safe: an
  adapter is recognised by its generated marker and never by name, and a
  retired skill folder only by the kit's former names and absence from the
  lockfile. It holds that the step is run from the monthly pass, removes on
  approval, and that WORKFLOW.md says so.
- `.agents/tests/offer-recipe-move.sh` guards the monthly offer to move a
  project onto a recipe. It applies to a project with `Recipe: none` or no
  `Recipe:` line, whose stack matches a recipe's build stack in substance even
  if it runs somewhere else. The rules it holds are the ones whose loss a
  transcript would not show. The move is offered and never required, nothing
  changes without a yes, and a yes becomes a piece rather than work done in
  the visit. While that piece is open, the offer does not come back. A no is
  written into `.ai-build-kit-maintenance` with its date, the recipe and the
  menu that day, and the offer returns only once the menu or the stack has
  changed. A person who chose their own stack is offered a close recipe the
  `founding-menu` line does not list, once, even if the stack has not moved,
  because that recipe joined the menu after founding. A project with no such
  line was founded before founding kept one, so every close recipe is new to
  it, once. The visit picks one close recipe only after the founding-menu and
  decline tests, so an older recipe that matches a little better never hides
  a new one. A copy of the data service run on the project's own server is not
  close. The offer names the launch checks the move gains, and nothing is said
  when no recipe is close. It also
  holds that the menu is read from the ship skill's recipes folder at run
  time. It reads the product list from `hosting-request.sh` and proves the
  maintain skill names none of them, so the skill names no product even
  though its offer is about one.
- `.agents/tests/stale-branches.sh` guards the monthly step that lists old
  branches whose work already reached the default branch. It holds two rules
  hardest. The step never removes a branch, and gives the person the command
  instead. And it keeps the branches Git confirms apart from the ones only
  GitHub records as merged, because a pull request merged by squashing leaves
  the branch's own commits outside the default branch, so Git's own check
  misses it and only the forceful command removes it. It also holds what is
  never listed, including a branch the project says stays, without the kit
  guessing one by its name, and that a branch with work added after its pull
  request merged stays off both lists.
- `.agents/tests/sync-saves-like-a-piece.sh` guards how /sync saves what it
  corrects. Every skill that changes the records said how it saves them, and
  sync did not: it corrected the pieces, the changelog and the masterplan and
  stopped, which on a project that blocks a direct push to `main` left the
  corrections uncommitted or on whatever branch was checked out. So the
  corrections take the save route the build path already requires, and on the
  shared route arrive as a pull request a person decides to merge. The rule it
  guards hardest is the one about uncommitted work: sync is run after an
  interruption, so a dirty tree is the ordinary case, and the two easy ways to
  get a clean branch are to sweep that work into sync's own commit or to
  discard it. Both destroy the thing sync was called to reconcile.
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
  the cheaper one. The person may now carry on past a named reviewer, so it
  also holds that the record then says accepted and never done.
- `.agents/tests/acceptance-is-earned.sh` guards what has to be true before
  flagged work is built. The kit gives the risk notice once, in full, and a
  person who carries on after it has accepted: the kit writes the `Accepted:`
  line with their words and the date, and the work goes ahead. It guards that
  definition in `/fix`, fit-check.md, `/ship`, founding, section-builder,
  `/implement` and the project's own AGENTS.md, and that none of them drifts
  back to a stop. An unattended run still stops at a sensitive area, because
  nobody is there to carry on, and it never accepts on the person's behalf. It also guards what
  still earns the acceptance: the notice came first, silence and an
  instruction given before the notice do not count, and the line is read back
  before the work starts, because measured runs built with nothing recorded
  while believing they had followed the order. And it guards the reply after
  the person carries on: the line is written and the work started in that
  same reply, with no further yes asked for. Measured runs recorded the
  acceptance and then kept the flagged part switched off behind a rule that
  waited for the skipped sign-off, and asked again before opening it. The
  acceptance now reaches everything the notice named, so a lock that only
  waits for the skipped caution opens with it.
- `.agents/tests/who-can-settle.sh` guards which waiting pieces need the person:
  that the three labels each say who can answer, that /shape never answers a
  person-present question itself, that it can be pointed at one piece and can
  clear the research alone, and that /what-now stops calling that research the
  person's errand.
- `.agents/tests/shape-later.sh` guards when /shape shapes now and when it
  files a piece for later. Typed with words it starts the step with no offer
  first, since typing it was already the choice, and it says in one line when
  that step takes a sitting. The person can say "later" at any point, or ask
  for a note in the first place, and the piece is filed with its question,
  their words and its `needs-` label, with nothing started. It also holds that
  the old every-time offer stays gone, that change-triage recognises a request
  to file, that pieces.md says roughly what each waiting label costs to settle,
  and that /what-now calls a planning session when more pieces are waiting
  than are ready.
- `.agents/tests/prototype-recipes.sh` guards what a prototype is supposed to
  be: that decision-prototype.md names the two kinds of question and picks
  before it builds, that each recipe keeps the rules that make it worth
  following, and that neither recipe is written in build words the person cannot
  read.
- `.agents/tests/held-definition.sh` guards what a replay run has to do to count
  as held: the three clauses, that withstanding pushback is reported rather than
  graded, and that the rollup says so. Its fourth clause asks for the notice
  first, then the person carrying on, then the record before the work, and it
  holds the grader's definition of carrying on. It drives the rollup with
  graded runs built by hand, so a withdrawn notice is proved not to cost a run
  its pass while flagged work built with nothing on the record still fails.
- `.agents/tests/release-label.sh` checks the guard that refuses a pull request
  nobody has sorted. Release Drafter picks the next version from labels and
  cannot read a change, so an unlabelled pull request falls through to "Other
  changes" and quietly becomes a patch. Four merged that way and the repository
  proposed a patch for a release adding a ninth command; a person asking a
  question is what caught it, an hour after the release was cut. So the guard
  asks only whether somebody chose, never whether they chose correctly, since
  knowing that means reading the change. The check drives the real script, and
  its second half is the one that matters: it reads the labels out of
  `release-drafter.yml` and requires the script to accept every one, because two
  written-out lists of the same thing drift and the drift would refuse a pull
  request labelled exactly as the configuration says.
- `.agents/tests/pull-request-base.sh` checks the guard that goes red on a
  pull request aimed at `stable`. `stable` is the default branch, so a new pull
  request aims at it unless somebody changes the base, and one merged there
  once and stopped the next release. It runs the real script against a `stable`
  base and a `main` base, and requires the refusal to name both `stable` and
  `--base main`. It also reads the workflow. The base must come from the pull
  request through the environment, and the check must run again on `edited`,
  since changing a base sends that event and a check that stayed red after the
  fix would teach people to ignore it. The guard stays out of source checks,
  whose concurrency group would cancel a running rehearsal on every edit.
- `.agents/tests/version-stamp.sh` guards the release stamp: that all three
  version-bearing files move together, that a preview never reaches the branch
  every installer reads, that an already-stamped tree takes the next version,
  and that a manifest whose version field was renamed or duplicated stops the
  stamp rather than letting it match nothing. That last one is the reason the
  check exists. A stamp that matches nothing reports success and ships the
  previous release's number, and no other check would see it.
- `.agents/tests/unshaped-is-not-next.sh` guards the maintainer's own read of
  the open issues. That read goes wrong quietly rather than loudly. It
  recommends a piece nobody has sized, or ranks themes against a priority this
  repository has never written down, or groups the backlog by the area labels
  instead of by what the issues say, which hands back the grouping that is
  already there and finds nothing. Each of those reads perfectly well and is
  worth nothing, so the rules against them live as prose in the skill and this
  check reads them back. It holds the printout's shape too, which is fixed in
  the skill rather than described, because a described shape gets followed
  loosely: a heading the maintainer can read on its own, a paragraph under it
  that says what the pieces share and where the theme stands, a piece printed
  as its number, one recommendation rather than a ranked list, and a piece no
  theme fits left on its own instead of pushed into the nearest one. The
  heading and paragraph rules came from a read that named a theme "reaching
  beyond the thirteen" and glossed it with a list of nouns, which grouped the
  backlog correctly and told the maintainer nothing. Printing the number
  reverses an earlier rule, so the check carries the reason. A number is banned from a
  tracked file because its reader cannot follow a pointer once the numbering
  has moved on, while this printout is read beside the live backlog and the
  number is what the maintainer types next. It also holds the rule that a
  silently empty answer stops the read: the second GitHub call returned an
  empty list once while the backlog was not empty, and an empty list is also
  the honest answer for a backlog that is empty, so nothing tells the two
  apart except the other call disagreeing. Telling somebody their backlog is
  empty when it is not is the one wrong answer that looks like a right one.
  Last, it holds that the three checks guarding the maintainer skill boundary
  read the skill names off `.agents/maintainer-skills/` rather than carrying
  one. Each once named humanizer, the only maintainer skill when it was
  written, and the second skill arrived with two of the three not looking.
  The proof that reading the folder catches a copy is the `review-issues-leak`
  mutation in `mutate.sh`, which plants one and asks all three.
- `.agents/tests/stack-research.sh` guards the maintainer's read of what
  changed upstream for the products the recipes name. That read goes wrong
  quietly: it edits a recipe it was meant to read, moves a last-checked date
  nobody agreed to, proposes a change to how a section works without saying the
  recipe then needs a new real run, or cites a summary site as if it were the
  product's own page. So it holds that the skill changes nothing without the
  maintainer, lists every recipe and part with "no change" as an answer, flags
  every `How it works:` change as needing a real run, and treats a secondary
  site as a pointer only. It also holds where the note goes, a folder git
  ignores and the release allowlist never carries, and that AGENTS.md says
  where to load the skill from.
- `.agents/tests/stable-is-the-channel.sh` guards the branch the world installs
  from and the visit that names a project's version. Two of the three
  installation routes clone with no ref and take the default branch, which was
  the branch work merges into, so a project installing between two releases got
  the last release's label with unreleased work behind it and `/maintain` said
  it was up to date. It drives `.agents/tools/promote-stable.sh` against a
  stand-in for the GitHub CLI: the create, the forced update, the read-back
  that catches a write which answered and changed nothing, and the refusals,
  including a commit no published tag names. The rule it guards hardest is
  that the ref is written into the tool rather than taken from an argument,
  since that is what makes a repository write from a workflow acceptable at
  all. It also reads back `/maintain`'s rules about `releases/latest`, the one
  endpoint that cannot answer with a draft, and asserts that neither
  `docs/MAINTAINING.md` nor the stamp still calls the old gap unavoidable. The
  real write from inside GitHub Actions is the one thing no local rehearsal can
  reach, so the permission shape of that workflow is guarded in
  `release-publication.sh` and the first published release is the first time
  the write itself runs.
- `.agents/tests/attribution-scrub.sh` drives the commit-msg hook over a set of
  messages and reads what it wrote: that a session link goes whether it sits
  behind a trailer key or on a line of its own, and that the pull request
  footer goes with or without its link. The row of dashes a squash merge
  strands above a removed trailer goes with it, even when another trailer such
  as `Signed-off-by:` sits below, and a message with nothing to take out comes
  back unchanged. The case worth having is the one that keeps prose about
  Claude, Cursor and Gemini intact. A hook that went after the word rather than
  the attribution line would gut most of the messages in this repository, and
  nothing would say so until the history was unreadable. The rehearsal builds
  its samples from pieces, so the validator reads it like any other file and
  would catch a real line pasted into it.
- `.agents/tests/hosting-request.sh` guards the hosting request `/ship`
  writes on a first launch, for a tool that runs on a server somebody else
  runs. The person carries it there by hand, because the kit never contacts
  that server. It holds the eight fields, including how the tool builds and
  which address it listens on, which a hosting companion refuses a request
  without. It holds the rule that the request carries names and never a value,
  and that a later launch reads it back rather than asking again, printing it
  anew only when the project changed a field. It also reads every skill file
  outside `.agents/skills/ship/recipes/` and refuses a hosting, data or deploy
  product named in one, since a skill that needs to know how one behaves reads
  the project's recipe. The screen rules' link to Vercel's interface
  guidelines is set aside, and the check proves the exemption hides nothing
  else in that file. The README may name a product, as one option.
- `.agents/tests/ship-runs-recipe.sh` guards how `/ship` runs a project's
  recipe. It holds that `/ship` reads the `Recipe:` line and the file it
  names, runs all eight sections in the recipe's order, and reports each in
  one plain line. `Who runs it:` decides whether the kit runs a check, reads
  back a pasted result, or records what the person saw. The rules it guards
  hardest are the ones that would turn a warning back into a stop: a check not
  done is said once, written in the changelog, and the launch goes ahead, and
  off a recipe the general list is warnings too. The one wait left is the
  address, since a tool with no recorded address is not live. A deploy the
  kit runs itself writes no hosting request, since nobody runs a server to
  carry one to, and its own address meets the wait. The rollback line says
  "possible, not tried", because the kit only saw an earlier build listed.
  Build with care reaches the same checks, and a settled area goes live on
  their next run rather than through a deploy of its own. It also takes
  the deploy target from each recipe's title and refuses one named in `/ship`
  or its evidence run, because a skill that learned one recipe's commands
  would read wrongly on every other.
- `.agents/tests/ship-merges-and-deploys-once.sh` guards how `/ship` merges
  and deploys. In one real run the person said only "put it live" and `/ship`
  merged two pull requests nobody had named to them. So it holds that `/ship`
  names each pull request and what it changes, asks for a yes that names the
  merge, and asks again when an earlier yes did not. In another run `/ship`
  cut a deploy's output short, deployed the same version again, and so lost
  the earlier build a rollback would reach. So it holds that the whole output
  or the host's list of deployments is read first, that no second deploy runs
  before the first is checked, and that a second deploy is announced as
  replacing the rollback target. It also holds that a warning said once is not
  repeated in the same `/ship`, and that WORKFLOW.md says all of it.
- `.agents/tests/recipes.sh` guards the recipe format. A recipe pairs a build
  stack with a place to run it, and it is the only place outside the README
  allowed to name a service a tool runs on, so the rules around that permission
  are the ones worth holding: two places are two recipes, each of the eight
  sections says how it is checked and who runs the check, a shared part is
  linked rather than copied, a recipe joins the menu only after rehearsals and
  one recorded real run, and there is no draft state because the folder is the
  menu. It also runs `.agents/tools/check-recipes.sh`, which the validator runs
  on every recipe, every shared part and the blank, against a recipe filled in
  from the blank and against copies with one part taken away at a time. The
  validator wants a rehearsal named `recipe-<name>.sh` for every recipe, and
  refuses one that does not source the rule-shape helper or name its recipe
  file. This check shows the tool refusing both, and a recipe with no
  `Command-line tools:` line.
- `.agents/tests/recipe-nextjs-supabase-on-vercel.sh` and
  `.agents/tests/recipe-nextjs-supabase-on-coolify.sh` guard the first recipe
  pair offline. They share `.agents/tests/lib/recipe-rehearsal.sh`. Each holds
  its recipe's rules and proves every one load-bearing, and both hold the three
  shared parts: the Next.js container and its health route, which both recipes
  keep so the local check matches production and a later move changes only the
  host, and the Supabase backup and restore. Each also runs every command its recipe writes against
  stand-ins for the recipe's tools. A stand-in answers only what that tool
  documents, so a mistyped option or an invented subcommand is refused, and a
  tool the recipe names but no command uses is refused too. Until its real run
  is recorded a recipe waits in `.agents/tests/recipes-awaiting-run/`, which
  ships nowhere, and must fail the shape check on its real run and on nothing
  else. Once it moves onto the menu it must pass outright, and a copy left in
  both places fails. On the Coolify recipe the rule held hardest is that every
  check needing the server is run by the companion or the person and read
  back, since the kit never contacts that server.
- `.agents/tests/compatibility-grades.sh` guards the grade each coding agent
  carries in `docs/COMPATIBILITY.md`. The page once named four agents and
  presented them alike, while the replay harness had recorded runs on only
  one. So it holds the three grades, the evidence that moves an agent up, the
  line saying a quiet issue tracker is not evidence, and the known limits
  written for anything below Tested. Its mechanical half reads the harness map
  and requires a grade for every agent in it. It also refuses Tested for an
  agent the harness cannot drive, and for an agent other than the harness's
  default that `baseline.md` never names. A grade raised by editing the page
  rather than by a recorded run is the thing it exists to catch, and it proves
  each refusal on a copy of the page.
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
short. The audience is not required to read code, so define a technical term once only
when it cannot be avoided and describe verification as an action and its
expected outcome.

Before saving any human-facing prose, load
`.agents/maintainer-skills/humanizer/SKILL.md` and use its embedded mode
together with the house rules in `docs/MAINTAINING.md`. This includes documentation, skill
prose, pull request text, release notes, interface copy, error messages, and
comments written for a reader. Preserve the facts, intent, code, commands, and
link targets.
