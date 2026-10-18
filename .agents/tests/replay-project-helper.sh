#!/usr/bin/env sh
# replay-project-helper.sh: check founded replay projects get the kit's helper.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=${TMPDIR:-/tmp}/abk-replay-helper-$$
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
mkdir -p "$WORK/kit/.agents/skills/setup-ai-build-kit/templates/foundation" \
  "$WORK/worktree/.agents/skills/setup-ai-build-kit/templates/foundation" \
  "$WORK/project"

printf '%s\n' 'assembled kit helper' > \
  "$WORK/kit/.agents/skills/setup-ai-build-kit/templates/foundation/codex-github-check.py"
printf '%s\n' 'worktree decoy helper' > \
  "$WORK/worktree/.agents/skills/setup-ai-build-kit/templates/foundation/codex-github-check.py"

sh "$ROOT/.agents/tests/replay/prepare/install-project-helper.sh" \
  "$WORK/project" "$WORK/kit"
cmp -s \
  "$WORK/kit/.agents/skills/setup-ai-build-kit/templates/foundation/codex-github-check.py" \
  "$WORK/project/.agents/tools/codex-github-check.py" \
  || { echo "FAIL: prepared project did not get the assembled kit helper" >&2; exit 1; }

# A founded project also carries the plan helper. A kit that ships none is an
# older release, and its projects have none, so that is not a fault.
[ ! -e "$WORK/project/.agents/tools/plan-refresh.sh" ] \
  || { echo "FAIL: a plan helper appeared from a kit that has none" >&2; exit 1; }
printf '%s\n' 'assembled plan helper' > \
  "$WORK/kit/.agents/skills/setup-ai-build-kit/templates/foundation/plan-refresh.sh"
mkdir -p "$WORK/project2"
sh "$ROOT/.agents/tests/replay/prepare/install-project-helper.sh" \
  "$WORK/project2" "$WORK/kit"
cmp -s \
  "$WORK/kit/.agents/skills/setup-ai-build-kit/templates/foundation/plan-refresh.sh" \
  "$WORK/project2/.agents/tools/plan-refresh.sh" \
  || { echo "FAIL: prepared project did not get the assembled kit's plan helper" >&2; exit 1; }

run="$ROOT/.agents/tests/replay/run.sh"
grep -Fq '"$REPLAY_DIR/prepare/install-project-helper.sh" "$project" "$KIT"' "$run" \
  || { echo "FAIL: replay runner does not take the helper from its assembled kit" >&2; exit 1; }
grep -Fq 'if [ "$setup" = "blank" ] && [ -z "$prepare" ]; then' "$run" \
  || { echo "FAIL: blank projects still start with the foundation AGENTS.md" >&2; exit 1; }
grep -Fq 'rm -f "$project/AGENTS.md"' "$run" \
  || { echo "FAIL: blank founding does not remove the copied foundation instructions" >&2; exit 1; }
grep -Fq 'codex-github-check.py|.agents/tools/codex-github-check.py' \
  "$ROOT/.agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh" \
  || { echo "FAIL: setup bootstrap no longer installs the project helper" >&2; exit 1; }
for case_number in 5 31; do
  case_file=$(printf '%s/.agents/tests/replay/cases/%02d.txt' "$ROOT" "$case_number")
  grep -q '^# setup: blank$' "$case_file" \
    || { echo "FAIL: case $case_number is no longer a blank founding case" >&2; exit 1; }
done

echo "PASS: founded projects get the helper from the assembled kit; blank founding can install it itself"
