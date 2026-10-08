#!/usr/bin/env sh
# repair-is-a-piece.sh: guard how a fault becomes a piece now that no command
# of its own exists.
#
# A separate repair command made the person sort their own request before
# typing, which the kit is meant to do for them. So a bug is a piece like any
# other: /shape reproduces it and writes the failing case as its done line, and
# /implement builds it with the repair rules. Those rules moved whole into one
# reference section-builder loads, and the checks that guard them read it there.
#
# This check holds what the move added. A bug is shaped by reproducing it, and
# is ready only once it is. A request for behaviour nobody promised is new work.
# A small, clear repair is ready at once and offered for the same session, so a
# typo does not cost a planning sitting. A live break after a recent merge gets
# the earlier version offered back first, whatever was typed, and only on a yes
# that names it. Some hosts hold the live copy on the earlier version until a
# newer build is promoted, and a later run of /setup-hosting has to notice that,
# or every merge after the rollback silently stops going live.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SKILLS="$ROOT/.agents/skills"
REPAIR="$SKILLS/section-builder/references/repair.md"
TRIAGE="$SKILLS/change-triage/SKILL.md"
SHAPE="$SKILLS/shape/SKILL.md"
BUILDER="$SKILLS/section-builder/SKILL.md"
IMPLEMENT="$SKILLS/implement/SKILL.md"
HOSTING="$SKILLS/setup-hosting/SKILL.md"
VERCEL="$SKILLS/setup-hosting/recipes/nextjs-supabase-on-vercel.md"
PIECES="$SKILLS/setup-ai-build-kit/references/pieces.md"
BLOCKED="$SKILLS/setup-ai-build-kit/references/blocked-commands.md"
GUARD="$ROOT/.agents/guard/blocked-commands.md"
WHATNOW="$SKILLS/what-now/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "A repair is a piece"
rs_exists "$REPAIR" "$TRIAGE" "$SHAPE" "$BUILDER" "$IMPLEMENT" "$HOSTING" \
  "$VERCEL" "$PIECES" "$BLOCKED" "$GUARD" "$WHATNOW" "$WORKFLOW"

# The repair command is gone, so nothing may send the person to it. The
# mutation audit lists rules only, so these direct reads stay out of its way.
if [ -z "${RS_LIST:-}" ]; then
  [ ! -e "$SKILLS/fix" ] || rs_fail "the fix skill folder is still there"
  rs_ok "the fix skill folder is gone"
  stale=$(rs_retired_mentions '/fix([^a-z-]|$)|the fix skill' "$SKILLS" "$WORKFLOW" "$ROOT/README.md" "$ROOT/llms.txt")
  [ -z "$stale" ] || rs_fail "a shipped file still points at /fix: $stale"
  rs_ok "no shipped skill, WORKFLOW, README or llms.txt points at /fix"
fi

# Shaping a bug is reproducing it.
rs_rule "shaping changes no saved file" 'shaping changes no file the project saves'
rs_rule "a throwaway goes where git ignores it" 'a throwaway harness goes in `\.agents/tmp/`, which git ignores'
rs_rule "a bug is ready once reproduced" 'a repair is ready once it is reproduced'
rs_rule "the failing case is the done line" 'its `## done when` is the failing case'
rs_rule "the check travels with the piece" 'put the check itself, how it is run and how reliable it is, in `under the hood`'
rs_rule "no loop means the piece waits on the person" 'a `## waiting on you` section naming what is missing'
rs_rule "never patch without a loop" 'never begin speculative patching without a loop'
# Building it follows the rules the repair command held.
rs_rule "the build runs the recorded check first" 'run the check the piece records before anything else'
rs_rule "a check that no longer fails stops the build" 'where it no longer fails, say so in one line and ask whether the fault still happens'
rs_rule "the reset step is announced" 'say in one line, before you run it, that the reset throws away the failed attempt and nothing else'
rs_rule "the reset step is the only place for the discard commands" 'this announced step is the only place either command is allowed'
rs_rule "the shaping throwaway is cleared" 'clear what shaping left in `\.agents/tmp/` for this piece too'
rs_guard "$REPAIR" "section-builder's repair reference"

rs_reset
rs_rule "a fault comes through triage too" 'a report of a fault comes here too, in whatever words it arrives'
rs_rule "a live break offers the earlier version first" 'offer the earlier version back first, before shaping the repair'
rs_rule "the rollback waits for a yes that names it" 'run it only after a yes that names it'
rs_rule "the rollback follows setup-hosting's procedure" 'following the `setup-hosting` skill.s "rolling back"'
rs_rule "off a recipe the kit says it cannot" 'off a recipe, say what a rollback would need and that the kit cannot do it here'
rs_rule "then the repair is shaped" 'either way, then shape the repair'
rs_rule "a repair needs a promise" 'a report is a repair only where the behaviour it asks for was promised'
rs_rule "an unpromised wish is new work" 'route it as new behaviour'
rs_rule "a small clear repair is ready at once" 'mark the piece ready at once, with the failing case as its `## done when`'
rs_rule "and offered for the same session" 'offer to build it in this same session rather than a fresh one'
rs_rule "anything else is reproduced" 'anything less certain is shaped by reproducing it'
# A review found the fast path could mark a fault ready from the report alone,
# which the old repair command never allowed: no patching without a loop.
rs_rule "the fast path needs a look on this computer" 'where one look on this computer shows the fault'
rs_rule "a report alone is not a reproduction" 'a report alone is not enough: you must have seen the fault yourself'
rs_rule "the fast path still defines the symptom" 'still define the symptom as "shaping a repair" says'
# The same review found a fresh session reporting a fault for the fourth time
# went straight to shaping, and the three-attempt notice never came.
rs_rule "the history is read before shaping" 'read the history for the same area before shaping anything'
rs_rule "merged pull requests count as history" 'closed pieces and merged pull requests'
rs_rule "three surviving attempts escalate in the same reply" 'follow that file.s "escalation" in this same reply, notice included, before marking anything ready'
rs_rule "a fresh session does not reset the count" 'a fresh session is no reason to start the count again'
# And a rollback offered for a project with nothing live, or for a fault that
# was already there, brings back nothing worth having.
rs_rule "a rollback needs a recorded live address" 'records a live address'
rs_rule "and a recipe that says how to roll back" 'whose rollback section names how to roll back'
rs_rule "the earlier version must have worked" 'check first that the version before that merge did not have the fault'
rs_rule "a fault already there gets no offer" 'a fault that was already there is not brought back by a rollback, so offer none'
rs_guard "$TRIAGE" "change-triage's broken-report checks"
rs_require_order "the promise check comes before the live break" "$TRIAGE" \
  '^### Was this ever promised\?$' '^### A live break after a recent merge$'
rs_require_order "the live break comes before the three-attempt read" "$TRIAGE" \
  '^### A live break after a recent merge$' '^### A fault that has survived three attempts$'
rs_require_order "the three-attempt read comes before the fast path" "$TRIAGE" \
  '^### A fault that has survived three attempts$' '^### A small, clear repair$'
rs_require_order "the live break comes before the usual steps" "$TRIAGE" \
  'A live break after a recent merge' '^## Step 2: Classify intent$'

rs_reset
rs_rule "shape follows the repair reference" 'follow "shaping a repair" in the `section-builder` skill.s `references/repair\.md`'
rs_rule "shape says the piece is ready once reproduced" 'the piece is ready once it is reproduced'
rs_rule "shape takes an unreproduced repair first" 'take a repair not yet reproduced first'
rs_rule "the small repair is offered here and now" 'a small, clear repair is the one exception'
rs_guard "$SHAPE" "shape's repair rules"

rs_reset
rs_rule "section-builder loads the repair reference for a broken piece" 'a piece labelled `broken` is a repair\. load `references/repair\.md`'
rs_rule "its escalation holds" 'its escalation holds after three failed attempts'
rs_rule "a held live copy is said before the merge" 'the merge alone does not put this change live'
rs_rule "a held live copy is said after the merge" 'the merge does not go live until /setup-hosting promotes it'
rs_rule "and is not read as did not update" 'do not read the health line as "did not update"'
rs_rule "the merge step rolls nothing back itself" 'run none in this step\. nothing here changes the live copy unasked'
rs_rule "a live break after the merge goes to triage" 'a rollback runs only on the yes it asks for'
rs_rule "a ready repair is named next first" 'a ready repair comes first: name a piece under its `broken` group marked `\(ready\)`'
rs_guard "$BUILDER" "section-builder's repair hand-off"

rs_reset
rs_rule "a ready repair comes first" 'a ready repair comes first'
rs_rule "a live break goes to triage first" 'given a report that the live tool broke, wherever it was typed'
rs_rule "a ready repair is named next first" 'a repair under `broken` marked `\(ready\)` comes first'
rs_rule "an auto run takes no repair" 'no repair labelled `broken`'
rs_guard "$IMPLEMENT" "implement's repair rules"

rs_reset
rs_rule "an auto run never takes a repair" 'a repair, a piece labelled `broken`, is never taken'
rs_rule "because its notice needs a person" 'three failed attempts owe the risk notice in the same reply'
rs_guard "$SKILLS/implement/references/running-longer.md" "the auto run's repair rule"

# The rollback procedure lives with the other live-copy rules.
rs_reset
rs_rule "a rollback waits for a named yes even on a recipe" 'so it waits for a yes that names it, as "a change to a live service" says, even where the recipe names the command'
rs_rule "the version brought back is named" 'name the version the rollback brings back'
rs_rule "the rollback output is read whole" 'run the recipe.s rollback once, read its whole output'
rs_rule "never twice" 'never run it a second time before you have checked the first'
rs_rule "the rollback is recorded when it happens" 'record the rollback when it happens, not when the repair lands'
rs_rule "the repair's piece names the rollback" 'name the rollback on the repair.s piece too'
rs_rule "the pin is said plainly in the same reply" 'on such a host, say it plainly in the same reply'
rs_rule "the pin is recorded on main at once" 'write the hold into the masterplan.s "how it stays running" in the same records save'
rs_rule "the pin line goes on the promote" 'once the promote has gone live, remove the hold line'
rs_rule "the repair's merge needs the promote" 'the repair.s merge then needs that promote'
rs_rule "the promote waits for its own yes" 'it is a change to the live service, so it waits for its own named yes'
rs_rule "a later run notices the pin" 'whether the live copy is still held on an earlier version since a rollback'
rs_rule "the host list shows it even unrecorded" 'the host.s list of deployments shows it whether or not it was recorded'
rs_rule "off a recipe the kit says it cannot" 'say that the kit cannot do it here, and that whoever runs the host can'
rs_guard "$HOSTING" "setup-hosting's rollback rules"

# The recipe that pins says so. Its How it works line is not ours to reword.
rs_require "the Vercel recipe names the pin" "$VERCEL" \
  'after a rollback, vercel stops moving new pushes to production until a newer build is promoted'

rs_require "pieces.md says implement builds a repair" "$PIECES" 'builds it with the repair rules'
rs_require "what-now sends a ready repair to implement" "$WHATNOW" 'a repair already reproduced and marked ready goes to /implement'
rs_require "the shipped blocked list names the repair's reset step" "$BLOCKED" \
  'allowed only inside the repair.s announced reset step'
rs_require "the maintainer guard names the repair's reset step" "$GUARD" \
  'allowed inside the repair.s announced reset step'
rs_require "WORKFLOW says a bug goes to shape" "$WORKFLOW" 'a bug is a piece like any other'
rs_require "WORKFLOW tells the rollback-first story" "$WORKFLOW" 'you are offered the earlier version back first, whatever you typed'
rs_require "WORKFLOW tells the pin" "$WORKFLOW" 'some hosts stop putting new changes live after a rollback'
rs_require "WORKFLOW tells the fast path" "$WORKFLOW" 'offers to build it in the same session'
rs_require_load_bearing "what-now sends a red pull request back to its own build" "$WHATNOW" \
  'a red check on an open pull request belongs to that piece.s own build'
rs_require_load_bearing "WORKFLOW sends a red check to the piece's build" "$WORKFLOW" \
  'say it to /implement, which takes that piece.s build back up'
rs_require "the repair reference keeps the fast path's look" "$REPAIR" \
  'one look on this computer that shows the fault is the reproduction\. a report alone is never enough'

rs_done
