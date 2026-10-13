#!/usr/bin/env sh
# logs.sh: read back the error lines from the container's output in Coolify
# since the deployment.
#
# Usage: logs.sh --pasted <file>
#
# The paste is the container's output since the deployment. Coolify writes
# lines of its own into a build log, such as a missing build helper container
# or a warning about orphan containers during a rolling update. Those are not
# the tool's errors and are left out. Every other line naming an error is
# printed, so the kit can name the ones from the new build.
#
# Exit 0 when the output holds no error from the tool, 1 when it does, 2 when
# there is no paste.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../../scripts/check-lib.sh"

[ "${1:-}" = "--pasted" ] && [ -f "${2:-}" ] ||
  cl_cannot "Nothing was pasted back from the container's output yet."
errors=$(grep -i 'error' "$2" | grep -vi 'helper container' | grep -vi 'orphan' || true)
[ -z "$errors" ] && cl_pass "The container's output is readable, and holds no error from the tool since the deployment."
printf '%s\n' "$errors" >&2
count=$(printf '%s\n' "$errors" | wc -l | tr -d ' ')
[ "$count" = 1 ] && cl_fail "The container's output holds 1 error line since the deployment."
cl_fail "The container's output holds $count error lines since the deployment."
