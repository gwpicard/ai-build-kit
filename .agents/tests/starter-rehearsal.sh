#!/usr/bin/env sh
# starter-rehearsal.sh: prove that a released starter can become a clean,
# independently saved project with the founding record templates in place.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
BUILDER="$ROOT/.agents/tools/build-release.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[ -x "$BUILDER" ] || fail "release builder is missing or not executable"

SCRATCH=$(mktemp -d)
PACK="$SCRATCH/pack"
PROJECT="$SCRATCH/project"
PLUGIN_PROJECT="$SCRATCH/plugin-project"
cleanup() {
  rm -R "$SCRATCH"
}
trap cleanup EXIT

"$BUILDER" v0.1.0 "$PACK" >/dev/null

# Rehearse the Claude plugin boundary: Claude runs the same canonical start
# skill from its plugin cache while the project owns only its foundation.
mkdir -p "$PLUGIN_PROJECT"
PLUGIN_BOOTSTRAP="$PACK/.agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh"
"$PLUGIN_BOOTSTRAP" "$PLUGIN_PROJECT" >/dev/null || \
  fail "Claude plugin setup-ai-build-kit skill could not prepare a blank project"
[ -f "$PLUGIN_PROJECT/AGENTS.md" ] || \
  fail "Claude plugin setup-ai-build-kit skill did not prepare project instructions"
[ ! -e "$PLUGIN_PROJECT/.agents/skills" ] || \
  fail "Claude plugin bootstrap copied managed skills into the project"

PLUGIN_DUPLICATE="$SCRATCH/plugin-duplicate"
mkdir -p "$PLUGIN_DUPLICATE/.agents"
cp -R "$PACK/.agents/skills" "$PLUGIN_DUPLICATE/.agents/skills"
if "$PLUGIN_BOOTSTRAP" "$PLUGIN_DUPLICATE" >/dev/null 2>&1; then
  fail "Claude plugin bootstrap accepted a second AI Build Kit installation"
fi
[ ! -e "$PLUGIN_DUPLICATE/AGENTS.md" ] || \
  fail "Claude plugin bootstrap wrote project files before reporting the duplicate installation"

# Rehearse the shared skills installer boundary: only skill folders arrive in
# the project. The installed setup-ai-build-kit skill then prepares the project-owned
# foundation without needing the rest of the release repository.
mkdir -p "$PROJECT/.agents"
cp -R "$PACK/.agents/skills" "$PROJECT/.agents/skills"
BOOTSTRAP="$PROJECT/.agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh"
[ -x "$BOOTSTRAP" ] || fail "installed setup-ai-build-kit skill has no executable project bootstrap"
(cd "$PROJECT" && "$BOOTSTRAP" >/dev/null) || \
  fail "installed setup-ai-build-kit skill could not prepare a blank project"
[ -x "$PROJECT/.agents/hooks/session-start.sh" ] || \
  fail "installed setup-ai-build-kit skill did not prepare an executable session hook"

for record in masterplan.md CHANGELOG.md .ai-build-kit-maintenance; do
  [ ! -e "$PROJECT/$record" ] || \
    fail "starter unexpectedly contains founding record $record"
done

for maintainer_only in starter release-manifest.txt docs/MAINTAINING.md \
  .agents/tests .agents/maintainer-skills; do
  [ ! -e "$PROJECT/$maintainer_only" ] || \
    fail "starter contains maintainer-only $maintainer_only"
done

skill_count=$(find "$PROJECT/.agents/skills" -mindepth 2 -maxdepth 2 \
  -name SKILL.md | wc -l | tr -d ' ')
[ "$skill_count" -eq 12 ] || fail "installed project does not contain twelve skills"

grep -qF '(Project name, written by start)' "$PROJECT/README.md" || \
  fail "project foundation README is not ready for start"
grep -qF '(One line, written by the setup-ai-build-kit skill.)' "$PROJECT/AGENTS.md" || \
  fail "starter instructions are not ready for the founding workflow"
grep -qF '.claude/settings.local.json' "$PROJECT/.gitignore" || \
  fail "project foundation does not keep local Claude plugin state out of Git"

printf '%s\n' "Existing project instructions" > "$PROJECT/AGENTS.md"
(cd "$PROJECT" && "$BOOTSTRAP" >/dev/null) || \
  fail "project bootstrap could not be rerun"
[ "$(cat "$PROJECT/AGENTS.md")" = "Existing project instructions" ] || \
  fail "project bootstrap overwrote existing project instructions"
cp "$PACK/.agents/skills/setup-ai-build-kit/templates/foundation/AGENTS.md" "$PROJECT/AGENTS.md"

REDIRECTED="$SCRATCH/redirected"
OUTSIDE="$SCRATCH/outside"
mkdir -p "$REDIRECTED/.agents" "$OUTSIDE"
cp -R "$PACK/.agents/skills" "$REDIRECTED/.agents/skills"
ln -s "$OUTSIDE" "$REDIRECTED/.github"
if (cd "$REDIRECTED" && \
  .agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh >/dev/null 2>&1); then
  fail "project bootstrap accepted a redirected foundation folder"
fi
[ ! -e "$REDIRECTED/AGENTS.md" ] || \
  fail "project bootstrap wrote partial foundation before rejecting a redirect"
[ ! -e "$OUTSIDE/copilot-instructions.md" ] || \
  fail "project bootstrap wrote outside the project"

BROAD="$SCRATCH/broad"
mkdir -p "$BROAD/.agents"
cp -R "$PACK/.agents/skills" "$BROAD/.agents/skills"
if "$BROAD/.agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh" "$SCRATCH" \
  >/dev/null 2>&1; then
  fail "project bootstrap accepted a parent workspace"
fi
[ ! -e "$SCRATCH/AGENTS.md" ] || \
  fail "project bootstrap wrote foundation files into a parent workspace"

git -C "$PROJECT" init -q
git -C "$PROJECT" config user.name "AI Build Kit rehearsal"
git -C "$PROJECT" config user.email "rehearsal@example.invalid"
git -C "$PROJECT" config commit.gpgsign false
git -C "$PROJECT" add .
git -C "$PROJECT" commit -q -m "Start from AI Build Kit"

for record in masterplan.md CHANGELOG.md; do
  cp "$PROJECT/.agents/skills/setup-ai-build-kit/templates/$record" "$PROJECT/$record"
done

git -C "$PROJECT" add masterplan.md CHANGELOG.md
git -C "$PROJECT" commit -q -m "Create founding project records"

[ "$(git -C "$PROJECT" rev-list --count HEAD)" -eq 2 ] || \
  fail "disposable project did not save both expected checkpoints"
[ -z "$(git -C "$PROJECT" status --short)" ] || \
  fail "disposable project is not clean after its founding records were saved"

echo "starter-rehearsal.sh: all checks passed"
