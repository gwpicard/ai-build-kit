#!/usr/bin/env sh
# ready-piece.after-commit.sh: put the project's code online, so a pull request
# has a main branch to aim at. The remote next door stands in for GitHub.
set -eu
project=${1:?project directory}
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sh "$here/code-online.after-commit.sh" "$project"
