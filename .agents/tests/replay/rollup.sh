#!/usr/bin/env sh
# rollup.sh: print the graded replay results as a summary table.

set -eu
REPLAY_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$#" -gt 1 ]; then
  echo "usage: rollup.sh [results-folder]" >&2
  exit 2
fi
python3 "$REPLAY_DIR/rollup.py" "${1:-$REPLAY_DIR/results}"
