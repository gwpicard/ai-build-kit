---
description: The command for turning an idea into a ready piece before anything is built.
disable-model-invocation: true
---
<!-- GENERATED from .agents/skills/plan/. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->

When this command comes from a Claude plugin, load and follow `${CLAUDE_PLUGIN_ROOT}/.agents/skills/plan/SKILL.md`. Otherwise, load and follow `.agents/skills/plan/SKILL.md`. It is the single source of truth for the `/plan` command. Treat anything typed after the command as the user's request and pass it through unchanged.
