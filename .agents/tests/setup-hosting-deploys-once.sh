#!/usr/bin/env sh
# setup-hosting-deploys-once.sh: guard how /setup-hosting deploys, saves its
# records, and compares the live copy with main.
#
# Two real runs of the command, then called /ship, went wrong at the same step.
# In one, the person said only "put it live", and it merged two pull requests
# nobody had named to them. In the other, it cut a deploy's output short, could
# not tell whether it had worked, and deployed again, so the same version was
# live twice and the earlier build a rollback would reach was gone. It also
# listed warnings again that it had already given in the same visit.
#
# Merging code has since moved to /implement, where a merge is a deploy once
# the tool is live, and implement-merges-on-a-yes.sh guards those rules. This
# check holds what stays here: the command merges no code, a deploy runs once
# unless it plainly did not go live, and its own records take the save route a
# piece takes, on a pull request of their own that needs its own yes. Two more
# faults from the same launch shaped that last part. With GitHub out of reach,
# the kit merged on this computer and pushed `main`. With GitHub in reach, it
# pushed its changelog entries straight to `main`, saying they only changed the
# record.
#
# It also holds the later run, which compares the live copy with main, says
# each gap in one line, and repairs a gap only on a yes that names it.
#
# Each rule here is prose an agent reads, and its absence would not show on
# screen until the next run did the same thing again.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

HOSTING="$ROOT/.agents/skills/setup-hosting/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Setup-hosting deploy, records and later-run rules"
rs_exists "$HOSTING" "$WORKFLOW"

# Where the rules reach.
rs_rule "go-live points at the deploy and records rules" 'any deploy on the way follows "deploying, and the records" below'
rs_rule "the rules hold on every path that goes live" 'these rules hold at every go-live, on a recipe or off one, and on build with care as well'

# It merges no code. A request to put a piece live goes to /implement.
rs_rule "the skill never merges code" 'this skill never merges a pull request that changes the tool.s code'
rs_rule "an open piece is left open and named for /implement" 'where an open pull request holds a piece, leave it open\. say in one line that /implement merges it after the person.s yes'
rs_rule "the first run merges no code" 'pieces reach `main` through /implement, so the first run merges no code'
rs_rule "the only merge here is its own records" 'the one pull request it may merge is its own records pull request, below, and only on a yes that names it'

# How the records are saved.
rs_rule "the records take the build path's save route" 'take the save route the build path already requires: the three routes section-builder names, with no fourth for records'
rs_rule "the records include a later confirmation" 'a confirmation the person gives later'
rs_rule "a checkpoint commit is enough on the checkpoint route" 'on the checkpoint route, a checkpoint commit is enough'
rs_rule "one branch for each run, cut from the current main" 'one branch for this run, cut from the up-to-date `main`'
rs_rule "only this run's own files are staged" 'stage only the files this run itself changed'
rs_rule "the records get one pull request, once, after the launch is checked" 'open one pull request for them, once, after the launch is checked and its records are written'
rs_rule "its yes is asked in the reply that reports the launch" 'ask for its yes in the reply that reports the launch'
rs_rule "an unreachable github keeps the records on their branch" 'where github cannot be reached, save the records on that branch, note in one plain line the step that did not happen, and open the pull request once github is reachable'
rs_rule "records are never pushed straight to main" 'never push records straight to `main`'
rs_rule "a later confirmation joins the open records branch, or a new one" 'a later confirmation joins that branch while its pull request is open, or a new branch and pull request once it has merged'
rs_rule "the records merge is named and asked for" 'the records pull request is a merge like any other: name it in one plain line and ask for a yes that names it'
rs_rule "no earlier yes covers it" 'no yes given earlier covers it, because that pull request did not exist when the person gave it'
rs_rule "the records merge is made on the pull request" 'make the merge as section-builder.s "merging" says: on the pull request itself, never on this computer with a push of `main`'
# A host that builds every change to main builds the records merge too, and
# that build becomes what a rollback returns to.
rs_rule "a records merge on a building host is one more build" 'where the host builds every change to `main`, merging it starts one more build of the same code and moves the rollback target'
rs_rule "the extra build is said in the line asking for the yes" 'say so in the line that asks for its yes'
rs_rule "leaving it open for the next change is offered" 'offer to leave it open so it goes out with the next change'
rs_rule "the rollback line is corrected before that merge" 'if they say yes, correct the rollback line on that branch before the merge'
rs_rule "merging the records writes no record of its own" 'merging it writes no record of its own'
rs_rule "the person's uncommitted work stays where it is" 'uncommitted work of the person.s stays exactly where it is'
rs_rule "it is never swept into the records commit" 'never sweep it into the records commit'
rs_rule "and never discarded for a clean tree" 'never discard it to get a clean tree'

# The deploy runs once unless it plainly did not go live.
rs_rule "the whole output or the deployment list is read first" 'before you decide a deploy failed, read its whole output, or read the host.s own list of deployments or have it read'
# On a server the kit never contacts, the list comes back as a paste.
rs_rule "an unreachable host's list is read by the person or a companion" 'where the kit cannot reach the host, the person or a companion reads that list and pastes it here'
rs_rule "the output is never cut short" 'never cut the output short'
rs_rule "an unclear result is checked at the live address" 'ask the live address which version it serves'
rs_rule "no second deploy before the first is checked" 'never run a deploy a second time until you have checked that the first did not go live'
rs_rule "a second deploy of one version spends the rollback target" 'a second deploy of the same version replaces the earlier build as the rollback target'
rs_rule "a second deploy is announced before it runs" 'when a second deploy is still needed, say that in one line before you run it'
rs_rule "the rollback line is corrected after it" 'correct the rollback line to match'

# A warning once.
rs_rule "a warning said once is not said again in the same run" 'a warning said once in a run of /setup-hosting is not said again in that run, even when a step runs twice'
# Two of six replays of scenario 54 gave the backup warning again in full when
# the person asked what was left.
rs_rule "asked what is left, a held warning is a one-line pointer" 'when the person asks what is left, a warning this run has said, or one the changelog already holds, is one line that points to the changelog, without its reason, its risk or what to do about it'
rs_rule "a later mention is a pointer to the changelog" 'one line saying the changelog already holds it is enough'
rs_rule "the area risk notice is not caught by it" 'the risk notice for a named area is not a warning'

# The later run. A merge is already a deploy, so a later run moves nothing
# over: it compares, says each gap once, and repairs only on a named yes.
# Without the yes, a recipe's commands would run because "the recipe names
# them", when nobody asked for a launch at all.
rs_rule "a later run compares the live copy with main" 'it compares the live copy with `main` and repairs what differs'
rs_rule "it compares before it changes anything" 'compare first, and change nothing while comparing'
rs_rule "each gap is one plain line" 'report each gap in one plain line, and say nothing more about a part that matches'
rs_rule "the latest merge is read from health or the host's list" 'whether the live copy runs the latest merge on `main`, read from its health route or the host.s list of deployments'
rs_rule "an unapplied migration is a gap" 'whether `main` holds a database migration the live database does not have'
rs_rule "a missing secret is a gap, by name only" 'whether a secret or setting the tool needs is missing on the host, by name only'
rs_rule "each repair waits for a yes that names it" 'then repair each gap after a yes that names it'
rs_rule "a recipe command waits for that yes too in a later run" 'nobody asked for a launch in a later run, so a recipe.s command waits for that yes too'
rs_rule "the live-change rule makes the same exception" 'a later run is the exception: nobody asked for a launch, so each repair waits for the yes "a later run" describes'
rs_rule "a migration goes before the merge that needs it" 'a migration is applied before the merge that needs it, since migrations only add'
# The piece's migration is on its own branch until the merge, so a later run
# that read only main would find nothing to apply, and /implement would wait.
rs_rule "a piece's migration is read from its pull request branch" 'a piece.s migration is not on `main` yet, so read it from that piece.s pull request branch'
rs_rule "it is applied from a separate checkout after a named yes" 'apply it only after a yes that names it, and from a separate temporary checkout of that branch'
rs_rule "uncommitted work is never touched" 'so the person.s own uncommitted work is never touched'
rs_rule "it tells /implement when the merge can go ahead" 'once it is applied or present, say in one line that /implement can now ask for the merge'
rs_rule "moving host keeps the old copy serving" 'moving to a different host or recipe is a later run too'
rs_rule "the new recipe is recorded only once the new copy answers" 'only once the new live copy answers its health check'
rs_guard "$HOSTING" "setup-hosting's deploy, records and later-run rules"

rs_require_order "the rules sit after the recipe checks and before Build with care" "$HOSTING" '^#### Deploying, and the records$' '^### Build with care$'
rs_require_absent "no code merge rules are left behind" "$HOSTING" 'say yes to put it live, which merges'

rs_require_load_bearing "WORKFLOW says setup-hosting never merges code" "$WORKFLOW" '/setup-hosting never merges your code'
rs_require_load_bearing "WORKFLOW says a piece is merged by /implement" "$WORKFLOW" 'a finished piece waiting in a pull request is merged by /implement, on a yes that names the merge'
rs_require_load_bearing "WORKFLOW says setup-hosting checks before deploying again" "$WORKFLOW" '/setup-hosting checks whether it went live before it tries again'
rs_require_load_bearing "WORKFLOW says a second deploy spends the rollback" "$WORKFLOW" 'a second deploy of the same version leaves nothing older to roll back to'
rs_require_load_bearing "WORKFLOW says a warning is not repeated" "$WORKFLOW" 'a warning you have already heard is not repeated in the same run'
rs_require_load_bearing "WORKFLOW says records are saved the way a piece is" "$WORKFLOW" 'the records /setup-hosting writes, such as its changelog entries and a colleague later saying the new version is live, take the same save route as a piece'
rs_require_load_bearing "WORKFLOW says a records merge is one more build" "$WORKFLOW" 'merging it starts one more build and moves the rollback target, and offers to leave it for the next change'
rs_require_load_bearing "WORKFLOW says records get their own pull request, never main" "$WORKFLOW" 'one pull request for each run, never straight to `main`'
rs_require_load_bearing "WORKFLOW says the records merge needs its own yes" "$WORKFLOW" 'merging that pull request needs its own yes'
rs_require_load_bearing "WORKFLOW says unsaved work is left alone" "$WORKFLOW" 'kept out of the records and never thrown away'
rs_require_load_bearing "WORKFLOW says a later run compares the live copy" "$WORKFLOW" 'a later /setup-hosting compares the live copy with `main` and tells you each gap in one plain line'
rs_require_load_bearing "WORKFLOW gives the later-run exception to the recipe's commands" "$WORKFLOW" 'a later run is different: nobody asked for a launch, so each repair it makes waits for a yes that names it'
rs_require_load_bearing "WORKFLOW says a gap is repaired only on a yes" "$WORKFLOW" 'it repairs each gap only after a yes that names it'

rs_done
