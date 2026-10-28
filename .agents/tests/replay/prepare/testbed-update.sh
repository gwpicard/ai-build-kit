#!/usr/bin/env sh
# Copy an older project without founding it again or saving unfinished work.
set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
python3 "$here/testbed-update-data.py" seed "${REPLAY_TESTBED_SOURCE:?name a test bed}" "$1" "${REPLAY_TESTBED_KIT:?assembled kit}"
