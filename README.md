# AI Build Kit

[![Licence: MIT](https://img.shields.io/github/license/gwpicard/ai-build-kit)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/gwpicard/ai-build-kit)](https://github.com/gwpicard/ai-build-kit/releases/latest)

**[Site](https://gwpicard.github.io/ai-build-kit/)** · [Releases](https://github.com/gwpicard/ai-build-kit/releases)

AI Build Kit helps people who do not write code build and run tools with a
coding agent. It suits team leads, operations staff, analysts, product
managers and founders who are comfortable with technology. Developers new to
agent-led work can use it too.

The six commands are:

- `/setup-ai-build-kit` prepares a project.
- `/shape` turns an idea or fault into a ready piece of work.
- `/implement` builds a ready piece and asks before merging by default.
- `/setup-hosting` sets up or checks how the tool runs live.
- `/maintain` checks the records and live copy, and runs upkeep when due.
- `/what-now` says where the project stands and what to do next.

Automatic merging is off by default. The masterplan records the choice and its
limits under `Runs on its own:`.

The kit does not host tools or store project records. It is for internal tools
with a manual fallback. Passing checks do not prove that software is safe or
right for your purpose. The kit cannot replace a professional developer or
provide legal, medical, financial or security advice.

## Quick start

Choose one route for each project. For the Claude Code terminal app alone,
run these commands from your project folder:

```bash
claude plugin marketplace add gwpicard/ai-build-kit
claude plugin install ai-build-kit@ai-build-kit --scope local
```

Start Claude Code there and type `/ai-build-kit:setup-ai-build-kit`.

For another agent, or a project using several agents, run:

```bash
npx skills add gwpicard/ai-build-kit
```

Choose the agents you use and install all the kit's skills. Then ask your
agent: "Run the setup-ai-build-kit skill."

For Codex on a Mac, start each session from your project folder with
`python3 .agents/skills/setup-ai-build-kit/scripts/codex-with-github.py`.
Setup explains any extra tools your recipe needs. [Manual installation and
Agent Plugins](docs/COMPATIBILITY.md#choose-one-installation-route) are also
available.

[Read the AI Build Kit site](https://gwpicard.github.io/ai-build-kit/) for the
workflow, the rules and checks, supported agents, design, releases and sources.

## A sample session

This shortened example comes from a replayed session on an office noticeboard
app, using Claude Code. The tool is already live and a change is ready to merge.

> **Person:** `/implement` I opened the preview and the sign-in button says
> "Email me a sign-in link", which is right. Merge it and put it live.
>
> **Agent:** All four tests and the project check pass. I've added a dated
> changelog line. The review has no unresolved concern, so I'm asking Claude
> Code to merge it. Claude Code will show you a confirmation box before the
> merge runs.

After the merge, the agent reads the live page:

> **Agent:** The sign-in button at the live address now says "Email me a
> sign-in link". The live copy runs this change. This read only checks the button text.
>
> **Person:** Priya still sees the old "Continue" button. Can you put it out again?
>
> **Agent:** The live page already shows the new button. Try a full refresh
> in Priya's browser. I have not deployed it again.

## Contributing and licence

Read [CONTRIBUTING.md](CONTRIBUTING.md) to report a problem or suggest a
change. The kit is provided as is, without warranty, under the [MIT licence](LICENSE).
