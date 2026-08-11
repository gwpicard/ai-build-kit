# AI Build Kit

An installable workflow that helps non-developers build reliable software with an
AI coding agent. Seven commands cover the project's life. Four more skills
run in the background, handling the interview, routing, building and review.

You do not need to read code. You do need to explain what should happen, try
the results, and make the product and risk decisions the agent cannot make
for you.

## What this is

Coding agents can write working software. They will not stop you skipping the steps that make it trustworthy: agreeing what a thing should do before building it, proving it works before saving it, checking the risky parts before anyone relies on them, and keeping records so next month you can still tell what happened.

This kit is those steps, packaged as skills the agent follows and words you type. Three records hold the project's memory, because the agent forgets everything between sessions and the records don't. A build path, set at the start and rechecked as the project changes, decides how much of the process applies right now.

## Start a project

Choose one installation route. Do not use more than one in the same project.

For a project that uses only the Claude Code terminal app, open the project
folder and run:

```bash
claude plugin marketplace add gwpicard/ai-build-kit
claude plugin install ai-build-kit@ai-build-kit --scope local
```

Start Claude Code in that folder and type `/ai-build-kit:start`. Local scope
keeps the plugin attached to this project on this computer without changing
the settings shared with the project.

For Codex, Cursor, Gemini CLI, another coding agent, or a project that uses
more than one agent, run this from the project folder:

```bash
npx skills add gwpicard/ai-build-kit
```

Choose the agents you use and install all eleven AI Build Kit skills. Then ask
the agent: "Run the start skill."

Whichever route you choose, answer one question at a time. The agent prepares
the project files, checks what the environment can do, decides the project's
build path, creates the records, and tells you the next step.

The shared [skills installer](https://github.com/vercel-labs/skills) supports
Claude Code, Codex, Cursor, and Gemini CLI. It installs the skills inside this
project and records their source for later updates. The workflow itself needs
an agent that can read and edit project files, run shell commands, and use Git.

If this computer cannot run `npx`, download the
[latest public Release](https://github.com/gwpicard/ai-build-kit/releases/latest),
copy its `.agents/skills` folder into the project, and ask the agent: "Open
`.agents/skills/start/SKILL.md` and run the start skill." This manual route
keeps the same workflow, but later updates also need to be copied manually.

The seven commands are the interface. Some coding agents also list the four
background skills in a skill picker, but you never need to pick one.
[docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) explains the installation paths
and fallback.

## The seven words

Commands are named after moments, because that's how you'll reach for them.

| The moment | Type | What it does |
|---|---|---|
| I'm starting something | `/start` | Interview, fit check, founding documents. |
| Keep going, or: I want it to... | `/build` | The next piece, or anything new you ask for. |
| It's broken | `/fix` | Cause before code, and evidence that keeps it fixed. |
| I think it's ready | `/ship` | Checks everything, then takes it live, one path at a time. |
| I'm done for today | `/sync` | Documents caught up with reality. |
| It's been a while | `/maintain` | The service visit. |
| I'm lost | `/what-now` | Which word comes next, and why. |

You never have to choose the hidden technique, and you never have to sort your own request: both `/build` and `/fix` check what you typed against the masterplan and route it correctly. [WORKFLOW.md](WORKFLOW.md) is the day-to-day manual for all seven.

## How a project flows

```mermaid
flowchart LR
  S["/start<br/>once"] --> L["/build, /fix, /sync<br/>the loop"]
  L --> P["/ship<br/>first time, then again each release"]
  P --> R["the long run<br/>/build · /fix · /sync · /maintain"]
  R --> P
  F["the fit check re-runs,<br/>the build path is rewritten"]
  L -. a request that changes what kind of<br/>project this is .-> F
  R -. a request that changes what kind of<br/>project this is .-> F
  F -. same words, care matched to the path .-> L
  F -. same words, care matched to the path .-> R
```

Every piece follows the same shape: agree the behaviour in one plain sentence, choose the evidence it needs, build the smallest complete slice, try it by hand, then save it through the route the build path requires.

## The three records

Three project records hold the product's memory: `masterplan.md` is the present, `plan.md` is what's left, `CHANGELOG.md` is the past. `AGENTS.md` sits alongside them as the standing instruction file the agent reads to know how this repository works. The agent reads all of them so you don't have to; [WORKFLOW.md](WORKFLOW.md) explains what goes where.

## Which path will I be on?

| Situation | Likely path |
|---|---|
| Trying an idea with disposable data | Explore privately |
| Internal tool with a manual fallback | Build and run it |
| Outside users, payments, sensitive data, or business-critical reliance | Build with expert help |
| Regulation, irreplaceable live data, high-consequence automation, or technical ownership the team cannot carry | Professional-led |

The path is not a permanent label. The kit rechecks it whenever the project changes character.

## What keeps it safe

The kit assumes the person directing the work can't review code, so every protection is behavioural or mechanical. It opens with a fit check, which sets the build path and names any outside help that path requires; the four possible paths are explained in [fit-check.md](.agents/skills/start/references/fit-check.md).

Every promised behaviour gets evidence. Stable rules and bugs usually get automated tests, shown failing first. Visual and exploratory work may be checked by trying it. Shared, live, or risky changes get stronger checkpoints: a pull request with a clean-machine check next to the merge button, and an independent review. The build path decides how much of this applies to a given piece of work.

Underneath sit the blunt protections. Destructive commands are on a blocked list, alongside standing restrictions like never disabling authentication to make a test pass. Secrets live in `.env` and nowhere else.

## Does this fit my project?

The kit is strongest for internal tools: something for your own team, holding your own data, with nobody outside relying on it. Trackers, dashboards, small workflow tools, internal calculators. It can also help define, prototype, and get acceptance criteria for software other people will use; the fit check says plainly when that production build needs expert help or professional ownership, and names the scope.

## How it compares

All-in-one builders (Lovable, Bolt, Replit) are the fastest way to a working app, and the trade is that the platform owns the shape of your project, so extending it or leaving gets harder as it grows. Bare agent tools (Claude Code, Cursor, Codex on their own) give you an agent's full power with no process around it. The developer skill packs (Superpowers, agent-skills) carry a similar discipline and assume you read code, because they are written for people who do. This kit carries that discipline for people who don't, and its fit check says when a project needs a professional instead of the kit, or alongside it.

Much of what the kit does was borrowed from people working in the open. [docs/SOURCES.md](docs/SOURCES.md) names them and says what each one contributed.

## When outside help is needed

The kit is specific about what's needed: a short advice conversation, a scoped review of one named area, a supervised change for one risky event, or professional ownership of the whole build. It prepares the brief and keeps the rest of the project moving, wherever that remains safe, while the flagged part waits.

## What it costs

The kit is free. Building with it needs an agent subscription, which is the real running cost, and accounts with services that mostly start free. `/maintain` watches the bills once you're live.

## For technical people

The public repository is an Agent Skills source, a Claude Code plugin
marketplace, and an Agent Plugins folder at `agent-plugin`. Each folder under
`.agents/skills/` contains one skill and all of the references, templates, or
scripts it needs, and every installation route carries the same skills. The
shared installer records the source in `skills-lock.json`. The Claude plugin
keeps its copy in Claude's plugin cache, where the seven commands use the
`ai-build-kit:` prefix and the four background skills stay out of the menu until
a command needs them.

The `agent-plugin` folder is the newest route, for a client that reads the open
Agent Plugins format. Such a client is free to skip a skill it judges
non-standard, so the shared installer is the safer choice.

The start skill carries the project foundation. On its first run it creates
missing project instructions, harness pointers, environment examples, and the
placeholder project check. Existing files are preserved. It then creates
`masterplan.md`, `plan.md`, and `CHANGELOG.md` from the founding interview.

Put project-specific rules in `AGENTS.md`. Treat installed skill folders as
managed packages. `maintain` reads the public Release notes, asks before an
update, and uses the same route that installed the kit. Application code,
records, project instructions, environment files, and the project's own check
remain under the project's control.

This repository contains the complete public release. Each numbered version has
a matching tag and reviewed Release notes. The legacy starter files remain
temporarily so projects created before the installer model can migrate through
one compatible release.

Problems and suggestions belong in the public issue tracker. Read
[CONTRIBUTING.md](CONTRIBUTING.md) before opening one.
