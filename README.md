# AI Build Kit

<p align="center"><img src="https://gwpicard.github.io/ai-build-kit/hero.jpg" alt="AI Build Kit: build tools you can maintain without reading code" width="100%"></p>

[![Licence: MIT](https://img.shields.io/github/license/gwpicard/ai-build-kit)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/gwpicard/ai-build-kit)](https://github.com/gwpicard/ai-build-kit/releases/latest)

**Build the internal tool your team needs with a coding agent, and keep it running without reading code.**

The person who needs an internal tool usually knows what it should do, and often discovers the details while building it. AI Build Kit lets that person lead the build. It gives a coding agent such as Claude Code or Codex (an AI assistant that writes software) six commands to follow: you describe the tool, the agent builds it one agreed piece at a time, and by default you try each change before you approve its merge.

The kit suits team leads, operations staff, analysts, product managers and founders who do not write code but can create accounts and follow technical setup steps. Developers new to agent-led work can use it too.

## Why this kit

- A recipe is one of the kit's fixed routes for going live. A tool built on one runs in accounts you control, and a developer can take it over: it is a standard Next.js and Supabase project in your GitHub account, running on Vercel or on a server you rent and manage through Coolify.
- Before the kit merges a change, scripts and a reviewer agent check it. By default you then try the change, and the merge script rejects the merge until your approval is recorded.
- Each piece of work starts with written "Done when" criteria, which you use to judge the result when you try it.
- Each recipe sets out the steps for preview, launch, backup, restore and rollback, and its record shows which of those steps have run on a live host.

Hosted app builders such as Lovable or Bolt often produce a first app within minutes. The kit takes longer, because it needs a founding interview, a GitHub account and a hosting choice before the first screen. In return, a tool built on a recipe runs in accounts you control, and every merge the kit makes passes its checks and, by default, your approval. [How it differs](https://gwpicard.github.io/ai-build-kit/how-it-differs/) compares the kit with hosted builders, skill sets for coding agents and Kiro.

## Commands

- `/setup-ai-build-kit` prepares a project for work.
- `/shape` turns a request or fault into a ready piece of work.
- `/implement` builds a ready piece and, by default, asks for your approval before merging it into the main project.
- `/setup-hosting` sets up or checks where and how the tool runs.
- `/maintain` checks the project's records and the running tool, and runs maintenance when it is due.
- `/what-now` reports the project's status and what to do next.

## Install

Choose one route for each project.

For the Claude Code terminal app, run:

```bash
claude plugin marketplace add gwpicard/ai-build-kit
claude plugin install ai-build-kit@ai-build-kit --scope local
```

Start Claude Code in your project folder and type `/ai-build-kit:setup-ai-build-kit`.

For another agent, or a project using several agents, run:

```bash
npx skills add gwpicard/ai-build-kit
```

When the installer asks, choose the coding agents you use, install the kit for this project, and install all of the kit's skills, the instructions those agents follow.

On a Mac, Codex cannot read your GitHub sign-in by itself. Start each Codex session from a terminal opened in your project folder, not from inside Codex, with:

```bash
python3 .agents/skills/setup-ai-build-kit/scripts/codex-with-github.py
```

Then ask your agent to run `setup-ai-build-kit`.

Claude Code is graded "Tested" and Codex "Expected to work"; Cursor, Gemini CLI and GitHub Copilot are "Experimental". [Compatibility](docs/COMPATIBILITY.md) explains each grade and each agent's known limits.

## Limits

The kit is intended for internal tools where a team can keep working by hand if the tool is unavailable. The kit itself runs no online service and does not store project information. Passing checks do not prove that software is safe or right for your purpose. No run of either recipe on a live host has yet restored a backup.

The kit cannot replace a professional developer or provide legal, medical, financial or security advice. You use it at your own risk and are responsible for reading and following the terms of the services your tool uses.

## More information

[AI Build Kit site](https://gwpicard.github.io/ai-build-kit/) · [How it differs](https://gwpicard.github.io/ai-build-kit/how-it-differs/) · [Compatibility and installation](docs/COMPATIBILITY.md) · [Releases](https://github.com/gwpicard/ai-build-kit/releases) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md)
