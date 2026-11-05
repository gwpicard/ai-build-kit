#!/usr/bin/env sh
# docker-cleanup.sh: check labelled cleanup on success, failure and signals, and the sweep boundary.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
exec python3 "$ROOT/.agents/tests/lib/docker-cleanup.py"
