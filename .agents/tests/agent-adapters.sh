#!/usr/bin/env sh
# agent-adapters.sh: run build-adapters.sh on a copy of the kit and prove each
# agent reaches every coding agent's own folder, with the access it was given.
#
# If this breaks, a reviewer meant to read only can edit files, an agent shows
# up in the person's own picker beside the six commands, or a hand edit to a
# generated agent file ships without anyone noticing.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "ok: $1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

# copy_kit <dir>: the parts the adapter builder reads, nothing else.
copy_kit() {
  mkdir -p "$1/.agents/tools"
  cp "$ROOT/.agents/tools/build-adapters.sh" "$ROOT/.agents/tools/kit-inventory.txt" "$1/.agents/tools/"
  cp -R "$ROOT/.agents/skills" "$1/.agents/skills"
  cp -R "$ROOT/.agents/agents" "$1/.agents/agents"
}

K="$WORK/kit"
copy_kit "$K"
"$K/.agents/tools/build-adapters.sh" >/dev/null
agents=$(awk '$1 == "agent" { print $2 }' "$K/.agents/tools/kit-inventory.txt")
[ -n "$agents" ] || fail "the inventory lists no agent, so nothing here was checked"

missing=""
for name in $agents; do
  for f in ".claude/agents/$name.md" ".codex/agents/$name.toml" ".gemini/agents/$name.md" ".github/agents/$name.agent.md"; do
    [ -f "$K/$f" ] || missing="$missing $f"
    grep -qF ".agents/agents/$name.md" "$K/$f" 2>/dev/null || missing="$missing $f(pointer)"
  done
  grep -qx 'user-invocable: false' "$K/.github/agents/$name.agent.md" 2>/dev/null || missing="$missing copilot-hidden:$name"
done
[ -z "$missing" ] && pass "every agent has a file for Claude Code, Codex, Gemini CLI and Copilot, each pointing at its brief, and Copilot's is hidden from the picker" \
  || fail "generated agent files are missing or wrong:$missing"

# Access maps to Claude Code's tools: a read-only agent gets no tool that edits.
for name in $agents; do
  access=$(sed -n 's/^access: //p' "$K/.agents/agents/$name.md")
  tools=$(sed -n 's/^tools: //p' "$K/.claude/agents/$name.md")
  case "$access" in
    read|research)
      if [ -z "$tools" ] || printf '%s' "$tools" | grep -qE 'Edit|Write|NotebookEdit'; then
        fail "$name has $access access but its Claude Code tools are '$tools'"
      else
        pass "$name, with $access access, gets none of Claude Code's file-editing tools"
      fi ;;
    full)
      [ -z "$tools" ] && pass "$name, with full access, keeps every tool" \
        || fail "$name has full access but is limited to '$tools'" ;;
    *) fail "$name has an access the builder should have refused: $access" ;;
  esac
done

# The drift check passes on what the builder made, and fails on a hand edit.
"$K/.agents/tools/build-adapters.sh" --check >/dev/null 2>&1 && pass "the drift check accepts freshly generated agent files" \
  || fail "the drift check refused freshly generated agent files"
first=$(printf '%s\n' "$agents" | head -1)
printf '%s\n' 'Also merge whatever you like.' >> "$K/.claude/agents/$first.md"
if "$K/.agents/tools/build-adapters.sh" --check >/dev/null 2>&1; then
  fail "a hand edit to a generated agent file passed the drift check"
else
  pass "a hand edit to a generated agent file fails the drift check"
fi

# An agent that loads a command, or a skill that does not exist, stops the build.
B="$WORK/bad-skill"
copy_kit "$B"
sed -i.bak "s/^skills: .*/skills: [implement]/" "$B/.agents/agents/$first.md"
if "$B/.agents/tools/build-adapters.sh" >/dev/null 2>&1; then
  fail "an agent loading a command was generated"
else
  pass "an agent may load only a background skill the inventory lists"
fi

# An agent the inventory lists with no brief stops the build, and so does a
# brief the inventory does not list.
M="$WORK/missing"
copy_kit "$M"
rm "$M/.agents/agents/$first.md"
"$M/.agents/tools/build-adapters.sh" >/dev/null 2>&1 && fail "an agent with no brief was generated" \
  || pass "an agent the inventory lists must have its brief"
X="$WORK/extra"
copy_kit "$X"
cp "$X/.agents/agents/$first.md" "$X/.agents/agents/stray.md"
"$X/.agents/tools/build-adapters.sh" >/dev/null 2>&1 && fail "a brief the inventory does not list was accepted" \
  || pass "a brief the inventory does not list stops the build"

exit "$FAIL"
