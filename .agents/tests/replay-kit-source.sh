#!/usr/bin/env sh
# replay-kit-source.sh: run a case with a stand-in Codex and alternate kit source.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
REPLAY="$ROOT/.agents/tests/replay"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
SOURCE="$WORK/old-kit"
mkdir -p "$SOURCE/.agents/tools" "$WORK/bin"
mkdir -p "$WORK/codex-home"
cat > "$SOURCE/.agents/tools/build-release.sh" <<'BUILDER'
#!/usr/bin/env sh
set -eu
version=$1
out=$2
mkdir -p "$out"
printf '%s\n' 'alternate source tree' > "$out/.kit-source-marker"
printf '%s\n' "$version" > "$out/VERSION"
# What the preflight needs to see in any kit: the six commands and the helper.
for name in setup-ai-build-kit shape implement setup-hosting maintain what-now; do
  mkdir -p "$out/.agents/skills/$name"
  printf -- '---\nname: %s\n---\n' "$name" > "$out/.agents/skills/$name/SKILL.md"
done
mkdir -p "$out/.agents/skills/setup-ai-build-kit/templates/foundation"
printf '%s\n' helper > "$out/.agents/skills/setup-ai-build-kit/templates/foundation/codex-github-check.py"
BUILDER
chmod +x "$SOURCE/.agents/tools/build-release.sh"
cat > "$WORK/bin/codex" <<'CODEX'
#!/usr/bin/env sh
set -eu
args="$*"
if printf '%s' "$args" | grep -q -- '--sandbox read-only'; then
  out=
  prev=
  for arg in "$@"; do
    if [ "$prev" = yes ]; then out=$arg; prev=; else [ "$arg" = -o ] && prev=yes; fi
  done
  cat > "$out" <<'JSON'
{"scenario":58,"verdicts":{"Visible explanation":{"verdict":"hit"}},"held":true,"held_note":"stand-in grader"}
JSON
  exit 0
fi
[ -f .kit-source-marker ] || { echo 'case did not receive KIT_SRC output' >&2; exit 4; }
thread=$(python3 -c 'import uuid; print(uuid.uuid4())')
printf '{"type":"thread.started","thread_id":"%s"}\n' "$thread"
printf '%s\n' '{"type":"item.completed","item":{"type":"agent_message","text":"The starter command was refused. Shall I use another route?"}}'
CODEX
chmod +x "$WORK/bin/codex"
PATH="$WORK/bin:$PATH" REPLAY_PROVIDER=codex MODEL=stand-in GRADER_MODEL=stand-in \
  KIT_SRC="$SOURCE" REPEATS=1 JOBS=1 REPLAY_WORK="$WORK/work" \
  CODEX_HOME="$WORK/codex-home" \
  REPLAY_RESULTS="$WORK/results" sh "$REPLAY/run.sh" 58 > "$WORK/run.out" 2>&1 || {
    cat "$WORK/run.out" >&2; exit 1;
  }
grep -q 'Assembling v0.0.0-replay' "$WORK/run.out" || { cat "$WORK/run.out" >&2; exit 1; }
grep -q 'alternate source tree' "$WORK/work/kit/.kit-source-marker" || {
  echo "FAIL: run.sh did not assemble from KIT_SRC" >&2; exit 1;
}
grep -q 'finished scenario 58 run 1' "$WORK/run.out" || { cat "$WORK/run.out" >&2; exit 1; }
echo "ok: harness and case came from this tree while the alternate kit source was assembled"
