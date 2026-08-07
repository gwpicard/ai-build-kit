# AI Build Kit

A clonable workflow that helps non-developers build reliable software with an
AI coding agent. Seven commands cover the project's life. Four internal
disciplines handle interviewing, routing, building, and review behind the
scenes.

You do not need to read code. You do need to explain what should happen, try
the results, and make the product and risk decisions the agent cannot make
for you.

## What this is

AI agents can write working software now. What they can't do is stop you from skipping the steps that make software trustworthy: agreeing what a thing should do before building it, proving it works before saving it, checking the risky parts before anyone relies on them, and keeping records so next month's you knows what this month's you did.

This kit is those steps, packaged as skills the agent follows and words you type. Seven commands cover a project's whole life, and three records hold its memory, because the agent forgets everything between sessions and the records don't. A build path, set at the start and rechecked as the project changes, decides how much of that process actually applies to this project right now. You describe what you want in plain language and judge the results by using them; the kit handles everything in between.

No coding knowledge is needed. The workflow never asks you to read code: every check is something you click or something you see.

## Quick start

1. Use this repository as a private template and open the clone in an agent tool.
2. Ask the agent to run `start`. Native `/start` works where the tool supports it.
3. Answer one question at a time. The agent checks what the environment can do, decides the project's build path, creates the records, and tells you the next step.

The core workflow works in any agent harness that can read and edit repository files, run shell commands, and use Git. Generated adapters make the experience more native in Claude Code, Cursor, and Gemini CLI; Codex reads the canonical skills directly.

In a harness with native project commands, typing `/` should list the seven words. Otherwise, ask for `start` by name and confirm the agent opens `.agents/skills/start/SKILL.md`. The seven commands are the user interface. The four disciplines are internal machinery; some harness skill pickers may still display them, but users never need to select them. [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) covers every tool, including harnesses with no adapter at all.

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

You never have to choose the hidden technique. The agent decides whether the moment needs an interview, a prototype, source research, a test, a review, or outside help. You never have to sort your own request either: both `/build` and `/fix` check what you typed against the masterplan and route it correctly. [WORKFLOW.md](WORKFLOW.md) is the day-to-day manual for all seven.

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

Every piece follows the same shape: agree the behaviour in one plain sentence, choose the evidence it needs, build the smallest complete slice, try it by hand, then save through the route the build path requires. Private exploration may end in a simple checkpoint; shared or live work lands through a pull request, so nothing reaches the shared project until you click merge, and the version your team relies on changes only when you type `/ship`.

## The three records

Three project records hold the product's memory: `masterplan.md` is the present, `plan.md` is what's left, `CHANGELOG.md` is the past. `AGENTS.md` sits alongside them as the standing instruction file the agent reads to know how this repository works. The agent reads all of them so you don't have to; [WORKFLOW.md](WORKFLOW.md) explains what goes where.

## Which path will I be on?

| Situation | Likely path |
|---|---|
| Trying an idea with disposable data | Explore privately |
| Internal tool with a manual fallback | Build and run it |
| Outside users, payments, sensitive data, or business-critical reliance | Build with expert help |
| Regulation, irreplaceable live data, high-consequence automation, or technical ownership the team cannot carry | Professional-led |

The path is not a permanent label. The kit rechecks it when the system changes character, and moving up a path means the fit check caught something before the consequences did.

## What keeps it safe

The kit assumes the person directing the work can't review code, so every protection is behavioural or mechanical. It opens with a fit check, which sets the project's build path and names any outside help that path requires. That check runs again whenever the project changes character; the four possible paths are explained in [fit-check.md](.agents/skills/start/references/fit-check.md).

Every promised behaviour gets evidence. Stable rules and bugs usually get automated tests, shown failing first. Visual and exploratory work may be checked by trying it. Shared, live, or risky changes get stronger checkpoints: a pull request with a clean-machine check next to the merge button, and an independent review. The project's build path decides how much of this applies to a given piece of work: a private prototype never gets the full production checks, and `/ship` only performs a real production launch on the path built for one.

Underneath sit the blunt protections. Destructive commands are on a blocked list, alongside standing restrictions like never disabling authentication to make a test pass. Secrets live in `.env` and nowhere else. And `/ship` reads the build path before launching, then refuses or changes shape when the project's own answers say it should.

## Does this fit my project?

The kit is strongest for internal tools: something for your own team, holding your own data, with nobody outside relying on it. Trackers, dashboards, small workflow tools, internal calculators. It can also help define, prototype, and get acceptance criteria for software other people will use; the fit check will say plainly when that production build needs expert help or professional ownership, and name the scope. Nobody should find out at launch what the fit check would have told them at the start.

## Why this and not the alternatives?

Each alternative is good at what it's for. All-in-one builders (Lovable, Bolt, Replit) are the fastest way to a working app, and the trade is that the platform owns the shape of your project, so extending it or leaving gets harder as it grows. Bare agent tools (Claude Code, Cursor, Codex on their own) give you an agent's full power with no process around it, and they'll happily help you build an unmaintainable thing quickly. The developer skill packs (Superpowers, agent-skills) are excellent, and they assume you read code, because they're written for people who do.

This kit carries the same discipline, written for people who don't read code: every check it asks of you is behaviour you can judge by using the tool. It also runs a fit check, which will tell you when your project needs a professional instead of this kit, or alongside it.

## When outside help is needed

The kit is specific about what's needed: a short advice conversation, a scoped review of one named area, a supervised change for one risky event, or professional ownership of the whole build. It prepares the brief and keeps the rest of the project moving, wherever that remains safe, while the flagged part waits.

## What it costs

The kit is free. Building with it needs an agent subscription, which is the real running cost, and accounts with services that mostly start free. `/maintain` watches the bills once you're live.

## For technical people

`.agents/skills/` is the single source of truth. Claude Code, Cursor, and Gemini CLI each get thin, generated adapters that point back at it, so their native slash commands and skills light up; Codex reads the canonical skills directly, guided by an `agents/openai.yaml` policy file beneath each command that disables implicit invocation. The core workflow never depends on an adapter existing; it works through `AGENTS.md`'s load rule in any harness that can read and edit files, run shell commands, and use Git. A skill is a folder in `.agents/skills/` containing a `SKILL.md`: frontmatter description for triggering, numbered steps ending on checkable criteria, stop conditions, and a done-when. `disable-model-invocation: true` on the seven commands prevents Claude from starting a human command automatically; `user-invocable: false` on the four generated Claude discipline skills hides them from the human command menu while leaving them available for a command to compose. Composition is by name: a command's body references a discipline, and the agent loads it.

To extend or adapt, edit the canonical `SKILL.md` and rerun `.agents/tools/build-adapters.sh`; never hand-edit the generated `.claude/`, `.cursor/`, or `.gemini/` folders. [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md) carries the five questions a new capability has to answer before it earns a place, and the examples of ones that didn't.

The machinery that isn't a skill: an optional, report-only session-end hook in `.agents/hooks/`, a command deny list in `.agents/guard/`, and the pull request check in `.github/workflows/checks.yml`, which ships as a placeholder that fails on purpose until `/start` replaces it with the project's real install and test commands. The maintainer source performs its own deeper validation before publishing this starter. [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) maps every tool and every generated file.

The three project records don't exist yet on purpose: `/start` creates `masterplan.md`, `plan.md`, and `CHANGELOG.md` from templates, so a fresh starter begins as a kit, ready to become your project. Maintainer-only files are excluded before a release reaches this repository.

After the project is under way, `/maintain` checks for stable AI Build Kit
updates. It asks before changing anything, updates only kit-owned workflow
files, rebuilds every harness adapter, and leaves the tool and its project
records alone. A conflict or redirected managed folder stops before changes;
after an unexpected application failure, automatic restoration runs when the
computer still permits it, with the required clean checkpoint as the fallback.
