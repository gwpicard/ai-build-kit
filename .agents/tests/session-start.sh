#!/usr/bin/env sh
# session-start.sh: prove that a session opening on a released project reports
# an overdue check-up, prints nothing at any other time, and stays silent
# inside the kit's own source.

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
SOURCELIKE="$SCRATCH/sourcelike"
OUT="$SCRATCH/out"
cleanup() {
  rm -R "$SCRATCH"
}
trap cleanup EXIT

# --- this repository is never reminded ------------------------------------
[ ! -e "$ROOT/.agents/hooks/session-start.sh" ] || \
  fail "the maintainer source carries a project session-start hook"
if grep -qF 'SessionStart' "$ROOT/.claude/settings.json"; then
  fail "the maintainer source wired a project session hook into its own settings"
fi

"$BUILDER" v0.3.0 "$PACK" >/dev/null

TEMPLATE="$PACK/.agents/skills/setup-ai-build-kit/templates/foundation/session-start.sh"
[ -x "$TEMPLATE" ] || fail "the released setup-ai-build-kit skill has no executable session-start template"
[ -f "$PACK/.agents/skills/setup-ai-build-kit/templates/maintenance-record" ] || \
  fail "the released setup-ai-build-kit skill has no check-up date template"
[ ! -e "$PACK/.agents/hooks/session-start.sh" ] || \
  fail "the released starter ships a project hook that start should place itself"

# A folder that looks like the kit's own source stays silent. It is given a
# masterplan and a long-overdue visit on purpose. Without them the hook has
# nothing to report and stays quiet whatever the source guard does, so this
# check used to pass even with the guard removed.
mkdir -p "$SOURCELIKE/.agents/hooks" "$SOURCELIKE/.agents/tests"
printf '%s\n' "# allowlist" > "$SOURCELIKE/release-manifest.txt"
printf '%s\n' "# Masterplan" > "$SOURCELIKE/masterplan.md"
printf '%s\n' "founded|2020-01-01" > "$SOURCELIKE/.ai-build-kit-maintenance"
cp "$TEMPLATE" "$SOURCELIKE/.agents/hooks/session-start.sh"
"$SOURCELIKE/.agents/hooks/session-start.sh" > "$OUT" 2>&1 || \
  fail "the session hook failed inside a maintainer-shaped folder"
[ ! -s "$OUT" ] || fail "the session hook spoke inside a maintainer-shaped folder"

# Take the source markers away and the same folder must speak. That is what
# proves the silence above came from the source guard rather than from the hook
# having nothing to say.
rm -f "$SOURCELIKE/release-manifest.txt"
"$SOURCELIKE/.agents/hooks/session-start.sh" > "$OUT" 2>&1 || \
  fail "the session hook failed in an overdue project"
[ -s "$OUT" ] || \
  fail "the maintainer-source check proves nothing: silent even without the source markers"
printf '%s\n' "# allowlist" > "$SOURCELIKE/release-manifest.txt"

# --- the released starter wires it ---------------------------------------
grep -qF 'SessionStart' "$PACK/.claude/settings.json" || \
  fail "the released starter does not wire the session hook"
grep -qF '.agents/hooks/session-start.sh' "$PACK/.claude/settings.json" || \
  fail "the released session wiring does not name the project hook"
cmp -s "$PACK/.claude/settings.json" \
  "$PACK/.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json" || \
  fail "the released Claude settings differ from start's foundation template"
[ ! -e "$PACK/.ai-build-kit-maintenance" ] || \
  fail "the released starter carries a project check-up file"

# --- the shared installer route ends up with both files ------------------
mkdir -p "$PROJECT/.agents"
cp -R "$PACK/.agents/skills" "$PROJECT/.agents/skills"
(cd "$PROJECT" && .agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh >/dev/null) || \
  fail "the installed setup-ai-build-kit skill could not prepare a blank project"
HOOK="$PROJECT/.agents/hooks/session-start.sh"
[ -x "$HOOK" ] || fail "project bootstrap did not install an executable session hook"
grep -qF 'SessionStart' "$PROJECT/.claude/settings.json" || \
  fail "project bootstrap did not wire the session hook"
[ ! -e "$PROJECT/.ai-build-kit-maintenance" ] || \
  fail "project bootstrap created a check-up file before start founded the project"

# An existing Claude settings file, and an adjusted hook, are never rewritten.
printf '%s\n' '{ "permissions": {} }' > "$PROJECT/.claude/settings.json"
printf '%s\n' '#!/usr/bin/env sh' > "$HOOK"
(cd "$PROJECT" && .agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh >/dev/null) || \
  fail "project bootstrap could not be rerun"
if grep -qF 'SessionStart' "$PROJECT/.claude/settings.json"; then
  fail "project bootstrap rewrote a Claude settings file that already existed"
fi
[ "$(cat "$HOOK")" = '#!/usr/bin/env sh' ] || \
  fail "project bootstrap replaced a session hook the project had already changed"
cp "$PACK/.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json" \
  "$PROJECT/.claude/settings.json"
cp "$TEMPLATE" "$HOOK"

run_hook() {
  ( cd "$PROJECT" && AI_BUILD_KIT_TODAY="$1" .agents/hooks/session-start.sh ) > "$OUT" 2>&1 || \
    fail "the session hook exited non-zero on $1"
}

# --- a project with no masterplan -----------------------------------------
run_hook 2026-03-01
[ ! -s "$OUT" ] || fail "a project with no masterplan was not silent"

# --- a founded project ----------------------------------------------------
git -C "$PROJECT" init -q
git -C "$PROJECT" config user.name "AI Build Kit rehearsal"
git -C "$PROJECT" config user.email "rehearsal@example.invalid"
git -C "$PROJECT" config commit.gpgsign false
cp "$PACK/.agents/skills/setup-ai-build-kit/templates/masterplan.md" "$PROJECT/masterplan.md"
cp "$PACK/.agents/skills/setup-ai-build-kit/templates/maintenance-record" \
  "$PROJECT/.ai-build-kit-maintenance"
git -C "$PROJECT" add -A
git -C "$PROJECT" commit -q -m "Found the project"

write_record() {
  {
    printf '%s\n' "founded|$1"
    printf '%s\n' "last-light-pass|$2"
    printf '%s\n' "last-full-pass|"
  } > "$PROJECT/.ai-build-kit-maintenance"
}

# Within cadence: 34 days after the recorded visit, nothing at all is printed.
write_record 2026-01-01 2026-02-01
run_hook 2026-03-07
[ ! -s "$OUT" ] || fail "a project inside its check-up cadence was not silent"

# At cadence: 35 days, the reminder appears once, with the action beside it.
run_hook 2026-03-08
grep -qF '35 days since the last check-up' "$OUT" || \
  fail "a project past its check-up cadence was not told, counted from the recorded visit"
grep -qF 'Type /maintain when you have ten minutes.' "$OUT" || \
  fail "the check-up reminder did not name the command to type"
[ "$(grep -c 'since the last check-up' "$OUT")" -eq 1 ] || \
  fail "the check-up reminder appeared more than once"

# Never visited, inside one window since founding: nothing is said.
write_record 2026-03-01 ""
run_hook 2026-03-20
[ ! -s "$OUT" ] || fail "a newly founded project was told a check-up was overdue"

# Never visited, past one window since founding: it is told, and told why.
run_hook 2026-04-10
grep -qF 'has had no check-up yet' "$OUT" || \
  fail "a project past one cadence window since founding was not told"

# No check-up file at all: the founding date comes from the first save of
# masterplan.md, so today's project is never flagged.
rm "$PROJECT/.ai-build-kit-maintenance"
run_hook "$(git -C "$PROJECT" log --reverse --diff-filter=A --format=%cd \
  --date=short -- masterplan.md | head -n 1)"
[ ! -s "$OUT" ] || fail "a project founded today was flagged with no check-up file present"
run_hook 2099-01-01
grep -qF 'check-up' "$OUT" || \
  fail "a long-untouched project with no check-up file was not flagged"

# A damaged file still reports the overdue visit and still never fails.
printf '%s\n' "nonsense" > "$PROJECT/.ai-build-kit-maintenance"
run_hook 2099-01-01
grep -qF 'check-up' "$OUT" || fail "a damaged check-up file suppressed the reminder"

# --- Claude Code hook mode ------------------------------------------------
write_record 2026-01-01 2026-02-01
( cd "$PROJECT" && AI_BUILD_KIT_TODAY=2026-03-08 \
  .agents/hooks/session-start.sh --claude-hook < /dev/null ) > "$OUT" || \
  fail "the session hook exited non-zero in Claude hook mode"
[ "$(wc -l < "$OUT" | tr -d ' ')" -eq 1 ] || \
  fail "Claude hook mode did not produce one line of output"
grep -qF '"hookEventName":"SessionStart"' "$OUT" || \
  fail "Claude hook mode did not name the session-start event"
grep -qF 'since the last check-up' "$OUT" || \
  fail "Claude hook mode dropped the check-up reminder"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$OUT" <<'PYEOF' || fail "Claude hook mode did not produce valid JSON carrying the reminder"
import json, sys
data = json.load(open(sys.argv[1]))
assert data["hookSpecificOutput"]["hookEventName"] == "SessionStart"
assert "since the last check-up" in data["systemMessage"]
assert "check-up is overdue" in data["hookSpecificOutput"]["additionalContext"]
PYEOF
else
  echo "NOTE: python3 unavailable; skipped the JSON parse of Claude hook output" >&2
fi

# Nothing to say means no output at all, rather than an empty message.
( cd "$PROJECT" && AI_BUILD_KIT_TODAY=2026-03-07 \
  .agents/hooks/session-start.sh --claude-hook < /dev/null ) > "$OUT" || \
  fail "the session hook exited non-zero in Claude hook mode inside its cadence"
[ ! -s "$OUT" ] || fail "Claude hook mode spoke with nothing to say"

# A compaction is not a session opening.
printf '%s' '{"source":"compact"}' | ( cd "$PROJECT" && \
  .agents/hooks/session-start.sh --claude-hook ) > "$OUT" || \
  fail "the session hook exited non-zero on a compaction payload"
[ ! -s "$OUT" ] || fail "the session hook spoke again after a compaction"

# --- it changes nothing ---------------------------------------------------
git -C "$PROJECT" checkout -q -- .ai-build-kit-maintenance
[ -z "$(git -C "$PROJECT" status --porcelain)" ] || \
  fail "the session hook changed project files"
[ ! -e "$PROJECT/.agents/tmp" ] || \
  fail "the session hook wrote a working file into the project"

echo "session-start.sh: all checks passed"
