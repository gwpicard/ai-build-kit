#!/usr/bin/env sh
# container-check.sh: build the app's container here and read its health.
#
# Usage: container-check.sh
#
# It checks Docker is running with `docker info`, builds the image with
# `docker build -t app-check .`, passing the public Supabase address and key as
# build arguments, runs it with
# `docker run -d --name app-check -p <free port>:3000 --env-file .env.container app-check`
# and reads the HTTP status and JSON from its health route: 200 with
# "database":"reachable" or the older "database":"ok". It then builds a
# second image with the database address
# pointed nowhere, and the same route must answer 503 rather than claim the
# tool is up. `docker rm -f app-check` removes the container each time, and
# both images are removed on exit.
#
# `.env.container` is the container's own values file, which git ignores. It
# holds only names in `.env.example`, and its values are never printed.
#
# Exit 0 when both answers are right, 1 when the image fails to build, bind or
# answer as it should, 2 when the check could not run here, such as Docker not
# running or no `.env.container`.

set -u
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$here/check-lib.sh"

cl_need docker curl
docker info >/dev/null 2>&1 ||
  cl_cannot "Docker's engine is not running on this computer, so the local container check could not run."
[ -f Dockerfile ] || cl_cannot "The project has no Dockerfile, so the local container check could not run."
[ -f .env.container ] ||
  cl_cannot "The project has no .env.container file, so the local container check could not run."

extra=
for name in $(cl_names .env.container); do
  cl_names .env.example | grep -qx "$name" || extra="$extra $name"
done
[ -z "$extra" ] || cl_fail ".env.container holds names .env.example does not list:$extra."

NEXT_PUBLIC_SUPABASE_URL=$(cl_value .env.container NEXT_PUBLIC_SUPABASE_URL)
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=$(cl_value .env.container NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)
NEXT_PUBLIC_SUPABASE_ANON_KEY=$(cl_value .env.container NEXT_PUBLIC_SUPABASE_ANON_KEY)
[ -n "$NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY" ] || NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=$NEXT_PUBLIC_SUPABASE_ANON_KEY
export NEXT_PUBLIC_SUPABASE_URL NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY NEXT_PUBLIC_SUPABASE_ANON_KEY

port=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])' 2>/dev/null) ||
  cl_cannot "No free port was found on this computer, so the local container check could not run."
response=$(mktemp) || cl_cannot "The local container check could not create its response file."

cleanup() {
  docker rm -f app-check >/dev/null 2>&1 || true
}
trap 'cleanup; docker rmi app-check >/dev/null 2>&1; docker rmi app-check-nowhere >/dev/null 2>&1; rm -f "$response"' EXIT

answer() {
  # answer <image>: run the image on a free port here and read its health
  # route. Store its body in the response file, print the HTTP status,
  # and return curl's status. A failed container start returns 90.
  cleanup
  docker run -d --name app-check -p "$port:3000" --env-file .env.container "$1" >/dev/null 2>&1 || return 90
  curl -sS -o "$response" -w '%{http_code}' --retry 15 --retry-connrefused --retry-delay 2 --max-time 120 "http://localhost:$port/api/health" 2>/dev/null
}

docker build -t app-check --build-arg NEXT_PUBLIC_SUPABASE_URL --build-arg NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY . >&2 ||
  cl_fail "The app's image failed to build on this computer."
http_status=$(answer app-check)
status=$?
[ "$status" -ne 90 ] || cl_fail "The app's image built, but its container would not start."
[ "$status" -eq 0 ] && [ "$http_status" = 200 ] ||
  cl_fail "The app's container started, but its health route did not answer 200."
fields=$(cl_health_fields "$response")
[ "$(printf '%s\n' "$fields" | sed -n 2p)" = ok ] ||
  cl_fail "The app's container answered 200, but its health route did not report the database reachable."

NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:9
docker build -t app-check-nowhere --build-arg NEXT_PUBLIC_SUPABASE_URL --build-arg NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY . >&2 ||
  cl_fail "The app's image failed to build a second time, with the database pointed nowhere."
http_status=$(answer app-check-nowhere)
status=$?
[ "$status" -ne 90 ] || cl_fail "The image with its database pointed nowhere could not start, so its health response was not checked."
[ "$status" -eq 0 ] || cl_fail "The health request failed with its database pointed nowhere; no HTTP 503 response was confirmed."
[ "$http_status" = 503 ] ||
  cl_fail "With its database pointed nowhere, the health route answered HTTP $http_status instead of 503."
cl_pass "The app's container answered here: 200 with the database reachable, and 503 with the database pointed nowhere."
