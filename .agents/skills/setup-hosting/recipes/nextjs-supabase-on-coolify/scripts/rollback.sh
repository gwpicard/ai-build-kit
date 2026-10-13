#!/usr/bin/env sh
# rollback.sh: read back the list of kept images on the app's Rollback page in
# Coolify, to see that an earlier one is there. It never rolls back.
#
# Usage: rollback.sh --pasted <file>
#
# Coolify keeps earlier images until its nightly cleanup, which leaves the two
# newest. The paste is that page's list. Two or more different commits on it
# mean an earlier image a rollback can reach, so a rollback is possible, not
# tried. The rollback itself is always a click on that page, by the person or
# the companion.
#
# Exit 0 when an earlier image is listed, 1 when only one is, 2 when there is
# no paste or it lists no commit.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

[ "${1:-}" = "--pasted" ] && [ -f "${2:-}" ] ||
  cl_cannot "Nothing was pasted back from the Rollback page yet."
# A commit is a run of 7 to 40 hexadecimal characters holding at least one
# letter, so a date or a time on the page is not counted as one.
count=$(python3 - "$2" <<'PY'
import re, sys
text = open(sys.argv[1], errors="replace").read()
found = {m.group(0)[:7] for m in re.finditer(r"(?<![0-9A-Za-z])[0-9a-f]{7,40}(?![0-9A-Za-z])", text)
         if re.search(r"[a-f]", m.group(0))}
print(len(found))
PY
)
[ "$count" -gt 0 ] || cl_cannot "The paste lists no image by its commit, so the kit cannot tell whether a rollback is possible."
[ "$count" -ge 2 ] || cl_fail "Only one image is kept, so there is nothing earlier to roll back to yet."
cl_pass "An earlier image is kept on the Rollback page, so a rollback could bring it back."
