# AI Build Kit

<p align="center"><img src="https://gwpicard.github.io/ai-build-kit/hero.jpg" alt="AI Build Kit: build tools you can maintain without reading code" width="100%"></p>

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
provide legal, medical, financial or security advice. You use it at your own
risk. The terms of the services you run a tool on, such as a host or a database
plan, are between you and those services, and you are responsible for reading
and following them.

## Why this kit

The person who needs an internal tool usually knows best what it should do,
and often only discovers the details while building it. AI Build Kit lets that
person build the tool with an AI coding tool such as Claude Code or Codex,
and keep it running without reading code.

- **It's yours.** Each tool is a standard Next.js and Supabase project in your
  GitHub, running on Vercel or on a server you rent through Coolify, which can
  host several tools on one machine. You can move it, and a developer can take
  it over at any time.
- **It lasts.** The agent's work goes through scripted checks and a second
  agent's review, you try every change in a preview before deciding whether to
  merge it, and a fixed recipe handles launch, backups and rollback.
- **You get better at it.** Every change starts as a small piece of work with
  written acceptance criteria, its "Done when", so you learn to specify and
  lead the build as well as use the result.

### Compared with hosted app builders

Lovable, Replit, Bolt and similar builders are the fastest route to a working
demo, and the right choice for a prototype. However, the app lives on their
platform: the hosting, the database and the deploys stay tied to it even when
the code can be exported, and reviewing what the AI built is largely left to
you. The kit takes longer to set up, because you create the accounts it runs in,
and in exchange the tool runs where you control it and its changes are checked
before they are merged.

### Compared with developer skill sets

Skill sets such as Superpowers or Addy Osmani's agent skills rest on the same
idea as the kit: a capable model works best inside a well-designed harness.
They are written for developers, who choose the stack and hosting and enforce
the rules by reading the code. The kit is written for people who do not read
code, so it fixes the stack through recipes, runs its rules as scripts where
it can, and asks you to judge each change by trying it.

### How it holds up

| | AI coding tool alone | Developer skill sets | Hosted app builders | AI Build Kit |
|---|---|---|---|---|
| Code and hosting | Your repository; you choose the hosting | Your repository; you choose the hosting | The platform hosts the app; code export varies | Your GitHub, and your Vercel or Coolify account |
| How changes are verified | You read the code | Written instructions to the agent, then you read the code | Platform scans, often optional; you test the app | Scripted checks and a second agent's review, then you try a preview |
| Going live and upkeep | Up to you | Up to you | Built into the platform | A fixed recipe for each host, and `/maintain` |
| Time to a first app | Hours | Hours | Minutes | Longer: you set up GitHub and hosting accounts first |

During each build, a script confirms that every new test fails without the
change and passes with it. Once a piece's tests are committed, the project
check on its pull request fails any commit that alters them, unless the commit
is marked as a test fix with a reason. Before you see a preview, the agent
removes code the change added but does not need, and the merge waits until
the second review has no blocking finding. The launch script will not put a
tool live until a backup check passes and a rollback step is defined, and
after launch `/maintain` compares the live tool with the code and reports what
differs, such as a database change not yet applied.

Claude Code is fully tested and Codex is expected to work. Cursor, Gemini
CLI and Copilot are experimental. Each recipe's `PROVEN.md` records
which steps have run on a live host; others, such as restoring a backup, are
rehearsed by script but not yet proven live.

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
