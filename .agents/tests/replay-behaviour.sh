#!/usr/bin/env sh
# replay-behaviour.sh: prove the disk checks of the behaviour scenarios can fail.
#
# Each behaviour scenario, 64 to 81, is read from disk as well as from the
# transcript. A disk check that only ever says hit proves nothing, so this builds
# each end state by hand, once as the contract describes it and once with the fault
# the scenario catches, and asserts the verdict. It also proves the three backbone
# assertions: a merge only at the version its review read, nothing online before a
# yes, and no secret shown. It calls no model and no network.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
command -v python3 >/dev/null 2>&1 || { echo "FAIL: python3 is needed" >&2; exit 2; }
exec python3 "$ROOT/.agents/tests/lib/replay_behaviour.py"
