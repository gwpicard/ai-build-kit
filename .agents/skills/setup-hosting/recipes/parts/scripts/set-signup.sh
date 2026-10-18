#!/usr/bin/env sh
# set-signup.sh: close or open sign-up on the hosted Supabase project, then
# read it back. It changes a live service, so it runs only after the person's
# yes that names the change.
#
# Usage: set-signup.sh closed|open
#
# The project's own supabase/config.toml may hold settings written for this
# computer, such as a local site address, and `supabase config push` would
# send them all. So this writes a config.toml that declares nothing but
# `[auth] enable_signup`, in a folder of its own, and pushes that alone:
# `supabase --workdir <folder> config push --project-ref <ref> --yes`.
# Recent versions of the tool leave every setting the file does not declare
# as it is, but older ones filled in their own defaults for the rest. So it
# first runs `supabase --workdir <folder> config diff --project-ref <ref>
# --exit-code`, which changes nothing, and pushes only when the difference
# names no setting but enable_signup. A tool too old to have `config diff`
# fails that step, so nothing is pushed. It uses the Supabase command line
# tool's own sign-in. signup.sh then reads the result.
#
# Exit 0 when sign-up now reads as asked, 1 when the push failed or it reads
# otherwise, 2 when it could not run or the difference names anything else.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/check-lib.sh"

want=${1:-}
case "$want" in
  closed) enable=false ;;
  open) enable=true ;;
  *) cl_cannot "Say closed or open, so the kit knows which way to set sign-up. Nothing was changed." ;;
esac
cl_need supabase
ref=$(cl_ref)
[ -n "$ref" ] || cl_cannot "The kit does not know which database project this is, so nothing was changed."

folder=$(mktemp -d)
trap 'rm -rf "$folder"' EXIT
mkdir -p "$folder/supabase"
printf 'project_id = "%s"\n\n[auth]\nenable_signup = %s\n' "$ref" "$enable" > "$folder/supabase/config.toml"
supabase --workdir "$folder" config diff --project-ref "$ref" --exit-code > "$folder/diff" 2>/dev/null
case $? in
  0) result=$(sh "$here/signup.sh" "$want")
     case $? in
       0) cl_pass "Nothing needed changing. $result" ;;
       1) cl_fail "Supabase's settings already say this, but sign-up reads otherwise. $result" ;;
       *) cl_cannot "Supabase's settings already say this, but sign-up could not be read. $result" ;;
     esac ;;
  2) ;;
  *) cl_cannot "The Supabase command line tool could not show what the change would touch, so nothing was changed. If it is older than the one that has \`supabase config diff\`, update it first." ;;
esac
others=$(python3 - "$folder/diff" <<'PY'
import re, sys
try:
    names = set()
    for line in open(sys.argv[1], errors="replace"):
        line = re.sub(r"\x1b\[[0-9;]*m", "", line)
        if line.startswith(("+++", "---")):
            continue
        found = re.match(r"^[+-]\s*([A-Za-z_][\w.\"-]*)\s*=", line)
        if found:
            names.add(found.group(1).strip('"').split(".")[-1])
    if not names:
        print("unknown")
    else:
        print(" ".join(sorted(names - {"enable_signup"})))
except Exception:
    print("unknown")
PY
)
case "$others" in
  '') ;;
  unknown) cl_cannot "The kit could not tell which settings the change would touch, so nothing was changed." ;;
  *) cl_cannot "The change would also touch other settings on the live project ($others), so nothing was changed. Update the Supabase command line tool, then try again." ;;
esac
cl_approved
supabase --workdir "$folder" config push --project-ref "$ref" --yes >&2 ||
  cl_fail "Supabase did not take the change, so sign-up is as it was."
result=$(sh "$here/signup.sh" "$want")
case $? in
  0) cl_pass "$result" ;;
  1) cl_fail "Supabase took the change, but sign-up still reads otherwise. $result" ;;
  *) cl_cannot "Supabase took the change, but sign-up could not be read back. $result" ;;
esac
