#!/usr/bin/env sh
# push-to-main-rules.sh: guard the deny rules that stop a direct push to main.
#
# A project's Claude Code settings refuse a direct push to main. The first
# rules matched three exact spellings, and a real run pushed with
# `git push -q origin main`, which none of them matched. So this check feeds a
# list of spellings to the rules and reads back which ones are refused.
#
# Nothing here can run Claude Code's own matcher without a model, so the check
# carries a small matcher that follows the documented rule shape, taken from
# https://code.claude.com/docs/en/permissions ("Wildcard patterns" and "Bash"):
#
#   - a rule matches the whole command text;
#   - `*` may sit anywhere and stands for any text, spaces included;
#   - everything else is literal, including a space before a `*`, and a colon
#     anywhere but a final `:*`;
#   - a final `:*` is the same as a final ` *`;
#   - a final ` *` that is the rule's only wildcard also matches the bare
#     command with nothing after it.
#
# The matcher is tested first against the examples in that page's own table,
# so a matcher that drifted from the documentation fails before it judges
# anything. It is fed one command at a time. Claude Code also splits a compound
# command and strips wrappers such as `timeout` and leading variable
# assignments before it matches, and a deny rule applies when any part matches;
# none of the spellings below needs that, so it is not modelled.
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

  python3 - "$SETTINGS" "$BLOCKED" > "$rs_dir/matcher.out" 2>&1 <<'PY' || {
import json
import re
import sys

settings_path, blocked_path = sys.argv[1], sys.argv[2]


def compile_rule(rule):
    m = re.fullmatch(r"Bash\((.*)\)", rule, re.S)
    if not m:
        return None
    body = m.group(1)
    if body.endswith(":*"):
        body = body[:-2] + " *"
    pattern = ".*".join(re.escape(part) for part in body.split("*"))
    bare = body[:-2] if body.count("*") == 1 and body.endswith(" *") else None
    return re.compile(pattern, re.S), bare


def matches(rule, command):
    compiled = compile_rule(rule)
    if compiled is None:
        return False
    pattern, bare = compiled
    return pattern.fullmatch(command) is not None or command == bare


def denied(rules, command):
    return any(matches(rule, command) for rule in rules)


problems = []

# The documentation's own table, row by row.
documented = [
    ("Bash(npm run build)", ["npm run build"], ["npm run build --watch"]),
    ("Bash(npm run *)", ["npm run build", "npm run test --watch", "npm run"], ["npm install"]),
    ("Bash(git log * main)",
     ["git log --oneline main", "git log -5 main", "git log --output=<file> main"],
     ["git log main", "git push origin main"]),
    ("Bash(git * main)",
     ["git merge main", "git push origin main", "git -c core.fsmonitor=<script> diff main"],
     ["git log"]),
    ("Bash(* --version)", ["node --version", "bash -c 'echo hi' --version"], ["node -v"]),
    ("Bash(ls *)", ["ls -la", "ls"], ["lsof"]),
    ("Bash(ls*)", ["ls -la", "lsof"], []),
    ("Bash(* --help *)", ["npm --help x"], ["npm --help"]),
    ("Bash(ls:*)", ["ls -la", "ls"], ["lsof"]),
    ("Bash(git:* push)", [], ["git push", "git status push"]),
]
for rule, yes, no in documented:
    for command in yes:
        if not matches(rule, command):
            problems.append("matcher: %s should match %r, as the documentation says" % (rule, command))
    for command in no:
        if matches(rule, command):
            problems.append("matcher: %s should not match %r, as the documentation says" % (rule, command))
if problems:
    print("\n".join(problems))
    sys.exit(1)
print("  ok: the matcher agrees with every example in the documentation's table")


def read_list(text, marker):
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if marker in line:
            break
    else:
        return None
    items, current = [], None
    for line in lines[i + 1:]:
        if line.startswith("- "):
            if current is not None:
                items.append(current)
            current = line[2:].strip()
        elif line.startswith("  ") and current is not None:
            current += " " + line.strip()
        elif line.strip() == "" and current is None:
            continue
        else:
            break
    if current is not None:
        items.append(current)
    spellings = []
    for item in items:
        spellings += [s for s in re.findall(r"`([^`]+)`", item) if "push" in s and " " in s]
    return spellings


blocked = open(blocked_path).read()
refused = read_list(blocked, "These spellings are refused")
not_refused = read_list(blocked, "These spellings are not refused")
if not refused:
    print("blocked-commands.md has no list of refused spellings")
    sys.exit(1)
if not not_refused:
    print("blocked-commands.md has no list of spellings the rules miss")
    sys.exit(1)

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
    if not evaluate([r for r in push_rules if r != rule]):
        print("taking out %s changes nothing, so the check does not need it" % rule)
        sys.exit(1)
print("  ok: taking out any one of the %d push rules is caught" % len(push_rules))

# A force push and a forced delete. The lists come from their own section of
# blocked-commands.md, so the written gap and the patterns cannot disagree.
section_start = blocked.find("## A force push and a forced delete")
if section_start < 0:
    print("blocked-commands.md has no section on a force push and a forced delete")
    sys.exit(1)
section = blocked[section_start:]
next_heading = section.find("\n## ", 4)
if next_heading > 0:
    section = section[:next_heading]


def read_spans(text, marker):
    start = text.find(marker)
    if start < 0:
        return None
    body = text[start:].split("\n\n", 2)
    items = body[1] if len(body) > 1 else ""
    return [span for span in re.findall(r"`([^`]+)`", items)
            if span.startswith("git push") or span.startswith("rm ") or span.startswith("sh -c")]


force_refused = read_spans(section, "These force pushes and deletes are refused")
force_missed = read_spans(section, "These are not refused")
if not force_refused or not force_missed:
    print("the force-push section lacks its refused or its missed list")
    sys.exit(1)
for command in ["git push origin feature --force", "git push origin feature --force-with-lease",
                "git push origin +feature", "rm -fr build", "rm --recursive --force build"]:
    if command not in force_refused:
        problems.append("blocked-commands.md does not list %r as refused" % command)
force_allowed = force_missed + [
    "git push origin feature",
    "git push -u origin feature",
    "git push --follow-tags origin feature",
    "git push origin fix-f",
    "rm -f notes.txt",
    "rm notes.txt",
]


def force_problems(deny):
    found = []
    for command in force_refused:
        if not denied(deny, command):
            found.append("%r is not refused" % command)
    for command in force_allowed:
        if denied(deny, command):
            found.append("%r is refused" % command)
    return found


for command in force_refused + force_allowed:
    print("  %-7s %s" % ("denied" if denied(rules, command) else "allowed", command))
problems += force_problems(rules)
if problems:
    print("\n".join(problems))
    sys.exit(1)
print("  ok: every force-push and forced-delete spelling listed as refused is denied, and the listed gaps and ordinary commands are not")

kept_for_parity = {"Bash(git push --force:*)", "Bash(git push -f:*)", "Bash(rm -rf:*)"}
force_rules = [r for r in rules if r not in push_rules and r not in kept_for_parity
               and (r.startswith("Bash(git push") or r.startswith("Bash(rm "))]
if len(force_rules) < 5:
    print("the settings hold fewer than five newer force-push or forced-delete rules")
    sys.exit(1)
for rule in force_rules:
    if not force_problems([r for r in rules if r != rule]):
        print("taking out %s changes nothing, so the check does not need it" % rule)
        sys.exit(1)
print("  ok: taking out any one of the %d newer force-push and forced-delete rules is caught" % len(force_rules))
if not force_problems(rules + ["Bash(rm -*f*)"]):
    print("an over-broad rule that refuses rm -f notes.txt went unnoticed")
    sys.exit(1)
print("  ok: an over-broad rule that refuses an ordinary delete is caught")

# The question before a merge.
ask = json.load(open(settings_path)).get("permissions", {}).get("ask", [])
must_ask = [
    "gh pr merge",
    "gh pr merge 12 --squash",
    "gh pr merge 12 --merge --delete-branch",
    "gh pr merge --auto 12",
    "gh api -X PUT repos/team/tool/pulls/12/merge",
    "gh api --method PUT repos/team/tool/pulls/12/merge -f merge_method=squash",
    "gh api repos/team/tool/merges -f base=main -f head=feature",
    "gh api graphql -f query='mutation { mergePullRequest(input: {pullRequestId: \"x\"}) { clientMutationId } }'",
]
must_not_ask = [
    "gh pr view 12",
    "gh pr list --state merged",
    "gh pr create --base main --fill",
    "gh pr checks 12",
    "gh api repos/team/tool/pulls/12",
    "gh api repos/team/tool/branches",
]


def ask_problems(rules_ask):
    found = []
    for command in must_ask:
        if not denied(rules_ask, command):
            found.append("%r does not ask" % command)
    for command in must_not_ask:
        if denied(rules_ask, command):
            found.append("%r asks" % command)
    return found


for command in must_ask + must_not_ask:
    print("  %-7s %s" % ("asks" if denied(ask, command) else "runs", command))
if ask_problems(ask):
    print("\n".join(ask_problems(ask)))
    sys.exit(1)
print("  ok: every way of merging asks first, and reading a pull request does not")
for rule in ask:
    if not ask_problems([r for r in ask if r != rule]):
        print("taking out the ask rule %s changes nothing, so the check does not need it" % rule)
        sys.exit(1)
print("  ok: taking out any one of the %d ask rules is caught" % len(ask))
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

# Apply and decline on the frozen settings, keeping the person's entries.
if [ -z "${RS_LIST:-}" ]; then
  python3 - "$ROOT" "$rs_dir" <<'PY'
import json, os, pathlib, shutil, subprocess, sys
root, work = map(pathlib.Path, sys.argv[1:])
script=root/'.agents/skills/maintain/scripts/settings-rules.py'
p=work/'settings-project'; (p/'.claude').mkdir(parents=True)
settings=p/'.claude/settings.json'
shutil.copy2(root/'.agents/tests/fixtures/upgrade-v0.19.3/claude-settings.json',settings)
old=json.loads(settings.read_text()); old['my-setting']={'keep':True}
settings.write_text(json.dumps(old,indent=2)+'\n')
def run(flag=None,code=0):
    command=[sys.executable,str(script)]+([flag] if flag else [])+[str(p)]
    result=subprocess.run(command,capture_output=True,text=True)
    assert result.returncode==code,(command,result.returncode,result.stdout,result.stderr)
    return result.stdout
assert '\nask\tBash(gh pr merge:*)' in '\n'+run(code=1)
run('--merge-box',1)
original=settings.read_bytes()
run('--decline'); assert settings.read_bytes()==original
assert 'push-rules-declined|' in (p/'.ai-build-kit-maintenance').read_text()
assert all(l.startswith('declined\t') for l in run().splitlines())
# An older no covering fewer rules must bring the full offer back.
(p/'.ai-build-kit-maintenance').write_text('push-rules-declined|2026-01-01|Bash(gh pr merge:*)\n')
run(code=1)
run('--apply'); current=json.loads(settings.read_text())
assert current['my-setting']==old['my-setting']
for key,value in old['permissions'].items():
    if key in ('ask','deny'): assert current['permissions'][key][:len(value)]==value
    else: assert current['permissions'][key]==value
assert not run(); run('--merge-box')
second=settings.read_bytes(); run('--apply'); assert second==settings.read_bytes()
# Removed broad force/delete rules stay removed; asks and main rules still offered.
old['permissions']['deny']=[r for r in old['permissions']['deny'] if r not in ('Bash(git push --force:*)','Bash(rm -rf:*)')]
settings.write_text(json.dumps(old))
(p/'.ai-build-kit-maintenance').unlink()
offer=run(code=1)
assert not any(l.startswith('deny\tBash(rm ') or l.startswith('deny\tBash(git push') and 'main' not in l for l in offer.splitlines()),offer
# Invalid JSON, malformed lists and linked parents must not be rewritten.
settings.write_text('{not json'); assert 'left\t' in run('--apply'); assert settings.read_text()=='{not json'
settings.write_text('{"permissions":{"ask":"my own value"}}'); original=settings.read_bytes()
assert 'left\t' in run('--apply'); assert settings.read_bytes()==original
settings.unlink(); (p/'.claude').rmdir()
outside=work/'settings-outside'; outside.mkdir(); external=outside/'settings.json'
external.write_text(json.dumps(old)); original=external.read_bytes()
(p/'.claude').symlink_to(outside,target_is_directory=True)
assert 'left\t' in run('--apply'); assert external.read_bytes()==original
maintenance=work/'maintenance-outside'; maintenance.write_text('My own record.\n')
(p/'.ai-build-kit-maintenance').symlink_to(maintenance)
run('--decline'); assert maintenance.read_text()=='My own record.\n'
print('  ok: settings apply, declines, merge-box detection and linked paths preserve the project')
PY
fi

# The monthly offer in /maintain.
rs_rule "no settings file ends the step" 'where the project has no `\.claude/settings\.json`, this step ends'
rs_rule "the rules come from the installed template" 'take the rules from that file, never from memory'
rs_rule "nothing missing means nothing said" 'when no rule is left, say nothing'
rs_rule "only rules naming a push to main are offered" 'names both `git push` and `main`'
rs_rule "a removed rule is not brought back" 'the person may have removed a rule on purpose'
rs_rule "force rules only while the old one stays" 'offered only while the project still holds `bash\(git push --force:\*\)` for a force push, or `bash\(rm -rf:\*\)` for a forced delete'
rs_rule "the merge question is offered" 'a rule in `ask`, which makes claude code ask before a merge'
rs_rule "each rule goes back to its own list" 'adds only the missing rules to the end of the list each came from'
rs_rule "an earlier no stands" 'where it already lists every missing rule, the earlier no stands'
rs_rule "offered once in one reply" 'offer the change once, in one reply'
rs_rule "it names the rules" 'name the rules it adds'
rs_rule "it changes nothing else" 'changes nothing else in the file'
rs_rule "it points to the written gap" 'lists the spellings the rules still cannot catch'
rs_rule "it waits for a yes" 'ask for a yes'
rs_rule "every other entry stays" 'keeps every other entry and setting as it is'
rs_rule "the file stays valid" 'still reads as valid json'
rs_rule "a no changes nothing" 'on a no, change nothing'
rs_rule "the no is recorded" 'push-rules-declined\|<yyyy-mm-dd>\|'
rs_rule "the offer returns only for a new rule" 'offers again only when a new release adds a rule that line does not list'
rs_guard "$MAINTAIN" "maintain's push-rule offer"
rs_require "every visit reads the safety rules" "$MAINTAIN" 'the check in "finishing a kit update" runs it on every visit'

# The written gap.
rs_reset
rs_rule "the refused list" 'these spellings are refused:'
rs_rule "the missed list" 'these spellings are not refused, and the rule above still forbids them'
rs_rule "why some are missed" 'reads the words of the command as written'
rs_rule "a branch that only starts with main still pushes" 'only starts with `main`, such as `main-fix`, still pushes'
rs_rule "an option value may be refused too" 'may also refuse a push where `main` is the value of an option'
rs_rule "the rule itself holds for every spelling" 'never push a change directly to `main`'
rs_rule "a force push is refused wherever the option sits" 'refuse both wherever the option sits in the command'
rs_rule "a conflict needs no force" 'merge `main` into the branch and push it. that needs no force'
rs_rule "a merge asks first" 'ask before every merge the agent runs'
rs_rule "the merge is named before the box" 'say in one line what the merge does just before the box appears'
rs_rule "other agents keep only the written rule" 'other coding agents have no such box, so there the written rule is the only guard'
rs_guard "$BLOCKED" "blocked-commands.md"

rs_require "WORKFLOW.md explains the offer" "$WORKFLOW" 'offers to add them to `\.claude/settings\.json`, once'
rs_require "WORKFLOW.md names the merge question" "$WORKFLOW" 'ask you before any merge'
rs_require "WORKFLOW.md says a no is kept" "$WORKFLOW" 'a no is recorded, and the offer comes back only when a release adds another rule'

rs_done
