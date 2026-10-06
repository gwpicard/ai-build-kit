#!/usr/bin/env sh
# code-online.after-commit.sh: put the project's main on the remote next door,
# as an established project on GitHub has it.
#
# The harness starts every remote empty. Since the first upload of a project's
# code waits for the person's yes, a case whose piece is saved as a pull
# request through the usual route met that question instead, and never reached
# the pull request its contract judges. Scenario 55 measures the first upload,
# and keeps its empty remote. Scenarios 8 and 45 assume a project whose code is
# already online, and name this preparation.
#
# Usage: code-online.after-commit.sh <project-dir>

set -eu

project=${1:?project directory}
me=code-online.after-commit.sh

# Only a fresh replay project: its own repository, one commit made by the
# harness, and an empty remote next door. Anything else, this repository
# included, is refused before a branch is renamed or pushed.
top=$(git -C "$project" rev-parse --show-toplevel 2>/dev/null || true)
here=$(cd "$project" 2>/dev/null && pwd -P || true)
[ -n "$top" ] && [ "$(cd "$top" && pwd -P)" = "$here" ] || {
  echo "$me: $project is not the top of its own repository" >&2
  exit 1
}
[ "$(git -C "$project" rev-list --count --all)" = "1" ] \
  && [ "$(git -C "$project" log -1 --format=%s)" = "Project before the scenario" ] || {
  echo "$me: $project has history beyond the harness's first commit, so it is not a fresh replay project" >&2
  exit 1
}
[ "$(git -C "$project" remote get-url origin 2>/dev/null || true)" = "$project.git" ] || {
  echo "$me: $project has no remote next door" >&2
  exit 1
}
set +e
git -C "$project" ls-remote --exit-code --heads origin >/dev/null 2>&1
listed=$?
set -e
[ "$listed" -eq 2 ] || {
  echo "$me: the remote is not empty, or could not be read (exit $listed)" >&2
  exit 1
}

git -C "$project" branch -M main
git -C "$project" push -q origin main
git -C "$project" branch -q --set-upstream-to=origin/main main
