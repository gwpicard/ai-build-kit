# AI Build Kit

<p align="center"><img src="https://gwpicard.github.io/ai-build-kit/hero.jpg" alt="AI Build Kit: build tools you can maintain without reading code" width="100%"></p>

[![Licence: MIT](https://img.shields.io/github/license/gwpicard/ai-build-kit)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/gwpicard/ai-build-kit)](https://github.com/gwpicard/ai-build-kit/releases/latest)

**Build the internal tool your team needs with a coding agent, and keep it running without reading code.**

The person who needs an internal tool usually knows what it should do, and often discovers the details while building it. AI Build Kit lets that person lead the build. It gives a coding agent, an AI assistant that writes software such as Claude Code or Codex, six commands to follow: you describe the tool, the agent builds it one agreed piece at a time, and by default you try each change before deciding whether to merge it.

The kit suits people who do not write code but can create accounts and follow technical setup steps, such as team leads, operations staff, analysts, product managers and founders. Developers new to agent-led work can use it too.

## Why this kit

- A tool built on a recipe runs in accounts you control. It is a standard Next.js and Supabase project in your GitHub account, running on Vercel or on a server you rent and manage with Coolify, so a developer can take it over.
- Before the kit merges a change, scripts and a reviewer agent check it, and by default you try it and the merge script refuses to merge without your recorded approval.
- Going live follows a fixed recipe, with steps for preview, launch, backup, restore and rollback. Each recipe's record shows which of those steps have run on a live host.
- Each piece of work starts with written "Done when" criteria, which you use to judge the result when you try it.

Hosted app builders such as Lovable or Bolt often reach a first app in minutes. The kit takes longer, because it needs a founding interview, a GitHub account and a hosting choice before the first screen. In return, a tool built on a recipe runs in accounts you control, and each merge the kit makes goes through its checks and, by default, your approval. [How it differs](https://gwpicard.github.io/ai-build-kit/how-it-differs/) compares the kit with hosted builders, skill sets for coding agents and Kiro.

## Commands

- `/setup-ai-build-kit` prepares a project for work.
- `/shape` turns a request or fault into a ready piece of work.
- `/implement` builds a ready piece and asks for approval before merging a change into the main project by default.
- `/setup-hosting` sets up or checks where and how the tool runs.
- `/maintain` checks the project's information and running tool, and runs maintenance when due.
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

Choose the coding agents you use and install all the kit's skills, which are the instructions they follow. Then ask your agent to run `setup-ai-build-kit`.

Claude Code is graded Tested, Codex Expected to work, and Cursor, Gemini CLI and Copilot Experimental. [Compatibility](docs/COMPATIBILITY.md) explains each grade and each agent's known limits, including the extra step Codex needs on a Mac.

## Limits

The kit is intended for internal tools where a team can keep working by hand if the tool is unavailable. The kit itself runs no online service and does not store project information. Passing checks do not prove that software is safe or right for your purpose, and no real run of either recipe has yet restored a backup. The kit cannot replace a professional developer or provide legal, medical, financial or security advice. You use it at your own risk and are responsible for reading and following the terms of the services your tool uses.

## More information

[AI Build Kit site](https://gwpicard.github.io/ai-build-kit/) · [How it differs](https://gwpicard.github.io/ai-build-kit/how-it-differs/) · [Compatibility and installation](docs/COMPATIBILITY.md) · [Releases](https://github.com/gwpicard/ai-build-kit/releases) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md)
