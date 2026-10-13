#!/usr/bin/env sh
# upgrade-route.sh: run upgrade-check.py --latest --route with stand-ins for
# the GitHub and Claude Code command line tools.
#
# If this breaks, /maintain offers an update that does not exist yet because a
# draft release was read, says a project is up to date when the check never
# ran, or updates a shared installation with `npx skills update`, which drops
# any skill the lockfile does not list and so loses a renamed command.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SKILL="$ROOT/.agents/skills/maintain"
SCRIPT="$SKILL/scripts/upgrade-check.py"
HELD=$(cat "$SKILL/VERSION")

FAIL=0
fail() { echo "FAIL: $1" >&2; FAIL=1; }
pass() { echo "ok: $1"; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin" "$WORK/project"
ln -s "$(command -v python3)" "$WORK/bin/python3"
ln -s "$(command -v sh)" "$WORK/bin/sh"
P="$WORK/project"
printf '# Masterplan\n' > "$P/masterplan.md"
LOG="$WORK/calls.log"

# gh answers releases/latest with $LATEST, or 404 when it is empty.
cat > "$WORK/bin/gh" <<'SH'
#!/bin/sh
echo "gh $*" >> "$CALLS_LOG"
case "$*" in
  "api repos/gwpicard/ai-build-kit/releases/latest --jq .tag_name")
    [ -n "$LATEST" ] || { echo "gh: Not Found (HTTP 404)" >&2; exit 1; }
    echo "$LATEST" ;;
  *) echo "unexpected call" >&2; exit 1 ;;
esac
SH
# claude prints $PLUGINS as its plugin list.
cat > "$WORK/bin/claude" <<'SH'
#!/bin/sh
echo "claude $*" >> "$CALLS_LOG"
[ "$*" = "plugin list --json" ] || exit 1
printf '%s\n' "${PLUGINS:-[]}"
SH
chmod +x "$WORK/bin/gh" "$WORK/bin/claude"
export CALLS_LOG="$LOG" PLUGINS='[]' LATEST=

run() {
  r=$(cd "$P" && PATH="$WORK/bin" python3 "${SCRIPT_AT:-$SCRIPT}" "$@" .) && c=0 || c=$?
  printf '%s\n' "$r" >> "$WORK/every-answer.txt"
  printf '%s\n' "$r"
  return "$c"
}

echo "== The version check =="
LATEST=$HELD
out=$(run --latest) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s\n' "$out" | grep -qx "holds	$HELD" && printf '%s\n' "$out" | grep -qx "latest	$HELD" \
  && pass "matching versions exit 0 and name both numbers" \
  || fail "matching versions returned $code: $out"
[ "$(grep -c '^gh ' "$LOG")" -eq 1 ] && grep -qx 'gh api repos/gwpicard/ai-build-kit/releases/latest --jq .tag_name' "$LOG" \
  && pass "only releases/latest is asked, the endpoint that never answers with a draft" \
  || fail "the version check asked: $(cat "$LOG")"

LATEST=v99.0.0
out=$(run --latest) && code=0 || code=$?
[ "$code" -eq 1 ] && printf '%s\n' "$out" | grep -qx 'latest	v99.0.0' \
  && pass "a newer published release exits 1" || fail "a newer release returned $code: $out"

LATEST=
out=$(run --latest) && code=0 || code=$?
[ "$code" -eq 3 ] && printf '%s\n' "$out" | grep -q '^latest	unknown' && ! printf '%s' "$out" | grep -q 'compare' \
  && pass "a failed call exits 3 and claims no comparison" || fail "a failed call returned $code: $out"

LATEST='Not a version'
out=$(run --latest) && code=0 || code=$?
[ "$code" -eq 3 ] && pass "an answer that is not a version is not trusted" || fail "a garbled answer returned $code"

mv "$WORK/bin/gh" "$WORK/gh.away"
out=$(run --latest) && code=0 || code=$?
[ "$code" -eq 3 ] && pass "with no GitHub tool the check says it did not happen" || fail "a missing gh returned $code"
mv "$WORK/gh.away" "$WORK/bin/gh"

echo "== The update route =="
out=$(run --route) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'route	older	npx skills add gwpicard/ai-build-kit' \
  && pass "an installation with no record is updated with the installer's add" \
  || fail "an older installation read as $code: $out"

printf '{"skills": {"shape": {"source": "gwpicard/ai-build-kit"}}}\n' > "$P/skills-lock.json"
out=$(run --route) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'route	shared	npx skills add gwpicard/ai-build-kit' \
  && pass "a shared installation is updated with add" || fail "a shared installation read as $code: $out"

PLUGINS='[{"id":"ai-build-kit@ai-build-kit","scope":"local","enabled":true,"projectPath":"'"$P"'"}]'
out=$(run --route) && code=0 || code=$?
[ "$code" -eq 4 ] && printf '%s\n' "$out" | grep -q '^route	claude-plugin' \
  && pass "two active routes exit 4, so the person chooses one" || fail "two routes returned $code: $out"

rm "$P/skills-lock.json"
out=$(run --route) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'route	claude-plugin	claude plugin marketplace update ai-build-kit' \
  && printf '%s\n' "$out" | grep -qx 'then	claude plugin update ai-build-kit@ai-build-kit --scope local' \
  && pass "the Claude plugin route names its two commands with the recorded scope" \
  || fail "the plugin route read as $code: $out"

PLUGINS='[{"id":"ai-build-kit@ai-build-kit","scope":"local","enabled":true,"projectPath":"/another/project"}]'
out=$(run --route) && code=0 || code=$?
printf '%s\n' "$out" | grep -q '^route	older' \
  && pass "a plugin installed for another folder does not count here" || fail "another folder's plugin was counted: $out"
PLUGINS='[]'

# An Agent Plugins installation: the skill runs from <plugin>/skills/maintain.
mkdir -p "$WORK/agent-plugin/skills"
cp -R "$SKILL" "$WORK/agent-plugin/skills/maintain"
printf '{"name": "ai-build-kit"}\n' > "$WORK/agent-plugin/plugin.json"
SCRIPT_AT="$WORK/agent-plugin/skills/maintain/scripts/upgrade-check.py"
out=$(run --route) && code=0 || code=$?
unset SCRIPT_AT
[ "$code" -eq 0 ] && printf '%s\n' "$out" | grep -q '^route	agent-plugin' \
  && pass "an Agent Plugins installation is named as its own route" || fail "the agent plugin route read as $code: $out"

# A project holding a release from before v0.20 goes through v0.20.3 first,
# since a later release no longer finishes the changes made before then.
mkdir -p "$WORK/old-kit"
cp -R "$SKILL" "$WORK/old-kit/maintain"
printf 'v0.19.3\n' > "$WORK/old-kit/maintain/VERSION"
LATEST=v99.0.0
SCRIPT_AT="$WORK/old-kit/maintain/scripts/upgrade-check.py"
out=$(run --latest) && code=0 || code=$?
unset SCRIPT_AT
[ "$code" -eq 1 ] && printf '%s\n' "$out" | grep -q '^first	v0.20.3	' \
  && pass "a project older than v0.20 is told to install v0.20.3 first" \
  || fail "an older project read as $code: $out"
out=$(run --latest) && code=0 || code=$?
! printf '%s\n' "$out" | grep -q '^first' \
  && pass "a current project is not sent back to v0.20.3" || fail "a current project was sent back: $out"

LATEST=$HELD
out=$(run --latest --route) && code=0 || code=$?
[ "$code" -eq 0 ] && printf '%s\n' "$out" | grep -q '^latest' && printf '%s\n' "$out" | grep -q '^route' \
  && pass "both together give the version and the route" || fail "both together returned $code: $out"

grep -q 'npx skills add' "$WORK/every-answer.txt" && ! grep -q 'skills update' "$WORK/every-answer.txt" \
  && pass "no answer ever names npx skills update" || fail "an answer named npx skills update"

out=$(run --latest --monthly 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && pass "--latest does not mix with the other steps" || fail "mixed flags returned $code"

[ "$FAIL" -eq 0 ] || exit 1
echo "upgrade-route.sh: all checks passed"
