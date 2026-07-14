# COMPATIBILITY.md: which tool lights up what

This kit runs the same seven words and four disciplines in any agent tool. It
does that two ways at once:

- **The standard.** `AGENTS.md` is the open instruction file that Claude Code,
  Cursor, Codex, Gemini CLI, Copilot, Aider, Windsurf, Zed and others read. It
  carries a load rule: type `/word` (or the older `$word`, or just ask for a
  skill by name) and the agent opens `.agents/skills/<word>/SKILL.md` and follows
  it. This alone makes the kit work anywhere that reads `AGENTS.md`.
- **Native adapters.** For the four tools below, thin generated files make the
  words show up as real slash commands and the disciplines trigger on their own.

The one source of truth is `.agents/skills/`. Everything else is generated from
it by `.agents/tools/build-adapters.sh`.

## The map

| Tool | Seven words | Four disciplines | Standing rules | Session-end sync | Blocked commands |
|---|---|---|---|---|---|
| **Claude Code** | `.claude/commands/<w>.md` → `/start` … (slash) | `.claude/skills/<d>/SKILL.md` (auto-trigger) | `CLAUDE.md` → `AGENTS.md` | `.claude/settings.json` `SessionEnd` hook | `.claude/settings.json` `permissions.deny` |
| **Cursor** | `.cursor/commands/<w>.md` → `/start` … (slash) | via `AGENTS.md` load rule (also loads Claude skills) | `AGENTS.md` (native) | add the hook in Cursor's hook settings | mirror the patterns in Cursor's settings |
| **Gemini CLI** | `.gemini/commands/<w>.toml` → `/start` … (slash) | via `AGENTS.md` load rule | `GEMINI.md` → `AGENTS.md` | wire the hook in Gemini's config | document / configure per Gemini |
| **OpenAI Codex** | `.codex/skills/<w>/SKILL.md` (run by name; see caveat) | `.codex/skills/<d>/SKILL.md` | `AGENTS.md` (native) | `/sync` by hand, or a shell wrapper | `~/.codex/config.toml` sandbox / approval |

`<w>` = a word (start, build, fix, ship, sync, maintain, what-now).
`<d>` = a discipline (grilling, change-triage, section-builder, second-opinion).

## What "native" means per tool

**Claude Code.** The strongest fit. The seven words are slash commands in
`.claude/commands/` (they must be *commands*, not skills: a skill marked
`disable-model-invocation: true` can't be launched by slash either, so the two
kinds are split deliberately). The four disciplines are auto-triggering skills in
`.claude/skills/`. `.claude/settings.json` wires the session-end sync hook and
mirrors the blocked-command deny list.

**Cursor.** Reads `AGENTS.md` natively and picks up `/start …` from
`.cursor/commands/`. Cursor can also load Claude's skills, so the disciplines are
available; failing that, the `AGENTS.md` load rule reaches them by path.

**Gemini CLI.** Reads its pointer `GEMINI.md` (→ `AGENTS.md`) and picks up
`/start …` from `.gemini/commands/*.toml`. Disciplines come through the load rule.

**OpenAI Codex.** Reads `AGENTS.md` at the repo root natively. All eleven skills
ship as project skills in `.codex/skills/`. **Caveat:** Codex has no
*project-level* slash commands (only user-level `~/.codex/prompts/`), so `/start`
is not a project slash command there. Instead you ask for the word by name and
Codex runs the matching skill, guided by the `AGENTS.md` load rule. If you want
literal `/start` in Codex, copy the seven command bodies into
`~/.codex/prompts/` on your machine (optional, per-user, not committed).

## Adding, changing, or removing a skill

1. Edit (or add/remove) the canonical folder under `.agents/skills/<name>/`.
2. Run `.agents/tools/build-adapters.sh`.
3. Commit the canonical change together with the regenerated adapter folders.

Never hand-edit anything under `.claude/`, `.cursor/`, `.gemini/`, or `.codex/`
— those files carry a GENERATED banner and are overwritten on every run. The one
hand-maintained file in those trees is `.claude/settings.json`; keep its
`permissions.deny` in step with `.agents/guard/blocked-commands.md`.

## Anything else

Any tool that reads `AGENTS.md` works with no adapter at all: the load rule in
that file is enough to resolve `/word`, `$word`, or a plain "run the build skill"
to the right `SKILL.md`. The kit takes no position on which tool you use.
