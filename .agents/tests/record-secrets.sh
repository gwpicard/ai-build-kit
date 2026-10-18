#!/usr/bin/env sh
# record-secrets.sh: a secret-shaped value never reaches the kit's saved records (masterplan, changelog, AGENTS.md, a pull request or issue body), and the refusal names the record, never the value.
#
# secrets-gates.sh and push-guard.sh hold commits and command output. This
# holds the records the kit itself writes: the pull request body gate.py
# records, the changelog entry run-recipe.sh writes, and what Claude Code would
# write into a record file or a GitHub body. Each is given a made-up key and
# must refuse, say which record, and leave it as it was.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
FOUNDATION="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation"
GATE="$ROOT/.agents/skills/quality-checks/scripts/gate.py"
RUNNER="$ROOT/.agents/skills/setup-hosting/scripts/run-recipe.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
FAILED=0
fail() { echo "FAIL: $1" >&2; FAILED=1; }
pass() { echo "ok: $1"; }
export SCAN_SECRETS_DISABLE_GITLEAKS=1
# Built here, so no key-shaped text sits in a tracked file.
KEY=$(python3 -c 'import secrets; print("gh" + "p_" + secrets.token_hex(18))')

git -C "$WORK" init -q project
PROJECT="$WORK/project"
git -C "$PROJECT" config user.name Rehearsal
git -C "$PROJECT" config user.email rehearsal@example.invalid
printf '# Changelog\n\n## 2024-01-01\n\nStarted.\n' > "$PROJECT/CHANGELOG.md"
git -C "$PROJECT" add CHANGELOG.md
git -C "$PROJECT" commit -qm base

# --- the pull request body gate.py records -----------------------------------
mkdir -p "$WORK/bin"
cat > "$WORK/bin/gh" <<'SH'
#!/usr/bin/env sh
case "$1 $2" in
  "pr view") printf '%s\n' '{"title":"Example","body":"Summary","headRefOid":"","author":{"login":"agent"},"reviews":[]}' ;;
  "pr edit") printf 'edited\n' >> "$GH_EDITS" ;;
  *) exit 2 ;;
esac
SH
chmod +x "$WORK/bin/gh"
export GH_EDITS="$WORK/edits"
out=$(cd "$PROJECT" && PATH="$WORK/bin:$PATH" python3 "$GATE" record --pr 9 2>&1 <<JSON
[{"mark":"reasoned","finding":"The settings page shows the key $KEY to visitors","scenario":"A visitor opens the settings page and can read the key","worth_stopping_for":true}]
JSON
) && code=0 || code=$?
[ "$code" -eq 2 ] && [ ! -e "$WORK/edits" ] && printf '%s' "$out" | grep -q 'possible secret in pull request 9 body' \
  && ! printf '%s' "$out" | grep -qF "$KEY" \
  && pass "a review record carrying a key is not written to the pull request, and the refusal names the body only" \
  || fail "a key reached the pull request body or was printed ($code): $out"

# --- the changelog entry run-recipe.sh writes --------------------------------
cp "$PROJECT/CHANGELOG.md" "$WORK/changelog-before"
out=$(sh "$RUNNER" --project "$PROJECT" --chose "Go on without a recipe" --note "Set the token to $KEY" none 2>&1) && code=0 || code=$?
[ "$code" -eq 2 ] && cmp -s "$WORK/changelog-before" "$PROJECT/CHANGELOG.md" \
  && printf '%s' "$out" | grep -q 'possible secret in CHANGELOG.md' && ! printf '%s' "$out" | grep -qF "$KEY" \
  && pass "a changelog entry carrying a key is not written, and the refusal names CHANGELOG.md only" \
  || fail "a key reached the changelog or was printed ($code): $out"
out=$(sh "$RUNNER" --project "$PROJECT" --chose "Go on without a recipe" --note "Set the token from the team vault" none 2>&1) && code=0 || code=$?
grep -q 'Set the token from the team vault' "$PROJECT/CHANGELOG.md" \
  && pass "an entry that names only where a secret is kept is written" || fail "a clean entry was not written ($code): $out"

# --- what Claude Code would write -------------------------------------------
guard() {
  python3 -c 'import json, sys; print(json.dumps({"hook_event_name": "PreToolUse", "tool_name": sys.argv[1], "tool_input": json.loads(sys.argv[2])}))' "$1" "$2" |
    CLAUDE_PROJECT_DIR="$PROJECT" sh "$FOUNDATION/guard-secrets.sh" > "$WORK/guard-out" 2> "$WORK/guard-err"
}
denied() { grep -q '"permissionDecision":"deny"' "$WORK/guard-out"; }
tool_input() { python3 -c 'import json, sys; print(json.dumps(dict(zip(sys.argv[1::2], sys.argv[2::2]))))' "$@"; }

guard Write "$(tool_input file_path "$PROJECT/masterplan.md" content "Key: $KEY")"
denied && grep -q 'into masterplan.md' "$WORK/guard-out" && ! grep -qF "$KEY" "$WORK/guard-out" \
  && pass "Claude Code is refused a masterplan write carrying a key, named by file" || fail "the masterplan write was not refused: $(cat "$WORK/guard-out")"
guard Edit "$(tool_input file_path "$PROJECT/CHANGELOG.md" old_string Started. new_string "Started with $KEY")"
denied && grep -q 'into CHANGELOG.md' "$WORK/guard-out" \
  && pass "Claude Code is refused a changelog edit carrying a key" || fail "the changelog edit was not refused: $(cat "$WORK/guard-out")"
guard Write "$(tool_input file_path "$PROJECT/masterplan.md" content "The key is kept in the team vault.")"
denied && fail "a masterplan write naming only where a key is kept was refused" || pass "a record naming only where a key is kept is written"
guard Bash "$(tool_input command "gh issue create --title Login --body 'Use $KEY to sign in'")"
denied && grep -q 'into the issue body' "$WORK/guard-out" && ! grep -qF "$KEY" "$WORK/guard-out" \
  && pass "Claude Code is refused an issue body carrying a key, named without the value" || fail "the issue body was not refused: $(cat "$WORK/guard-out")"
printf 'Rotate %s today\n' "$KEY" > "$PROJECT/body.md"
guard Bash "$(tool_input command "gh pr edit 9 --body-file body.md")"
denied && grep -q 'into the pull request body' "$WORK/guard-out" \
  && pass "Claude Code is refused a pull request body file carrying a key" || fail "the body file was not refused: $(cat "$WORK/guard-out")"

[ "$FAILED" -eq 0 ] && echo "record-secrets.sh: all checks passed"
exit "$FAILED"
