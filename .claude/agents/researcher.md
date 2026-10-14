---
name: researcher
description: "Settles one outside fact against its primary source, or searches for existing work, in a fresh context, and returns a short cited note. Runs the research skill. Started by a command, never by the person."
tools: Read, Grep, Glob, WebFetch, WebSearch, Skill
readonly: true
model: inherit
---
<!-- GENERATED from .agents/agents/researcher.md. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->

When this agent comes from a Claude plugin, load and follow `${CLAUDE_PLUGIN_ROOT}/.agents/agents/researcher.md`. Otherwise, load and follow `.agents/agents/researcher.md`. It is the single source of truth for this agent. Treat what you were asked to do as its brief.
