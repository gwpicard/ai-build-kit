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
  stale=$(rs_retired_mentions '/sync([^a-z-]|$)|the sync skill' "$SKILLS" "$WORKFLOW" "$README" \
    "$ROOT/llms.txt" "$ROOT/docs/COMPATIBILITY.md" "$ROOT/.agents/hooks")
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
rs_rule "the comparison makes only the listed reads" \
  'compare the live copy with `main`, read-only\. where the masterplan.s "how it stays running" section records a live address, make only these reads'
rs_rule "the live commit against main" \
  'whether the live copy runs the latest merge on `main`, from its health route or the host.s list of deployments'
rs_rule "a hold left by a rollback" 'whether the live copy is still held on an earlier version since a rollback'
rs_rule "migrations not applied, secret by location" \
  'read with the recipe.s own dry run where it has one, its secret passed by its location'
rs_rule "secret names on the host" 'whether each secret name the tool needs is present on the host, by name only'
rs_rule "health" 'whether health answers\.'
rs_rule "each gap is one line and nothing changes" 'report each gap in one plain line, and change nothing'
rs_rule "no changelog line and no fit check from the comparison" \
  'write nothing to the changelog here, and do not rerun the fit check from this step'
rs_rule "backup, restore, preview and the full checks stay in setup-hosting" \
  'the backup, the restore, the preview and the rest of the recipe.s checks stay in /setup-hosting.s later run'
rs_rule "a gap is sent to setup-hosting" 'offer that later run in one line, with any gap found'
rs_rule "the visit never changes the live service" \
  'never apply a migration, deploy, promote or roll back from this visit'
rs_rule "no live address, no comparison and no word" \
  'without a recorded live address, skip this step and say nothing'
rs_rule "monthly is due thirty days on" \
  'the monthly part is due 30 days after its `last-light-pass` date, or 30 days after founding when no visit is recorded'
rs_rule "quarterly is due ninety days on" \
  'the quarterly part is due 90 days after its `last-full-pass` date'
rs_rule "a handover makes the quarterly part due" 'and whenever the person asks for a handover'
rs_rule "a records-only visit runs only the every-visit steps" \
  'a records-only visit, where the person asks only for the records to be checked, runs only the every-visit steps'
rs_rule "the fit check reruns before the rest of the monthly part" \
  'run it before the rest of the monthly part'
rs_rule "the upgrade runs on every visit" 'finish a kit update, as "finishing a kit update" below says. this runs on every visit'
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
  "$HOSTING" '/maintain makes the reads in this list, except the backup, on every visit, stops there, and sends any gap here for its repair'
rs_require_load_bearing "setup-hosting keeps the heavy checks to its later run" \
  "$HOSTING" 'the backup, the restore, the preview and the rest of the recipe.s checks run only in this later run'

# Told in three places: the skill, WORKFLOW.md, and the README's table row.
rs_require_load_bearing "WORKFLOW says maintain runs at any time" \
  "$WORKFLOW" '/maintain makes the project true and healthy, and you can type it at any time'
rs_require_load_bearing "WORKFLOW says the live copy is compared without change" \
  "$WORKFLOW" 'once your tool is live, every visit also compares the live copy with your project, and changes nothing while it does'
rs_require_load_bearing "WORKFLOW says the upkeep waits until due" \
  "$WORKFLOW" 'the monthly and quarterly upkeep further down runs only when it is due'
# The row once said a visit makes the live copy true. The skill only reads
# the live copy and sends a gap to /setup-hosting, so the row says that.
rs_require "README's row says what a visit does" \
  "$README" 'makes the records true again and checks the live copy against your project, plus any upkeep that is due'
rs_require_absent "README's row no longer says a visit makes the live copy true" \
  "$README" 'makes the records and the live copy true again'

# The session-end reminder sends the person to what-now, the one home for
# leftover work, rather than to a command that no longer exists.
rs_require_load_bearing "the session-end reminder names what-now" \
  "$HOOK" 'next session, /what-now says what they belong to'
rs_require_load_bearing "the session-end reminder says what the changes are" \
  "$HOOK" 'they are edits to its files since the last saved checkpoint'
rs_require_load_bearing "the session-end reminder names maintain for the records" \
  "$HOOK" '/maintain then makes the records true'
rs_require_load_bearing "WORKFLOW says the heavy checks stay in setup-hosting" \
  "$WORKFLOW" 'the backup, restore and preview checks stay in /setup-hosting'

# Retirement switches off things nobody can switch back on. Each step waits
# for its own named yes, and says first whether it can be undone.
rs_require_load_bearing "the export is read back before anything is switched off" "$MAINTAIN" 'export first, and read the export back before anything is switched off'
rs_require_load_bearing "each irreversible ending step waits for a named yes" "$MAINTAIN" 'switches a service off or archives the repository waits for a yes that names that step'
rs_require_load_bearing "it says whether the step can be undone" "$MAINTAIN" 'before asking, say what it changes and whether it can be undone'
rs_require_load_bearing "a yes covers one step" "$MAINTAIN" 'a yes to one step covers only that step'

rs_done
