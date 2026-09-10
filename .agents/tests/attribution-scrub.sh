#!/usr/bin/env sh
# attribution-scrub.sh: drive the commit-msg hook and read what it wrote.
#
# The hook exists because this repository went public carrying a session link
# in nineteen commit messages and in thirteen pull request descriptions. A
# session link is a personal address on the agent vendor's site. Taking them
# out meant rewriting every commit and force-pushing a branch other people had
# already cloned, which is a thing to do once.
#
# A setting turns the lines off at the source, and this hook is the guard
# behind it, for the session that overrides the setting and the clone that
# never had it. So the hook is the thing worth testing, and it is testable:
# a message goes in, a message comes out, and a machine can judge it.
#
# The case that matters most is the last one. The kit is built with Claude,
# Cursor and Gemini and writes about them in almost every commit. A hook that
# went after the word rather than the attribution line would quietly gut those
# messages, and nobody would notice until the history was unreadable.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
HOOK="$ROOT/.githooks/commit-msg"

[ -f "$HOOK" ] || { echo "FAIL: missing $HOOK" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

passes=0

echo "Attribution scrub checks:"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

ok() {
  echo "  ok: $1"
  passes=$((passes + 1))
}

# scrub <message>: run the real hook over a message, print the result.
scrub() {
  printf '%s\n' "$1" > "$WORK/msg"
  sh "$HOOK" "$WORK/msg"
  cat "$WORK/msg"
}

# gone <what> <message> <needle>: the needle must not survive the hook.
gone() {
  if scrub "$2" | grep -qiF -- "$3"; then
    fail "$1"
  fi
  ok "$1"
}

# kept <what> <message> <needle>: the needle must survive the hook.
kept() {
  if scrub "$2" | grep -qF -- "$3"; then
    ok "$1"
  else
    fail "$1"
  fi
}

session_trailer='Say the thing

Claude-Session: https://claude.ai/code/session_0000000000000000000000'

coauthor_trailer='Say the thing

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>'

squashed='Say the thing

Some body text.

---------

Co-authored-by: Claude <noreply@anthropic.com>'

footer='Say the thing

🤖 Generated with [Claude Code](https://claude.com/claude-code)'

about_the_tools='Rename the command that shapes a piece

Claude Code now carries a /plan of its own, which starts its read-only plan
mode. The command is now /shape, and it reads the same in Claude, Cursor and
Gemini alike.'

bare_link='Say the thing

https://claude.ai/code/session_0000000000000000000000'

plain='Say the thing

A body with nothing to take out of it.'

gone "the session link goes" "$session_trailer" 'claude.ai/code/session_'
gone "the co-author trailer goes" "$coauthor_trailer" 'Co-Authored-By: Claude'
gone "the vendor address goes with it" "$coauthor_trailer" 'noreply@anthropic.com'
gone "the pull request footer goes" "$footer" 'Generated with [Claude Code]'
gone "a bare session link goes" "$bare_link" 'claude.ai/code/session_'

# A squash merge writes a row of dashes above the trailer it folds in. Take the
# trailer and leave the dashes, and every rewritten message ends on punctuation
# with nothing after it.
gone "the stranded squash separator goes too" "$squashed" '---------'
kept "the body above the separator stays" "$squashed" 'Some body text.'

# The subject line is the one part of a message that is always read.
kept "the subject line survives" "$session_trailer" 'Say the thing'

# The rule the hook is most likely to get wrong.
kept "prose about the tools survives" "$about_the_tools" 'reads the same in Claude, Cursor and'
kept "so does a slash command named in prose" "$about_the_tools" '/shape'

# A message with nothing to remove must come back byte for byte, or the hook is
# editing every commit in the repository rather than the ones it was written for.
printf '%s\n' "$plain" > "$WORK/before"
cp "$WORK/before" "$WORK/msg"
sh "$HOOK" "$WORK/msg"
if cmp -s "$WORK/before" "$WORK/msg"; then
  ok "a clean message is returned unchanged"
else
  fail "a clean message was edited"
fi

# The control. A check that cannot fail proves nothing, so take the rule out of
# a copy of the hook and require the run to notice.
#
# The message here is the bare link rather than the trailer. Two rules catch a
# Claude-Session trailer, the one that reads the key and the one that reads the
# address, so removing either still left the trailer caught and the control
# passed while proving nothing. The bare link is reached by one rule only.
sed '/claude.ai\/code\/session_/d' "$HOOK" > "$WORK/hook-without-the-rule"
printf '%s\n' "$bare_link" > "$WORK/msg"
sh "$WORK/hook-without-the-rule" "$WORK/msg"
if grep -qF 'claude.ai/code/session_' "$WORK/msg"; then
  ok "removing the session rule is caught"
else
  fail "the hook still removed the session link without its rule, so nothing here is guarded"
fi

echo
echo "attribution-scrub.sh: all $passes checks passed"
