#!/usr/bin/env sh
# push-to-main-rules.sh: guard the deny rules that stop a direct push to main.
#
# A project's Claude Code settings refuse a direct push to main. The first
# rules matched three exact spellings, and a real run pushed with
# `git push -q origin main`, which none of them matched. So this check feeds a
# list of spellings to the rules and reads back which ones are refused.
#
# Nothing here can run Claude Code's own matcher without a model, so the check
# uses the small matcher in lib/permission-matcher.py, which follows the
# documented rule shape and is shared with merge-ask-rule.sh. The matcher is
# tested first against the examples in the documentation's own table, so a
# matcher that drifted from the documentation fails before it judges anything.
# A deny rule applies when any part of a compound command matches; none of the
# spellings below needs that, so it is not modelled.
#
# The lists come from two places. The spellings the reference says are refused,
# and the ones it says are not, are read out of blocked-commands.md, so the
# written gap and the patterns cannot disagree without this check failing. The
# spellings that must never be refused, a branch that only starts with main and
# an ordinary branch, are written here, because the reference only mentions
# the first. Each push rule is then taken out in turn, to prove every one is
# needed, and an over-broad rule is added, to prove the check notices a rule
# that would stop a piece branch from pushing.
#
# The second half guards prose: the monthly offer in /maintain that brings the
# rules to a project founded before them, and the written gap itself.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/rule-shape.sh"

SETTINGS="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json"
BLOCKED="$ROOT/.agents/skills/setup-ai-build-kit/references/blocked-commands.md"
MAINTAIN="$ROOT/.agents/skills/maintain/SKILL.md"
WORKFLOW="$ROOT/WORKFLOW.md"

rs_init "Push-to-main rule checks"
rs_exists "$SETTINGS" "$BLOCKED" "$MAINTAIN" "$WORKFLOW"

if [ -z "${RS_LIST:-}" ]; then
  command -v python3 >/dev/null 2>&1 || \
    rs_fail "python3 is needed to read the settings file and run the matcher"

  python3 - "$SETTINGS" "$BLOCKED" "$ROOT/.agents/tests/lib" > "$rs_dir/matcher.out" 2>&1 <<'PY' || {
import json
import os
import sys

settings_path, blocked_path, lib_dir = sys.argv[1], sys.argv[2], sys.argv[3]
sys.path.insert(0, lib_dir)
matcher = __import__("permission-matcher")
denied = matcher.any_match

problems = matcher.self_test()
if problems:
    print("\n".join(problems))
    sys.exit(1)
print("  ok: the matcher agrees with every example in the documentation's table")


def push_spelling(s):
    return "push" in s and " " in s


blocked = open(blocked_path).read()
refused = matcher.read_list(blocked, "These spellings are refused", push_spelling)
not_refused = matcher.read_list(blocked, "These spellings are not refused", push_spelling)
if not refused:
    print("blocked-commands.md has no list of refused spellings")
    sys.exit(1)
if not not_refused:
    print("blocked-commands.md has no list of spellings the rules miss")
    sys.exit(1)

problems = []

# The spelling from the real run, and the other flag spellings, are required
# here as well as in the reference, so taking them out of the reference fails.
listed_refused = [
    "git push -q origin main",
    "git push -u origin main",
    "git push --force origin main",
    "git push -f origin main",
    "git push origin HEAD:refs/heads/main",
    "git push origin +main",
]
for command in listed_refused:
    if command not in refused:
        problems.append("blocked-commands.md does not list %r as refused" % command)
# Flags in other orders and long forms, which the reference does not list one
# by one.
required_refused = listed_refused + [
    "git push --quiet origin main",
    "git push -q -u origin main",
    "git push -u -q origin main",
    "git push --force --quiet origin main",
    "git push origin main -q",
    "git push origin +main --force",
    "git push origin HEAD:main -q",
    "git push origin refs/heads/main -q",
]

must_push = [
    "git push origin main-fix",
    "git push -u origin main-fix",
    "git push origin feature",
    "git push -u origin feature",
    "git push -q origin feature",
    "git push origin mainline",
    "git push origin feature:main-fix",
    "git push origin refs/heads/main-fix",
    "git push origin main:other",
]
option_value = "git push -o main origin feature"


def evaluate(rules):
    found = []
    for command in refused + required_refused + [option_value]:
        if not denied(rules, command):
            found.append("%r is not refused" % command)
    for command in not_refused + must_push:
        if denied(rules, command):
            found.append("%r is refused" % command)
    return found


rules = json.load(open(settings_path)).get("permissions", {}).get("deny", [])
for command in dict.fromkeys(refused + required_refused + [option_value] + not_refused + must_push):
    print("  %-7s %s" % ("denied" if denied(rules, command) else "allowed", command))

problems += evaluate(rules)
if problems:
    print("\n".join(problems))
    sys.exit(1)
print("  ok: every refused spelling is denied, and every spelling the reference says is missed is allowed")

# Each push rule is needed.
push_rules = [r for r in rules if r.startswith("Bash(git push") and "main" in r]
if len(push_rules) < 2:
    print("the settings hold fewer than two rules naming a push to main")
    sys.exit(1)
for rule in push_rules:
    if not evaluate([r for r in rules if r != rule]):
        print("taking out %s changes nothing, so the check does not need it" % rule)
        sys.exit(1)
print("  ok: taking out any one of the %d push rules is caught" % len(push_rules))

# The first rules miss the spelling from the real run.
first_rules = ["Bash(git push origin main:*)", "Bash(git push -u origin main:*)",
               "Bash(git push origin HEAD:main:*)"]
if denied(first_rules, "git push -q origin main"):
    print("the first rules already refuse 'git push -q origin main', so the check proves nothing")
    sys.exit(1)
print("  ok: the first three rules miss 'git push -q origin main', and the check says so")

# A rule broad enough to stop a piece branch is caught.
if not any("main-fix" in p or "feature" in p for p in evaluate(rules + ["Bash(git push *main*)"])):
    print("an over-broad rule that refuses main-fix went unnoticed")
    sys.exit(1)
print("  ok: an over-broad rule that refuses a branch named main-fix is caught")
PY
    cat "$rs_dir/matcher.out"
    rs_fail "the deny rules and the written gap disagree"
  }
  cat "$rs_dir/matcher.out"
fi

# The monthly offer in /maintain.
rs_rule "no settings file ends the step" 'where the project has no `\.claude/settings\.json`, this step ends'
rs_rule "the rules come from the installed template" 'take the rules from that file, never from memory'
rs_rule "nothing missing means nothing said" 'when there is none, say nothing'
rs_rule "only rules naming a push to main are offered" 'names both `git push` and `main`'
rs_rule "a removed force-push rule is not brought back" 'the person may have removed one on purpose'
rs_rule "an earlier no stands" 'where it already lists every missing rule, the earlier no stands'
rs_rule "offered once in one reply" 'offer the change once, in one reply'
rs_rule "it names the rules" 'name the rules it adds'
rs_rule "it changes nothing else" 'changes nothing else in the file'
rs_rule "it points to the written gap" 'lists the spellings the rules still cannot catch'
rs_rule "it waits for a yes" 'ask for a yes'
rs_rule "a yes adds only the missing rules" 'on a yes, add only the missing rules'
rs_rule "every other entry stays" 'keep every other entry and setting as it is'
rs_rule "the file stays valid" 'still reads as valid json'
rs_rule "a no changes nothing" 'on a no, change nothing'
rs_rule "the no is recorded" 'push-rules-declined\|<yyyy-mm-dd>\|'
rs_rule "the offer returns only for a new rule" 'offers again only when a new release adds a rule that line does not list'
rs_guard "$MAINTAIN" "maintain's push-rule offer"
rs_require "the monthly pass runs the offer" "$MAINTAIN" '16\. run "adding the rules that stop a push to `main`"'

# The written gap.
rs_reset
rs_rule "the refused list" 'these spellings are refused:'
rs_rule "the missed list" 'these spellings are not refused, and the rule above still forbids them'
rs_rule "why some are missed" 'reads the words of the command as written'
rs_rule "a branch that only starts with main still pushes" 'only starts with `main`, such as `main-fix`, still pushes'
rs_rule "an option value may be refused too" 'may also refuse a push where `main` is the value of an option'
rs_rule "the rule itself holds for every spelling" 'never push a change directly to `main`'
rs_guard "$BLOCKED" "blocked-commands.md"

rs_require "WORKFLOW.md explains the offer" "$WORKFLOW" 'offers to add them to `\.claude/settings\.json`, once'
rs_require "WORKFLOW.md says a no is kept" "$WORKFLOW" 'a no is recorded, and the offer comes back only when a release adds another rule'

rs_done
