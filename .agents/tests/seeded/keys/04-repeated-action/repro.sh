#!/usr/bin/env sh
# repro.sh <tree> <variant>: the independent reproduction for fault key 04.
# SEEDED-KEY-04-5b8e03d7
set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
command -v node >/dev/null 2>&1 || { echo "node is not installed" >&2; exit 2; }
NODE_NO_WARNINGS=1 exec node --experimental-strip-types "$here/repro.mjs" "$@"
