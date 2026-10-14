#!/usr/bin/env sh
# access.sh: check that who can reach the live tool matches the masterplan's
# Access: line, from what was pasted back about the server and from the
# kit's own read of sign-up. It changes nothing.
#
# Usage: access.sh --pasted <file>
#
# The paste is what a request signed in to nothing got from the live
# address's /api/health, from a computer outside the team's private network:
# the number `curl -sS -o /dev/null -w '%{http_code}'` prints, or its error.
# 401 means Coolify's HTTP Basic Authentication stands in front. No
# connection, or a name that does not resolve, means the address is reached
# only over the private network. Either is the gate private needs. 200 means
# anyone reaches it, which public needs. The shared signup.sh reads sign-up
# itself: closed for private, and for public by invitation only.
#
# Exit 0 when both match the record, 1 when one does not, 2 when there is no
# paste, it cannot be read, or no setting is recorded.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

record=$(cl_access)
[ -n "$record" ] || cl_cannot "The masterplan records no access setting, so there is nothing to compare the live tool with."
ask=$(cl_ask "$here/../recipe.md" Access)
[ "${1:-}" = "--pasted" ] && [ -f "${2:-}" ] ||
  cl_cannot "Nothing was pasted back about who can reach the live address yet. $ask"
setting=${record% *}
gate=$(python3 - "$2" <<'PY'
import re, sys
text = open(sys.argv[1], errors="replace").read().lower()
if re.search(r"could not resolve|failed to connect|couldn't connect|timed out|connection refused|\b000\b", text):
    print("gated")
elif re.search(r"\b40[13]\b", text):
    print("gated")
elif re.search(r"\b200\b", text):
    print("open")
else:
    print("unknown")
PY
)
[ "$gate" != unknown ] || cl_cannot "The paste holds no answer the kit can read. $ask"

signup_line=$(sh "$here/../../parts/scripts/signup.sh" "${record#* }")
signup=$?
if [ "$setting" = private ] && [ "$gate" = open ]; then
  cl_fail "The live address answers anyone who is not signed in, though the record says private."
fi
if [ "$setting" = public ] && [ "$gate" = gated ]; then
  cl_fail "The live address turns away anyone who is not signed in, though the record says public."
fi
case $signup in
  0) ;;
  1) cl_fail "$signup_line" ;;
  *) cl_cannot "Who can reach the live address matches the record, but sign-up could not be read. $signup_line" ;;
esac
[ "$setting" = private ] &&
  cl_pass "Private, as recorded: the live address turns away anyone outside the team's gate, and $(printf '%s' "$signup_line" | sed 's/^S/s/')"
cl_pass "Public, as recorded: the live address answers anyone. $signup_line"
