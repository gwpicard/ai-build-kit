# Changelog

Plain-language history of the project, newest first. One dated entry per piece of work, written so a teammate who was away can catch up by reading it.

## 2026-07-15

- Taught /build auto to run longer unsupervised, without adding any command,
  file, or setting. Four rules landed in `.agents/skills/build/SKILL.md`: auto
  only takes pieces whose done line a machine can prove (eyes-only pieces are
  left to-build); a failing piece gets three attempts, the same cap /fix uses,
  then is parked with a note and the run moves on; a disappointing run is
  answered by sharpening the documents, never hand-editing the code; and native
  /goal features are governed under the same rules. `WORKFLOW.md`'s "Running
  ahead" section and the `start/templates/masterplan.md` autonomy line were
  updated to match, and the adapters were regenerated (no adapter changes, since
  they defer skill bodies to the canonical files and no description changed).

## 2026-07-14

- Rewrote README.md as a full ai-build-kit overview, then revised the quick
  start and project fit-check details. Added an MIT LICENSE.

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
