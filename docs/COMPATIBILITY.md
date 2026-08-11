# COMPATIBILITY.md: one kit across coding agents

## The portable core

AI Build Kit works when the coding agent can read and edit project files, run
shell commands, and use Git. Native skill pickers, slash commands, hooks,
subagents, and command deny lists can improve the experience, but the workflow
does not depend on them.

The eleven skills use the open Agent Skills folder format. Each skill keeps its
own instructions and supporting files together. A command that needs a
background skill loads it by name.

## Choose one installation route

A Claude-only project can use the public repository as a Claude Code plugin.
From the project folder, run:

```bash
claude plugin marketplace add gwpicard/ai-build-kit
claude plugin install ai-build-kit@ai-build-kit --scope local
```

The plugin uses local project scope, so it does not replace the project's
shared Claude settings. It exposes the seven commands and the four
background skills. The commands use the `ai-build-kit:` prefix, so start with
`/ai-build-kit:start`.

Use the shared skills installer when the project uses Codex, Cursor, Gemini
CLI, another coding agent, or more than one agent. From the project folder,
run:

```bash
npx skills add gwpicard/ai-build-kit
```

The shared [skills installer](https://github.com/vercel-labs/skills) detects
installed coding agents and asks where the project skills should appear. It
keeps one project-level copy and uses the selected harness locations for
discovery. The same command can install the kit for several harnesses used on
one project.

A coding agent that installs plugins in the open
[Agent Plugins](https://agent-plugins.org) format can use the `agent-plugin`
folder of the public repository. Point that agent's own plugin installer at
the folder. It holds a `plugin.json` manifest and a `skills` folder with the
same eleven skills, each carrying its own supporting files. This is the newest
route, and a client may skip a skill it judges non-standard, so prefer the
shared installer when the project has a choice.

Install all eleven AI Build Kit skills. Seven are commands you type:
`start`, `build`, `fix`, `ship`, `sync`, `maintain`, and `what-now`. Four run in
the background when a command needs them: `grilling`, `change-triage`,
`section-builder`, and `second-opinion`.

After installation, run `start`. That skill prepares missing project
foundation files before the interview. It preserves existing files, so every
route works for a blank folder and for a project that already has code.

Use one route per project. Do not run two AI Build Kit installations in the
same project. If the project later needs another coding agent, install the
shared skills, confirm they work, then remove the other installation.

## Update the installed skills

During `maintain`, the agent reads the latest public Release notes and asks
before changing the kit. It first identifies the installation route.

For the Claude plugin, the approved update is:

```bash
claude plugin marketplace update ai-build-kit
claude plugin update ai-build-kit@ai-build-kit --scope local
```

Claude loads the new plugin after `/reload-plugins` or the next session.
If the marketplace cannot be reached, the installed version remains enabled.
`maintain` reports that no update happened and tries again later.

The shared installer records project skill sources in `skills-lock.json`. Its
approved update is limited to the eleven AI Build Kit skill names:

```bash
npx skills update start build fix ship sync maintain what-now grilling change-triage section-builder second-opinion -p
```

The `-p` flag limits the update to this project.

An Agent Plugins installation belongs to the coding agent that installed it,
so use that agent's own plugin update command. When the agent has none,
download the latest public Release and replace the installed `agent-plugin`
folder, after a clean checkpoint and explicit approval.

Every route leaves application code, `AGENTS.md`, `README.md`, the three
project records, environment files, and the project check under the project's
control.

Projects created before this installation model may not have
`skills-lock.json`. Their existing archive updater can move them to the bridge
release. On the next `maintain` visit, `npx skills add gwpicard/ai-build-kit`
registers the installed skills. Later updates use the normal command above.

## Harness map

The shared installer owns the exact placement and symlinks. Its current project
paths are:

| Harness | Project skill location | Standing instructions |
|---|---|---|
| Claude Code, shared installer | `.claude/skills/` | `CLAUDE.md` points to `AGENTS.md` |
| Claude Code, plugin | Claude's plugin cache | the seven commands use the `ai-build-kit:` prefix; the four background skills stay out of the menu |
| Codex | `.agents/skills/` | reads `AGENTS.md` |
| Cursor | `.agents/skills/` | reads `AGENTS.md` |
| Gemini CLI | `.agents/skills/` | `GEMINI.md` points to `AGENTS.md` |
| GitHub Copilot | `.agents/skills/` | `.github/copilot-instructions.md` points to `AGENTS.md` |

Another coding agent may work through the same portable files.

The start skill creates missing standing-instruction pointers. It does not
replace an existing harness configuration.

Use the harness's skill picker or ask for a skill by name. When native
discovery is unavailable, open `.agents/skills/<name>/SKILL.md` directly and
follow it.

## Who may start a command

You type the seven commands yourself. Four more skills run in the background
when a command needs them, and you never call those directly. The kit tells your
coding agent not to start a command on its own. Not every tool enforces that, so
if one offers to run a command you did not ask for, say no.

## Manual fallback

If the computer cannot run `npx`, download the latest public Release and copy
its `.agents/skills` directory into the project's `.agents/skills` directory.
Then ask the agent:

> Open `.agents/skills/start/SKILL.md` and run the start skill.

A later manual update replaces only the eleven AI Build Kit skill folders,
after a clean checkpoint and explicit approval.

## Optional harness features

| Capability | Portable behaviour | Optional enhancement |
|---|---|---|
| Command invocation | Ask for a skill by name | Native skill picker or slash command |
| Background skills | Command loads the named skill | Automatic skill triggering |
| Independent review | A clean separate chat with a prepared instruction | Subagent or separate automated session |
| Sync | Run `sync` when needed | Session-end reminder |
| Check-up due | `what-now` says when a visit is overdue | Said automatically when a session opens |
| Safety | Standing restrictions and approval gates | Mechanical command deny list |
| Long runs | Normal sequential work | Native goal or orchestration mode |

During `start`, the capability check records which enhancements the current
harness provides and selects a fallback for anything absent. Missing optional
automation reduces convenience rather than changing the workflow's rules.

`start` writes the session-start wiring only into a Claude settings file it
creates itself, and never into one that already exists. A project whose Claude
settings predate AI Build Kit keeps them exactly as they are, and its check-up
reminder arrives through `what-now`.
