#!/usr/bin/env sh
# refused-commands.sh: guard what happens when a command is refused, and the
# commands that destroy files or Git's recovery history.
#
# In a project built with the kit, Claude Code's deny list refused `rm -rf`
# seven times across sessions. Once, the agent ran the same deletion again as
# `rm -r`, and it went through. The same project cleared Git's reflog and
# pruned its objects on the main folder, with no checkpoint, which throws away
# the history Git would use to recover lost work. Neither was on the blocked
# list, and nothing said what to do when a command is refused.
#
# So both blocked-commands.md files carry one rule before their list: a refused
# command goes to the person, and never round the refusal in another spelling,
# another tool, or the same work in steps. Both name the new commands. The
# deny patterns themselves are judged by push-to-main-rules.sh, which reads
# the founded file's lists; this check guards the prose.
#
# /maintain removed a stale skill folder and the whole-copy leftovers without
# saying how, and the usual way is a recursive delete, now refused. So each of
# those three steps says to remove a tracked folder with `git rm -r`, which the
# saved history can undo and no rule refuses, and to give an untracked folder
# to the person as a command with its path.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

FOUNDED="$ROOT/.agents/skills/setup-ai-build-kit/references/blocked-commands.md"
GUARD="$ROOT/.agents/guard/blocked-commands.md"
MAINTAIN="$ROOT/.agents/skills/maintain/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Refused-command checks"
rs_exists "$FOUNDED" "$GUARD" "$MAINTAIN" "$WORKFLOW"

# The founded file, which every project's agent reads.
rs_rule "a refused command stops the work" 'when the coding agent refuses a command, or this list forbids it, stop'
rs_rule "the person hears which command and why, in one line" 'tell the person in one line which command was refused and what it was for'
rs_rule "the person decides" 'and let them decide'
rs_rule "never the same result another way" 'never reach the same result another way'
rs_rule "the three ways round are named" 'another spelling, another tool such as `find -delete` or a script, or the same work split into steps'
rs_rule "a person asking for it gets the command to run" 'when the person asks you to run a refused command, say it is refused and give them the command to run themselves'
rs_rule "the rule comes before the list" 'or the same work split into steps\. .*this instruction holds in every harness'
rs_rule "a recursive delete in any spelling" '[-] a recursive delete in any spelling'
rs_rule "git reflog expire" '[-] `git reflog expire`'
rs_rule "git gc with prune" '[-] `git gc` with `--prune`'
rs_rule "a throwaway folder is refused too" 'deleting a throwaway folder, such as a build folder, is refused too'
rs_rule "the person can run it themselves" 'the person can run it themselves, or the project.s own clean command can'
rs_guard "$FOUNDED" "the founded blocked-commands.md"

# The maintainer's own list.
rs_reset
rs_rule "a refused command stops the work" 'when the coding agent refuses a command, or this list forbids it, stop'
rs_rule "the person hears which command and why" 'tell the person in one line which command was refused and what it was for'
rs_rule "never the same result another way" 'never reach the same result another way'
rs_rule "the three ways round are named" 'another spelling, another tool such as `find -delete` or a script, or the same work split into steps'
rs_rule "the rule comes before the list" 'or the same work split into steps\. .*## commands'
rs_rule "a recursive delete in any spelling" '[-] a recursive delete in any spelling'
rs_rule "git reflog expire" '[-] git reflog expire'
rs_rule "git gc with prune" '[-] git gc with --prune'
rs_guard "$GUARD" "the maintainer's blocked-commands.md"

# The three removals in /maintain.
rs_reset
rs_rule "a tracked start folder goes with git rm" 'remove a tracked `start` folder with `git rm -r'
rs_rule "which history can undo and no rule refuses" 'which the saved history can undo and no deny rule refuses'
rs_rule "an untracked start folder goes to the person" 'where the `start` folder is untracked, give the person the command to run, with the folder.s path'
rs_rule "a tracked plan folder goes with git rm" 'remove a tracked `plan` folder with `git rm -r'
rs_rule "an untracked plan folder goes to the person" 'where the `plan` folder is untracked, give the person the command to run, with the folder.s path'
rs_rule "a tracked leftover goes with git rm" 'remove a tracked leftover with `git rm -r'
rs_rule "an untracked leftover folder goes to the person" 'an untracked leftover folder goes to the person as the command to run, with its path'
rs_guard "$MAINTAIN" "maintain's removal steps"

rs_require "WORKFLOW.md says the settings refuse the new commands" "$WORKFLOW" \
  'also refuse deleting a folder with everything in it, in any common spelling'
rs_require "WORKFLOW.md says a refused command comes to the person" "$WORKFLOW" \
  'when a command is refused, the agent stops and tells you in one line which command it was and what it was for'
rs_require "WORKFLOW.md says it never goes round" "$WORKFLOW" \
  'it never tries another way round'

rs_done
