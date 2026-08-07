# COMPATIBILITY.md: one kit across coding agents

## The portable core

AI Build Kit works when the coding agent can read and edit project files, run
shell commands, and use Git. Native skill pickers, slash commands, hooks,
subagents, and command deny lists can improve the experience, but the workflow
does not depend on them.

The eleven skills use the open Agent Skills folder format. Each skill keeps its
own instructions and supporting files together. A command that needs an
internal discipline loads that discipline by name.

## Choose one installation route

A Claude-only project can use the public repository as a Claude Code plugin.
From the project folder, run:

```bash
claude plugin marketplace add gwpicard/ai-build-kit
claude plugin install ai-build-kit@ai-build-kit --scope local
```

The marketplace is available to the current user. The plugin itself uses
local project scope, recorded in `.claude/settings.local.json`, so it does not
replace the project's shared Claude settings. The plugin exposes seven manual
commands and four internal disciplines. Each thin Claude adapter loads its
canonical skill from the plugin cache. The commands use the `ai-build-kit:`
prefix, so start with `/ai-build-kit:start`.

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

Install all eleven AI Build Kit skills. Seven are words the person invokes:
`start`, `build`, `fix`, `ship`, `sync`, `maintain`, and `what-now`. Four are
disciplines those words compose: `grilling`, `change-triage`,
`section-builder`, and `second-opinion`.

After installation, run `start`. That skill prepares missing project
foundation files before the interview. It preserves existing files, so either
route works for a blank folder and for a project that already has code.

Do not install the Claude plugin and the shared skills in the same project.
If the project later needs another coding agent, install the shared skills,
confirm they work, then remove the Claude plugin from that project.

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

The `-p` flag limits the update to this project. Both routes leave application
code, `AGENTS.md`, `README.md`, the three project records, environment files,
and the project check under the project's control.

Projects created before this installation model may not have
`skills-lock.json`. Their existing archive updater can move them to the bridge
release. On the next `maintain` visit, `npx skills add gwpicard/ai-build-kit`
registers the installed skills. Later updates use the normal command above.

## Harness map

The shared installer owns the exact placement and symlinks. Its current project
paths for the main supported harnesses are:

| Harness | Project skill location | Standing instructions |
|---|---|---|
| Claude Code, shared installer | `.claude/skills/` | `CLAUDE.md` points to `AGENTS.md` |
| Claude Code, plugin | Claude's plugin cache | seven manual commands use the `ai-build-kit:` prefix; four hidden disciplines may run when needed |
| Codex | `.agents/skills/` | reads `AGENTS.md` |
| Cursor | `.agents/skills/` | reads `AGENTS.md` |
| Gemini CLI | `.agents/skills/` | `GEMINI.md` points to `AGENTS.md` |
| GitHub Copilot | `.agents/skills/` | `.github/copilot-instructions.md` points to `AGENTS.md` |
| Other supported agents | chosen by the installer | `AGENTS.md` supplies the portable fallback |

The start skill creates missing standing-instruction pointers. It does not
replace an existing harness configuration.

Use the harness's skill picker or ask for a skill by name. When native
discovery is unavailable, open `.agents/skills/<name>/SKILL.md` directly and
follow it.

## Manual fallback

If the computer cannot run `npx`, download the latest public Release and copy
its `.agents/skills` directory into the project's `.agents/skills` directory.
Then ask the agent:

> Open `.agents/skills/start/SKILL.md` and run the start skill.

This fallback supplies the complete portable core because each skill carries
its own supporting files. A later manual update replaces only the eleven AI
Build Kit skill folders after a clean checkpoint and explicit approval.

## Optional harness features

| Capability | Portable behaviour | Optional enhancement |
|---|---|---|
| Command invocation | Ask for a skill by name | Native skill picker or slash command |
| Internal disciplines | Command loads the named skill | Automatic skill triggering |
| Independent review | A clean separate chat with a prepared instruction | Subagent or separate automated session |
| Sync | Run `sync` when needed | Session-end reminder |
| Safety | Standing restrictions and approval gates | Mechanical command deny list |
| Long runs | Normal sequential work | Native goal or orchestration mode |

During `start`, the capability check records which enhancements the current
harness provides and selects a fallback for anything absent. Missing optional
automation reduces convenience rather than changing the workflow's rules.
