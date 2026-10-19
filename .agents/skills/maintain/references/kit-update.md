# Finishing a kit update

From the project root, run `python3 <installed maintain skill>/scripts/upgrade-check.py`,
with `--monthly` when the monthly part runs. It changes nothing. Exit 0:
nothing left. Exit 1: a step is left. Exit 2: it could not run; say so and
carry on. Where the harness cannot run it, change nothing by hand, except to
copy the installed `setup-ai-build-kit` skill's
`templates/foundation/plan-refresh.sh` to `.agents/tools/` where it is missing.

Give its `say` lines in one reply, in order, and keep to these rules:

- Ask once. Make the full offer on the first visit that finds a step and on
  monthly visits, then record `upgrade-offered|<installed VERSION>` in
  `.ai-build-kit-maintenance`. On other visits say only: "The kit update is
  not finished. The earlier /maintain offer still stands." Exit 0 with only
  `mention`, `left` or `secrets` sentences: say them and record the same line.
- Copy each `mention`, `left` and `secrets` sentence you say into the visit's
  changelog line, word for word. On a yes to `secrets`, copy the founding
  template's lines refusing to show a secret into AGENTS.md.
- Apply only on a yes, on the clean checkpoint, with `--apply <step>`. The
  `helper` and `ready` steps need no question. A `missing` line is recovered
  with the update command approved this visit, or offered first. An
  `installer` line is removed with the command it names. Never remove a
  skill, file or folder by hand.
- A `commands` line left as written gets an agent edit: propose the lines from
  the installed founding template, keep the person's own sentences, and change
  only those lines on a yes.
- A `settings` line is the offer of the kit's newer safety rules: on a yes run
  `--apply settings`. Never edit the JSON by hand.
- A `gate` line names one project check or hook that is missing or out of date.
  On a yes run `--apply <gate name>`. On a no run `--decline <gate name>`.
  Each gate is offered separately, and a decline leaves its files as they are.
- A `fitcheck` line loads `risk-move.md` beside this file. Show the move before
  asking.
- A `recipe-format` line offers a move from `Build stack:` to the current
  recipe fields. On a yes, open a piece describing the move. On a no, run
  `--decline recipe-format`; it records the decline without changing project
  instructions.
- An `access` line asks which setting the project wants. A public answer first
  hears what public means, as the fit check says. Record the answer with
  `--apply access=private`, `access=open-address` or `access=public`,
  then run the recipe's `live-check.sh --only access` and say its line. Off
  a recipe, say that the access check cannot run, since no recipe names one.
  Making the live tool match is a live-service change for /setup-hosting.
- On a no, run the check with `--decline <step>`.

Rerun after each step and at the end. Record one dated
changelog line saying what was done and what was declined.

Checks reading kit files: [project-checks.md](project-checks.md).

## The Codex start check

In Codex, offer the session-start GitHub check to an older project missing
it, once the tree is clean. On a yes naming `.codex/hooks.json` and
`.agents/tools/codex-github-check.py`, run the installed
`setup-ai-build-kit` skill's `scripts/setup-codex.py` with `--hooks`, explain that
the person trusts the project and reviews the hook with `/hooks`, then
restarts, and with approval add the template's check-before-work rule to the
top of AGENTS.md. Never bypass the review. A hook pointing at a former
project location is offered the same repair. The marked shell block is
updated or removed with `--shell-install` or `--shell-remove` only on a yes
naming the shell file. Never repeat a declined shell offer.
