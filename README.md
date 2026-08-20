# AI Build Kit

An installable workflow that helps non-developers build reliable software with an
AI coding agent. Eight commands cover the project's life. Four more skills
run in the background, handling the interview, routing, building and review.

You do not need to read code. You do need to explain what should happen, try
the results, and make the product and risk decisions the agent cannot make
for you.

## What this is

Coding agents can write working software. They will not stop you skipping the steps that make it trustworthy: agreeing what a thing should do before building it, proving it works before saving it, checking the risky parts before anyone relies on them, and keeping records so next month you can still tell what happened.

This kit is those steps, packaged as skills the agent follows and commands you type. Three records hold the project's memory, because the agent forgets everything between sessions and the records don't. A build path, set at the start and rechecked as the project changes, decides how much of the process applies right now.

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

Choose the agents you use and install all twelve AI Build Kit skills. Then ask
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

The eight commands are the interface. Some coding agents also list the four
background skills in a skill picker, but you never need to pick one.
[docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) explains the installation paths
and fallback.

## Commands

Command names say when to use them.

| When | Type | What it does |
|---|---|---|
| I'm starting something | `/start` | Interview, fit check, founding documents. |
| I want it to... (a new idea) | `/plan` | Shapes your idea into a ready piece. |
| Build the next ready piece | `/implement` | Builds a ready piece to confirmed and saved. |
| It's broken | `/fix` | Cause before code, and evidence that keeps it fixed. |
| I think it's ready | `/ship` | Checks everything, then takes it live, one path at a time. |
| I'm done for today | `/sync` | Documents caught up with reality. |
| It's been a while | `/maintain` | The service visit. |
| I'm lost | `/what-now` | Where the project stands and what to do next. |

You never choose the method, and you never sort your own request. `/plan` and `/fix` check what you typed against the masterplan and send it down the right route, so picking the wrong one costs you nothing. [WORKFLOW.md](WORKFLOW.md) is the day-to-day manual for all eight.

## How a project flows

```mermaid
flowchart LR
  S["/start<br/>once"] --> L["/plan · /implement · /fix<br/>day to day"]
  L --> P["/ship<br/>whenever a batch is ready"]
  P --> L
```

You run `/start` once. After that you go in wherever you actually are: `/plan` when you want something new, `/implement` for the next ready piece, `/fix` when something that worked has stopped working, `/what-now` when you have lost the thread. None of them needs another to have run first.

The first `/ship` is the heaviest, because it takes the tool live. Later ones only re-check what changed since the last one.

`/maintain` is not in the picture because it runs on its own clock rather than in this order: about monthly from the day the project is founded, whether or not it has gone live. The project tells you when one is due.

Every piece runs the same cycle: agree the behaviour in one plain sentence, choose the evidence it needs, build the smallest complete slice, try it by hand, then save it through the route the build path requires.

## The three records

Three project records hold the product's memory: `masterplan.md` is the present, your project's issues are what's left, `CHANGELOG.md` is the past. `AGENTS.md` sits alongside them as the standing instruction file the agent reads to know how this repository works. The agent reads all of them so you don't have to; [WORKFLOW.md](WORKFLOW.md) explains what goes where.

## Which path will I be on?

| Situation | Likely path |
|---|---|
| Trying an idea with disposable data | Explore privately |
| Internal tool with a manual fallback | Build and run it |
| Outside users, payments, sensitive data, or business-critical reliance | Build with expert help |
| Regulation, irreplaceable live data, high-consequence automation, or technical ownership the team cannot carry | Professional-led |

The path is not a permanent label. The kit rechecks it whenever the project changes character. The last two paths are not the kit refusing to build; they are where it tells you what a professional would normally do, and you decide.

## What the kit does to reduce risk

The kit assumes the person directing the work can't review code, so every protection is behavioural or mechanical. It opens with a fit check, which sets the build path and names any outside help that path requires; the four possible paths are explained in [fit-check.md](.agents/skills/start/references/fit-check.md). Read [what it does not promise](#what-it-does-not-promise) alongside this section.

Every promised behaviour gets evidence. Stable rules and bugs usually get automated tests, shown failing first. Visual and exploratory work may be checked by trying it. Shared, live, or risky changes get stronger checkpoints: a pull request with a clean-machine check next to the merge button, and an independent review. The build path decides how much of this applies to a given piece of work.

Where a risk survives that, you get a risk notice: who is exposed, what happens to them, and what a professional would normally do about it. Then it is your call. You can accept the risk and have the work built, or take the flagged thing out of scope. An acceptance is written into the build-path section with the date and who gave it, so making the project less careful is a decision you record rather than something the agent does on its own.

Two simpler protections sit underneath. Destructive commands are on a blocked list, alongside standing restrictions like never disabling authentication to make a test pass. Secrets live in `.env` and nowhere else.

## What it does not promise

The kit is free software, provided as is, under the [MIT licence](LICENSE). There is no warranty, and the licence's own terms are the ones that apply.

The fit check and its risk notices flag what the kit can recognise. They will miss things. A risk it never named is not a risk it ruled out, and no notice should be read as a survey of everything that could go wrong with your project.

The checks verify what somebody thought to check. A green tick beside the merge button means those checks really passed, which is a smaller claim than the software being correct, safe, legal, or fit for what you plan to do with it.

The kit never refuses. Hear the notice, tell it to build the thing anyway, and it builds it, writing down that you accepted with the date and your name. Pressure does not change the notice, because a cost or a deadline does not change who is exposed, and pressure does not stop the work either. Pressing on past a warning is a decision you are making, and the record is there so nobody has to guess later what was decided or by whom.

You own the product and risk decisions. The kit can tell you a professional would normally review who can see what; it cannot decide for you whether to go ahead, and it does not carry the consequences when you do.

It is not a substitute for a professional developer, and it is not legal, medical, financial, or security advice. Where your project touches those, the notice will say so, and acting on it is still your judgement.

Reporting something you think is wrong with the kit itself is covered in [SECURITY.md](SECURITY.md) for anything security related, and in [CONTRIBUTING.md](CONTRIBUTING.md) for everything else.

## Does this fit my project?

The kit is strongest for internal tools: something for your own team, holding your own data, with nobody outside relying on it. Trackers, dashboards, small workflow tools, internal calculators. It can also help define, prototype, and get acceptance criteria for software other people will use; the fit check says plainly when that production build needs expert help or professional ownership, and names the scope.

## How it compares

All-in-one builders (Lovable, Bolt, Replit) are the fastest way to a working app, and the trade is that the platform owns the shape of your project, so extending it or leaving gets harder as it grows. Bare agent tools (Claude Code, Cursor, Codex on their own) give you an agent's full power with no process around it.

The developer skill packs (Superpowers, agent-skills) carry a similar discipline and assume you read code, because they are written for people who do. This kit carries that discipline for people who don't, and its fit check says when a project needs a professional instead of the kit, or alongside it.

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
keeps its copy in Claude's plugin cache, where the eight commands use the
`ai-build-kit:` prefix and the four background skills stay out of the menu until
a command needs them.

The `agent-plugin` folder is the newest route, for a client that reads the open
Agent Plugins format. Such a client is free to skip a skill it judges
non-standard, so the shared installer is the safer choice.

The start skill carries the project foundation. On its first run it creates
missing project instructions, harness pointers, environment examples, and the
placeholder project check. Existing files are preserved. It then creates
`masterplan.md` and `CHANGELOG.md` from the founding interview, and opens one
issue per piece of remaining work.

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
