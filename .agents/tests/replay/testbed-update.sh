#!/usr/bin/env sh
# testbed-update.sh: visit copies of older test beds with the current kit.
set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec python3 "$here/testbed-update-run.py" "$@"
