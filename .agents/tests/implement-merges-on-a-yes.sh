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
# until a run merged something nobody had agreed to. The one decision a
# machine can make, whether a recipe's check before the merge passed, failed
# or could not run, is made by a shipped script, run here against stand-ins.

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
# The recipe's own check before the merge, such as the local container check,
# is a warning when it cannot run, as in /setup-hosting. Three of five replays
# of scenario 54 held the merge for it and asked for a set phrase instead.
# A check that runs and fails is the opposite case, and holds the merge as a
# red project check does. The two were told apart by reading the output, so a
# shipped script now decides, and its exit code is what the kit acts on.
rs_rule "the check runs through the shipped script" 'run it through `scripts/check-before-merge\.sh` from this skill.s folder'
rs_rule "with its ready and cleanup commands" 'the command that shows the check.s tool is running as `--ready`, the one that removes what the check started as `--cleanup`'
rs_rule "a read of a background start waits with its own retry" 'a command that reads something the check started in the background waits for it with its own retry option and carries its own time limit'
rs_rule "the exit code decides, not a reading" 'the exit code decides, never a reading of the output'
rs_rule "exit 0 is a pass" 'exit 0 means it passed'
rs_rule "a pre-merge check that cannot run is a warning" 'exit 2 means it could not run here, for example because no container engine is running\. then it is a warning, as a check not done is in /setup-hosting'
rs_rule "a check that runs and fails holds the merge" 'exit 1 means the check ran and failed, and that holds the merge as a red project check does'
rs_rule "the failure is said in one line" 'say so in one line, naming what failed in plain words'
rs_rule "the piece goes back to its build" 'the piece goes back to its build, from step 5, to fix the cause'
rs_rule "and the merge waits until the check passes" 'the merge is not asked for until the check passes'
rs_rule "it is said once and recorded in the piece's pull request" 'say it once, record it in changelog\.md with the date in this piece.s pull request, and carry on'
rs_rule "it never holds the merge or asks for a choice" 'do not hold the merge for it, and do not ask the person to choose to merge without it'
rs_rule "a warning the changelog holds is a pointer" 'where the changelog already holds that warning, one line pointing to it is enough'
# Two replays of scenario 54 still explained the container check again in full,
# what it does and why it could not run, beside the pointer.
rs_rule "and only the pointer, with no reason or risk" 'in that case say only that line, in this reply and any later one: not what the check does, why it could not run, or what it would have caught'
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
rs_rule "an approved merge is made on the pull request" 'make an approved merge on the pull request itself, such as with `gh pr merge --merge`'
rs_rule "never a local merge and a push of main" 'never merge the branch on this computer and push `main`'
rs_rule "an unreachable github makes the merge wait" 'where github cannot be reached, the merge waits: say in one line that the person can merge it on github themselves'
rs_rule "the box is announced only in claude code" 'where the session runs in claude code, read first whether the project.s settings show a confirmation box before the merge runs'
rs_rule "the merge box is read by the script" 'scripts/settings-rules\.py` and `--merge-box`. exit 0 means they do'
rs_rule "without a box the chat yes runs the merge" 'the merge runs on their yes in this chat, and that /maintain can add the question'
rs_rule "new environment names are read by the script" 'scripts/env-names-added\.sh` and the piece.s branch'
rs_rule "new names hold the merge" 'exit 1 prints each name the branch adds: treat each one as a name on a `live side needs:` line, so the merge waits until /setup-hosting reports it present on the host'
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
rs_require_load_bearing "WORKFLOW says a failing pre-merge check holds the merge" "$WORKFLOW" 'a check that runs and fails holds the merge as a red check does, and the piece goes back to its build until it passes'
rs_require_load_bearing "WORKFLOW says one that cannot run is a warning" "$WORKFLOW" 'a check that cannot run here is a warning you hear once, and the merge goes ahead'

# A pull request another change has collided with cannot merge, and asking
# for a yes it cannot honour leaves the person holding a merge that fails.
rs_require_load_bearing "mergeability is read before asking" "$BUILDER" 'before asking, read whether github can merge the pull request, with `gh pr view <number> --json mergeable`'
rs_require_load_bearing "a conflict is said in one line" "$BUILDER" 'where it answers `conflicting`, another change has landed in the same place since this piece began\. say so in one line'
rs_require_load_bearing "the offer is to merge main into the branch and push" "$BUILDER" 'offer to bring the newest `main` into the piece.s branch: merge `main` into it on this computer and push the branch'
rs_require_load_bearing "never a force push or a rebase" "$BUILDER" 'never force a push and never rebase\. do it only on a yes'
rs_require_load_bearing "the check runs again before the ask" "$BUILDER" 'run the project check again, and ask for the merge only once it is green'
rs_require_order "mergeability comes before the ask" "$BUILDER" '^\*\*Whether it can merge\.' '^\*\*Asking\.\*\* Name the pull request'

# --- the script that decides ----------------------------------------------
# Run against stand-in commands, so no container engine is needed. Each case
# is one of the three answers the skill acts on.
if [ -z "${RS_LIST:-}" ]; then
  CHECK="$ROOT/.agents/skills/section-builder/scripts/check-before-merge.sh"
  rs_exists "$CHECK"
  log="$rs_dir/cleanup.log"
  run_check() {
    # run_check <expected exit> <description> <args>...
    want=$1; what=$2; shift 2
    : > "$log"
    set +e
    last=$(sh "$CHECK" "$@" 2>/dev/null)
    got=$?
    set -e
    [ "$got" -eq "$want" ] || rs_fail "$what: exited $got, not $want ($last)"
    rs_ok "$what"
  }
  run_check 0 "every command passing exits 0" --ready true true 'echo built'
  run_check 0 "a cleanup that fails does not turn a pass into anything else" --cleanup false true
  run_check 1 "a command that runs and fails exits 1" --ready true true false
  run_check 1 "a failing read of a health route exits 1, not 2" 'sh -c "exit 22"'
  run_check 2 "a ready command that fails exits 2" --ready false true
  run_check 2 "a tool that is not installed exits 2" 'no-such-tool-for-this-check build'
  run_check 2 "a ready command whose tool is missing exits 2" --ready 'no-such-tool-for-this-check info' true
  run_check 2 "a tool past a leading ! or a setting is still looked for" 'FOO=1 ! no-such-tool-for-this-check'
  run_check 2 "no command at all exits 2" --ready true
  run_check 2 "a missing tool later in a line exits 2, not 1" 'true && no-such-tool-for-this-check'
  run_check 2 "a ready option with no command exits 2, not 1" true --ready
  run_check 2 "an option it does not have exits 2" --retries 3 true
  run_check 0 "a program in quotes is found" '"sh" -c true'
  run_check 0 "a program after a bracket is found" '(sh -c true)'
  run_check 1 "a quoted program whose check fails still exits 1" '"sh" -c false'
  set +e
  sh "$CHECK" --cleanup "echo cleaned >> '$log'" true false 'echo never >> '"'$log'" >/dev/null 2>&1
  set -e
  [ "$(cat "$log")" = cleaned ] ||
    rs_fail "after a failure the cleanup must run and no later command may"
  rs_ok "after a failure the cleanup runs, and no later command does"
  : > "$log"
  sh "$CHECK" --cleanup "echo cleaned >> '$log'" true >/dev/null 2>&1
  [ "$(cat "$log")" = cleaned ] || rs_fail "after a pass the cleanup must run"
  rs_ok "after a pass the cleanup runs too"
  out=$(sh "$CHECK" --ready false true 2>/dev/null || true)
  case $out in "could not run:"*) rs_ok "a check that could not run says so on its last line" ;;
    *) rs_fail "a check that could not run printed: $out" ;; esac
  out=$(sh "$CHECK" true false 2>/dev/null || true)
  case $out in "failed: false exited 1") rs_ok "a failed check names the command that failed" ;;
    *) rs_fail "a failed check printed: $out" ;; esac
fi

rs_done
