#!/usr/bin/env sh
# preflight.sh: find out before a pass whether the harness can run at all.
#
# A run the harness breaks measures the harness. Once, every run of the older kit
# stopped at a missing startup check in the test project, and the comparison
# proved nothing. A model call costs time, so the cheap faults are found first:
# a missing tool, a stand-in the person's own tools would hide, a kit without
# the helpers a founded project carries, a case with no contract or no turns.
#
# Usage: preflight.sh <assembled-kit-folder> <case number>...
# Needs REPLAY_PROVIDER, GH_DIR, HOST_DIR and REPLAY_SHELL_HOME, and the folder
# provider_prepare writes the throwaway shell profiles into.
#
# Exit 0: nothing found. Exit 2: could not run. It never exits 1, because a
# broken harness is neither a pass nor a fail of the kit.

REPLAY_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$REPLAY_DIR/lib.sh"
. "$REPLAY_DIR/turn-gate.sh"
. "$REPLAY_DIR/provider.sh"

kit=${1:-}
[ "$#" -gt 0 ] && shift
problems=""
problem() { problems="$problems
  could not run: $1"; }

# The tools a run is built from.
for tool in python3 git awk sed grep find; do
  command -v "$tool" >/dev/null 2>&1 || problem "$tool is not installed"
done

# The coding agent the run drives.
REPLAY_PROVIDER=${REPLAY_PROVIDER:-claude}
case "$REPLAY_PROVIDER" in
  claude) command -v claude >/dev/null 2>&1 || problem "Claude Code is not installed" ;;
  codex) command -v codex >/dev/null 2>&1 || problem "Codex CLI is not installed" ;;
  *) problem "REPLAY_PROVIDER must be 'claude' or 'codex', not '$REPLAY_PROVIDER'" ;;
esac

# The assembled kit is a folder with the six commands and the helpers a founded
# project is given. Without the Codex helper, run.sh cannot prepare a project.
if [ -z "$kit" ] || [ ! -d "$kit/.agents/skills" ]; then
  problem "the assembled kit is missing or holds no skills"
else
  for command_name in setup-ai-build-kit shape implement setup-hosting maintain what-now; do
    [ -f "$kit/.agents/skills/$command_name/SKILL.md" ] \
      || problem "the assembled kit has no $command_name command"
  done
  [ -f "$kit/.agents/skills/setup-ai-build-kit/templates/foundation/codex-github-check.py" ] \
    || problem "the assembled kit has no foundation helper, so a prepared project would stop at its startup check"
fi

# The kit's first instruction names what to read at the top of the masterplan.
# The fixtures carry a risk record, and prepare/legacy-masterplan.py writes the
# build-path section an older release reads. Any other first read is a section the
# fixtures cannot give, and every run would stop at the kit's own startup check.
if [ -f "$kit/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md" ]; then
  startup=$(sed -n 's/.*[Rr]ead the \([^`]*\) at the top of `masterplan.md`.*/\1/p' \
    "$kit/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md" | head -n 1)
  case "$startup" in
    "risk record") : ;;
    "build-path section")
      probe="${TMPDIR:-/tmp}/preflight-masterplan-$$"
      cp "$REPLAY_DIR/fixture/masterplan.md" "$probe"
      python3 "$REPLAY_DIR/prepare/legacy-masterplan.py" "$probe" >/dev/null 2>&1 \
        && grep -q '^## Build path' "$probe" \
        || problem "the kit reads a build-path section, and the fixture cannot be given one"
      rm -f "$probe"
      ;;
    "") problem "the kit's foundation instructions name no section of the masterplan to read first" ;;
    *) problem "the kit starts by reading the $startup of the masterplan, which the replay fixture does not provide" ;;
  esac
fi

# The GitHub stand-in has to be the command a login shell finds first, and it
# has to answer as a stand-in. The real command answers as a signed-out tool,
# and the kit then works without pull requests or issues.
if [ -z "${GH_DIR:-}" ] || [ ! -x "$GH_DIR/gh" ]; then
  problem "the GitHub stand-in is missing or not runnable"
else
  want=$(CDPATH= cd -- "$GH_DIR" && pwd -P)/gh
  if [ -n "${BASH_ENV:-}" ] && command -v bash >/dev/null 2>&1; then
    found=$(BASH_ENV="$BASH_ENV" bash -c 'command -v gh' 2>/dev/null || true)
    [ "$(CDPATH= cd -- "$(dirname -- "${found:-/nonexistent}")" 2>/dev/null && pwd -P)/gh" = "$want" ] \
      || problem "a bash shell finds ${found:-no gh} before the stand-in at $GH_DIR/gh"
  fi
  if [ -n "${ZDOTDIR:-}" ] && command -v zsh >/dev/null 2>&1; then
    found=$(ZDOTDIR="$ZDOTDIR" zsh -lc 'command -v gh' 2>/dev/null | tail -n 1 || true)
    [ "$(CDPATH= cd -- "$(dirname -- "${found:-/nonexistent}")" 2>/dev/null && pwd -P)/gh" = "$want" ] \
      || problem "a zsh login shell finds ${found:-no gh} before the stand-in at $GH_DIR/gh"
  fi
  answer=$(FAKE_GH_STATE=/nonexistent/preflight.json FAKE_GH_LOG=/dev/null \
    "$GH_DIR/gh" auth status 2>&1 || true)
  printf '%s\n' "$answer" | grep -qF "$REAL_GH_SIGNED_OUT" \
    && problem "the GitHub stand-in answers as the real signed-out command"
  printf '%s\n' "$answer" | grep -qF "$REAL_GH_NO_HOSTS" \
    && problem "the GitHub stand-in answers as the real signed-out command"
fi

# Somewhere to write.
for folder in "${WORK:-}" "${RESULTS:-}"; do
  [ -n "$folder" ] || continue
  mkdir -p "$folder" 2>/dev/null
  probe="$folder/.preflight-$$"
  { : > "$probe"; } 2>/dev/null && rm -f "$probe" || problem "$folder cannot be written to"
done

# Every case has a contract, at least one turn, a known setup and a preparation
# that exists. A case that fails here would otherwise die inside a run with no
# result file, and a missing result is read as nothing happening.
for number in "$@"; do
  padded=$(printf '%02d' "$number")
  casefile="$REPLAY_DIR/cases/$padded.txt"
  if [ ! -f "$casefile" ]; then
    problem "scenario $number has no case file"
    continue
  fi
  [ -n "$(scenario_title "$number")" ] || problem "scenario $number has no contract in scenarios.md"
  setup=$(awk -F': *' '/^# setup:/ { print $2; exit }' "$casefile")
  case "$setup" in
    blank|fixture) : ;;
    *) problem "case $padded names the setup '$setup', which is neither blank nor fixture" ;;
  esac
  turns=$(awk '
    /^#/ { next }
    /^---$/ { if (started) { count++; started = 0 } next }
    { started = 1 }
    END { if (started) count++; print count + 0 }
  ' "$casefile")
  [ "$turns" -gt 0 ] || problem "case $padded holds no turns"
  prepare=$(case_prepare "$casefile")
  if [ -n "$prepare" ] && [ ! -f "$REPLAY_DIR/prepare/$prepare.sh" ]; then
    problem "case $padded names the preparation '$prepare', which does not exist"
  fi
done

if [ -n "$problems" ]; then
  printf 'Preflight found what stops a run:%s\n' "$problems" >&2
  exit 2
fi
echo "Preflight: the harness can run"
exit 0
