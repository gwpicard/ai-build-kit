#!/usr/bin/env sh
# maintain-drift-rehearsal.sh: drift a disposable project and run /maintain's
# restore scripts. If this breaks, drift can survive a maintenance visit or a
# project can lose its own run-mode choice.

set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
PROJECT="$WORK/project"
mkdir -p "$PROJECT/.agents/skills/maintain/scripts" \
  "$PROJECT/.agents/skills/setup-ai-build-kit/templates/foundation" \
  "$PROJECT/.claude/commands" "$WORK/bin"
cp -R "$ROOT/.agents/skills/maintain/." "$PROJECT/.agents/skills/maintain/"
cp "$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json" \
  "$PROJECT/.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json"

# A stale generated command is kit-owned and may be removed by the update.
cat > "$PROJECT/.claude/commands/ship.md" <<'EOF'
<!-- GENERATED from .agents/skills/ship/. Do not edit here; regenerate with .agents/tools/build-adapters.sh -->
old command
EOF

# The old safety file has a person's rule and is deliberately edited.
cat > "$PROJECT/.claude/settings.json" <<'EOF'
{
  "permissions": {"deny": ["Bash(git push --force:*)"], "ask": []},
  "customSetting": "keep this"
}
EOF
cat > "$PROJECT/AGENTS.md" <<'EOF'
Recipe: retired-recipe
EOF
cat > "$PROJECT/masterplan.md" <<'EOF'
Path: Build and run it
Runs on its own: queue, parallel 2, loop (decided 2026-10-15, "rehearsal")
EOF
mkdir -p "$PROJECT/.agents/skills/setup-hosting/recipes"

pass() { echo "  ok: $1"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

report=$(python3 "$PROJECT/.agents/skills/maintain/scripts/kit-leftovers.py" "$PROJECT")
adapter_line=$(printf 'adapter\t.claude/commands/ship.md')
printf '%s\n' "$report" | grep -q "$adapter_line" \
  || fail "the stale generated command was not reported"
python3 "$PROJECT/.agents/skills/maintain/scripts/kit-leftovers.py" --remove "$PROJECT" >/dev/null
[ ! -e "$PROJECT/.claude/commands/ship.md" ] || fail "the stale generated command was not removed"
pass "removes a stale generated kit command"

rules=$(python3 "$PROJECT/.agents/skills/maintain/scripts/settings-rules.py" "$PROJECT" || [ "$?" -eq 1 ])
printf '%s\n' "$rules" | grep -q '^deny[[:space:]]' || fail "edited settings drift was not reported"
python3 "$PROJECT/.agents/skills/maintain/scripts/settings-rules.py" --apply "$PROJECT"
python3 - "$PROJECT/.claude/settings.json" <<'PY' || fail "settings restore lost the person's setting or missed kit rules"
import json, sys
data=json.load(open(sys.argv[1]))
assert data['customSetting']=='keep this'
deny=data['permissions']['deny']
assert 'Bash(git push --force:*)' in deny
assert any('main' in rule and 'git push' in rule for rule in deny)
PY
pass "adds missing kit settings and keeps the person's setting"

set +e
recipe=$(python3 "$PROJECT/.agents/skills/maintain/scripts/recipe-freshness.py" "$PROJECT")
recipe_status=$?
set -e
[ "$recipe_status" -eq 1 ] && printf '%s\n' "$recipe" | grep -q 'Recipe superseded: retired-recipe' \
  || fail "the retired recipe was not reported for a separate move"
pass "reports the retired recipe without changing it"

# Stand in for GitHub. No request leaves this temporary rehearsal.
cat > "$WORK/bin/gh" <<'EOF'
#!/usr/bin/env python3
import json, os, sys
args=sys.argv[1:]
if args[:2] != ['api','-X']:
    sys.exit(2)
method, path=args[2], args[3]
if method == 'GET' and path.endswith('/protection'):
    print('Not Found', file=sys.stderr); sys.exit(1)
if method == 'GET':
    print('{}'); sys.exit(0)
if method == 'PUT' and path.endswith('/protection'):
    body=json.load(sys.stdin)
    assert body['required_status_checks']['contexts']==['project-check']
    open(os.environ['FAKE_PROTECTION'], 'w').write('project-check')
    sys.exit(0)
sys.exit(2)
EOF
chmod +x "$WORK/bin/gh"
FAKE_PROTECTION="$WORK/protection" PATH="$WORK/bin:$PATH" \
  python3 "$ROOT/.agents/skills/merge/scripts/protect-branch.py" example/project main \
  >"$WORK/protection.out" 2>"$WORK/protection.err" \
  || fail "the missing protection could not be restored against the local stand-in"
grep -q 'project-check required on main' "$WORK/protection.out" \
  && [ "$(cat "$WORK/protection")" = project-check ] \
  || fail "the missing project-check protection was not reported and restored"
pass "restores missing branch protection through a local stand-in"

grep -q 'Runs on its own: queue, parallel 2, loop' "$PROJECT/masterplan.md" \
  || fail "maintenance changed the project's queued, parallel or loop choice"
pass "keeps the project's queued, parallel and loop record while resetting kit files"
echo "Drift restore rehearsal passed."
