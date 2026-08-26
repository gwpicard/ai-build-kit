# MAINTAINING.md: notes for the kit's own maintainers

This file is for people working on the kit itself. The release allowlist keeps
it out of the kit a project receives.

## This repository is the kit's source

The distinction is easy to lose in the middle of a session, and losing it has
produced the same mistake more than once.

- None of the project records exists here. `masterplan.md`
  and `CHANGELOG.md` are created by `/setup-ai-build-kit` from
  `.agents/skills/setup-ai-build-kit/templates/`, so the installed setup-ai-build-kit skill can prepare
  someone's project. The kit's own history lives in commit
  messages and release notes, not a root `CHANGELOG.md`.
- Root `AGENTS.md` carries the source-maintainer rules.
  `.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md` carries the rules that
  start places at the root of a project.

The eight user-facing commands are product under test here, not the source
repository's own operating workflow. Maintainer changes follow root `AGENTS.md`
and this guide.

## How the issues are organised

The kit's own work is tracked in this repository's GitHub issues. The scheme is
native, needs no organisation account, and carries no dates, because the work is
not on a deadline. Follow it so the board stays legible.

An **epic** is one issue that describes an initiative, with the work under it as
**sub-issues** (GitHub's own parent and child link). The parent shows a progress
bar that fills as its children close. Keep it to two levels, an epic and its
tasks. Mark the parent with the `epic` label. Add a child with
`gh issue edit <parent> --add-sub-issue <child>`, or open one under a parent with
`gh issue create --parent <parent>`. Put an issue under an epic only when it is
genuinely part of that initiative, not merely related; a related issue is linked
by mentioning it in the body instead.

**Labels** carry the categories. Each open issue takes exactly one `area:` label,
one of `area:skills`, `area:tests`, `area:release`, or `area:docs`. Its type is
one of the existing `bug`, `enhancement`, `feature`, `documentation`, or `chore`.
`status:blocked` and `status:needs-decision` are added only when they say
something. Colour is one hue per family, so the list stays scannable. There is no
priority label: what to pick up next is set by the maintainer's cadence, not
recorded on the issues.

Some labels are read by the release machinery and must not be renamed or removed:
`release-major`, `release-minor`, `release-patch`, `skip-release-notes`, and the
type labels `bug`, `enhancement`, `feature`, and `documentation`, which feed the
version bump and the release notes. Only add organising labels around them.

The **Kit maintenance** user Project (`github.com/users/gwpicard/projects/3`) is
the one dashboard across every open issue. Group its table by Parent issue for an
epic view, or add a second view grouped by an area field. A Project groups by its
own fields or by Parent issue, never by a label, so drive its grouping off the
parent link rather than duplicating the area labels as Project fields.

For a quick slice without the Project, bookmark an issue search:
`is:open label:epic` for the epics, `is:open no:parent -label:epic` for
top-level work, `is:open label:"area:tests"` for one area, and
`is:open label:"status:blocked"` for waiting work.

Milestones are not used, because they are release or date buckets and the work
has no timeline. Issue Types, the built-in type field, need an organisation
account this repository does not have, so the `epic` and type labels stand in for
them.

## Adaptive process is a contract

Every rule declares where it applies (always, on named paths or changes, or
professional-only), the way PHILOSOPHY.md requires; do not add a strict step to
the default workflow merely because it is good engineering practice. When
changing a skill, check all four build paths: a change that improves the
professional-led path but burdens private exploration belongs behind a path
condition, not in the shared default.

## Changing a skill

Start with PHILOSOPHY.md, beside this file. Its five questions get answered in
the pull request description before the skill changes. A change that cannot
answer them gets reshaped before it's considered for merge.

`.agents/skills/` is the single source of truth. Edit `<name>/SKILL.md`, run
`.agents/tools/build-adapters.sh`, and commit the canonical change together with
the regenerated compatibility fixtures. Never hand-edit anything under
`.claude/`, `.cursor/`, or `.gemini/`. New projects use the shared skills
installer, the optional Claude Code plugin, or the Agent Plugins folder. The
Claude plugin metadata lives under `.claude-plugin/`. It explicitly
selects the eight generated command files and four generated background skills.
Those thin adapters load the canonical instructions from the plugin cache. The
Agent Plugins manifest lives under `agent-plugin/`, and its `skills`
folder is assembled by the release allowlist rather than by
`build-adapters.sh`, so the canonical skills stay in one place here. The
generated files also remain as maintainer checks. There is no `.codex/` adapter tree to
protect.

The eight commands each end their description with a sentence saying the person
types the command and it never starts on its own. That description is the only
text a client reads before deciding to trigger a skill by itself, so the
sentence stays. It must stay last, because the generated adapters take the
first sentence only. The validator checks both the exact wording and its
position, so change it there and in `.agents/tests/agent-plugin.sh` together.

Every skill declares how it is triggered, in its own file. A command a person
types carries `disable-model-invocation: true`. An internal background skill
another skill calls carries `user-invocable: false`. The adapter builder stops
with an error when a skill declares neither, or both, so a dropped or misspelt
line cannot quietly turn a command into a skill the model may start on its own.

Those two settings are the part several coding agents enforce, not decoration on
the generated adapters: the shared installer and an Agent Plugins client load the
canonical files directly, so removing a trigger setting changes behaviour even
when every generated adapter still looks correct. Tested against Claude Code:
with the setting present it refused to start the skill by itself, and with it
absent it started it.

They are not in the written Agent Skills standard, so its reference checker
reports every shipped skill as invalid. Keep them anyway, with the cost on the
record: the plugin standard tells a client to skip any skill that fails the
skill standard, so a strict Agent Plugins client would load none of the twelve.
Claude Code accepts them, which is why that route works today. If the standard
adopts a setting of its own, follow it and update the short person-facing
version in `docs/COMPATIBILITY.md`.

Humanizer is not in that tree at all. It lives under
`.agents/maintainer-skills/`, and it is the only thing there.

The reason is what a shared skills installer reads. It looks in
`.agents/skills/` and `.claude/skills/` and offers whatever it finds in either,
merging the two by the `name` in each file's frontmatter. The twelve adapters
carry the names of the twelve skills they point at, so they merge away and an
installer finds twelve. Nothing else is called `humanizer`, so a copy in either
folder would be a thirteenth skill offered to every project.

Sitting outside both folders is what prevents that. It is also why the skill
gets no generated adapter and no line in the release allowlist. A marker file
was tried first and cannot work: the marker is this kit's own convention, and
an installer written by somebody else has never heard of it.

Load it by its path when you need it. The validator checks the placement rather
than trusting it, and fails if a folder or command file named for a maintainer
skill turns up anywhere an installer reads.

The vendored copy is pinned to version 2.9.1 from
[blader/humanizer](https://github.com/blader/humanizer/tree/v2.9.1) under its
included MIT licence. Review upstream changes before replacing the local copy.

Some skills carry a `references/` folder loaded only when it applies. Keeping
rules that apply to a minority of sessions out of the always-loaded body is the
pattern to follow when a skill grows.

A project's Claude settings live in start's foundation template, not in this
repository's own `.claude/settings.json`. Change the deny list in both, because
the validator compares each of them against `.agents/guard/blocked-commands.md`.
Only the template carries the session-start wiring, and only `setup-ai-build-kit` places the
session-start script into a project.

The session-end hook, `.agents/hooks/session-end-sync.sh`, ships alongside it
but is opt-in by design rather than by oversight: a check-up cadence should not
be missed, while reconciling records at session end is a lighter prompt. Its own
header gives the per-tool wiring, and typing `/sync` by hand does the same job on
any tool.

Editing a skill's body usually produces no adapter diff, because the adapters are
pointers carrying only the frontmatter description; changing a description does.
COMPATIBILITY.md, beside this file, holds the full per-tool map.

## Maintainer validation

Every change to `.agents/skills/` or the kit's own machinery runs
`.agents/tools/validate-kit.sh`, which checks:

- the canonical skill inventory (exactly eight commands and four background
  skills, named exactly, with nothing else in the folder);
- the maintainer skill boundary: the writing skill carries its vendored licence,
  and no folder or command file named for it exists in `.agents/skills/`,
  `.claude/skills/`, `.claude/commands/`, `.cursor/commands/`,
  `.gemini/commands/`, or the release allowlist;
- frontmatter on every `SKILL.md` (name, description, folder match, no
  duplicates);
- harness contracts: every command's Codex `openai.yaml` disables implicit
  invocation, no background skill carries one, `.codex/skills` does not exist,
  and Claude's generated commands stay person-invoked while generated background
  skills carry `user-invocable: false`;
- trigger declarations: every skill says in its own file whether a person types
  it or another skill calls it; the adapter builder
  refuses to run when one does not say, the validator rehearses that refusal,
  and `.claude/commands/` and `.claude/skills/` are compared as whole listings
  against the expected names;
- that every local Markdown link and every skill, reference, or template path
  named in another file resolves;
- the fit check's structure: all four canonical build paths and their
  decision-order headings are present;
- that the plan template carries the `Subjects` column, that only the four
  canonical build-path names appear as path values, and that `team.md` is
  referenced nowhere;
- that clarify says which questions may be offered as choices and which are
  asked in plain words, with the matching maintainer scenario present;
- that `/ship` keeps its go-live and operational-readiness steps inside the
  path branches that use them, never as a shared section reachable from all
  four;
- that the generated adapters match what `.agents/skills/` produces, with no
  stale adapter folder left behind;
- shell syntax on every script, and that config files (JSON, TOML, YAML)
  parse;
- that the Claude Code deny list mirrors the mechanically enforceable entries
  in `.agents/guard/blocked-commands.md`, in this repository's own settings and
  in the settings template a project receives;
- that the project's Claude settings template carries the session-start wiring
  while this repository's own settings do not;
- that every tracked file opening with a shebang is saved as runnable, unless
  this repository only ever sources it or hands it to `sh`. It reads the mode
  git recorded rather than asking the disk, for the Windows-mount reason given
  under releases below;
- that project-facing docs carry none of the stale claims this kit has made
  before: "all markdown", "seven skills" describing the whole repository,
  "four project documents", `team.md`, a mandatory fresh session for every
  build, a universal pull-request or test-first requirement, an automatic
  rebuild treated as the fourth `/fix` attempt, an absolute claim that the
  four background skills never appear in any harness, incorrect Claude invocation
  semantics, `.codex/` described as a generated adapter, or a claim that
  everything in the kit is markdown.

CI runs the same script in this repository's own pull requests, alongside every
rehearsal in `.agents/tests/`. The released starter receives its deliberately
failing project check from
`.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml`; `setup-ai-build-kit` replaces that
placeholder with the project's real commands during stand-up.

## Scenario review

Before a release, work through `.agents/tests/scenarios.md` and confirm each
scenario still resolves to the path, evidence, and route it names. It is a
maintainer contract: nothing there is shown to someone building a project
with the kit.

`.agents/tests/replay/` does part of that walk for you. It holds a whole
conversation with an assembled release and asks a separate grader whether what
happened matches the contract, several times over, so the answer is a rate
rather than a pass. Read its table before a release. It settles nothing on its
own: a session with nobody in it is a lead rather than a verdict, and anything
it turns up should be repeated by hand before it counts as a defect. Its own
folder explains what it covers and what it cannot reach.

## What earns a shell test

The suite under `.agents/tests/` grew by artefact rather than by risk, which is
how a check ends up guarding something nobody would ever break. Answer these
before adding one.

1. What does a person lose if this breaks? If the honest answer is nothing they
   would notice, it does not belong here.
2. Can it break quietly? Something that fails loudly the first time anyone runs
   it needs no guard. These checks earn their place against silent failure.
3. Is it a boundary or a behaviour? Shell owns boundaries: what ships, what gets
   written, what gets published, what gets overwritten. How the kit behaves in a
   conversation is judged by the scenario review, not here.
4. Does an existing check already build this fixture? Then add the assertion
   there. A new file is justified by a new fixture, not by a new topic.
5. Would it still be true after a rewrite? A check pinned to particular wording
   or an internal path fails when someone tidies up and teaches nobody anything.

An assertion that cannot be made to fail is not protecting anything.
`.agents/tests/mutate.sh` breaks one promise at a time and records which checks
noticed, which is how that gets settled with evidence rather than opinion. Run
it when the suite changes shape. Anything it shows to be unbreakable comes out
at the next release, and anything it breaks without being noticed is the gap to
close first.

## The pull request check

`.github/workflows/checks.yml` is private source machinery. Its
`source-kit-validation` job regenerates the adapters and runs `validate-kit.sh`
on pull requests here. It never ships.

Its `rehearsal` job runs each script in `.agents/tests/` as a separate check, so
a failure names itself on the pull request rather than sitting in a log nobody
opens. The jobs run side by side and none of them stops the others, so one
broken rehearsal still leaves you the state of the other eight.
`validate-kit.sh` compares that folder with the list of jobs, so a rehearsal
added later cannot sit there unrun. Only `mutate.sh` is left out, and it audits
the suite rather than passing or failing.

`validate-kit.sh` calls eight of those rehearsals itself, which is what keeps it
a single local command and what gives release preparation its coverage. So the
hosted run does that work twice, and at about half a minute for the whole set
that is cheaper than either half losing it.

Do not add a switch to skip the rehearsals when the jobs run them. Every
expensive fault this repository has had came from a check that passed by never
running, and the duplication costs half a minute and fails loudly.

This job installs Claude Code and runs the Claude plugin rehearsal for real, and
runs `fake-github.sh`, neither of which the checks list alone covered. Nothing
else here reaches the network or uses a token, since the stand-in for the GitHub
command line tool covers what would otherwise need an account.

The replay harness stays out of this workflow. It holds conversations with a
large model and costs about a pound each time, so it is run by hand before a
release and its output is read rather than enforced.

The starter's root `.github/workflows/checks.yml` is copied from
`.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml`. That project check
fails on purpose, so a new project cannot receive a green tick that verified
nothing. `setup-ai-build-kit` replaces the placeholder with the project's real install and
test commands during stand-up. Keeping these workflows separate is what stops a
founded project inheriting the kit's own checks, which would fail in a place
they mean nothing.

`.github/workflows/maintainer-branch-check.yml` is the source repository's
fallback: it runs the same maintainer validation when a non-`main` branch is
published, with read-only file access and no retained checkout credential. It
is intentionally absent from `release-manifest.txt`, so starter and user
projects do not inherit this extra automation.

Every workflow gate names this repository, and `release-publication.sh` reads
the folder rather than a list, so a workflow written tomorrow has to carry one
too. After a rename or a transfer, update all of them together: a gate naming
the old name skips its job, and a skipped job reports as nothing wrong.

If the pull request that changes the identity cannot receive the old hosted
check, merge it only with the complete local validator and an independent review
recorded. Then require a green hosted result from the non-main branch fallback
on a small follow-up pull request before configuring or publishing a release.

## Keep it generic

Nothing in the released kit names a project, a company, or a person;
`/setup-ai-build-kit` is what makes it someone's. Every workflow names this
repository in a gate, so none of them runs in somebody's fork, and none of those
workflows ships.

## When a release is cut

Ask first what an existing user must do to upgrade. The kit has had real users
since v0.5, so a release is an upgrade for them as much as a first install for a
newcomer. Name anything that breaks a project already running on an earlier
version: a renamed command, a removed feature, a changed record or label, or a
new precondition. For each, there must be a path that carries an existing project
across without losing its work, and the person must be told about it in a place
they will see. A one-time migration lives in `/maintain`, which runs on its own
clock and is idempotent, and the visible change is named in the release notes.
If a breaking change has neither, it is not ready to ship. A release that only
adds behaviour still gets this check, and answers it with "nothing to do".

Run PHILOSOPHY.md's five questions over everything already here, including what
is being added. Anything that now fails a question it used to pass has drifted
(PHILOSOPHY.md explains how), and that is the list of work for the next pass.

Check `docs/SOURCES.md` in the same sweep. A borrowed idea that arrived since
the last release belongs there, and a credit for something the kit no longer
does comes out.

Then build the released kit into a new temporary folder with
`.agents/tools/build-release.sh <version> <folder>`. The allowlist in
`release-manifest.txt` is the boundary: only its paths ship. Run
`.agents/tests/release-builder.sh`, `.agents/tests/starter-rehearsal.sh`, and
the full source validator. The release check proves the boundary and the
rehearsal proves that installed skills can prepare a clean, independently saved
project with its founding record templates in place. It does not replace a
person's guided `setup-ai-build-kit` check of the interview itself.

The release builder also writes the version without its leading `v` into the
Claude plugin manifest. Validate the assembled folder with
`claude plugin validate <folder> --strict`, then rehearse the plugin from an
isolated `CLAUDE_CONFIG_DIR`. The rehearsal must cover marketplace discovery,
the manual command boundary, local project installation, bootstrap, a failed
marketplace refresh, a successful update, and removal. It must not change the
maintainer's real Claude configuration.

Run `.agents/tests/agent-plugin.sh` too. It builds a release and checks the
assembled `agent-plugin` folder against the open standard: the manifest's
permitted fields, the twelve skills as immediate children of `skills`, no
skill hidden deeper, no maintainer-only writing skill, and a project
stand-up from that folder alone.

Run `.agents/tests/release-publication.sh` as well. It rehearses preparing a
draft against a stand-in for GitHub: a draft that does not exist yet, one naming
a different version, a Release already published, and a repeat that must leave
one archive rather than two. It then proves what no longer exists. No workflow
or tool may run a push, no file may be named for the deleted starter publisher,
no workflow may mint a credential beyond the run's own token, and only the two
workflows that edit a Release may write at all. Every job in the folder is
checked for its repository gate, per job rather than per file, because a
file-wide check is satisfied by one gated job while a second runs beside it
ungated.

Approved folders contribute only files already tracked here, so an unexpected
local file cannot enter a release.

Each merge into `main` updates one draft Release. Closing a pull request without
merging it changes nothing. The draft collects the pull request titles since the
last published version and suggests the next version. Features and enhancements
suggest a minor version; other changes suggest a patch. The `release-major`,
`release-minor`, and `release-patch` labels make the intended version visible,
with the highest matching increase winning. If labels change after a merge, run
`update release draft` from the Actions page to refresh the suggestion.
The draft workflow and its configuration are maintainer machinery and do not
ship in the released kit.

Online release still has two deliberate stages, and one thing has to happen
before either of them. Three files carry the version an installation reports:
the two plugin manifests and `maintain`'s `VERSION` marker. Both installers read
this branch, so the branch has to say which version it is. Run
`.agents/tools/stamp-version.sh vX.Y.Z` on a branch, open the pull request, let
the checks run, and merge it. Then merge nothing else until the release is
published, or the version covers work the notes do not mention.

When the draft is ready, start `prepare release` with the version shown on it,
such as `v0.1.0`. The workflow rejects a version whose tag already exists,
validates `main`, confirms `main` carries that version, assembles the starter,
and attaches the checked archive to that draft. If the Release Drafter
draft is missing, preparation stops and tells the maintainer to refresh it.
GitHub's native generated notes are not used because their pull request format
cannot omit private numbers. Check the version, archive, and notes before
publishing. If another pull request merges after preparation, run
`prepare release` again so the archive matches the latest draft.

`.github/release-drafter.yml` groups labelled work and keeps unlabelled work in
`Other changes`, so an absent label cannot silently remove a change. A pull
request title may become a line in the public notes, which makes the title
human-facing prose. Public notes omit the private pull request number. Review
the draft before publishing. Remove internal noise, correct any misleading
summary, and state any action an existing user must take. Use
`skip-release-notes` only when a merged pull request has no useful place in the
project's public history.

Publishing the draft is the release. There is nothing to copy anywhere and no
credential to mint, because the repository the version is prepared in is the
repository people install from.

`verify release` then rebuilds the published version from its own tag and
compares it with the archive that was reviewed before publication. It cannot
un-publish anything, and it is not meant to. What it catches is a draft
retargeted by hand, or a pull request that merged between preparation and
publication, either of which would leave the tag and the reviewed archive
describing different things. It accepts only a tag contained in reviewed `main`.

A publisher that took an assembled release and made it the exact tree of a
second repository used to run here, along with a GitHub App and its two Actions
settings. All of it existed because a workflow token cannot write to another
repository. There is no other repository, and that same code aimed at this one
would replace the source with a packaged release, so it was deleted rather than
pointed somewhere safer. The rehearsal now proves its absence: no workflow or
tool may run a push, and only the two workflows that edit a Release may write
at all.

A fix to a release workflow cannot rescue the release being published. A
`release` event runs the workflow from the tagged commit, not from current
`main`, so a repair sitting on `main` takes effect only for the next version.

Building a release locally on a Windows mount records the wrong file modes,
because every file on that mount reports as runnable. The same mount also hides
a script saved without its runnable bit, which is why `validate-kit.sh` reads
the mode git recorded for every script the kit runs by path rather than asking
the disk.

Preparation is safe to repeat. It refuses to create a draft where Release
Drafter has not left one, refuses when a draft names a different version,
refuses to touch a Release that is already published, and removes the archive it
replaces rather than leaving two attached. Running it twice for the same version
leaves one archive, not two.

Between releases this branch carries the last published version while its
contents move ahead of it, so somebody installing mid-cycle gets skills a little
ahead of the label they wear and `/maintain` tells them they are up to date.
That gap cannot be closed while the branch is where the work happens, and it is
a much smaller untruth than a version that never resolves. Keep it small by
cutting a release soon after a meaningful merge.

The bridge for projects installed before the shared installer is retired. Only
v0.1.0 and v0.1.1 shipped a `/maintain` that could reach it, v0.1.0 was never
tagged publicly, and the kit's own record says real users arrived at v0.5. A
project older than that reinstalls with `npx skills add gwpicard/ai-build-kit`
once and then updates like any other. Every installation now records where its
skills came from and updates through that route, and project records, AGENTS.md,
README.md, environment files, application code, and the project's own check stay
project-owned either way.

Preview builds can be assembled locally, but only stable numbered releases
update the public repository.

## House rules for writing

Anything written into this repository, by a person or an agent, follows these.
They exist because the audience cannot read code, so the words are the product.
A short form of the list ships in `AGENTS.md`'s project template, so a project
built with the kit inherits the plain-language spirit of it without carrying the
full editorial machinery. This is the full version, and it governs the kit's own
documents.

Before saving human-facing prose, load
`.agents/maintainer-skills/humanizer/SKILL.md` and run its embedded mode. This
covers documentation, skills, pull request titles and descriptions, issues,
release notes, interface copy, error messages, and reader-facing comments. The local
skill is the shared instruction for every supported harness; the rules below
remain the kit's own stricter house style.

Preserve the information and intended voice rather than the draft's sentence
shape. Never invent facts, names, figures, dates, quotations, or citations.
Leave code blocks, frontmatter, data, commands, and link targets untouched.
After the first edit, ask what still sounds generated and revise once more.
Technical and reference writing should stay neutral and plain; personality
belongs only where the subject and author's voice call for it.

- British spelling. No em dashes: a comma, colon, semicolon, or full stop is
  always available and always clearer.
- Plain words over jargon. When a technical term is unavoidable, define it once
  in the sentence that introduces it and then use it plainly.
- Banned: leverage, robust, comprehensive, seamless, crucial, foster, enhance,
  transformative, delve, navigate as a metaphor, empower, streamline, holistic.
- No contrastive reframes ("it's not X, it's Y"), no rhetorical triplets, no
  bulleted lists where each item opens with a bold header.
- Explain a concept where it lives, and link from everywhere else.
- One name per thing. This is a kit, and calling it a pack somewhere else only
  makes a reader wonder whether the two are different.
- Paragraphs stay under about 100 words. Four here had passed 140 before the
  rule existed, and the audience is people who do not read code.
- Vary the sentence shape. Almost every explanation wants to arrive as
  "statement: a, b, and c", and a document leaning on one device reads as a
  template however clear each instance is.
- Two house aphorisms earn their keep and were both badly overused: "X is how
  something good goes wrong", and "X, never Y". Two of each per document.

## One owner per concept

This repository grew heavy through duplication, so every concept has exactly one
home and every other mention is a link.

- Root `README.md`: what the kit is, installation, and positioning for someone
  deciding whether to use it. It ships as the public README unchanged, so it is
  written for that reader rather than for a maintainer. The eight-command table
  there is a summary; what each command actually does belongs to WORKFLOW.
  Orientation for someone working on the source belongs in root `AGENTS.md`.
- `WORKFLOW.md`: everything operational. How work runs, day to day, for someone
  already using it. Operational detail belongs here and nowhere else, including
  the parts of setup that come after the README's quick start.
- Root `AGENTS.md`: standing rules for maintaining the source.
  `.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md`: standing rules for the
  agent working on a user project, plus the capability profile filled in by
  `setup-ai-build-kit`.
- `docs/PHILOSOPHY.md`: why the kit is shaped as it is, who it is for, and the
  test any addition has to pass. Read before changing what a skill does.
- `docs/COMPATIBILITY.md`: the portable core contract and per-tool detail.
  `docs/MAINTAINING.md`: this file.
- `docs/SOURCES.md`: the outside work the kit took ideas from, and what each
  source contributed. It names a borrowed idea in the kit's own vocabulary and
  links to that idea's owner rather than explaining it again.

Two concepts carry two names on purpose, on the same reasoning both times: the
name a person reads is the one that matters, and an internal name is left alone
where changing it would churn output nobody reads for no reader benefit.

A person reads "background skills"; the code identifiers and check messages say
"disciplines". They are the same four skills.

A person reads that the agent chooses the method; `.agents/tests/scenarios.md`
and `.agents/tests/replay/grader-prompt.md` call that field "hidden technique".
It is a graded field, and the grader prompt was last changed in August after a
run that measured its variance, so renaming it again would make the recorded
results harder to compare against the next ones. Rename it when a measurement is
not the thing standing behind it.

Nothing should say the old "words" name for the commands now, in prose or in an
identifier.

Before adding an explanation, check whether its owner already carries it. If it
does, link. If two documents disagree, the owner wins and the other is edited.
