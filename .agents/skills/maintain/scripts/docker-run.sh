#!/usr/bin/env sh
# Run a check with its own Docker labels and remove its resources on every exit.
set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CODEX_RUN_ID=${CODEX_RUN_ID:-$(python3 -c 'import uuid; print(uuid.uuid4())')}
ABK_DOCKER_SCOPE=$(python3 -c 'import uuid; print(uuid.uuid4().hex)')
COMPOSE_PROJECT_NAME="abk-$(printf '%s' "$CODEX_RUN_ID" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_-' '-')-$ABK_DOCKER_SCOPE"
export CODEX_RUN_ID ABK_DOCKER_SCOPE COMPOSE_PROJECT_NAME
child=
finish() {
  status=$?
  trap - EXIT HUP INT TERM
  if [ -n "$child" ]; then
    kill -TERM "$child" 2>/dev/null || true
    wait "$child" 2>/dev/null || true
  fi
  python3 "$here/docker-resources.py" clean || status=1
  exit "$status"
}
trap finish EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
python3 "$here/docker-resources.py" run "$@" &
child=$!
status=0
wait "$child" || status=$?
child=
exit "$status"
