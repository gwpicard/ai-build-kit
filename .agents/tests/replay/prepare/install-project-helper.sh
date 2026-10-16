#!/usr/bin/env sh
# Install the helper a founded replay project already has, from its assembled
# kit rather than from the maintainer worktree.

set -eu

project=${1:?project directory}
kit=${2:?assembled kit directory}
source="$kit/.agents/skills/setup-ai-build-kit/templates/foundation/codex-github-check.py"
destination="$project/.agents/tools/codex-github-check.py"

[ -f "$source" ] && [ ! -L "$source" ] || {
  echo "install-project-helper.sh: the assembled kit has no foundation helper" >&2
  exit 1
}
mkdir -p "$(dirname -- "$destination")"
if [ ! -e "$destination" ] && [ ! -L "$destination" ]; then
  cp -p "$source" "$destination"
fi
[ -f "$destination" ] && [ ! -L "$destination" ] || {
  echo "install-project-helper.sh: project helper is not a regular file" >&2
  exit 1
}
