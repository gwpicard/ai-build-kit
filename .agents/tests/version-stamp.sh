#!/usr/bin/env sh
# version-stamp.sh: prove the release stamp writes all three version-bearing
# files together, refuses what it should, and can be asked whether a branch
# already carries a version.
#
# Why this is worth a rehearsal of its own. While the released kit lived in a
# second repository, those three files held a placeholder here and the real
# number was written into the packaged copy. One repository ends that: both
# installers read the default branch, so an unstamped branch installs a kit that
# calls itself `v0.0.0-development`, and /maintain compares that file with the
# latest Release. It would offer an update that is already installed, apply it,
# and report that it did not take, on every visit, for everybody.
#
# The stamp is what stands between that and a real number, and it half-works in
# a way nothing would notice: a manifest whose version field was renamed makes
# the substitution match nothing, so a release ships carrying the previous
# number and every check still passes. That is the fault this file exists for.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
STAMPER="$ROOT/.agents/tools/stamp-version.sh"
NOTES_CHECK="$ROOT/.agents/tools/check-release-notes.py"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[ -x "$STAMPER" ] || fail "the version stamper is missing or not executable"

WORK=$(mktemp -d)
trap 'rm -R "$WORK"' EXIT

CLAUDE_MANIFEST=".claude-plugin/plugin.json"
AGENT_MANIFEST="agent-plugin/plugin.json"
MAINTAIN_VERSION=".agents/skills/maintain/VERSION"

# A throwaway tree holding only the three files the stamper touches, plus the
# stamper itself at the path it expects to find them from.
build_tree() {
  tree="$WORK/$1"
  claude_value=$2
  agent_value=$3
  maintain_value=$4
  rm -rf "$tree"
  mkdir -p "$tree/.claude-plugin" "$tree/agent-plugin" \
    "$tree/.agents/skills/maintain" "$tree/.agents/tools"
  cp "$STAMPER" "$tree/.agents/tools/stamp-version.sh"
  cp "$NOTES_CHECK" "$tree/.agents/tools/check-release-notes.py"
  give_notes "$tree" v0.11.0
  give_notes "$tree" v0.12.0
  cat > "$tree/$CLAUDE_MANIFEST" <<CLAUDEJSON
{
  "name": "ai-build-kit",
  "version": "$claude_value",
  "description": "A throwaway manifest for the version-stamp rehearsal."
}
CLAUDEJSON
  cat > "$tree/$AGENT_MANIFEST" <<AGENTJSON
{
  "name": "ai-build-kit",
  "version": "$agent_value"
}
AGENTJSON
  printf '%s\n' "$maintain_value" > "$tree/$MAINTAIN_VERSION"
  printf '%s\n' "$tree"
}

# Notes the check accepts: the two sections, a page holding them with its pull
# request list, and a later review with no Critical or Major finding.
give_notes() {
  notes_dir="$1/docs/release-notes"
  review_dir="$1/.agents/tmp/release-notes-review/$2"
  mkdir -p "$notes_dir" "$review_dir"
  cat > "$notes_dir/$2.md" <<NOTES
$2 fixes one thing.

## Updating

Run /maintain, then start a new session.

## What changes

1. **A fix.** The thing now works.
NOTES
  { cat "$notes_dir/$2.md"; printf '\n## Pull requests in this release\n\n- A fix\n'; } \
    > "$review_dir/page.md"
  printf 'No findings.\n\nCritical: %s | Major: %s | Minor: 0\n' "${3:-0}" "${4:-0}" \
    > "$review_dir/review.md"
  touch -t 203001010000 "$review_dir/review.md"
}

stamp() {
  tree=$1
  shift
  "$tree/.agents/tools/stamp-version.sh" "$@"
}

assert_carries() {
  tree=$1
  version=$2
  plain=${version#v}
  grep -qF "\"version\": \"$plain\"" "$tree/$CLAUDE_MANIFEST" || \
    fail "$3: the Claude manifest does not carry $version"
  grep -qF "\"version\": \"$plain\"" "$tree/$AGENT_MANIFEST" || \
    fail "$3: the Agent Plugins manifest does not carry $version"
  [ "$(cat "$tree/$MAINTAIN_VERSION")" = "$version" ] || \
    fail "$3: the maintain version marker does not carry $version"
}

pass_count=0
ok() {
  echo "  ok: $1"
  pass_count=$((pass_count + 1))
}

echo "Version stamp checks:"

# --- a placeholder tree takes the stamp, in all three files together ------
TREE=$(build_tree placeholder 0.0.0-development 0.0.0-development v0.0.0-development)
stamp "$TREE" v0.11.0 >/dev/null
assert_carries "$TREE" v0.11.0 "stamping a placeholder tree"
ok "a placeholder tree takes a version in all three files"

# --- notes that are not ready stop the stamp, and nothing is written ------
refused_by_notes() {
  tree=$1
  label=$2
  if out=$(stamp "$tree" v0.11.0 2>&1); then
    fail "$label: the stamp went ahead"
  fi
  printf '%s\n' "$out" | grep -qF 'refused: the v0.11.0 notes' || \
    fail "$label: the refusal did not come from the notes check: $out"
  [ "$(cat "$tree/$MAINTAIN_VERSION")" = "v0.10.0" ] || \
    fail "$label: a version was written anyway"
  ok "$label"
}
NOTES=$(build_tree no-notes 0.10.0 0.10.0 v0.10.0)
rm "$NOTES/docs/release-notes/v0.11.0.md"
refused_by_notes "$NOTES" "missing notes stop the stamp"
NOTES=$(build_tree dash 0.10.0 0.10.0 v0.10.0)
printf 'One more line \342\200\224 with a dash.\n' >> "$NOTES/docs/release-notes/v0.11.0.md"
refused_by_notes "$NOTES" "an em dash in the notes stops the stamp"
NOTES=$(build_tree major 0.10.0 0.10.0 v0.10.0)
give_notes "$NOTES" v0.11.0 0 1
refused_by_notes "$NOTES" "a review with a Major finding stops the stamp"
NOTES=$(build_tree stale 0.10.0 0.10.0 v0.10.0)
touch -t 202001010000 "$NOTES/.agents/tmp/release-notes-review/v0.11.0/review.md"
refused_by_notes "$NOTES" "a review older than the page text stops the stamp"
NOTES=$(build_tree no-list 0.10.0 0.10.0 v0.10.0)
cp "$NOTES/docs/release-notes/v0.11.0.md" "$NOTES/.agents/tmp/release-notes-review/v0.11.0/page.md"
touch -t 203001010000 "$NOTES/.agents/tmp/release-notes-review/v0.11.0/review.md"
refused_by_notes "$NOTES" "a page without the pull request list stops the stamp"

# --- --check agrees, and disagrees about a different version -------------
stamp "$TREE" --check v0.11.0 >/dev/null || \
  fail "--check refused a tree it had just stamped"
ok "--check confirms the version it stamped"

if stamp "$TREE" --check v0.12.0 >/dev/null 2>&1; then
  fail "--check accepted a version the tree does not carry"
fi
ok "--check refuses a version the tree does not carry"

# --- a stamped tree restamps, which is the second release ----------------
# The release builder used to demand the development placeholder by name, so
# the second release found the first one's number and stopped.
stamp "$TREE" v0.12.0 >/dev/null
assert_carries "$TREE" v0.12.0 "restamping an already-stamped tree"
ok "an already-stamped tree takes the next version"

# --- a preview never reaches the branch every installer reads ------------
if stamp "$TREE" v0.13.0-preview.1 >/dev/null 2>&1; then
  fail "a preview version was stamped into the branch"
fi
assert_carries "$TREE" v0.12.0 "after a refused preview"
ok "a preview is refused, and changes nothing"

# --- a half-stamped tree is caught rather than quietly completed ---------
HALF=$(build_tree half 0.11.0 0.0.0-development v0.11.0)
if stamp "$HALF" --check v0.11.0 >/dev/null 2>&1; then
  fail "--check called a half-stamped tree stamped"
fi
ok "--check catches a tree where only some files carry the version"

# --- a manifest whose version field is gone stops the stamp --------------
# This is the silent one. Without it the substitution matches nothing, the
# stamp reports success, and the release ships carrying the previous number.
GONE=$(build_tree renamed 0.0.0-development 0.0.0-development v0.0.0-development)
sed 's/"version"/"pluginVersion"/' "$GONE/$AGENT_MANIFEST" > "$GONE/renamed.json"
mv "$GONE/renamed.json" "$GONE/$AGENT_MANIFEST"
gone_out=$(stamp "$GONE" v0.11.0 2>&1) &&   fail "a manifest with no version field was reported as stamped"
# The message matters as much as the exit. A script that dies with no output
# also exits non-zero, which is what this check used to accept, so the operator
# got a bare failure on the one fault this file exists to catch.
case "$gone_out" in
  *"expected exactly one version field"*) ;;
  *) fail "the stamp refused a renamed version field without saying why: '$gone_out'" ;;
esac
ok "a manifest whose version field was renamed stops the stamp, and says so"

# --- and a manifest carrying two of them stops it as well ----------------
TWICE=$(build_tree twice 0.0.0-development 0.0.0-development v0.0.0-development)
sed 's/  "name": "ai-build-kit",/  "name": "ai-build-kit",\
  "version": "9.9.9",/' "$TWICE/$CLAUDE_MANIFEST" > "$TWICE/twice.json"
mv "$TWICE/twice.json" "$TWICE/$CLAUDE_MANIFEST"
twice_out=$(stamp "$TWICE" v0.11.0 2>&1) &&   fail "a manifest with two version fields was stamped anyway"
case "$twice_out" in
  *"expected exactly one version field"*) ;;
  *) fail "the stamp refused two version fields without saying why: '$twice_out'" ;;
esac
ok "a manifest carrying two version fields stops the stamp, and says so"

# --- the release preparation asks before it assembles --------------------
PREPARE="$ROOT/.github/workflows/prepare-release.yml"
[ -f "$PREPARE" ] || fail "the prepare-release workflow is missing"
grep -qF 'stamp-version.sh --check' "$PREPARE" || \
  fail "release preparation does not confirm that main carries the version being prepared"
ok "release preparation confirms main is stamped before it assembles"

# --- and the stamper never ships -----------------------------------------
grep -qF 'stamp-version.sh' "$ROOT/release-manifest.txt" && \
  fail "the version stamper is in the release allowlist; it is a maintainer tool"
ok "the version stamper stays out of the released kit"

echo
echo "version-stamp.sh: all $pass_count checks passed"
