# Changelog

Plain-language history of the project, newest first. One dated entry per piece of work, written so a teammate who was away can catch up by reading it.

## 2026-07-14

- Made the kit usable across the common agent tools. `.agents/skills/` stays the
  single source of truth; a new `.agents/tools/build-adapters.sh` generates thin
  per-tool adapters so the seven words become native slash commands and the four
  disciplines auto-trigger: `.claude/` (commands + skills + settings.json), `.cursor/`
  (commands), `.gemini/` (TOML commands), `.codex/` (skills). Added an `AGENTS.md`
  skills index and load rule so any AGENTS.md-reading tool resolves `/word`, a
  `GEMINI.md` pointer, and `COMPATIBILITY.md` mapping each tool. Switched the docs to
  `/word` as the primary invocation. Wired the session-end sync hook and blocked-command
  deny list into `.claude/settings.json`.

<!-- Example entry:

## 2026-07-14

- Built: the board shows one column per project. Checked in the browser.
-->
