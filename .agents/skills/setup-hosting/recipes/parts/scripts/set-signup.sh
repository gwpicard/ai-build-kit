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
# The push leaves every setting the file does not declare as it is. It uses
# the Supabase command line tool's own sign-in. signup.sh then reads the
# result.
#
# Exit 0 when sign-up now reads as asked, 1 when the push failed or it reads
# otherwise, 2 when it could not run.

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
supabase --workdir "$folder" config push --project-ref "$ref" --yes >&2 ||
  cl_fail "Supabase did not take the change, so sign-up is as it was."
result=$(sh "$here/signup.sh" "$want")
case $? in
  0) cl_pass "$result" ;;
  1) cl_fail "Supabase took the change, but sign-up still reads otherwise. $result" ;;
  *) cl_cannot "Supabase took the change, but sign-up could not be read back. $result" ;;
esac
