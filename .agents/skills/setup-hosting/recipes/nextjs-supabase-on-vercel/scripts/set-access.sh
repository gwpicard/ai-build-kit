#!/usr/bin/env sh
# set-access.sh: put Vercel's sign-in in front of the live address, or take
# it away, then read the setting back. It changes a live service, so it runs
# only after the person's yes that names the change. Sign-up is a separate
# step, the shared set-signup.sh.
#
# Usage: set-access.sh private|public
#
# Vercel Authentication on every address is ssoProtection with deploymentType
# "all". Public keeps it on previews and on each build's own address,
# deploymentType "prod_deployment_urls_and_all_previews". `vercel project
# protection enable --sso` sets only the second, so the change goes through
# the API: `vercel api /v9/projects/<project id>[?teamId=<team id>] -X PATCH
# --input <file> --silent`, with the ids `vercel link` left in
# .vercel/project.json. --silent matters, since the answer holds the
# project's bypass keys. Then `vercel project protection --format json` must
# show the new type.
#
# Exit 0 when Vercel shows the new setting, 1 when it refused or shows
# another, 2 when it could not run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

case "${1:-}" in
  private) type=all ;;
  public) type=prod_deployment_urls_and_all_previews ;;
  *) cl_cannot "Say private or public, so the kit knows which way to set Vercel's sign-in. Nothing was changed." ;;
esac
cl_need vercel
[ -f .vercel/project.json ] || cl_cannot "This folder is not linked to a Vercel project, so nothing was changed."
endpoint=$(python3 -c '
import json
data = json.load(open(".vercel/project.json"))
team = data.get("orgId") or ""
print("/v9/projects/%s%s" % (data["projectId"], "?teamId=" + team if team.startswith("team_") else ""))
' 2>/dev/null) || cl_cannot "The Vercel link in this folder could not be read, so nothing was changed."

cl_approved
body=$(mktemp)
trap 'rm -f "$body"' EXIT
printf '{"ssoProtection":{"deploymentType":"%s"}}\n' "$type" > "$body"
vercel api "$endpoint" -X PATCH --input "$body" --silent >/dev/null 2>&1 ||
  cl_fail "Vercel did not take the change, so who can reach the live address is as it was."
now=$(vercel project protection --format json 2>/dev/null | python3 -c '
import json, sys
print((json.load(sys.stdin).get("ssoProtection") or {}).get("deploymentType") or "none")') ||
  cl_cannot "Vercel took the change, but its setting could not be read back."
[ "$now" = "$type" ] || cl_fail "Vercel took the change, but its setting reads otherwise."
if [ "$1" = private ]; then
  cl_pass "The live address and its previews now ask for Vercel's sign-in."
fi
cl_pass "The live address now answers anyone. Previews still ask for Vercel's sign-in."
