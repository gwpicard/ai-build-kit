#!/usr/bin/env sh
# hosting-request.sh: print the hosting request a first launch on this recipe
# carries to whoever runs the server, filled from the project itself.
#
# Usage: hosting-request.sh [--lane internal|public]
#
# `hosting-request.md` beside this folder says what each field means and how
# the answer is recorded. Repo comes from `origin`, Env vars from
# `.env.example`, by name only, and Build and Bind from the Dockerfile at the
# root, since the server builds and checks the tool from those two facts. The
# lane comes from the fit check: internal unless somebody outside the team
# signs in or relies on it. On this recipe Port is 3000 and Healthcheck is
# /api/health, and a value is never printed.
#
# Exit 0 when the request is complete, 1 when the tool cannot be hosted yet,
# such as a server bound to 127.0.0.1 or no Dockerfile, 2 when it could not
# run.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/../../parts/scripts/check-lib.sh"

lane=internal
[ "${1:-}" = "--lane" ] && lane=${2:-internal}
case "$lane" in internal|public) ;; *) cl_cannot "The lane is internal or public, not $lane." ;; esac
cl_need git
repo=$(git remote get-url origin 2>/dev/null) ||
  cl_cannot "The project has no GitHub repository yet, so there is nothing for the server to build."
# A sign-in written into the address, user:token@, is never printed.
repo=$(printf '%s\n' "$repo" | sed -E 's#^([A-Za-z][A-Za-z0-9+.-]*://)[^/@]*@#\1#')
case "$lane" in
  internal) lane_text="internal (private network)" ;;
  public) lane_text="public (internet)" ;;
esac
envs=$(cl_names .env.example | paste -sd, - | sed 's/,/, /g')
[ -n "$envs" ] || envs=none

hostable=yes
if [ -f Dockerfile ]; then
  if grep -Eqi '^FROM[[:space:]]+[^[:space:]]*slim' Dockerfile; then
    build="neither yet"
    hostable=no
  else
    build="Dockerfile at root, image has curl or wget"
  fi
  # HOSTNAME=0.0.0.0, quoted or not, or the older form HOSTNAME 0.0.0.0.
  if grep -Eq "(^|[[:space:]])HOSTNAME([[:space:]]+|=)[\"']?0\\.0\\.0\\.0[\"']?([[:space:]]|\$)" Dockerfile; then
    bind=0.0.0.0
  else
    bind="127.0.0.1 (not hostable yet)"
    hostable=no
  fi
else
  build="neither yet"
  bind="127.0.0.1 (not hostable yet)"
  hostable=no
fi

cat <<EOF
Hosting request
Repo:          $repo, branch main
Lane:          $lane_text
Port:          3000
Env vars:      $envs
Persist:       none
Healthcheck:   /api/health
Build:         $build
Bind:          $bind
EOF
[ "$hostable" = yes ] ||
  cl_fail "The tool cannot be hosted yet: the server needs a Dockerfile at the root whose image has curl or wget and listens on 0.0.0.0."
cl_pass "This tool needs a home. Take this request to whoever runs the server. Paste what they send back here, and I will record it for the next /setup-hosting."
