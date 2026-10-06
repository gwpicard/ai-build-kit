#!/usr/bin/env sh
# truing-saves-like-a-piece.sh: guard how /maintain saves what its truing
# corrects.
#
# The truing was once a command of its own, /sync, and it now runs on every
# /maintain visit. Every skill that changes the records says how it saves them,
# except that sync did not. It corrected the pieces, the changelog, the masterplan and the check's
# own file, and stopped. On a project whose guard blocks a direct push to main,
# that left the corrections uncommitted, or committed onto whatever branch was
# checked out, and a record that disagrees with what is saved is the drift sync
# exists to remove. So the corrections take the save route the build path
# already requires, the same three a piece uses, and on the shared route they
# arrive as a pull request a person decides to merge.
#
# The rule about uncommitted work is the one worth guarding hardest. The truing
# often runs after an interruption, so a dirty tree is the ordinary case rather than the
# exception, and the two easy ways to get a clean branch are to sweep the work
# into the visit's own commit or to discard it. Both destroy the thing the truing
# was meant to reconcile. /what-now owns what happens to that work, so the
# truing reports it and points there.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SYNC="$ROOT/.agents/skills/maintain/references/truing.md"
MAINTAIN="$ROOT/.agents/skills/maintain/SKILL.md"
WHATNOW="$ROOT/.agents/skills/what-now/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Truing-saves-like-a-piece checks"
rs_exists "$SYNC" "$WORKFLOW" "$MAINTAIN" "$WHATNOW"

# Arrival: start from a current main, and treat what is found as a finding.
rs_rule "main is brought up to date first" 'bring the shared `main` branch up to date'
rs_rule "uncommitted work is a finding" 'uncommitted work found here is the first finding'
rs_rule "and is left where it is" 'leave it exactly where it is'
rs_rule "never swept into the visit's own commit" 'never sweep it into a commit of your own'
rs_rule "never discarded for a clean tree" 'discard it to get a clean tree'

# The save itself.
rs_rule "the corrections use the build path's route" \
  'the save route the build path already requires'
rs_rule "the routes are section-builder's three" 'the three routes section-builder names'
rs_rule "the branch is cut from the current main" \
  'short-lived branch from the up-to-date `main`'
rs_rule "only the visit's own files are staged" 'stage only the files the visit itself changed'
rs_rule "a pull request is opened" 'open a pull request titled after the reconciliation'
rs_rule "the project check runs" 'run the project check'
rs_rule "the summary paragraph is the pull request body" \
  'is the body of that pull request'
rs_rule "the truing never merges" 'never merge it'
rs_rule "a person decides" 'a person decides whether to merge, always'
rs_rule "and it says why a direct commit is drift" 'a second kind of drift'
rs_rule "an unreachable github is a missing step, not a hazard" \
  'a missing step is not a hazard'
rs_rule "what-now is named for the found work" 'say once that /what-now offers the ways to continue it, save it or clear it'
rs_rule "the save comes at the end of the visit, with the rest" \
  'at the end of the visit, together with anything else the visit changed'
rs_guard "$SYNC" "the maintain skill's truing"

# WORKFLOW.md is where the person reads it.
rs_reset
rs_rule "maintain saves the way a piece does" 'saved the way a piece is saved'
rs_rule "on a shared project that is a pull request" \
  'arrive as a pull request you decide to merge'
rs_rule "and found work is left alone" 'reported and left alone'
rs_rule "an interrupted session starts at what-now" 'if a session stopped part-way, start with /what-now'
rs_guard "$WORKFLOW" "the shipped WORKFLOW.md"

# One home for each half. /maintain runs the truing first on every visit, and
# /what-now is where the person decides what to do with leftover work.
rs_require_load_bearing "maintain runs the truing on every visit" \
  "$MAINTAIN" 'make the records true\. load `references/truing\.md` and follow it'
rs_require_load_bearing "what-now is the one home for recovering left-behind work" \
  "$WHATNOW" 'this is the one home for recovering work an interrupted session left behind'
rs_require_load_bearing "what-now says the truing only reports it" \
  "$WHATNOW" 'truing reports such work and leaves it alone'

rs_done
