# AGENTS.md

Standing instructions for maintaining AI Build Kit itself. A project built with
the kit gets different instructions, from
`.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md`.

## What this repository is

The maintainer source. It holds the canonical skills, the checks, and the
machinery that assembles the public kit. It is never a project built with the
kit, so never run `/setup-ai-build-kit` here. `masterplan.md` and
`CHANGELOG.md` do not exist here by design.

Before any work, read `docs/PHILOSOPHY.md`, then the parts of
`docs/MAINTAINING.md` the work touches. Check the branch and any unsaved work
before editing.

## Where things live

- `.agents/skills/`: the six commands and the background skills. The single
  source of truth. Nothing else belongs in it.
- `.agents/agents/`: the agents, each a thin brief that names the background
  skills it loads. `.agents/tools/kit-inventory.txt` lists every skill and
  agent with its kind.
- `.agents/maintainer-skills/`: skills only maintainers use. They sit outside
  `.agents/skills/` and `.claude/skills/` so no installer offers them, and they
  get no adapter. Load one by its path: `writing-review/SKILL.md` for writing,
  `review-issues/SKILL.md` to choose the next piece of work,
  `stack-research/SKILL.md` to check the recipes against their products,
  `review-public-docs/SKILL.md` before a release, `release-notes/SKILL.md`
  to write a release's notes, and `housekeeping/SKILL.md` to clear what
  maintainer work left on this computer. The stack-research note goes to
  `.agents/tmp/stack-research/`, which git ignores, so it never ships.
- `.claude/`, `.cursor/`, `.gemini/`, `.codex/agents/`, `.github/agents/`:
  generated adapters. Change the canonical skill or agent, then run
  `.agents/tools/build-adapters.sh`, and commit both together.
- `.claude-plugin/` and `agent-plugin/plugin.json`: plugin metadata. The
  release assembles the plugin folders, so this repository keeps one copy of
  each skill.
- `release-manifest.txt`: the full allowlist for the public kit. A file not on
  it does not ship.
- `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `.github/ISSUE_TEMPLATE/`:
  public, and ship as they are.
- `.claude/settings.json` here is the maintainer's own. A project's copy comes
  from `templates/foundation/claude-settings.json`.

## How changes are made

One agreed, visible slice at a time, on a short-lived branch, through a pull
request a person decides to merge. A pull request targets `main`, never
`stable`.

A sentence in a skill earns its place only if a machine enforces it, a replay
shows it changes the outcome, or it carries a judgement. PHILOSOPHY.md says how
to decide. A change to a canonical skill also regenerates the adapters, runs the
validator, and records any borrowed idea in `docs/SOURCES.md`.

A maintainer skill does not have to clear that bar. It still follows the writing
rules and must pass the validator, which keeps it out of a release.

When a written instruction and a check disagree, trust the check, and say
plainly that the two disagree.

## Checks

- `.agents/tools/validate-kit.sh` checks the source, the adapters and the
  release boundaries.
- `.agents/tests/run-all.sh` runs every check in `.agents/tests/` and names
  each one that failed. Each check states on its second line what it guards.
- `.agents/tests/replay/` holds conversations replayed against the kit and
  graded on behaviour. Its README says how to run them and what they cost.
- `.agents/tests/seeded/` holds small products that each carry one planted
  fault. It runs the kit on them and counts what the kit catches. Its README
  says how to run it, and why the fault keys stay out of sight.
- `.agents/tests/mutate.sh` breaks one promise at a time and reports which
  checks noticed.
- `.agents/tools/rehearse-merged-tree.sh` runs the validator and the suite on
  a clean copy of the branch. Run it before pushing the branch.
- `.agents/tools/build-release.sh <version> <new-folder>` assembles a public
  release outside this repository.

A test checks an outcome, never a sentence. Shell checks own boundaries and
scripts; replays own behaviour.

## Referring to work

Issue and pull request numbers belong in issues, pull requests and a changelog,
never in a tracked file. Once the material is public, a number points at an
unrelated issue. Write the reason instead. `validate-kit.sh` fails on a number
in a tracked file.

## Attribution

A commit and a pull request carry the name of the person who made them and
nothing else: no co-author trailer naming a model, and no link to the session
the work came from. A session link is a personal address that opens for anyone,
and taking one out of public history means rewriting it.

Each coding agent's setting stops the lines being written. `.githooks/commit-msg`
removes them anyway, and `validate-kit.sh` refuses a tracked file that carries
one. A fresh clone runs one command before its first commit to turn the hook
on; `docs/MAINTAINING.md` gives it.

Prose about Claude, Cursor or Gemini is fine. Only the attribution line goes.

## Secrets and external changes

Keys, passwords and tokens never go in a tracked file, and are never printed.
Publishing a release, renaming a repository, or changing online access needs
the person's explicit approval at that step.

Before a technical confirmation box appears, say what the person will notice,
why it is needed now, whether anything leaves this computer, and what remains
unconfirmed if they decline.

Never discard, overwrite or delete unsaved work to make a check pass. Ask before
anything irreversible, or anything that changes data, access, money, automatic
actions or an online service. The commands in
`.agents/guard/blocked-commands.md` are off limits. Save a checkpoint before
sweeping changes.

## Writing

British spelling, no em dashes, short paragraphs. Write precisely and naturally,
never in forced simple words. Public documents use plain, adult prose for people
who do not read code; maintainer documents may be technical. Define a technical
term once where a public reader would not know it, and use established
terminology where it suits the reader. The writing framework replaces any
Simplified Technical English instruction for this repository.

Before saving prose, load `.agents/maintainer-skills/writing-review/SKILL.md` and
use its embedded mode. Follow the house rules in `docs/MAINTAINING.md`.
