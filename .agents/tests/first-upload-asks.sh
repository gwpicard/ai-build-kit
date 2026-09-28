#!/usr/bin/env sh
# first-upload-asks.sh: guard the yes the project's first upload waits for.
#
# Founding tells the person nothing will be uploaded, and that is true of
# founding. In a real run the first piece built afterwards then pushed the
# whole project to GitHub with no question, straight after the person had
# heard that nothing was uploaded. So the first push of a project's code asks
# first, naming the repository and whether it is public or private, and it asks
# once for each project.
#
# "Once" is read off the remote rather than kept in a record: a remote that
# lists no branch has nothing of this project on it. A record could disagree
# with the remote, and the remote is what the question is about.
#
# Each rule here is prose an agent reads. Its absence would not show until the
# next first build uploaded a project nobody agreed to put online.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

BUILDER="$ROOT/.agents/skills/section-builder/SKILL.md"
SETUP="$ROOT/.agents/skills/setup-ai-build-kit/SKILL.md"
SYNC="$ROOT/.agents/skills/sync/SKILL.md"
SHIP="$ROOT/.agents/skills/ship/SKILL.md"
BLOCKED="$ROOT/.agents/skills/setup-ai-build-kit/references/blocked-commands.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "First upload checks"
rs_exists "$BUILDER" "$SETUP" "$SYNC" "$SHIP" "$BLOCKED" "$WORKFLOW"

# The ask, and when it is due.
rs_rule "the first push waits for a yes" 'the first push of the project.s code waits for their yes'
rs_rule "the remote is read before any push" 'before any push, run `git ls-remote --heads origin`'
rs_rule "no branch listed means the first upload" 'when it lists no branch, nothing from this project is online yet and this push is the first upload'
rs_rule "a listed branch means no ask" 'when it lists one, the code is already there, so push without asking'
# How "once" is known.
rs_rule "once for each project, known from the remote, with no record" 'that listing is how you know the question was answered: it is asked once for each project, and no record is kept'
rs_rule "an empty remote earns no unreachable note" 'a remote with nothing on it also has no `main` to bring up to date, and that needs no note'

# The build finishes; only the push waits.
rs_rule "the piece is still built and checked" 'build and check the piece first\. only the push waits'
rs_rule "the ask names the upload" 'ask for a yes that names the upload'
rs_rule "it names the repository" 'the repository as `owner/name`'
rs_rule "and whether it is public or private, read from github" 'whether it is public or private, read with `gh repo view --json visibility`'
rs_rule "an unreadable visibility is said, not guessed" 'where you cannot read that, say so rather than guess'

# What a yes does. The settings refuse a push to main, so the one way main is
# created is written down rather than left for an agent to improvise.
rs_rule "a yes creates main on github at the local main" 'create `main` on github at the local `main`'
rs_rule "and makes it the default branch" 'make it the default branch'
rs_rule "the one time main is written other than by a merge" 'this is the one time `main` is written other than by a merge'

# A no, and nobody there.
rs_rule "a no keeps the piece on its own branch here" 'on a no, keep the piece on its own branch on this computer'
rs_rule "a no is the route the project cannot perform, with its note" 'that is the route the project cannot perform right now, with its one-line note'
rs_rule "the next piece asks again" 'the next piece that pushes asks again'
rs_rule "an unattended run never uploads" 'in an unattended run nobody is there to say yes, so never upload on the person.s behalf: keep the work local and note it on the piece'
rs_guard "$BUILDER" "section-builder's first upload rules"

rs_require_order "the rules sit in the safe start, before the piece is labelled" "$BUILDER" '^\*\*The first upload\.\*\*' 'Label the piece `building`'
rs_require_load_bearing "the save step points back at the ask" "$BUILDER" 'the project.s first upload waits for the yes in step 1'

# The other commands that push follow the same rule.
rs_require_load_bearing "sync's save follows the first upload rule" "$SYNC" 'the project.s first upload waits for the yes section-builder.s "the first upload" describes'
rs_require_load_bearing "ship's records follow the first upload rule" "$SHIP" 'the project.s first upload waits for the yes section-builder.s "the first upload" describes'
rs_require_load_bearing "the push-to-main rule names its one exception" "$BLOCKED" 'the one exception is the project.s first upload, which creates `main` on an empty repository'

# Founding's promise stays true, and says what comes next.
rs_require_load_bearing "founding says the first piece asks before the code goes online" "$SETUP" 'the code stays on this computer until the first piece that pushes asks the person first'

# WORKFLOW.md tells it.
rs_require_load_bearing "WORKFLOW says the first upload is asked" "$WORKFLOW" 'the first time anything pushes your project.s code online, the agent asks you first, naming the repository and whether it is public or private'
rs_require_load_bearing "WORKFLOW says it is asked once for each project" "$WORKFLOW" 'it asks once for each project: once the code is on github, it does not ask again'
rs_require_load_bearing "WORKFLOW says a no or nobody there keeps the piece local" "$WORKFLOW" 'if you say no, or nobody is there to answer, the piece is still built and checked, and it waits on its own branch on your computer until you say yes'
rs_require_load_bearing "WORKFLOW's founding story says the first build asks" "$WORKFLOW" 'your code stays there until your first build asks you before putting it online'

rs_done
