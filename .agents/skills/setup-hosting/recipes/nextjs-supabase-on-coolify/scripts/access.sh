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
# Where that could not connect, the paste also holds what the same request
# got from a computer inside the private network.
#
# The first answer in the paste is the one from outside. 401 or 403 means a
# password stands in front, which is the gate private needs. 200 means anyone
# reaches it, which the other two settings need. A failure to connect proves
# nothing alone, since the server may simply be down, so it counts as the
# gate only when a later answer in the paste, from inside, shows the address
# answering there. The shared signup.sh reads sign-up itself: closed for
# private, and for open address, invitation only.
#
# Exit 0 when both match the record, 1 when one does not, 2 when there is no
# paste, it cannot be read, or no setting is recorded. A setting the person
# chose not to record passes, and says so.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

record=$(cl_access)
[ -n "$record" ] || cl_access_unrecorded
ask=$(cl_ask "$here/../recipe.md" Access)
[ "${1:-}" = "--pasted" ] && [ -f "${2:-}" ] ||
  cl_cannot "Nothing was pasted back about who can reach the live address yet. $ask"
setting=${record% *}
gate=$(python3 - "$2" <<'PY'
import re, sys
try:
    failure = re.compile(r"could not resolve|failed to connect|couldn't connect|"
                         r"timed out|timeout was reached|connection refused")
    answers = []
    for line in open(sys.argv[1], errors="replace").read().lower().splitlines():
        # A line naming a failure to connect is one answer, whatever numbers,
        # such as a port, it also holds.
        if failure.search(line):
            answers.append("none")
            continue
        for code in re.findall(r"(?<![\w.:/-])(000|[1-5][0-9][0-9])(?![\w.:/-])", line):
            answers.append("none" if code == "000" else code)
    # curl prints its error and then 000 for the same request.
    merged = []
    for answer in answers:
        if not (merged and merged[-1] == "none" and answer == "none"):
            merged.append(answer)
    if not merged:
        print("unknown")
    elif merged[0] in ("401", "403"):
        print("gated")
    elif merged[0] == "200":
        print("open")
    elif merged[0] == "none" and any(a != "none" for a in merged[1:]):
        print("gated")
    elif merged[0] == "none":
        print("unconnected")
    else:
        print("unknown")
except Exception:
    print("unknown")
PY
)
case "$gate" in
  unknown) cl_cannot "The paste holds no answer the kit can read. $ask" ;;
  unconnected) cl_cannot "The live address could not be reached from outside, which could mean a private network or a server that is down. Please also paste what the same command prints on a computer inside your private network." ;;
esac

signup_line=$(sh "$here/../../parts/scripts/signup.sh" "${record#* }")
signup=$?
if [ "$setting" = private ] && [ "$gate" = open ]; then
  cl_fail "The live address answers anyone who is not signed in, though the record says private."
fi
if [ "$setting" != private ] && [ "$gate" = gated ]; then
  cl_fail "The live address turns away anyone who is not signed in, though the record says anyone may reach it."
fi
case $signup in
  0) ;;
  1) cl_fail "$signup_line" ;;
  *) cl_cannot "Who can reach the live address matches the record, but sign-up could not be read. $signup_line" ;;
esac
lower=$(printf '%s' "$signup_line" | sed 's/^S/s/')
case "$setting" in
  private) cl_pass "Private, as recorded: the live address turns away anyone outside the team's gate, and $lower" ;;
  open) cl_pass "Open address, invitation only, as recorded: the live address answers anyone, and $lower" ;;
esac
cl_pass "Public, as recorded: the live address answers anyone. $signup_line"
