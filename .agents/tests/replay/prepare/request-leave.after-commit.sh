#!/usr/bin/env sh
# request-leave.after-commit.sh: put the founded project's code on the local remote.
set -eu
project=${1:?project directory}
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ -f "$project/package-lock.json" ] && [ -f "$project/.gh-fixture.json" ] || {
  echo "request-leave.after-commit.sh: request-leave.sh did not prepare the project" >&2
  exit 1
}
sh "$here/code-online.after-commit.sh" "$project"
