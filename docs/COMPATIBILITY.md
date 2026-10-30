# COMPATIBILITY.md: one kit across coding agents

## The portable core

AI Build Kit works when the coding agent can read and edit project files, run
shell commands, and use Git. Native skill pickers, slash commands, hooks,
subagents, and command deny lists can improve the experience, but the workflow
does not depend on them.

The kit's skills use the open Agent Skills folder format. Each skill keeps its
own instructions and supporting files together. A command that needs a
background skill loads it by name.

## What is installed

Each skill folder holds its instructions with any references, templates and
scripts it needs. The [installation routes](#choose-one-installation-route)
explain where those folders live and how their source is recorded.

The setup skill carries the project foundation. On its first run it creates
missing project instructions, pointers for coding agents, environment examples,
the helper that prints the work list, Claude Code settings for push and merge
rules, and a placeholder project check. It preserves existing files. The
interview then produces `masterplan.md` and `CHANGELOG.md`, and one GitHub issue
for each piece still to build.

The source repository keeps only the Agent Plugins manifest; packaging adds
the skills to `agent-plugin` in the release archive. This keeps one source copy
of each skill to maintain.

Each numbered release has a matching tag and reviewed notes. `/maintain` reads
the latest published notes before offering an update. The repository also holds
the kit's maintainer tools; they do not ship in the release archive.

## How much has been proved on each agent

Meeting the portable core means the kit should work on an agent. It does not
mean anybody has watched it work there. Each agent this page names carries one
of three grades, so you can see how much evidence sits behind your choice
before you make it.

- **Tested.** The kit's replay harness has driven this agent through whole
  scripted conversations, and the results are on record with the date, the
  kit that was run and the models used. The replay harness is a maintainer
  tool: it sets up a throwaway project, talks to the kit, and grades what the
  kit did against what it promises.
- **Expected to work.** The agent reads the same skill files a tested agent
  reads, and nothing known stops the kit working there. Nobody has recorded a
  graded replay. Its known limits are listed below.
- **Experimental.** Nobody has recorded running the kit on this agent. The
  files it needs ship with the kit, and the only checks on them are checks of
  their shape.

| Coding agent | Grade |
|---|---|
| Claude Code | Tested |
| Codex | Expected to work |
| Cursor | Experimental |
| Gemini CLI | Experimental |
| GitHub Copilot | Experimental |
| Any other coding agent | Experimental |

### Moving up a grade

An agent moves up on evidence and on nothing else. A quiet issue tracker is not
evidence. An absence of complaints may only mean that nobody has tried.

To move from Experimental to Expected to work, somebody runs a published
release on the agent, from a blank folder through founding and one built
piece, and the maintainer writes down what happened and on which release. A
maintainer's own walk-through counts, and so does a report from a real user
that confirms the same.

To move from Expected to work to Tested, the replay harness drives the agent
through the replayed conversations and the rates are recorded beside the
Claude Code ones. The record names the agent the harness drove, and it names a
published release or the commit that release was cut from. The harness can already drive Codex. What Codex lacks is a
recorded run. The harness cannot drive Cursor, Gemini CLI or GitHub Copilot,
so each of them needs that work first.

An agent moves down when a recorded run shows the kit failing there in a way
it does not fail elsewhere.

## Known limits

### What Tested means for Claude Code

Tested describes a rate. The harness runs each conversation several
times and counts how often the kit behaved as promised; some cases succeed
less often than others. One case, a bug that resists repeated fixes, succeeded
in four of five runs on one Claude model and none of five on another. The runs
have no person in them, so a failure they show is a lead to check by hand.

The last time every case was measured together was 25 August 2026. Some cases
have been measured again since, on a changed kit, and the rest have not.

Every Claude Code run on record was on a commit of `main` between two
releases, not on a published release. The record names each commit, so a rate
can be traced to the exact kit it measured. No rate yet describes a release you
can install. From now on, a run that keeps an agent at Tested is recorded
against a published release or the commit that release was cut from.

The plugin route is rehearsed for installing, updating and removing the kit.
Its conversations cannot be replayed, because plugin commands do not load in
the unattended sessions the harness uses. The replayed conversations use the
skills installed into the project, which is the shared installer's route.

### Known limits of Codex

- No graded replay run is recorded. A check proves the harness can start, resume
  and grade a Codex conversation, against a stand-in for Codex and without a
  model. That proves the harness wiring, but provides no evidence about how the
  kit behaves in a graded run. The founding and first-upload run described under
  GitHub access in Codex is recorded, and it was not graded.
- The kit ships no Codex command files. Codex finds the skills in
  `.agents/skills/`, and you start a command by naming it.
- Codex has no result redaction, so a secret that a tool prints reaches the agent.
- Nothing reminds you of a check-up when a session opens. `what-now` reports when
  a visit is overdue.
- There is no kit deny list set up for you. `merge.py` requires a recorded
  approval before it merges; the kit does not show Codex a confirmation box.
  Codex's own approval settings are separate, and you set them yourself.
- The kit does not put background skills in Codex's command menu. Whether Codex
  loads them as intended has not been checked.
- GitHub access depends on the session's network permissions and the CLI's
  sign-in. See [GitHub access in Codex](#github-access-in-codex).

### Known limits of Cursor, Gemini CLI and GitHub Copilot

- Nobody has recorded a run, and the replay harness cannot drive these agents.
- The kit's release carries generated command files for Cursor and Gemini CLI.
  A check confirms each file is there and well formed. Nothing has confirmed
  that the agent lists the six commands, or that it loads a background skill
  when a command asks for one.
- Setup creates the file that points Gemini CLI at `AGENTS.md`,
  and the one that points GitHub Copilot at it. Nobody has confirmed that
  either agent follows that pointer.
- Nothing reminds you of a check-up when a session opens. `what-now` reports when
  a visit is overdue.
- Gemini CLI can hide a result, but cannot keep its original form. Unless
  Gemini is set up to hide it, a secret printed by a tool reaches the agent.
  Cursor cannot replace built-in Bash, Read or Grep results, so a secret they
  print reaches the agent. See the [Cursor hooks reference](https://cursor.com/docs/hooks)
  and [Gemini CLI hooks reference](https://geminicli.com/docs/hooks/reference/).
- There is no kit deny list set up for these agents. `merge.py` requires a
  recorded approval before it merges; the kit does not show a confirmation
  box. Where an agent has command allow and deny settings, you add the kit's
  blocked commands there yourself.
- The kit does not put background skills in the command menu. Whether these
  agents load them as intended has not been checked.

## GitHub access

### GitHub access in Codex

The kit needs a signed-in `gh` with permission to read and change the project's
repository. Check `gh auth status` and `gh repo view` from the agent's command
tool. A working terminal or GitHub connector does not prove that tool has the
same access. A connector can read issues while refusing writes.

Codex can use either the standard sandbox settings or named permission profiles.
Use the system active in your configuration, keep filesystem sandboxing and
allow networking for the workspace. Do not combine the two systems. Start a new
session after changing settings, and check what the client actually selected.
The installed setup skill's
[Codex recovery guide](../.agents/skills/setup-ai-build-kit/references/codex-github.md)
holds the settings and the checks, including managed restrictions.

On macOS a terminal can read the Keychain while sandboxed Codex cannot. Start
each Codex session with the
[session launcher](../.agents/skills/setup-ai-build-kit/scripts/codex-with-github.py)
from your project's ordinary terminal, as the README's install step shows.
It supplies the current login to that Codex process in memory, disables shell
snapshots and sends Git's GitHub sign-ins to `gh` for that process only. No
global Git setting changes, and `gh auth setup-git` is not needed. The recovery
guide holds the agent-facing diagnostics; the scripts give you the exact
restart command when access fails.

**What has been tried (October 2026, macOS).** Plain Codex CLI, with networking
enabled and no token variable, failed both the GitHub account read and Git's
remote read. Signing in again in that session did not help. Sessions started
through the launcher passed both kit checks without changing personal Git or
shell settings. The startup checks now ask only about the active GitHub account,
because checking every saved account failed. One launcher run founded a
disposable notes tool using real private GitHub issues and a local checkpoint.
It then built a piece that passed local tests, type checking and lint, pushed its
branch and opened a pull request, which stayed unmerged. GitHub did not start
the remote project check because of the account's billing limit. These runs
were not graded, so Codex keeps its grade above.

Codex supports project hooks at `.codex/hooks.json`. It loads them only for a
trusted project, and the person reviews each new or changed definition with
`/hooks`. The kit's check returns a stop and a restart sentence on failure,
and no output on success. The project's short instruction runs the same check
while the hook is untrusted or disabled. See [Codex hooks](https://learn.chatgpt.com/docs/hooks).

A failed plan refresh shows a credential-masked GitHub error and a recovery step,
and leaves the previous printout intact.

## Choose one installation route

Every route installs the same AI Build Kit skills. Six are commands you
type: `setup-ai-build-kit`, `shape`, `implement`, `setup-hosting`,
`maintain`, and `what-now`. The others run in the background when a command
needs them: `build-piece`, `clarify`, `evidence-run`, `fit-check`,
`live-copy`, `merge`, `quality-checks`, `records`, `repair`, `research`,
`screen-check`, `second-opinion` and `triage`. The routes differ in how the
skills reach the project, not in what arrives.

A Claude-only project can use the public repository as a Claude Code plugin.
From the project folder, run:

```bash
claude plugin marketplace add gwpicard/ai-build-kit
claude plugin install ai-build-kit@ai-build-kit --scope local
```

The plugin uses local project scope, so it does not replace the project's
shared Claude settings. It exposes the six commands, the background
skills and the kit's agents. The commands use the `ai-build-kit:` prefix, so start with
`/ai-build-kit:setup-ai-build-kit`.

Use the shared skills installer when the project uses Codex, Cursor, Gemini
CLI, another coding agent, or more than one agent. From the project folder,
run:

```bash
npx skills add gwpicard/ai-build-kit
```

The shared [skills installer](https://github.com/vercel-labs/skills) detects
installed coding agents and asks where the project skills should appear. It
keeps one project-level copy and uses the selected coding agent's locations for
discovery. The same command can install the kit for several coding agents used on
one project.

A coding agent that installs plugins in the open
[Agent Plugins](https://agent-plugins.org) format can use the `agent-plugin`
folder. That folder gains its skills when a numbered version is packaged, so
take it from the release archive rather than from a clone of the repository,
and point the agent's own plugin installer at it. It holds a `plugin.json`
manifest and a `skills` folder with the same skills, each carrying its
own supporting files. This is the newest route, and a client may skip a skill
it judges non-standard, so prefer the shared installer when the project has a
choice.

After installation, run `setup-ai-build-kit`. That skill prepares missing project
foundation files before the interview. It preserves existing files, so every
route works for a blank folder and for a project that already has code.

Use one route per project. Do not run two AI Build Kit installations in the
same project. If the project later needs another coding agent, install the
shared skills, confirm they work, then remove the other installation.

## Update the installed skills

During `maintain`, the agent names the version this project records and the
latest published one, reads that release's notes, and asks before changing the
kit. Every route delivers a published release, never work that has not been
released yet. The agent first identifies the installation route.

For the Claude plugin, the approved update is:

```bash
claude plugin marketplace update ai-build-kit
claude plugin update ai-build-kit@ai-build-kit --scope local
```

Claude loads the new plugin after `/reload-plugins` or the next session. The
update replaces the plugin's commands whole, so a command the kit has retired
is gone after that reload.
If the marketplace cannot be reached, the installed version remains enabled.
`maintain` reports that no update happened and tries again later.

The shared installer records project skill sources in `skills-lock.json`. Its
approved update is the same command that installs the kit:

```bash
npx skills add gwpicard/ai-build-kit
```

This refreshes a skill that is installed and adds one that is missing, which
is what carries a project across a rename. The installer's `update` command
is not the route: it refreshes only what the lockfile already lists and drops
any other name without a word, so a project that updated across the rename of
`plan` to `shape` lost one skill and never received the other.

The `add` command keeps a skill the kit has retired, such as `fix`, `queue`,
`sync` and `ship` after the move to six commands, and the lockfile still lists
it. `maintain` offers to remove each one with `npx skills remove`, which
removes the folder, its links and its lockfile entry. It runs that command only
with the person's approval.

That command replaces the installed skill files outright. Before replacement,
`maintain` compares them with the released copies recorded by the proposed
release, including edits already committed. It names files that match no
recorded copy and asks before overwriting them. A project rule belongs in
`AGENTS.md`; updates change it only with approval, for a renamed command or
a new safety rule.

An Agent Plugins installation belongs to the coding agent that installed it,
so use that agent's own plugin update command. When the agent has none,
download the latest public Release and replace the installed `agent-plugin`
folder, after a clean checkpoint and explicit approval.

Every route leaves application code, `AGENTS.md`, `README.md`, the three
project records, environment files, and the project check under the project's
control.

Projects created before this installation model may not have
`skills-lock.json`. The same command registers the installed skills on the
next `maintain` visit, and later visits use it again.

## Coding agent map

The shared installer sets the file locations and symlinks. Its current project
paths are:

| Coding agent | Project skill location | Standing instructions |
|---|---|---|
| Claude Code, shared installer | `.claude/skills/` | `CLAUDE.md` points to `AGENTS.md` |
| Claude Code, plugin | Claude's plugin cache | the six commands use the `ai-build-kit:` prefix; the background skills stay out of the menu |
| Codex | `.agents/skills/` | reads `AGENTS.md` |
| Cursor | `.agents/skills/` | reads `AGENTS.md` |
| Gemini CLI | `.agents/skills/` | `GEMINI.md` points to `AGENTS.md` |
| GitHub Copilot | `.agents/skills/` | `.github/copilot-instructions.md` points to `AGENTS.md` |

Another coding agent may work through the same portable files. It stays
Experimental until somebody records a run on it.

The setup-ai-build-kit skill creates missing standing-instruction pointers. It does not
replace an existing coding agent configuration.

Use the coding agent's skill picker or ask for a skill by name. When native
discovery is unavailable, open `.agents/skills/<name>/SKILL.md` directly and
follow it.

## Who may start a command

You can type one of the six commands, name it anywhere in a message, or just
say what you want done in your own words. The agent starts the right command
and tells you which one it is running. It never starts one you did not ask for.

The background skills run when a command needs them. The kit marks them so
that you cannot pick one yourself, where your coding agent enforces that.

## Agents

Some work goes better in a fresh context that has not seen the conversation so
far. The kit has four agents for that, and a command starts each one; you
never type them.

- `reviewer` looks at the founding masterplan or a piece's change with
  the `second-opinion` skill. It has not seen how the work was built.
- `builder` builds one ready piece with the `build-piece` skill, one piece at
  a time, during `/implement auto`.
- `researcher` checks one outside fact, or looks for existing work, with the
  `research` skill.
- `refuter` checks whether a review finding is wrong, with the `second-opinion`
  skill.

Each agent has one brief in `.agents/agents/`. The kit generates a file for
each coding agent that reads its own: `.claude/agents/`, which Cursor and VS
Code also read, `.codex/agents/`, `.gemini/agents/` and `.github/agents/`.
The release archive and the Claude Code plugin carry them. The shared skills
installer and the Agent Plugins folder carry skills only. For a review on
those routes, `second-opinion` starts an ordinary fresh subagent and tells it
to load the `second-opinion` skill with the same review inputs.

The reviewer, refuter and researcher only read. Enforcement depends on the
coding agent:

| Coding agent | What keeps a read-only agent from changing files |
|---|---|
| Claude Code | Its tool list has no editing tool. A review agent keeps the command line, because a review runs commands. The review guard restores changed files under review and reports other changes; if it cannot run, the agent reports that limit. |
| Cursor | `readonly: true` in the agent's file: no edits, and no command that changes anything. |
| Gemini CLI | Its tool list contains only reading and searching tools, with no command line. |
| GitHub Copilot | Its tool list holds reading, searching and the web, with no editing or commands. |
| Codex | Nothing in the agent's file. Codex keeps the session's own sandbox and approval settings for every agent. The brief instructs the agent to read only; the review guard restores changed files under review and reports other changes, or reports that it could not run. |

VS Code reads agents from both `.github/agents/` and `.claude/agents/`, and
Cursor from `.claude/agents/` and `.codex/agents/`. Each may list the kit's
agents twice. They are the same agents, and either copy runs the same brief.

Where a coding agent cannot start a subagent at all, the command runs the same
brief headless, with `claude -p`, `codex exec` or `gemini -p`. Failing that,
you open a clean chat and paste the one line the command gives you.

## Manual fallback

If the computer cannot run `npx`, download the latest public Release and copy
its `.agents/skills` directory into the project's `.agents/skills` directory.
Then ask the agent:

> Open `.agents/skills/setup-ai-build-kit/SKILL.md` and run the setup-ai-build-kit skill.

A later manual update replaces only the AI Build Kit skill folders,
after a clean checkpoint and explicit approval.

## Optional coding agent features

| Capability | Portable behaviour | Optional enhancement |
|---|---|---|
| Command invocation | Ask for a skill by name | Native skill picker or slash command |
| Background skills | Command loads the named skill | Automatic skill triggering |
| Independent review | A clean separate chat with a prepared instruction | The reviewer agent, another subagent, or a headless run |
| Unsaved work | `what-now` reports what it belongs to | Session-end reminder |
| Check-up due | `what-now` reports when a visit is overdue | Said automatically when a session opens |
| Safety | Standing restrictions and approval gates | Mechanical command deny list |
| Merge | By default, approval for that merge; recorded automatic merging is available with its limits. `merge.py` blocks merging while the project check is failing or review boxes are open | Claude Code blocks raw merge commands |
| Long runs | Normal sequential work | Native goal or orchestration mode |

During `setup-ai-build-kit`, the capability check records which enhancements the current
coding agent provides and selects a fallback for anything absent. Missing optional
automation reduces convenience. Autonomy remains off unless it is recorded in
the project's `Runs on its own:` setting and the coding agent can enforce its limits.

`setup-ai-build-kit` writes the session-start wiring only into a Claude settings file it
creates itself, and never into one that already exists. A project whose Claude
settings predate AI Build Kit keeps them exactly as they are, and its check-up
reminder arrives through `what-now`.
