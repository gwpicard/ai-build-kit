#!/usr/bin/env sh
# implement-merges-on-a-yes.sh: guard how /implement merges a finished piece.
#
# The merge rules were written for the command then called /ship, after a real
# run merged two pull requests when the person had said only "put it live",
# and another merged on this computer and pushed `main` when GitHub was out of
# reach. Both hosts the recipes name build every change to `main`, so once a
# tool is live the merge is the deploy, and the step that merges is the step
# that puts a change live. So the merge moved to section-builder's last step,
# which /implement runs, and the rules moved with it, word for word where they
# still fit.
#
# Moving the merge opened three gaps that this check also holds shut. A change
# that adds to the live database would go live before the addition was
# applied, a change needing a new secret on the host would go live without it,
# and a piece in a sensitive area would go live with nobody holding the gate
# that the launch command used to hold. So the merge waits for each, the piece
# carries a `Live side needs:` line saying what the host must gain, and after
# the merge the kit reads one line from the live copy and changes nothing.
#
# Each rule is prose an agent reads, and its absence would not show on screen
# until a run merged something nobody had agreed to.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

BUILDER="$ROOT/.agents/skills/section-builder/SKILL.md"
IMPLEMENT="$ROOT/.agents/skills/implement/SKILL.md"
PIECES="$ROOT/.agents/skills/setup-ai-build-kit/references/pieces.md"
SHAPE="$ROOT/.agents/skills/shape/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Implement merge rules"
rs_exists "$BUILDER" "$IMPLEMENT" "$PIECES" "$SHAPE" "$WORKFLOW"

# The merge is the person's, and it is asked for once the check is green.
rs_rule "the save step hands the merge to its own step" 'once the check is green the piece is ready for review, and step 10 asks the person whether to merge it'
rs_rule "never before that step, never on a red check" 'never merge before that step, and never on a red check'
rs_rule "a person decides, always" 'the person decides whether to merge, always'
rs_rule "a merge only on a yes that names it" 'merge only on a yes that names it'
rs_rule "on a live project the merge is a deploy" 'on a project that is live, the merge is a deploy'
rs_rule "the report says what to try and where" 'say what the person can try and where: the preview address, on a recipe whose preview section gives one'

# What has to be true on the live side before the merge is asked for.
rs_rule "the live side is checked read-only first" 'where it records a live address, the merge puts this change live, so check these first, read-only, and change nothing live'
rs_rule "a new migration is checked against the live database" 'where the change adds a database migration, check whether the live database already has it'
rs_rule "the migration goes first through /setup-hosting, from the pull request" 'this change adds to the database, so /setup-hosting applies that first, from this pull request\. migrations only add, so the version live now keeps working'
# The dry run reads the live database, which needs its password. A real launch
# once called a password absent when the person had named its file.
rs_rule "the dry run's password follows the secret rule" 'where the dry run needs the database password, follow the `setup-hosting` skill.s "a secret a check needs"'
rs_rule "the password is never called absent" 'ask once when nobody recorded it, and never say it is absent'
rs_rule "an unreadable live database means not applied" 'where the live database cannot be read, treat the migration as not applied, and say why in one line'
rs_rule "the merge waits until the migration is applied" 'ask for the merge only once /setup-hosting reports it applied'
rs_rule "a Live side needs line holds the merge" 'where the piece carries a `live side needs:` line, ask for the merge only once /setup-hosting reports each name on it present on the host'
# The area comes first, on any project, so nothing reaches the live side for
# a piece that may never merge.
rs_rule "a sensitive area is checked first, live or not" 'check it before anything else, live or not'
rs_rule "a sensitive area holds the merge until its caution is settled" 'ask for the merge only when the area.s caution is done or accepted on the record'
rs_rule "nothing is applied for a piece that may not merge" 'nothing is applied to the live side for a piece that may not merge'
# A merge on a live project is a go-live, and the readiness /setup-hosting gave
# each area and each launch has to happen somewhere.
rs_rule "the evidence run covers what the piece changed" 'run the evidence run in the `setup-hosting` skill.s `references/evidence-run\.md`, scoped to what this piece changed'
rs_rule "a settled area gets its readiness check" 'run that area.s operational readiness as the `setup-hosting` skill.s build with care step 5 says'
rs_rule "no notice is repeated" 'do not repeat a notice already given'
rs_rule "a readiness gap is a warning said once" 'a gap there is a warning, as it is in /setup-hosting: say it once, record it in changelog\.md with the date in this piece.s pull request, and carry on'
rs_rule "a piece stopped at its condition is never offered" 'a piece stopped at its condition is never offered for a merge'
rs_rule "until then the pull request waits, and says why" 'until then, the pull request stays open and ready for review, and the report says what it waits for'

# Asking. These came over from the launch command with the merge.
rs_rule "the pull request is named in one plain line" 'name the pull request in one plain line that says what it changes'
rs_rule "the yes asked for names the merge" 'then ask for a yes that names the merge'
rs_rule "merge only on a reply that covers it" 'merge only when the person.s reply plainly covers that merge'
rs_rule "a merge the person already named is the yes" 'where their own words already named the merge, as in "merge it", that is the yes: do not ask again'
rs_rule "an earlier yes to something else does not cover it" 'a yes to building, saving, uploading, going live or a hosting step, or to any question asked before the merge was named, does not cover it: ask again, and merge nothing until they answer'
rs_rule "puts it live is said only where the merge deploys" 'say the second half only where the project is live and the merge does deploy: on a recipe, or where the masterplan records that the host builds every change to `main`'
rs_rule "a no leaves the pull request open" 'a no leaves the pull request open, ready for review'
rs_rule "several waiting pieces are named one by one" 'where more than one piece waits on its merge, name each pull request in its own line'
rs_rule "a yes covers only what it names" 'a yes covers only the pull requests it names, or all of them where it plainly says so'

# How the merge is made.
rs_rule "an approved merge is made on the pull request" 'make an approved merge on the pull request itself, such as with `gh pr merge`'
rs_rule "never a local merge and a push of main" 'never merge the branch on this computer and push `main`'
rs_rule "an unreachable github makes the merge wait" 'where github cannot be reached, the merge waits: say in one line that the person can merge it on github themselves'
rs_rule "the box is announced only in claude code" 'where the session runs in claude code, the project.s settings show a confirmation box before the merge runs'
rs_rule "the confirmation box is announced" 'say in one line just before it that the box will ask them to allow the merge'
rs_rule "no box is promised elsewhere" 'under another coding agent, say nothing about a box'
rs_rule "an unattended run never merges" 'in an unattended run nobody is there to say yes, so never merge'

# After the merge: one read, and nothing changed.
rs_rule "one health line after the merge on a recipe" 'read one line of health from the live copy, read-only'
rs_rule "the line when the merge is live" 'the live copy now runs this change'
rs_rule "a build still running is read again" 'where the list shows the build still running, say so, wait a short while, and read the health line again'
rs_rule "no second deploy for a build in progress" 'never suggest a second deploy for a build in progress'
rs_rule "the line when it is not, with a next step" 'only where the build failed or is missing, say: "the live copy did not update," with the next step, which is /setup-hosting'
rs_rule "off a recipe, claim no more than was seen" 'claim no more than you saw'
rs_rule "nothing live changes after the merge" 'change nothing live after the merge: no deploy, no rollback, and no second push to `main`'
rs_rule "putting it out again is a read, then /setup-hosting" 'a further deploy belongs to /setup-hosting and its rules, never to this step'
rs_rule "a rollback question gets an answer and no rollback" 'that a rollback has not been tried, and run none'
rs_guard "$BUILDER" "section-builder's merge step"

rs_require_order "the area check comes before the live-side checks" "$BUILDER" 'A sensitive area first, on any project' 'Before asking, on a live project'
rs_require_order "the merge step follows the records step" "$BUILDER" '^## 9\. Update the records$' '^## 10\. Merge$'
rs_require_absent "the old stop-before-merge rule is gone" "$BUILDER" 'do not merge the pull request, and do not delete the branch'

# /implement points at the step, and takes a piece that only waits on its merge.
rs_reset
rs_rule "implement merges only on a named yes" 'merges only on a yes that names the merge'
rs_rule "implement says the merge is how a change goes live" 'on a live project that merge is a deploy, so this is also how a change goes live'
rs_rule "a built piece waits only for its merge" 'a piece whose pull request is open with a green check waits only for its merge'
rs_rule "put it live names no merge" '"put it live" names no merge, so ask'
rs_rule "never a pull request the person has not named" 'never merge a pull request the person has not named or plainly covered'
rs_guard "$IMPLEMENT" "implement's merge rules"

# The piece carries what the live side needs, by name.
rs_require_load_bearing "pieces.md has the Live side needs line" "$PIECES" 'live side needs: <only when the live copy must gain a new secret, setting or outside service'
rs_require_load_bearing "pieces.md says names only, and when the merge waits" "$PIECES" 'name each one, never its value\. on a live project the merge is a deploy'
rs_require_load_bearing "shape writes the line" "$SHAPE" 'write its `live side needs:` line on the surface, following pieces\.md'

rs_require_load_bearing "WORKFLOW says /implement asks for a yes that names the merge" "$WORKFLOW" 'names the pull request in one plain line and asks for a yes that names the merge'
rs_require_load_bearing "WORKFLOW says put it live is not that yes" "$WORKFLOW" 'saying "put it live" or "save it" before any merge was named is not that yes'
rs_require_load_bearing "WORKFLOW says the merge is made on the pull request" "$WORKFLOW" 'it makes the merge on the pull request itself, never by merging on your computer and pushing `main`'
rs_require_load_bearing "WORKFLOW says an unreachable github makes the merge wait" "$WORKFLOW" 'if github cannot be reached, the merge waits, and you can merge it on github yourself'
rs_require_load_bearing "WORKFLOW says a merge is a deploy once live" "$WORKFLOW" 'once the tool is live, a merge is a deploy'
rs_require_load_bearing "WORKFLOW says the database addition goes first" "$WORKFLOW" 'a change that adds to the database waits until /setup-hosting has applied that addition'
rs_require_load_bearing "WORKFLOW gives the health line" "$WORKFLOW" 'after the merge, /implement reads one line from the live copy'

rs_done
