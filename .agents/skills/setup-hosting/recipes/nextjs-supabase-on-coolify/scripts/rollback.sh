#!/usr/bin/env sh
# rollback.sh: read back the list of kept images on the app's Rollback page in
# Coolify, to see that an earlier one is there. It never rolls back.
#
# Usage: rollback.sh --pasted <file>
#
# Coolify keeps earlier images until its nightly cleanup, which leaves the two
# newest. The paste is that page's list or the companion's
# `deployment rollback_images` listing. Two or more different commits on it
# mean an earlier image a rollback can reach, so a rollback is possible, not
# tried.
#
# Exit 0 when an earlier image is listed, 1 when only one is, 2 when there is
# no paste or it lists no image by its tag, and then the last line asks again
# in the recipe's words.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

[ "${1:-}" = "--pasted" ] && [ -f "${2:-}" ] ||
  cl_cannot "Nothing was pasted back from the Rollback page yet."
# An image's commit is a run of 7 to 64 hexadecimal characters given as a tag
# after a colon, as a `tag` value in the companion listing, as a sha256 digest,
# or on a line that says image.
count=$(python3 - "$2" <<'PY'
import re, sys
found = set()
for line in open(sys.argv[1], errors="replace"):
    tagged = r"(?:sha256:|(?<=[\w.-]):)([0-9a-f]{7,64})(?![0-9A-Za-z])"
    listed = r"[\"']tag[\"']\s*:\s*[\"'](?:[^\"']*:)?([0-9a-f]{7,64})[\"']"
    loose = r"(?<![0-9A-Za-z])([0-9a-f]{7,64})(?![0-9A-Za-z])"
    patterns = [tagged, listed]
    if re.search(r"\bimages?\b", line, re.I):
        patterns.append(loose)
    for pattern in patterns:
        for m in re.finditer(pattern, line):
            if re.search(r"[a-f]", m.group(1)):
                found.add(m.group(1)[:7])
print(len(found))
PY
)
[ "$count" -gt 0 ] ||
  cl_cannot "The paste lists no image by its tag, so the kit cannot tell whether a rollback is possible. $(cl_ask "$here/../recipe.md" Rollback)"
[ "$count" -ge 2 ] || cl_fail "Only one image is kept, so there is nothing earlier to roll back to yet."
cl_pass "An earlier image is kept on the Rollback page, so a rollback could bring it back."
