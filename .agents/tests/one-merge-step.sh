#!/usr/bin/env sh
# one-merge-step.sh: guard the one merge step every route uses.
#
# The rule that a merge waits for a yes naming it lived in /ship. In a real
# project most merges happened inside /implement and hand-built runs, where the
# rule did not travel, and three merges went ahead on a yes that named nothing.
# The host put every merge to main live, so the first launch happened as a merge
# inside a run and /ship's launch checks never ran.
#
# So merging has one home, section-builder's references/merge.md, and every
# route points at it rather than carrying a copy. A copy is how the rule was lost
# the first time: the skill that had it was not the one running. This check
# holds the rule in that file, fails on a skill that restates it, and holds the
# promote step /ship gains for a tool whose merges reach a preview.
#
# Pre-approval is the first time the kit lets an agent merge. Its five
# conditions carry that risk, so each is a rule here, and each is proved
# load-bearing by removing it.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SKILLS="$ROOT/.agents/skills"
MERGE="$SKILLS/section-builder/references/merge.md"
SB="$SKILLS/section-builder/SKILL.md"
IMPLEMENT="$SKILLS/implement/SKILL.md"
LONGER="$SKILLS/implement/references/running-longer.md"
FIX="$SKILLS/fix/SKILL.md"
SHIP="$SKILLS/ship/SKILL.md"
SYNC="$SKILLS/sync/SKILL.md"
MASTERPLAN="$SKILLS/setup-ai-build-kit/templates/masterplan.md"
FOUNDED="$SKILLS/setup-ai-build-kit/templates/foundation/AGENTS.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "One merge step checks"
rs_exists "$MERGE" "$SB" "$IMPLEMENT" "$LONGER" "$FIX" "$SHIP" "$SYNC" \
  "$MASTERPLAN" "$FOUNDED" "$WORKFLOW"

# The yes that names the merge.
rs_rule "a person decides the merge" 'a person decides whether to merge\.'
rs_rule "each pull request is named with what it changes" 'name each pull request in one plain line'
rs_rule "the yes asked for names the merge" 'ask for a yes that names the merge'
rs_rule "merge only on a reply that covers it" 'merge only when the person.s reply plainly covers that merge'
rs_rule "a reply naming several counts for each one it names" 'a reply that names several pull requests, such as "merge 1, 2 and 4", counts for each one it names and for none it leaves out'
rs_rule "a merge the person already named is the yes" 'already named the merge, as in "merge both and put it live", that is the yes: do not ask again'
rs_rule "a go-live yes given before the merge was named does not cover it" 'a yes to going live, to a hosting step, or to any question asked before the merge was named does not cover it: ask again, and merge nothing until they answer'
rs_rule "a no leaves the pull request open" 'a no leaves the pull request open'

# Before any merge.
rs_rule "never over a red check" 'never merge over a red check'
rs_rule "a stacked pull request never merges before its base" 'is never merged before its base'
rs_rule "the base goes first when both are named" 'merge the base first when the person.s yes names both'

# How the merge is made.
rs_rule "an approved merge is made on the pull request" 'make an approved merge on the pull request itself'
rs_rule "never a local merge and a push of main" 'never merge the branch on this computer and push `main`'
rs_rule "the branch is never deleted by hand" 'never delete the branch yourself'
rs_rule "an unreachable github merges nothing" 'where github cannot be reached, nothing merges'
rs_rule "and says when to try again" 'it can be asked for again once github answers'

# When a merge goes live.
rs_rule "the masterplan records how the tool goes live" 'records how the tool goes live in its `goes live:` line'
rs_rule "the default is a preview, and /ship promotes" '`through /ship` is the kit.s default: a merge reaches a preview, and `/ship` promotes it to live'
rs_rule "a missing line is treated as live until the person says not" 'treat it as going live until the person says it does not'
rs_rule "the ask says this goes live now" 'the ask says so, as "this goes live now"'
rs_rule "the first such merge runs the first-launch checks first" 'this merge is the first launch\. before asking for it, load the `ship` skill and run its first-launch checks'

# Pre-approval.
rs_rule "pre-approval is written in the run's state file" 'write that as `merge_preapproved` in the run.s state file'
rs_rule "it ends with the run" 'holds for that run alone and ends with it'
rs_rule "all five conditions must hold" 'merge a piece only when all five hold'
rs_rule "condition: the check is green" '1\. its project check is green'
rs_rule "condition: the review found nothing worth stopping for" '2\. its review found nothing worth stopping for'
rs_rule "condition: no flagged choice" '3\. its pull request flags no choice for the person to confirm'
rs_rule "condition: no sensitive area" '4\. it touches no sensitive area named in the build-path section, accepted or not'
rs_rule "condition: the person has not opted in to check it" '5\. the person has not opted in to check it'
rs_rule "a piece that fails one stays in to check, with the reason" 'it stays in `to check` for the person, and the run.s report names the condition it failed'
rs_rule "no agent merge is ever a first launch" 'where a merge would be the first launch, the agent does not make it'
rs_guard "$MERGE" "the merge step"

# Every route points at the step. section-builder's line replaces the
# validator's old string, which held the pull-request route short of a merge.
rs_require_load_bearing "section-builder merges only through the step" "$SB" 'merge it only as `references/merge\.md` says'
rs_require_load_bearing "section-builder still reports ready for review, not done" "$SB" 'report the piece as ready for review, not as done'
rs_require_load_bearing "/implement points at the step" "$IMPLEMENT" 'the `section-builder` skill.s `references/merge\.md`'
rs_require_load_bearing "a run's merges follow the step" "$LONGER" 'the `section-builder` skill.s `references/merge\.md`'
rs_require_load_bearing "/fix points at the step" "$FIX" 'the `section-builder` skill.s `references/merge\.md`'
rs_require_load_bearing "/ship points at the step" "$SHIP" 'any merge follows the `section-builder` skill.s `references/merge\.md`'
rs_require_load_bearing "/sync points at the step" "$SYNC" 'merge it only as the `section-builder` skill.s `references/merge\.md` says'

# And none carries its own copy. A copy is how the rule stayed in /ship while
# the merges happened elsewhere.
for skill in "$SB" "$IMPLEMENT" "$LONGER" "$FIX" "$SHIP" "$SYNC"; do
  name=$(basename "$(dirname "$skill")")/$(basename "$skill")
  rs_require_absent "$name restates no merge yes" "$skill" 'ask for a yes that names the merge'
  rs_require_absent "$name restates no merge decider" "$skill" 'decides whether to merge'
  rs_require_absent "$name restates no covered reply" "$skill" 'reply plainly covers that merge'
  rs_require_absent "$name restates no local-merge ban" "$skill" 'never merge the branch on this computer'
  rs_require_absent "$name keeps no merge for a human alone" "$skill" 'merging belongs to a human'
done

# /ship promotes from a preview to live.
rs_require_order "the promote step sits before Build with care" "$SHIP" '^#### Promoting to live$' '^### Build with care$'
rs_require_load_bearing "/ship names what will go live" "$SHIP" 'name what will go live'
rs_require_load_bearing "/ship runs its checks before the promote" "$SHIP" 'run the checks this path requires before the promote'
rs_require_load_bearing "/ship promotes only on a yes naming it" "$SHIP" 'promote only on a yes that names the promote'
rs_require_load_bearing "a merge yes does not cover the promote" "$SHIP" 'a yes to a merge does not cover it'
rs_require_load_bearing "a no leaves the live tool as it was" "$SHIP" 'a no leaves the live tool as it was'
rs_require_load_bearing "on every merge there is nothing to promote" "$SHIP" 'on `on every merge`, there is nothing to promote'
rs_require_load_bearing "a first launch writes the Goes live line" "$SHIP" 'where "how it stays running" has no `goes live:` line, write one'

# The records.
rs_require_load_bearing "the masterplan template carries the Goes live line" "$MASTERPLAN" 'a `goes live:` line says how the tool goes live'
rs_require_absent "the founded AGENTS.md no longer says a human alone merges" "$FOUNDED" 'a human decides whether to merge'
rs_require_load_bearing "the founded AGENTS.md names the yes or the pre-approval" "$FOUNDED" 'a merge waits for the person.s yes naming it, or their pre-approval of a run'

# WORKFLOW.md tells it once, for every route.
rs_require_load_bearing "WORKFLOW says every route shares the step" "$WORKFLOW" 'the same merge step serves /implement, /fix, /ship and /sync'
rs_require_load_bearing "WORKFLOW says nothing merges unasked" "$WORKFLOW" 'nothing merges a pull request you have not agreed to'
rs_require_load_bearing "WORKFLOW says a reply naming several counts for each" "$WORKFLOW" 'a reply such as "merge 1, 2 and 4" covers each one it names'
rs_require_load_bearing "WORKFLOW says put it live is not that yes" "$WORKFLOW" 'saying "put it live" before any merge was named is not that yes'
rs_require_load_bearing "WORKFLOW says the merge is made on the pull request" "$WORKFLOW" 'each merge is made on the pull request itself, never by merging on your computer and pushing `main`'
rs_require_load_bearing "WORKFLOW says an unreachable github makes the merge wait" "$WORKFLOW" 'if github cannot be reached, the merge waits, and you can merge it on github yourself'
rs_require_load_bearing "WORKFLOW gives the pre-approval conditions" "$WORKFLOW" 'you can say that pieces which pass may be merged'
rs_require_load_bearing "WORKFLOW says the permission ends with the run" "$WORKFLOW" 'that permission ends with the run'
rs_require_load_bearing "WORKFLOW says an every-merge host is named in the ask" "$WORKFLOW" 'the ask says "this goes live now", and the first such merge runs /ship.s first-launch checks before it happens'
rs_require_load_bearing "WORKFLOW says /ship promotes" "$WORKFLOW" '/ship names what will go live, runs its checks, and promotes on your yes'
rs_require_absent "WORKFLOW no longer says a human alone merges, always" "$WORKFLOW" 'a human decides whether to merge, always'

rs_done
