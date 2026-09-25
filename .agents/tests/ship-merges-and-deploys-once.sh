#!/usr/bin/env sh
# ship-merges-and-deploys-once.sh: guard how /ship merges and deploys.
#
# Two real runs went wrong at the same step. In one, the person said only "put
# it live", and /ship merged two pull requests nobody had named to them. In the
# other, /ship cut a deploy's output short, could not tell whether it had
# worked, and deployed again, so the same version was live twice and the
# earlier build a rollback would reach was gone. It also listed warnings again
# that it had already given in the same visit.
#
# Each rule here is prose an agent reads, and its absence would not show on
# screen until the next run did the same thing again.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SHIP="$ROOT/.agents/skills/ship/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Ship merge and deploy rules"
rs_exists "$SHIP" "$WORKFLOW"

# Where the rules reach.
rs_rule "go-live points at the merge and deploy rules" 'any merge or deploy on the way follows "merging and deploying" below'
rs_rule "the rules hold on every path that goes live" 'these rules hold at every go-live, on a recipe or off one, and on build with care as well'

# The merge is the person's.
rs_rule "a person decides the merge, as with /implement" 'a person decides whether to merge, as with /implement'
rs_rule "each pull request is named with what it changes" 'before a merge, name each pull request in one plain line that says what it changes'
rs_rule "the yes asked for names the merge" 'ask for a yes that names the merge'
rs_rule "merge only on a reply that covers it" 'merge only when the person.s reply plainly covers that merge'
rs_rule "a go-live yes given before the merge was named does not cover it" 'a yes to going live, to a hosting step, or to any question asked before the merge was named does not cover it: ask again, and merge nothing until they answer'
rs_rule "a no leaves the pull request open" 'a no leaves the pull request open'

# The deploy runs once unless it plainly did not go live.
rs_rule "the whole output or the deployment list is read first" 'before you decide a deploy failed, read its whole output, or read the host.s own list of deployments'
rs_rule "the output is never cut short" 'never cut the output short'
rs_rule "an unclear result is checked at the live address" 'ask the live address which version it serves'
rs_rule "no second deploy before the first is checked" 'never run a deploy a second time until you have checked that the first did not go live'
rs_rule "a second deploy of one version spends the rollback target" 'a second deploy of the same version replaces the earlier build as the rollback target'
rs_rule "a second deploy is announced before it runs" 'when a second deploy is still needed, say that in one line before you run it'
rs_rule "the rollback line is corrected after it" 'correct the rollback line to match'

# A warning once.
rs_rule "a warning said once is not said again in the same ship" 'a warning said once in a /ship is not said again in that /ship, even when a step runs twice'
rs_rule "a later mention is a pointer to the changelog" 'one line saying the changelog already holds it is enough'
rs_rule "the area risk notice is not caught by it" 'the risk notice for a named area is not a warning'
rs_guard "$SHIP" "ship's merge and deploy rules"

rs_require_order "the rules sit after the recipe checks and before Build with care" "$SHIP" '^#### Merging and deploying$' '^### Build with care$'

rs_require_load_bearing "WORKFLOW says ship never merges unasked" "$WORKFLOW" '/ship never merges a pull request you have not agreed to'
rs_require_load_bearing "WORKFLOW says put it live is not that yes" "$WORKFLOW" 'saying "put it live" before any merge was named is not that yes'
rs_require_load_bearing "WORKFLOW says ship checks before deploying again" "$WORKFLOW" '/ship checks whether it went live before it tries again'
rs_require_load_bearing "WORKFLOW says a second deploy spends the rollback" "$WORKFLOW" 'a second deploy of the same version leaves nothing older to roll back to'
rs_require_load_bearing "WORKFLOW says a warning is not repeated" "$WORKFLOW" 'a warning you have already heard is not repeated in the same /ship'

rs_done
