#!/usr/bin/env sh
# skill-size-rehearsal.sh: prove a ref produces per-skill counts and a total.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/tests/replay/skill-size.sh"
output=$("$SCRIPT" HEAD)
printf '%s\n' "$output" | grep -q '^TOTAL ' || { echo "$output" >&2; exit 1; }
printf '%s\n' "$output" | grep -q '^setup-ai-build-kit ' || { echo "$output" >&2; exit 1; }
lines=$(printf '%s\n' "$output" | wc -l | tr -d ' ')
[ "$lines" -gt 5 ] || { echo "FAIL: no per-skill breakdown" >&2; exit 1; }
if "$SCRIPT" definitely-not-a-git-ref >/dev/null 2>&1; then
  echo "FAIL: invalid ref was accepted" >&2; exit 1
fi
echo "ok: ref output has per-skill word counts, a total and rejects unknown refs"
