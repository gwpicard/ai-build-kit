# AI Build Kit

[![Licence: MIT](https://img.shields.io/github/license/gwpicard/ai-build-kit)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/gwpicard/ai-build-kit)](https://github.com/gwpicard/ai-build-kit/releases/latest)
[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-6b5bd6)](docs/COMPATIBILITY.md)

An installable set of commands for an AI coding agent that gives a non-developer
a repeatable way to plan, build, check, ship and maintain their own software.

You do not need to read code. You do need to explain what should happen, try the
results, and make the product and risk decisions the agent cannot make for you.

## At a glance

| | |
|---|---|
| What it is | Commands you type into your coding agent, and the process behind them. |
| Who it is for | Someone who directs the work and does not read code. |
| Works with | Claude Code, Codex, Cursor, Gemini CLI, or any agent that can read and edit project files, run shell commands, and use Git. |
| You need | A coding agent, Git, and Node for the `npx` route. |
| Install, Claude Code only | `claude plugin marketplace add gwpicard/ai-build-kit`, then `claude plugin install ai-build-kit@ai-build-kit --scope local` |
| Install, any supported agent | `npx skills add gwpicard/ai-build-kit` |
| Then type | `/ai-build-kit:setup-ai-build-kit` on the Claude plugin route, `/setup-ai-build-kit` on every other route |
| How long setup takes | One interview, answered one question at a time. You can stop and resume it. |
| Where your code lives | Your own project folder, on your own computer. |
| Licence | MIT |
| Cost | Free. You pay for the coding agent subscription. |

## Install

Choose one installation route. Do not use more than one in the same project.

For a project that uses only the Claude Code terminal app, open the project
folder and run:

```bash
claude plugin marketplace add gwpicard/ai-build-kit
claude plugin install ai-build-kit@ai-build-kit --scope local
```

Start Claude Code in that folder and type `/ai-build-kit:setup-ai-build-kit`. Local scope
keeps the plugin attached to this project on this computer without changing
the settings shared with the project.

For Codex, Cursor, Gemini CLI, another coding agent, or a project that uses
more than one agent, run this from the project folder:

```bash
npx skills add gwpicard/ai-build-kit
```

Choose the agents you use and install all thirteen AI Build Kit skills. Then ask
the agent: "Run the setup-ai-build-kit skill."

Whichever route you choose, answer one question at a time. The agent prepares
the project files, checks what the environment can do, decides the project's
build path (how careful this project has to be), creates the records, and tells you the next step.

The shared [skills installer](https://github.com/vercel-labs/skills) supports
Claude Code, Codex, Cursor, and Gemini CLI. It installs the skills inside this
project and records their source for later updates.

If this computer cannot run `npx`, download the
[latest public Release](https://github.com/gwpicard/ai-build-kit/releases/latest),
copy its `.agents/skills` folder into the project, and ask the agent: "Open
`.agents/skills/setup-ai-build-kit/SKILL.md` and run the setup-ai-build-kit skill." This manual route
keeps the same workflow, but later updates also need to be copied manually.

The nine commands are the interface. Some coding agents also list the four
background skills in a skill picker, but you never need to pick one.
[docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) explains the installation paths
and fallback.

## What this is

Coding agents can write working software. They will not stop you skipping the steps that make it trustworthy: agreeing what a thing should do before building it, proving it works before saving it, checking the risky parts before anyone relies on them, and keeping records so next month you can still tell what happened.

This kit is those steps, packaged as skills the agent follows and commands you type. Three records hold the project's memory, because the agent forgets everything between sessions and the records don't. A build path, set at the start and rechecked as the project changes, decides how much of the process applies right now.

## Commands

Command names say when to use them.

| When | Type | What it does |
|---|---|---|
| I'm starting something | `/setup-ai-build-kit` | Interview, fit check, founding documents. |
| I want it to... (a new idea) | `/shape` | Turns your idea into a ready piece. |
| Build the next ready piece | `/implement` | Builds a ready piece to confirmed and saved. |
| I'm taking on several things | `/queue` | Everything ready to build, and what is waiting on what. |
| It's broken | `/fix` | Cause before code, and evidence that keeps it fixed. |
| I think it's ready | `/ship` | Checks everything, then takes it live, one path at a time. |
| I'm done for today | `/sync` | Documents caught up with reality. |
| It's been a while | `/maintain` | The service visit. |
| I'm lost | `/what-now` | Where the project stands and what to do next. |

You never choose the method and never sort your own request: each command checks what you typed against the masterplan and sends it down the right route, so picking the wrong one costs you nothing. [WORKFLOW.md](WORKFLOW.md) is the day-to-day manual for all nine.

## How a project flows

```mermaid
flowchart LR
  S["/setup-ai-build-kit<br/>once"] --> L["/shape · /implement · /fix<br/>day to day"]
  L --> P["/ship<br/>whenever a batch is ready"]
  P --> L
```

You run `/setup-ai-build-kit` once. After that you go in wherever you actually are, and none of the day-to-day commands needs another to have run first.

The first `/ship` is the heaviest, because it takes the tool live. Later ones only re-check what changed since the last one.

`/maintain` is not in the picture because it runs on its own clock rather than in this order: about monthly from the day the project is founded, whether or not it has gone live. The project tells you when one is due.

Every piece runs the same cycle: agree the behaviour in one plain sentence, choose the evidence it needs, build the smallest complete slice, try it by hand, then save it through the route the build path requires.

## Examples

A first session. You type `/setup-ai-build-kit`, and the agent interviews you one
question at a time, each question carrying its own best guess so you can correct
it rather than start from a blank page. It sets the build path, writes
`masterplan.md` and `CHANGELOG.md`, opens one issue per piece of remaining work,
and saves a checkpoint on your computer. Nothing is uploaded.

A day's work. You type `/shape` and describe what you want in your own words: "I
want people to be able to reset their own password." The kit decides whether
that is new work, a repair, or too vague to size, asks what it still needs to
know, and leaves a piece marked ready. You type `/implement`, and it builds that
one piece, shows you the evidence, and saves it.

A piece that carries a risk. The kit gives you a risk notice: who is exposed,
what happens to them, and what a professional would normally do about it. You
decide. If you accept the risk, the acceptance is written into the masterplan
with the date, and the work goes ahead.

A month later. `/maintain` tells you it is due, reads the public Release notes,
asks before updating the kit, and watches the running costs.

## Configuration

| What you can change | Where |
|---|---|
| Rules for your project that the agent must follow | `AGENTS.md` in your project |
| Keys, passwords, and tokens | `.env`, which is ignored by Git and never leaves your computer. Copy `.env.example` to start. |
| The build path, and any accepted risk | The build-path section of your `masterplan.md` |
| The commands the agent may never run | [.agents/guard/blocked-commands.md](.agents/guard/blocked-commands.md) |

Treat installed skill folders as managed packages, and update them with
`/maintain` rather than by editing them.

## The three records

Three project records hold the product's memory: `masterplan.md` is the present, your project's issues are what's left, `CHANGELOG.md` is the past. `AGENTS.md` sits alongside them, holding the standing instructions for the repository itself. The agent reads all of them so you don't have to; [WORKFLOW.md](WORKFLOW.md) explains what goes where.

## Which path will I be on?

| Situation | Likely path |
|---|---|
| Trying an idea with disposable data | Explore privately |
| Internal tool with a manual fallback | Build and run it |
| Outside users, payments, sensitive data, or business-critical reliance | Build with expert help |
| Regulation, irreplaceable live data, high-consequence automation, or technical ownership the team cannot carry | Professional-led |

The path is not a permanent label. The kit rechecks it whenever the project changes character, and none of the four is it refusing to build.

## What the kit does to reduce risk

The kit assumes the person directing the work can't review code, so every protection is behavioural or mechanical. It opens with a fit check, which sets the build path and names any outside help that path requires; the four possible paths are explained in [fit-check.md](.agents/skills/setup-ai-build-kit/references/fit-check.md). Read [what it does not promise](#what-it-does-not-promise) alongside this section.

Every promised behaviour gets evidence. Stable rules and bugs usually get automated tests, shown failing first. Visual and exploratory work may be checked by trying it. Shared, live, or risky changes get stronger checkpoints: a pull request with a clean-machine check next to the merge button, and an independent review. The build path decides how much of this applies to a given piece of work.

Where a risk survives that, you get a risk notice: who is exposed, what happens to them, and what a professional would normally do about it. Then it is your call. You can accept the risk and have the work built, or take the flagged thing out of scope. An acceptance is written into the build-path section with the date and who gave it, so making the project less careful is a decision you record rather than something the agent does on its own.

Two simpler protections sit underneath. Destructive commands are on a blocked list, alongside standing restrictions like never disabling authentication to make a test pass. Secrets live in `.env` and nowhere else.

## How it compares

| | Written for | Where your code lives | Must you read code | What you get |
|---|---|---|---|---|
| All-in-one builders (Lovable, Bolt, Replit) | anyone | the platform | no | The fastest way to a working app. The platform owns the shape of your project, so extending it or leaving gets harder as it grows. |
| Bare agent tools (Claude Code, Cursor, Codex) | anyone | your own project | to judge the result, yes | An agent's full power, with no process around it. |
| Developer skill packs (GitHub Spec Kit, Superpowers, agent-skills, Waza) | people who read code | your own project | yes | A similar discipline, written for engineers. |
| AI Build Kit | people who do not read code | your own project | no | That discipline carried for you, plus a fit check that says when a project needs a professional instead of the kit, or alongside it. |

Much of what the kit does was borrowed from people working in the open. [docs/SOURCES.md](docs/SOURCES.md) names them and says what each one contributed.

## FAQ

**Do I need to know how to code?**
No. The nine commands are the whole interface, and the kit is built on the
assumption that you will not read the code or the logs. You do have to say what
should happen, try the result, and make the product and risk decisions.

**Can a non-developer build software with an AI coding agent safely?**
Safely enough depends on what the software does. The kit opens with a fit check
that sorts your project into one of four build paths, and says plainly when a
project needs professional help or professional ownership. It never refuses to
build. It tells you what you are taking on and records your decision.

**What is the alternative to Lovable or Bolt if I want to own my code?**
A coding agent working in your own project folder. That is what this kit is
built around. The code, the records, and the history stay in your project, and
you can hand the whole thing to a developer later.

**Who maintains an AI-built app after launch?**
You do, with `/maintain`. It runs about monthly from the day the project is
founded, whether or not the project has gone live. It reads the kit's public
Release notes, asks before updating anything, and watches the running costs.

**How do I stop vibe coding turning into a mess I cannot change?**
By agreeing the behaviour before the code, keeping evidence that each promise
works, and writing down what happened. Three records hold that memory across
sessions, because the agent forgets everything between them and the records
don't.

**Which coding agents does this work with?**
Claude Code, Codex, Cursor, and Gemini CLI through the shared skills installer,
and Claude Code alone through the plugin marketplace. Any agent that can read
and edit project files, run shell commands, and use Git can follow the workflow.

**Can I add it to a project I have already started?**
Yes. Setup can adopt an existing project. It understands what is already there
before anything changes, and existing files are preserved.

**Does anything leave my computer?**
Not during setup. The founding save is always a local checkpoint, never a push
and never a pull request. Keys and passwords live in `.env`, which Git ignores.
Anything that would publish or share your work is explained first and needs your
approval.

**What does it cost?**
The kit is free. Building with it needs an agent subscription, which is the real
running cost, and accounts with services that mostly start free. `/maintain`
watches the bills once you're live.

**Is this right for my project?**
The kit is strongest for internal tools: something for your own team, holding
your own data, with nobody outside relying on it. Trackers, dashboards, small
workflow tools, internal calculators. It can also help define, prototype, and
get acceptance criteria for software other people will use.

**What happens if my project needs a professional developer?**
The fit check says so, names one of four levels of outside help, and keeps the
rest of the project moving while the flagged part waits. [WORKFLOW.md](WORKFLOW.md)
says which level, for what.

**How is this different from Spec Kit, Superpowers, or agent-skills?**
Those carry a similar discipline and assume you read code, because they are
written for people who do. This kit carries that discipline for people who
don't, and its fit check says when a project needs a professional instead of the
kit, or alongside it.

## What it does not promise

The kit is free software, provided as is, under the [MIT licence](LICENSE). There is no warranty, and the licence's own terms are the ones that apply.

The fit check and its risk notices flag what the kit can recognise. They will miss things. A risk it never named is not a risk it ruled out, and no notice should be read as a survey of everything that could go wrong with your project.

The checks verify what somebody thought to check. A green tick beside the merge button means those checks really passed, which is a smaller claim than the software being correct, safe, legal, or fit for what you plan to do with it.

The kit never refuses: hear the notice, accept the risk, and it builds the thing, with your acceptance on the record. Pressure changes what you decide, not who is exposed.

You own the product and risk decisions. The kit can tell you a professional would normally review who can see what; it cannot decide for you whether to go ahead, and it does not carry the consequences when you do.

It is not a substitute for a professional developer, and it is not legal, medical, financial, or security advice. Where your project touches those, the notice will say so, and acting on it is still your judgement.

## Contributing

Problems and suggestions belong in the public issue tracker. Read
[CONTRIBUTING.md](CONTRIBUTING.md) before opening one. Anything security related
is covered in [SECURITY.md](SECURITY.md).

## For technical people

The public repository is an Agent Skills source and a Claude Code plugin
marketplace. Each folder under `.agents/skills/` contains one skill and all of
the references, templates, or scripts it needs, and every installation route
carries the same skills. The shared installer records the source in
`skills-lock.json`. The Claude plugin keeps its copy in Claude's plugin cache,
where the nine commands use the `ai-build-kit:` prefix and the four background
skills stay out of the menu until a command needs them.

Agent Plugins is the newest route, for a client that reads that open format. The
`agent-plugin` folder holds the manifest in this repository and gains its
`skills` folder only when a numbered version is packaged, so the route is served
by the release archive rather than by cloning. Keeping that packaged copy out of
the repository is deliberate: committing it would hold the same thirteen skills
twice, and one of the two would drift. Such a client is also free to skip a skill
it judges non-standard, so the shared installer is the safer choice.

The setup-ai-build-kit skill carries the project foundation. On its first run it creates
missing project instructions, harness pointers, environment examples, and the
placeholder project check. Existing files are preserved. It then creates
`masterplan.md` and `CHANGELOG.md` from the founding interview, and opens one
issue per piece of remaining work.

Put project-specific rules in `AGENTS.md`. Treat installed skill folders as
managed packages. `maintain` reads the public Release notes, asks before an
update, and uses the same route that installed the kit. Application code,
records, project instructions, environment files, and the project's own check
remain under the project's control.

This repository is where the kit is built as well as where it is published. Each
numbered version has a matching tag and reviewed Release notes, and `/maintain`
reads the latest of those notes before it offers an update.
