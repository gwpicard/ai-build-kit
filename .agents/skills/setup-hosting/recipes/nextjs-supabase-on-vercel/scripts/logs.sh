#!/usr/bin/env sh
# logs.sh: read the live tool's errors from the last hour.
#
# Usage: logs.sh
#
# Vercel keeps what the tool writes with console.error, and
# `vercel logs --environment production --level error --since 1h --no-branch --json`
# prints one JSON object for each error line. `--no-branch` matters, since the
# command otherwise reads only the current git branch. The Hobby plan keeps
# runtime logs for one hour, so on Hobby this runs within the hour after a
# launch. Each error is printed, so the kit can name the ones from the new
# build.
#
# Exit 0 when the logs were read and hold no error, 1 when they hold errors,
# 2 when they could not be read.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../../scripts/check-lib.sh"

cl_need vercel
out=$(mktemp)
trap 'rm -f "$out"' EXIT
vercel logs --environment production --level error --since 1h --no-branch --json >"$out" 2>/dev/null ||
  cl_cannot "Vercel's logs could not be read, so the kit cannot tell whether the live tool wrote errors."
count=$(python3 - "$out" <<'PY'
import json, sys
count = 0
for line in open(sys.argv[1], errors="replace"):
    line = line.strip()
    if not line.startswith("{"):
        continue
    try:
        entry = json.loads(line)
    except ValueError:
        continue
    count += 1
    print(str(entry.get("message", ""))[:200], file=sys.stderr)
print(count)
PY
)
[ "$count" = 0 ] && cl_pass "The logs are readable, and the live tool wrote no errors in the last hour."
[ "$count" = 1 ] && cl_fail "The live tool wrote 1 error line in the last hour."
cl_fail "The live tool wrote $count error lines in the last hour."
