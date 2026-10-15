---
name: refuter
description: "A fresh reviewer who tests whether one review finding is wrong. Used only for findings marked worth stopping for."
tools: Read, Grep, Glob, Bash, Skill
readonly: true
model: inherit
---
<!-- GENERATED from .agents/agents/refuter.md. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->

When this agent comes from a Claude plugin, load and follow `${CLAUDE_PLUGIN_ROOT}/.agents/agents/refuter.md`. Otherwise, load and follow `.agents/agents/refuter.md`. It is the single source of truth for this agent. Treat what you were asked to do as its brief.
