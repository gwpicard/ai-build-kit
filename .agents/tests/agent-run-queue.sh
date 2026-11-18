#!/usr/bin/env sh
# agent-run-queue.sh: exercise the maintainer runner against fake Docker and agent commands.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PYTHONPYCACHEPREFIX=${TMPDIR:-/tmp}/abk-runner-test-pyc python3 "$ROOT/.agents/tests/lib/test-agent-run-queue.py"
