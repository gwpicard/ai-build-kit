# COMPATIBILITY.md: portable core and optional enhancements

## The portable core

The kit works when the agent can:

1. read AGENTS.md and repository files;
2. edit files;
3. run shell commands;
4. use Git;
5. report results in plain language.

Native slash commands, auto-triggered skills, hooks, subagents, background
agents, and mechanical deny lists improve the experience but are not required
for the workflow to function.

`AGENTS.md` is the open instruction file that Claude Code, Cursor, Codex, Gemini
CLI, Copilot, Aider, Windsurf, Zed and others read. It carries a load rule: type
`/word` (or the older `$word`, or just ask for a skill by name) and the agent
opens `.agents/skills/<word>/SKILL.md` and follows it. That alone makes the kit
work anywhere that reads `AGENTS.md`.

On top of that sit the native adapters. For the four tools below, thin generated
files make the words show up as real slash commands and the disciplines trigger
on their own.

The one source of truth is `.agents/skills/`. Everything else is generated from
it by `.agents/tools/build-adapters.sh`.

## Updating the portable core

Updates use the repository files rather than any one tool's extension system.
Every stable starter records its kit-owned paths in `.ai-build-kit-managed`.
During `/maintain`, `.agents/tools/update-kit.sh` compares the official current
and new releases against the project, updates or cleanly merges only those
paths, then regenerates the Claude Code, Cursor, and Gemini adapters. Codex and
any other harness continue to read the same canonical `.agents/skills/` source.

Project-owned files are outside that record. An update does not replace
AGENTS.md, README.md, the three project records, application code, environment
files, or the project's check. If a project and a release changed the same kit
instruction incompatibly, the updater stops before changing the project.

## What "works out of the box" means

A fresh clone works without generating adapters, because `AGENTS.md` points at
the canonical skills. Known adapters add native discovery and command surfaces
on top of that; they are not what makes the workflow function.

## Capability tiers

| Capability | Core behaviour | Enhanced behaviour |
|---|---|---|
| Command invocation | Ask for a skill by name | Native slash command |
| Hidden disciplines | Command loads canonical file | Tool auto-triggers discipline |
| Independent review | User opens a clean chat with supplied instruction | Subagent or separate automated session |
| Sync | Normal skill completion and manual `/sync` | Optional session-end reminder or report |
| Safety | Standing instructions and approval gates | Mechanical command deny list |
| Long runs | Normal sequential agent work | Native goal mode or orchestration |
| Manual setup | Conversational steps | Optional generated wizard |

## The map

| Tool | Core contract met? | Seven words | Four disciplines | Standing rules | Session-end sync | Blocked commands |
|---|---|---|---|---|---|---|
| **Claude Code** | Yes | `.claude/commands/<w>.md` → `/start` … (slash) | `.claude/skills/<d>/SKILL.md` (auto-trigger) | `CLAUDE.md` → `AGENTS.md` | optional: add a `SessionEnd` hook to `.claude/settings.json` | `.claude/settings.json` `permissions.deny` |
| **Cursor** | Yes | `.cursor/commands/<w>.md` → `/start` … (slash) | via `AGENTS.md` load rule | `AGENTS.md` (native) | add the hook in Cursor's hook settings | mirror the patterns in Cursor's settings |
| **Gemini CLI** | Yes | `.gemini/commands/<w>.toml` → `/start` … (slash) | via `AGENTS.md` load rule | `GEMINI.md` → `AGENTS.md` | wire the hook in Gemini's config | document / configure per Gemini |
| **OpenAI Codex** | Yes | `.agents/skills/<w>/SKILL.md` (run by name; `agents/openai.yaml` disables implicit invocation) | `.agents/skills/<d>/SKILL.md` | `AGENTS.md` (native) | `/sync` by hand, or a shell wrapper | `~/.codex/config.toml` sandbox / approval |
| **Any other harness that reads AGENTS.md** | Yes | Ask for the word by name | Ask for the discipline by name, or let the word's `SKILL.md` load it | `AGENTS.md` | manual `/sync` | standing instructions in `AGENTS.md` and `.agents/guard/blocked-commands.md` |

`<w>` = a word (start, build, fix, ship, sync, maintain, what-now).
`<d>` = a discipline (grilling, change-triage, section-builder, second-opinion).

Every row meets the portable core; the columns after it are enhancements a
tool adds on top, not requirements the workflow depends on.

## What "native" means per tool

### Claude Code

The strongest fit. The seven words are slash commands in `.claude/commands/`,
always launched directly by a human. `disable-model-invocation: true` on the
canonical skill is what marks something as one of the seven in the first
place: it prevents Claude from starting a human command automatically, so
build-adapters.sh generates it as a command rather than a skill. The four
disciplines are auto-triggering skills in `.claude/skills/`, each carrying
`user-invocable: false`, which hides an internal discipline from the human
command menu while leaving it available for the agent to trigger
automatically when a command composes it; the seven commands are the only
ones a human controls directly.

`.claude/settings.json` mirrors the blocked-command deny list, and can
optionally wire a report-only session-end reminder from
`.agents/hooks/session-end-sync.sh`. Claude Code also reads `.worktreeinclude`,
a list of files to carry into a separate working copy of the project; `/start`
adds the confidential-files folder to it when a project has one. No other tool
here keeps such a list, so that step is skipped elsewhere.

### Cursor

Reads `AGENTS.md` natively and picks up `/start …` from `.cursor/commands/`.
Whether Cursor also loads Claude's skill folders is unverified and may change
with Cursor's own conventions; the guaranteed route to the four disciplines is
the `AGENTS.md` load rule, which reaches them by path regardless.

### Gemini CLI

Reads its pointer `GEMINI.md` (→ `AGENTS.md`) and picks up `/start …` from
`.gemini/commands/*.toml`. Disciplines come through the load rule.

### OpenAI Codex

Codex reads `AGENTS.md` and discovers the canonical project skills directly
under `.agents/skills/`.

The seven commands carry `agents/openai.yaml` with implicit invocation
disabled, so Codex runs them only when the user asks for them. The four hidden
disciplines remain available for composition by those commands.

Ask for `start`, `build`, `fix`, `ship`, `sync`, `maintain`, or `what-now` by
name, or select the matching skill in the Codex interface available to you.

## Adding, changing, or removing a skill

1. Edit (or add/remove) the canonical folder under `.agents/skills/<name>/`.
2. Run `.agents/tools/build-adapters.sh`.
3. Commit the canonical change together with the regenerated adapter folders.

Never hand-edit anything under `.claude/`, `.cursor/`, or `.gemini/`; those
files carry a GENERATED banner and are overwritten on every run. The one
hand-maintained file in those trees is `.claude/settings.json`; keep its
`permissions.deny` in step with `.agents/guard/blocked-commands.md`. Codex has
no generated tree at all: it reads `.agents/skills/` directly, and
`.codex/skills/` does not exist.

## Any other harness

Open the repository and say:

> Read AGENTS.md, then run the start skill from
> .agents/skills/start/SKILL.md.

During start, the capability check records what the harness can do and selects
safe fallbacks. A missing optional capability must reduce automation, not break
the workflow. The kit takes no position on which tool you use.
