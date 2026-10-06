#!/usr/bin/env sh
# maintain-trues-every-visit.sh: guard what every /maintain visit does now that
# /sync has folded into it.
#
# /sync caught the records up with what really happened. It was a second door
# to the service visit, and most people never typed it. So every /maintain
# visit now trues the records first, whenever it runs, and the monthly and
# quarterly upkeep run only when they are due. A visit that ran the whole
# monthly pass every time it was typed would teach people not to type it.
#
# The same visit compares the live copy with main, using /setup-hosting's own
# comparison, and stops there. A visit nobody asked to change the live service
# must never apply a migration, deploy, promote or roll back. Those repairs
# stay with /setup-hosting, each behind its own yes.
#
# Two jobs had two homes before the fold, and each now has one. Leftover work
# from an interrupted session is /what-now's to recover; the truing reports it
# and leaves it alone. AGENTS.md is trimmed only by the monthly offer; the
# truing adds a learned line but never trims.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SKILLS="$ROOT/.agents/skills"
MAINTAIN="$SKILLS/maintain/SKILL.md"
TRUING="$SKILLS/maintain/references/truing.md"
HOSTING="$SKILLS/setup-hosting/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"
README="$ROOT/README.md"
HOOK="$ROOT/.agents/hooks/session-end-sync.sh"

rs_init "Maintain trues every visit"
rs_exists "$MAINTAIN" "$TRUING" "$HOSTING" "$WORKFLOW" "$README" "$HOOK"

# The sync command is gone, so nothing shipped may send the person to it. The
# mutation audit lists rules only, so these direct reads stay out of its way.
if [ -z "${RS_LIST:-}" ]; then
  [ ! -e "$SKILLS/sync" ] || rs_fail "the sync skill folder is still there"
  rs_ok "the sync skill folder is gone"
  stale=$(grep -rlE '/sync([^a-z-]|$)|the sync skill' "$SKILLS" "$WORKFLOW" "$README" \
    "$ROOT/llms.txt" "$ROOT/docs/COMPATIBILITY.md" "$ROOT/.agents/hooks" || true)
  [ -z "$stale" ] || rs_fail "a shipped file still points at /sync: $stale"
  rs_ok "no shipped skill, WORKFLOW, README, llms.txt, COMPATIBILITY or hook points at /sync"
  if rs_fold "$MAINTAIN" | grep -qE 'run sync'; then
    rs_fail "the quarterly part still runs sync, which every visit now does first"
  fi
  rs_ok "the quarterly part does not run the truing a second time"
fi

# Every visit, whenever it runs.
rs_rule "the visit can run at any time" \
  'this command can run at any time\. every visit makes the project true again'
rs_rule "the upkeep runs only when due" \
  'the monthly and quarterly parts run only when they are due'
rs_rule "the comparison is the later run's, read-only" \
  'run the comparison in the `setup-hosting` skill.s "a later run" read-only'
rs_rule "each gap is one line and nothing changes" \
  'compare, report each gap in one plain line, and change nothing'
rs_rule "a gap is sent to setup-hosting" 'offer /setup-hosting in one line to repair it'
rs_rule "the visit never changes the live service" \
  'never apply a migration, deploy, promote or roll back from this visit'
rs_rule "no live address, no comparison and no word" \
  'without a recorded live address, skip this step and say nothing'
rs_rule "monthly is due thirty days on" \
  'the monthly part is due 30 days after its `last-light-pass` date, or 30 days after founding when no visit is recorded'
rs_rule "quarterly is due ninety days on" \
  'the quarterly part is due 90 days after its `last-full-pass` date'
rs_rule "a handover makes the quarterly part due" 'and whenever the person asks for a handover'
rs_rule "a records-only request runs only the truing" \
  'where they ask only for the records to be checked, run only the steps in this section'
rs_rule "a part not due is named with its date" \
  'where a part is not due, say so in one line with the date it falls due'
rs_rule "the monthly heading says when due" '## monthly, when due'
rs_rule "the quarterly heading says when due" '## quarterly, when due'
rs_guard "$MAINTAIN" "the maintain skill's every-visit steps"

rs_reset
rs_rule "the truing runs on every visit" 'every `/maintain` visit runs this first, whenever it runs'
rs_rule "what-now owns recovery" '/what-now owns recovery after an interrupted session'
rs_rule "the truing only reports leftover work" \
  'the truing only reports that work and leaves it alone'
rs_rule "the AGENTS.md trim has one home" \
  'belong to the monthly trim offer, which is their one home, so do not trim agents\.md here'
rs_guard "$TRUING" "the maintain skill's truing"

rs_require_load_bearing "setup-hosting says maintain runs its comparison and stops" \
  "$HOSTING" '/maintain runs this same comparison on every visit, stops there, and sends any gap here for its repair'

# Told in three places: the skill, WORKFLOW.md, and the README's table row.
rs_require_load_bearing "WORKFLOW says maintain runs at any time" \
  "$WORKFLOW" '/maintain makes the project true and healthy, and you can type it at any time'
rs_require_load_bearing "WORKFLOW says the live copy is compared without change" \
  "$WORKFLOW" 'once your tool is live, every visit also compares the live copy with your project, and changes nothing while it does'
rs_require_load_bearing "WORKFLOW says the upkeep waits until due" \
  "$WORKFLOW" 'the monthly and quarterly upkeep further down runs only when it is due'
rs_require "README's row says what a visit does" \
  "$README" 'makes the records and the live copy true again, plus any upkeep that is due'

# The session-end reminder sends the person to what-now, the one home for
# leftover work, rather than to a command that no longer exists.
rs_require_load_bearing "the session-end reminder names what-now" \
  "$HOOK" 'next session, /what-now says what they belong to'

rs_done
