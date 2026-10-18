#!/usr/bin/env sh
# replay-preflight.sh: prove a run the harness breaks is "could not run", never a pass or a fail.
#
# The replay harness spends a model call on every turn, so a fault in the harness
# itself has to be found before the first one and, where it comes later, written
# down as a run that could not run. This breaks the harness in the ways that have
# happened or could: a stand-in command a login shell hides behind the real one, a
# kit without the helper a founded project carries, a case with no case file, a
# coding agent that is not installed, and a project whose preparation fails. Each
# must end in exit 2 and a result that says could not run. Nothing here calls a model.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
REPLAY="$ROOT/.agents/tests/replay"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

pass() { echo "ok: $1"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

# A kit with just what the preflight reads: the six commands and the helper.
KIT="$WORK/kit"
for command_name in setup-ai-build-kit shape implement setup-hosting maintain what-now; do
  mkdir -p "$KIT/.agents/skills/$command_name"
  printf -- '---\nname: %s\n---\n' "$command_name" > "$KIT/.agents/skills/$command_name/SKILL.md"
done
mkdir -p "$KIT/.agents/skills/setup-ai-build-kit/templates/foundation"
printf 'helper\n' > "$KIT/.agents/skills/setup-ai-build-kit/templates/foundation/codex-github-check.py"

# A coding agent that exists, and nothing else of the person's tools.
BIN="$WORK/bin"
mkdir -p "$BIN"
printf '#!/bin/sh\nexit 0\n' > "$BIN/claude"
chmod +x "$BIN/claude"

# preflight <kit> <case numbers...>: run it with the harness's own profiles.
preflight() {
  (
    set -eu
    REPLAY_DIR="$REPLAY"
    . "$REPLAY/lib.sh"
    GH_DIR="$REPLAY/fake-github"
    HOST_DIR="$REPLAY/fake-host"
    REPLAY_PROVIDER=${PREFLIGHT_PROVIDER:-claude}
    WORK="$WORK/run"
    RESULTS="$WORK/run/results"
    . "$REPLAY/provider.sh"
    mkdir -p "$WORK"
    provider_prepare
    if [ -n "${PREFLIGHT_DECOY:-}" ]; then
      printf 'export PATH="%s:$PATH"\n' "$PREFLIGHT_DECOY" >> "$REPLAY_SHELL_HOME/bash-env"
      printf 'export PATH="%s:$PATH"\n' "$PREFLIGHT_DECOY" >> "$REPLAY_SHELL_HOME/.zprofile"
    fi
    export GH_DIR HOST_DIR REPLAY_PROVIDER WORK RESULTS
    PATH="${PREFLIGHT_PATH:-$BIN:$PATH}" sh "$REPLAY/preflight.sh" "$@"
  )
}

kit=$KIT
code=0
preflight "$kit" 64 70 >"$WORK/out" 2>&1 || code=$?
[ "$code" -eq 0 ] || { cat "$WORK/out" >&2; fail "a sound harness was refused (exit $code)"; }
pass "a sound harness passes the preflight"

# A real gh a login shell finds before the stand-in is the fault that turned a
# whole pass into a run of the wrong tool.
mkdir -p "$WORK/decoy"
printf '#!/bin/sh\necho "To get started with GitHub CLI, please run: gh auth login"\n' > "$WORK/decoy/gh"
chmod +x "$WORK/decoy/gh"
code=0
( PREFLIGHT_DECOY="$WORK/decoy"; export PREFLIGHT_DECOY; preflight "$kit" 64 ) >"$WORK/out" 2>&1 || code=$?
[ "$code" -eq 2 ] && grep -q 'before the stand-in' "$WORK/out" \
  || { cat "$WORK/out" >&2; fail "a gh found before the stand-in was not caught (exit $code)"; }
pass "a gh found before the stand-in is could not run"

# A kit without the foundation helper stops every prepared project at its startup check.
rm "$KIT/.agents/skills/setup-ai-build-kit/templates/foundation/codex-github-check.py"
code=0
preflight "$kit" 64 >"$WORK/out" 2>&1 || code=$?
[ "$code" -eq 2 ] && grep -q 'no foundation helper' "$WORK/out" \
  || { cat "$WORK/out" >&2; fail "a kit with no helper was not caught (exit $code)"; }
pass "a kit with no foundation helper is could not run"
printf 'helper\n' > "$KIT/.agents/skills/setup-ai-build-kit/templates/foundation/codex-github-check.py"

rm -r "$KIT/.agents/skills/what-now"
code=0
preflight "$kit" 64 >"$WORK/out" 2>&1 || code=$?
[ "$code" -eq 2 ] && grep -q 'no what-now command' "$WORK/out" \
  || { cat "$WORK/out" >&2; fail "a kit with a command missing was not caught (exit $code)"; }
pass "a kit with a command missing is could not run"
mkdir -p "$KIT/.agents/skills/what-now"
printf -- '---\nname: what-now\n---\n' > "$KIT/.agents/skills/what-now/SKILL.md"

code=0
preflight "$kit" 64 999 >"$WORK/out" 2>&1 || code=$?
[ "$code" -eq 2 ] && grep -q 'scenario 999 has no case file' "$WORK/out" \
  || { cat "$WORK/out" >&2; fail "a case with no case file was not caught (exit $code)"; }
pass "a case with no case file is could not run"

# Only the tools the preflight itself needs, so a Codex CLI on this computer is not found.
mkdir -p "$WORK/limited"
for tool in python3 git awk sed grep find sh bash zsh cat tr dirname basename mkdir rm; do
  found=$(command -v "$tool" 2>/dev/null || true)
  [ -z "$found" ] || ln -sf "$found" "$WORK/limited/$tool"
done
code=0
( PREFLIGHT_PROVIDER=codex; PREFLIGHT_PATH="$WORK/limited"; export PREFLIGHT_PROVIDER PREFLIGHT_PATH
  preflight "$kit" 64 ) >"$WORK/out" 2>&1 || code=$?
[ "$code" -eq 2 ] && grep -q 'Codex CLI is not installed' "$WORK/out" \
  || { cat "$WORK/out" >&2; fail "a missing coding agent was not caught (exit $code)"; }
pass "a coding agent that is not installed is could not run"

# The whole runner, with a project whose preparation fails. It must write a result
# that says could not run, and exit 2 because nothing was graded.
TREE="$WORK/tree"
mkdir -p "$TREE/.agents/tests"
cp -R "$REPLAY" "$TREE/.agents/tests/replay"
cp "$ROOT/.agents/tests/scenarios.md" "$TREE/.agents/tests/scenarios.md"
mkdir -p "$TREE/.agents/tests/replay/cases"
rm -f "$TREE/.agents/tests/replay/cases/"*.txt
cp "$REPLAY/cases/80.txt" "$TREE/.agents/tests/replay/cases/80.txt"
{
  printf '# setup: fixture\n# prepare: breaks\n'
  grep -v '^# setup:' "$REPLAY/cases/80.txt"
} > "$TREE/.agents/tests/replay/cases/80.txt"
printf '#!/bin/sh\necho "this preparation cannot work" >&2\nexit 1\n' > "$TREE/.agents/tests/replay/prepare/breaks.sh"
code=0
PATH="$BIN:$PATH" KIT_SRC="$ROOT" REPEATS=1 JOBS=1 \
  REPLAY_WORK="$WORK/pass" REPLAY_RESULTS="$WORK/results" \
  sh "$TREE/.agents/tests/replay/run.sh" 80 >"$WORK/out" 2>&1 || code=$?
[ "$code" -eq 2 ] || { cat "$WORK/out" >&2; fail "a run whose preparation failed did not exit 2 (exit $code)"; }
grep -q 'could not run' "$WORK/results/s80-r1.json" 2>/dev/null \
  || { cat "$WORK/out" >&2; fail "a run whose preparation failed left no could-not-run result"; }
grep -q 'Runs graded: 0. Runs that could not run: 1' "$WORK/out" \
  || { cat "$WORK/out" >&2; fail "the pass did not say how many runs could not run"; }
pass "a run whose preparation fails is written as could not run, and a pass with nothing graded exits 2"

# And the roll-up keeps such a run out of the rate.
mkdir -p "$WORK/roll"
printf '%s\n' '{"scenario":80,"error":"could not run: preparing the project failed before the first turn"}' > "$WORK/roll/s80-r1.json"
printf '%s\n' '{"scenario":80,"held":true,"verdicts":{}}' > "$WORK/roll/s80-r2.json"
sh "$REPLAY/rollup.sh" "$WORK/roll" > "$WORK/rolled"
grep -q 'Scenario 80   no-notice control, false alarms 0/1' "$WORK/rolled" \
  && grep -q 'could not run (neither a pass nor a fail' "$WORK/rolled" \
  || { cat "$WORK/rolled" >&2; fail "the roll-up counted a run that could not run"; }
pass "the roll-up leaves a run that could not run out of the rate and says so"

echo "PASS: a run the harness breaks is could not run, never a pass or a fail"
