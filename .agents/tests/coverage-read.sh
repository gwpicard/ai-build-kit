#!/usr/bin/env sh
# coverage-read.sh: guard the read that compares the masterplan against the
# pieces.
#
# The masterplan says what the tool must do and the pieces say what gets built.
# The coverage read compares them at the end of founding and inside /sync, says
# what nothing would build, and changes nothing by itself. A
# machine cannot watch that conversation without paying a model, so this guards
# its source on every push: the rules that keep the read honest, the two
# commands that call it, and the plain explanation a person actually reads.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

READFILE="$ROOT/.agents/skills/setup-ai-build-kit/references/coverage-read.md"
SETUP="$ROOT/.agents/skills/setup-ai-build-kit/SKILL.md"
SYNC="$ROOT/.agents/skills/sync/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Coverage-read checks"

rs_rule "counts pieces open and closed" 'open and closed'
rs_rule "the line said when the plan covers the page" 'has a piece that builds it\."'
rs_rule "a promise left to a parked piece is a gap" 'parked counts as a gap'
rs_rule "never names a promise that is not on the page" 'not on the page'
rs_rule "never adds a piece without a yes" 'without a yes'
rs_rule "never edits or closes a piece by itself" 'never edits, closes'
rs_rule "offers once rather than repeatedly" 'one offer'
rs_rule "reports and stops on explore privately" 'explore privately'
rs_guard "$READFILE" "the shipped coverage-read.md"

rs_require "/setup runs the coverage read once the pieces are cut" \
  "$SETUP" 'references/coverage-read\.md'
rs_require "/sync runs the coverage read while reconciling" \
  "$SYNC" 'coverage-read\.md'

# The house rule is that a behaviour is told in three places or it is not
# finished. The skills carry two of them; WORKFLOW.md carries the plain one, in
# both the founding and the sync sections.
rs_require_twice "WORKFLOW.md explains it for founding and for sync" \
  "$WORKFLOW" 'piece that builds it'

rs_done
