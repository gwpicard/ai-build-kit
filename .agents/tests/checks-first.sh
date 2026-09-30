#!/usr/bin/env sh
# checks-first.sh: guard the checks written before the code, the tests a piece
# may not touch, and the walk-through that stands in for the person's try.
#
# Two things went wrong in almost every build of a real project. The agent
# checked its own work and saved it without anybody seeing the screen, and
# nothing proved a check tested the new behaviour: a check written after the
# code can pass on today's code, and an unattended builder can weaken a test
# until it passes. Telling an agent not to cheat does not change how often it
# does. So the checks are written first and shown to fail, an existing test
# changes only when the piece names it, and a small script lists every test
# file that changed without that.
#
# Each rule here is prose an agent reads, so the check reads it back and
# proves each one load-bearing. The script is different: it runs, so this
# check runs it in a throwaway repository, once with a changed test the piece
# does not name and once with the piece naming it.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

BUILDER="$ROOT/.agents/skills/section-builder/SKILL.md"
GUARD="$ROOT/.agents/skills/section-builder/scripts/test-guard.sh"
FIX="$ROOT/.agents/skills/fix/SKILL.md"
SETUP="$ROOT/.agents/skills/setup-ai-build-kit/SKILL.md"
MASTERPLAN="$ROOT/.agents/skills/setup-ai-build-kit/templates/masterplan.md"
RECORD="$ROOT/.agents/skills/setup-ai-build-kit/templates/maintenance-record"
PIECES="$ROOT/.agents/skills/setup-ai-build-kit/references/pieces.md"
IMPLEMENT="$ROOT/.agents/skills/implement/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Checks-first and walk-through checks"
rs_exists "$BUILDER" "$FIX" "$SETUP" "$MASTERPLAN" "$RECORD" "$PIECES" \
  "$IMPLEMENT" "$WORKFLOW"

# --- section-builder -------------------------------------------------------

# Checks first. Without the failing run a check can pass on today's code and
# prove nothing about the piece; without its own commit the history cannot
# show the check failing before the change that makes it pass.
rs_rule "machine checks are written before any code" \
  'before any code, write each check a machine can run'
rs_rule "each is run on today's code and shown to fail" \
  'run each one on today.s code and record that it fails'
rs_rule "the checks are committed on their own" \
  'commit the checks on their own, before the code'
rs_rule "checks only a person can make are exempt" \
  'checks only a person can make are exempt'
# A check that passes already means the line is wrong. Building it anyway is
# how a piece closes on a line that never changed anything.
rs_rule "a check passing on today's code means the line is wrong" \
  'the done when line is wrong: say so in the hand-over and do not build that line'
rs_rule "a colour change runs the checks it needs, not the whole suite" \
  'the whole suite is not the default'

# Test protection. The rule, the script that holds it, and what happens to a
# file it lists. The last is the one a builder is tempted past.
rs_rule "an existing test changes only when Under the hood names it" \
  'an existing test may change only when the piece.s `under the hood` names it and gives the reason'
rs_rule "the guard runs before saving" \
  'run this skill.s `scripts/test-guard\.sh'
rs_rule "a listed file is put back as it was" \
  'put each listed file back as it was at the base'
rs_rule "a test is never weakened, skipped or deleted to get past it" \
  'never weaken, skip or delete a test to get past it'
rs_rule "a wrong test or impossible line is reported, never worked round" \
  'report a wrong test or an impossible done when line in the hand-over, and never work round it'

# The walk-through.
rs_rule "the agent drives the tool with sample data" \
  'drive the tool yourself with the project.s sample data'
rs_rule "and records what it saw" 'record what you saw'
rs_rule "screenshots live in a folder git ignores" \
  '\.agents/tmp/walkthrough/<issue number>/'
rs_rule "the walk-through stands in for the person's try" \
  'the walk-through stands in for the person.s try before saving'
rs_rule "the piece still goes to to check and closes on merge" \
  'the piece still moves to `to check` and closes when its pull request merges'
rs_rule "without a browser or screenshots it says what it could check" \
  'where the coding agent cannot drive a browser or take screenshots'
rs_rule "and the piece goes to to check for the person" \
  'goes to `to check` for the person rather than closing'
rs_rule "the report never calls a screen accessible, compliant or good" \
  'never calls a screen accessible, compliant or good'

# Opting in.
rs_rule "a piece opts in with its own line" '`waiting on you: try it`'
rs_rule "every piece opts in through the maintenance record" '`check-myself: yes`'
rs_rule "one address and at most three numbered things to try" \
  'one address to open and up to three numbered things to try'
rs_rule "the address is the one a request reached" \
  'send a request to it and give the address that answered'
rs_rule "nothing is saved before the reply" 'save nothing until the person replies'
rs_rule "an unattended run cannot wait for a try" \
  'in an unattended run nobody is there to try it'
rs_guard "$BUILDER" "section-builder"

# The checkpoint route is still the one route that closes on save, and the
# walk-through that could not see is its one way into to check.
rs_require "the checkpoint route stays the one route that closes on save" \
  "$BUILDER" 'the one route where a piece closes when it is saved rather than when a pull request merges'

# --- /fix ------------------------------------------------------------------

rs_reset
rs_rule "a repair follows the same rules" \
  'the checks-first and test rules in section-builder.s step 4 apply to a repair too'
rs_rule "the failing regression check is committed first" \
  'commit the failing regression check on its own before the fix'
rs_rule "an existing test changes only where the repair names it" \
  'an existing test changes only where the repair.s issue names it'
rs_rule "a test in the way is reported, never weakened" \
  'reported as wrong, never weakened, skipped or deleted'
rs_guard "$FIX" "the /fix skill"

# --- founding offers sample data -------------------------------------------

rs_require_load_bearing "founding offers sample data or test accounts" \
  "$SETUP" 'offer a small set of sample data or test accounts'
rs_require_load_bearing "for a tool with sign-in or a long-lived history" \
  "$SETUP" 'where the tool has sign-in, or keeps a history that grows'
rs_require_load_bearing "and records the answer in How it stays running" \
  "$SETUP" 'a `sample data:` line in the masterplan.s "how it stays running"'
rs_require "the masterplan template names the line" "$MASTERPLAN" 'sample data:'

# --- the opt-in lines where they are read ----------------------------------

rs_require "the maintenance record names the every-piece line" \
  "$RECORD" 'check-myself: yes'
rs_require_load_bearing "pieces.md defines the per-piece line and says it is built" \
  "$PIECES" '`waiting on you: try it` line .{0,80}is built as usual'
rs_require_load_bearing "/implement builds a piece whose only wait is the try" \
  "$IMPLEMENT" 'the `waiting on you: try it` line is different'

rs_require "WORKFLOW.md says checks come first" "$WORKFLOW" 'written first and shown to fail'
rs_require "WORKFLOW.md tells the walk-through" "$WORKFLOW" 'walks through the tool itself'
rs_require "WORKFLOW.md gives the per-piece opt-in" "$WORKFLOW" 'waiting on you: try it'
rs_require "WORKFLOW.md gives the every-piece opt-in" "$WORKFLOW" 'check-myself: yes'
rs_require "WORKFLOW.md says an existing test is protected" \
  "$WORKFLOW" 'changes an existing test only when the piece names it'

# --- the test guard, run both ways -----------------------------------------

[ -f "$GUARD" ] || rs_fail "missing file $GUARD"
[ -x "$GUARD" ] || rs_fail "$GUARD is not runnable"

repo="$rs_dir/repo"
mkdir -p "$repo"
g() { git -C "$repo" -c user.name=check -c user.email=check@example.invalid "$@"; }
g init -q
mkdir -p "$repo/tests" "$repo/src/__tests__" "$repo/test" "$repo/pkg" \
  "$repo/lib" "$repo/docs" "$repo/web"
for f in tests/test_orders.py src/__tests__/list.js test/helper.rb \
  web/cart.test.js web/cart.spec.ts pkg/orders_test.go lib/orders.py \
  docs/testing.md lib/latest.py; do
  echo "one" > "$repo/$f"
done
g add -A
g commit -q -m base
base=$(g rev-parse HEAD)

# Every kind of test file, changed in every way: committed, staged, left
# unstaged, and deleted. Two ordinary files change too, one whose name only
# looks like a test's, and a new test file is added.
for f in tests/test_orders.py src/__tests__/list.js test/helper.rb \
  web/cart.test.js lib/orders.py docs/testing.md lib/latest.py; do
  echo "two" >> "$repo/$f"
done
g add -A
g commit -q -m build
echo "three" >> "$repo/web/cart.spec.ts"
g add web/cart.spec.ts
rm "$repo/pkg/orders_test.go"
echo "new" > "$repo/tests/test_refunds.py"

piece_none="$rs_dir/piece-none.md"
cat > "$piece_none" <<'EOF'
## So that
the orders list shows refunds

## Done when
### Works
- A refunded order shows as refunded. Check: tests/test_orders.py

<details><summary>Under the hood</summary>

Reuse the orders query. No existing test changes.

</details>
EOF

listed=$(cd "$repo" && "$GUARD" "$base" "$piece_none" 2>/dev/null) && status=0 || status=$?
expected="pkg/orders_test.go
src/__tests__/list.js
test/helper.rb
tests/test_orders.py
web/cart.spec.ts
web/cart.test.js"
got=$(printf '%s\n' "$listed" | sort)
rs_report "the guard lists every changed test file the piece does not name" \
  "$([ "$got" = "$expected" ] && echo yes || echo no)"
rs_report "and a file named only outside Under the hood still counts as unnamed" \
  "$(printf '%s\n' "$listed" | grep -qx 'tests/test_orders.py' && echo yes || echo no)"
rs_report "and stops the save by exiting non-zero" \
  "$([ "$status" -ne 0 ] && echo yes || echo no)"

piece_named="$rs_dir/piece-named.md"
cat > "$piece_named" <<'EOF'
## So that
the orders list shows refunds

<details><summary>Under the hood</summary>

Existing tests this piece changes, with the reason:
- tests/test_orders.py: the list now has a refunded column.
- src/__tests__/list.js, test/helper.rb, web/cart.test.js, web/cart.spec.ts:
  they build the old list shape.
- pkg/orders_test.go: it tested the removed refund screen.

</details>
EOF

listed=$(cd "$repo" && "$GUARD" "$base" "$piece_named" 2>/dev/null) && status=0 || status=$?
rs_report "the guard lists nothing when the piece names every changed test" \
  "$([ -z "$listed" ] && [ "$status" -eq 0 ] && echo yes || echo no)"

if (cd "$repo" && "$GUARD" not-a-commit "$piece_named") >/dev/null 2>&1; then
  rs_fail "the guard accepts a base that is not a commit"
fi
rs_ok "the guard refuses a base that is not a commit"

rs_done
