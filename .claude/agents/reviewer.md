---
name: reviewer
description: "Fresh eyes on a drafted masterplan, the change one piece makes, or the whole build before launch. Runs the second-opinion skill in a context that has not seen the builder's reasoning, and returns its report. Started by a command, never by the person."
tools: Read, Grep, Glob, Bash, Skill
readonly: true
model: inherit
---
<!-- GENERATED from .agents/agents/reviewer.md. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->

When this agent comes from a Claude plugin, load and follow `${CLAUDE_PLUGIN_ROOT}/.agents/agents/reviewer.md`. Otherwise, load and follow `.agents/agents/reviewer.md`. It is the single source of truth for this agent. Treat what you were asked to do as its brief.
