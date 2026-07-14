# Blocked commands

Never run these. Each one can destroy work in a way the people on this
project cannot see coming or recover from alone. Instructions do not prevent
execution and a mechanical guard does, so where the agent tool supports a
command deny list this list is mirrored there too:

- Claude Code: `.claude/settings.json` → `permissions.deny` (shipped, mirrors this list).
- Codex: set `approval_policy`/sandbox in `~/.codex/config.toml` so shell writes need approval.
- Cursor: add the same patterns under Cursor's command allow/deny settings.

This file stays the standing instruction, and the source of truth: when you
change it, update `.claude/settings.json` to match. Two entries below are left
out of the mechanical deny on purpose — `git checkout .` / `git restore .` are
allowed inside fix's announced reset step, and database drops are too varied to
pattern-match — so they remain instruction-only.

- git reset --hard (throws away unsaved work)
- git checkout . and git restore . (the same thing wearing different clothes; allowed only inside fix's reset step, announced out loud first)
- git push --force (rewrites shared history under teammates' feet)
- git clean -fd (deletes files git never saved)
- rm -rf (deletes anything, recursively, with no undo)
- any command that drops or empties a database table

Commit before anything sweeping. If one of these ever looks necessary,
stop, say why, and let the human decide with the reason in front of them.
