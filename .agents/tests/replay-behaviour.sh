#!/usr/bin/env sh
# replay-behaviour.sh: prove the disk checks of the behaviour scenarios can fail.
#
# Each behaviour scenario, 64 to 81, is read from disk as well as from the
# transcript. A disk check that only ever says hit proves nothing, so this builds
# each end state by hand, once as the contract describes it and once with the fault
# the scenario catches, and asserts the verdict. It also proves the three backbone
# assertions: a merge only at the version its review read, nothing online before a
# yes, and no secret shown. It calls no model and no network.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
command -v python3 >/dev/null 2>&1 || { echo "FAIL: python3 is needed" >&2; exit 2; }
exec python3 "$ROOT/.agents/tests/lib/replay_behaviour.py"
