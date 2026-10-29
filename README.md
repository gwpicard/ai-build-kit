# AI Build Kit

AI Build Kit helps people who do not write code build internal tools with a coding agent, an AI assistant that writes software, such as Claude Code or Codex. Six commands guide setup, planning, building and maintenance. The person tries the result and decides how to handle risks.

The kit is intended for internal tools where a team can keep working by hand if the tool is unavailable. The kit itself runs no online service and does not store project information. Passing checks do not prove that software is safe or right for your purpose, and the kit cannot replace a professional developer or provide legal, medical, financial or security advice. You use it at your own risk and are responsible for reading and following the terms of the services your tool uses.

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

## More information

[AI Build Kit site](https://gwpicard.github.io/ai-build-kit/) · [Compatibility and installation](docs/COMPATIBILITY.md) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md)
