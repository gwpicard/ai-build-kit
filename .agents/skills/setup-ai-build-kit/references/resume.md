# Resume safely

In Codex, before anything else, run this skill's
`templates/foundation/codex-github-check.py` with `python3`. On failure, give
its restart sentence and stop; do not sign in again or retry.

Run `scripts/bootstrap-project.sh` from this installed skill folder in the
project root. It creates only missing foundation files and never replaces one.
If the harness cannot run it, copy the missing files from
`templates/foundation/` to the paths it names. Where an existing `AGENTS.md`
lacks the installed-skill load rule, keep its instructions and add the
smallest compatible rule. If the script reports both a plugin and a separate
kit installation, stop and keep one: the plugin for one coding agent, the
shared skills for several. A broken link: say so plainly and offer to install
the kit again the same way. A setup note: say it once and record it as an open
question.

In Codex, run `scripts/setup-codex.py` with python3 and `--hooks` and say: "The
GitHub check runs when Codex starts; trust this project and review its hook
with /hooks, then restart." Never trust it for the person. On macOS, also run
it with `--shell-status` and give its offer once, outside the interview. On a
yes naming the file, run `--shell-install`; on a no, `--shell-decline`. Both
record the answer, so it is never asked again.

A folder holding `.ai-build-kit-version` is an installation waiting for a
project: found here without asking, however much it looks like the kit's
source. Only where `release-manifest.txt`, `.agents/tests/` and
`docs/MAINTAINING.md` sit at the root is this the kit's own source: stop and
say which of them you found. Never wait on a location otherwise.

Read the current state: whether masterplan.md, CHANGELOG.md and the pieces
exist, whether any look half-written, a placeholder still in
`.github/workflows/checks.yml`, uncommitted changes, an open question in the
changelog. Say where you are resuming from. Never overwrite a record without
saying so and getting agreement. Where `.agents/tmp/setup-notes.md` exists and
masterplan.md does not, say you are carrying on from those answers, read them
back as one short list, and wait for a yes.
