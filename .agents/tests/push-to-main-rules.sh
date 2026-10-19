#!/usr/bin/env sh
# push-to-main-rules.sh: run the deny and ask rules a founded project's Claude
# Code settings carry, and the script /maintain uses to bring them to an older
# project. If this breaks, a safe upload can be refused, or an agent can
# skip the push guard, throw away unsaved changes, read
# another tool's stored login, delete a folder, or merge or change a live
# service with no box for the person to click, or the monthly offer rewrites a
# person's own settings.
#
# The matcher follows the rule shape documented at
# https://code.claude.com/docs/en/permissions and is first checked against that
# page's own examples.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SETTINGS="$ROOT/.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json"

fail() { echo "FAIL: $1" >&2; exit 1; }

[ -f "$SETTINGS" ] || fail "missing $SETTINGS"
command -v python3 >/dev/null 2>&1 || fail "python3 is needed to read the settings file and run the matcher"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "Push-to-main rule checks:"

python3 - "$SETTINGS" "$work" > "$work/matcher.out" 2>&1 <<'PY' || {
import json
import re
import sys

settings_path = sys.argv[1]


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
    # A real Claude Code run on 19 October 2026 observed that a line with
    # a pipe is matched as a whole, including later commands and arguments.
    if "|" in command:
        return pattern.match(command) is not None or command == bare
    return any(pattern.fullmatch(part) is not None or part == bare
               for part in re.split(r"\s*(?:&&|;)\s*", command))


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


rules = json.load(open(settings_path)).get("permissions", {}).get("deny", [])
old_rules = [
    "Bash(git push --force:*)", "Bash(git push -f:*)",
    "Bash(git push * main)", "Bash(git push * main *)",
    "Bash(git push * +main)", "Bash(git push * +main *)",
    "Bash(git push *:main)", "Bash(git push *:main *)",
    "Bash(git push *refs/heads/main)", "Bash(git push *refs/heads/main *)",
    "Bash(git push --force*)", "Bash(git push -f*)",
    "Bash(git push * --force*)", "Bash(git push * -f)",
    "Bash(git push * -f *)", "Bash(git push * +*)",
]
with open(sys.argv[2] + '/retired.json', 'w') as handle:
    json.dump(old_rules, handle)
observed = [
    ('git push -u origin feat 2>&1 | tail -2 && echo pr --base main', True),
    ('git push -u origin feat 2>&1 | tail -2 && gh pr create --base main --head feat --title "Title" --body "a\\nb"', True),
    ('git push -u origin feat && echo pr --base main', False),
    ('git push -u origin feat 2>&1 | tail -2; echo pr --base other', False),
    ('git push -u origin feat 2>&1 | tail -2', False),
    ('git push -u origin feat 2>&1 | tail -2 && echo "a + b"', True),
    ('git push -u origin feat 2>&1 | tail -2 && echo x -f y', True),
    ('git push -u origin feat 2>&1 | tail -2 && echo --force', True),
    ('git push -u origin feat 2>&1 | cat; echo done --base main', True),
    ('git push origin main', True),
]
for command, was_denied in observed:
    assert denied(old_rules, command) == was_denied, command
    if command != 'git push origin main':
        assert not denied(rules, command), command
# Ref safety now belongs to the hook, including spellings text rules missed.
for command in ('git push origin main', 'git push origin HEAD:main',
                'git -C . push origin main', 'git push --force origin feature',
                'git push -f origin feature', 'git push origin +feature'):
    assert not denied(rules, command), command
print('  ok: all ten observed old-rule outcomes match; new rules allow every safe upload')

# Forced deletes retain their text rules.
force_refused = [
    "rm -rf build", "rm -fr build", "rm -Rf build", "rm -fR build",
    "rm -r -f build", "rm -f -r build", "rm -R -f build", "rm -f -R build",
    "rm --recursive --force build", "rm --force --recursive build",
]
force_missed = [
    "rm -r build",
]
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
print("  ok: every forced-delete spelling listed as refused is denied, and the listed gaps and ordinary commands are not")

force_rules = [r for r in rules if r.startswith("Bash(rm ") and r != "Bash(rm -rf:*)"]
if len(force_rules) < 5:
    print("the settings hold fewer than five newer forced-delete rules")
    sys.exit(1)
for rule in force_rules:
    if not force_problems([r for r in rules if r != rule]):
        print("taking out %s changes nothing, so the check does not need it" % rule)
        sys.exit(1)
print("  ok: taking out any one of the %d newer forced-delete rules is caught" % len(force_rules))
if not force_problems(rules + ["Bash(rm -*f*)"]):
    print("an over-broad rule that refuses rm -f notes.txt went unnoticed")
    sys.exit(1)
print("  ok: an over-broad rule that refuses an ordinary delete is caught")

# Direct merges and merge APIs are refused; the merge script alone can proceed.
merge_commands = [
    "gh pr merge",
    "gh pr merge 12 --squash",
    "gh pr merge 12 --merge --delete-branch",
    "gh pr merge --auto 12",
    "gh pr merge 12 --admin",
    "gh api -X PUT repos/team/tool/pulls/12/merge",
    "gh api --method PUT repos/team/tool/pulls/12/merge -f merge_method=squash",
    "gh api repos/team/tool/merges -f base=main -f head=feature",
    "gh api graphql -f query='mutation { mergePullRequest(input: {pullRequestId: \"x\"}) { clientMutationId } }'",
]
merge_reads = ["gh pr view 12", "gh pr checks 12", "gh api repos/team/tool/pulls/12"]
for command in merge_commands + merge_reads:
    print("  %-7s %s" % ("denied" if denied(rules, command) else "allowed", command))
if any(not denied(rules, command) for command in merge_commands):
    print("a direct merge route is not denied")
    sys.exit(1)
if any(denied(rules, command) for command in merge_reads):
    print("reading pull request state is denied")
    sys.exit(1)
print("  ok: direct merge commands and APIs are denied while reads remain available")
merge_rules = [r for r in rules if "merge" in r.lower()]
for rule in merge_rules:
    if all(denied([item for item in merge_rules if item != rule], command) for command in merge_commands):
        print("taking out %s changes nothing, so the check does not need it" % rule)
        sys.exit(1)
print("  ok: each merge denial covers a distinct route")
ask = json.load(open(settings_path)).get("permissions", {}).get("ask", [])
def leave_out_each(group, check, label):
    """Every rule in the group is needed: taking it out must break the check."""
    for rule in group:
        if not check([r for r in group if r != rule]):
            print("taking out %s changes nothing, so the check does not need it" % rule)
            sys.exit(1)
    print("  ok: taking out any one of the %d %s is caught" % (len(group), label))


# Skipping the push guard, and throwing away unsaved changes.
discard_refused = [
    "git push --no-verify origin feature",
    "git push origin feature --no-verify",
    "git push -u origin feature --no-verify",
    "git -c core.hooksPath=/dev/null push origin feature",
    "git -C . -c core.hooksPath=/dev/null push origin main",
    "git -c core.hookspath=/dev/null push origin feature",
    "git config core.hooksPath .git/hooks",
    "git config --local --unset core.hooksPath",
    "git checkout .",
    "git checkout HEAD .",
    "git checkout -- .",
    "git checkout -- app/sum.js",
    "git checkout HEAD -- .",
    "git checkout HEAD -- app/sum.js",
    "git checkout -f main",
    "git checkout main -f",
    "git checkout --force main",
    "git checkout main --force",
    "git switch -f main",
    "git switch main -f",
    "git switch --force main",
    "git switch --discard-changes main",
    "git switch main --discard-changes",
    "git restore .",
    "git restore -- .",
    "git restore -- app/sum.js",
    "git restore --worktree .",
    "git restore --source=HEAD --staged --worktree .",
    "git restore -W app/sum.js",
    "git restore --staged -W app/sum.js",
    "git clean -f",
    "git clean -fd",
    "git clean -df",
    "git clean -fdx",
    "git clean -xdf",
    "git clean -d -f",
    "git clean --force -d",
    "git clean build -fd",
    "git reset --hard",
    "git reset --hard HEAD~1",
    "git reset -q --hard",
    "git reset -q --hard HEAD",
    "git stash drop",
    "git stash drop stash@{1}",
    "git stash clear",
]
discard_allowed = [
    "git checkout main",
    "git checkout -b fix-total",
    "git checkout -b feature-fix",
    "git switch main",
    "git switch -c fix-total",
    "git restore --staged app/sum.js",
    "git restore --staged .",
    "git clean -n",
    "git clean -nd",
    "git reset -q",
    "git reset HEAD app/sum.js",
    "git reset --soft HEAD~1",
    "git stash",
    "git stash list",
    "git stash pop",
    "git push -u origin feature",
    "sh .agents/skills/repair/scripts/reset-attempt.sh",
]
# Kept from the first founding settings, and in this repository's own, so
# they are needed for parity rather than for any one spelling here.
parity = {"Bash(git reset --hard:*)", "Bash(git clean -f:*)", "Bash(git clean -fd:*)"}
discard_rules = [r for r in rules if r.startswith((
    "Bash(git checkout", "Bash(git restore", "Bash(git switch", "Bash(git clean",
    "Bash(git reset", "Bash(git stash", "Bash(git push --no-verify",
    "Bash(git push * --no-verify", "Bash(git *core.hooks"))]


def discard_problems(group):
    group = list(group) + sorted(parity)
    found = ["%r is not refused" % c for c in discard_refused if not denied(group, c)]
    found += ["%r is refused" % c for c in discard_allowed if denied(group, c)]
    return found


for command in discard_refused + discard_allowed:
    print("  %-7s %s" % ("denied" if denied(rules, command) else "allowed", command))
if discard_problems(discard_rules):
    print("\n".join(discard_problems(discard_rules)))
    sys.exit(1)
print("  ok: every way of skipping the guard or discarding changes is refused, and the repair's reset script and ordinary commands are not")
leave_out_each([r for r in discard_rules if r not in parity], discard_problems,
               "discard and guard rules")

# A restore that names one file, or unstages, is not refused, since the
# matcher cannot tell the two apart. It asks first instead.
restore_ask = ["git restore app/sum.js", "git restore --staged .", "git restore --staged app/sum.js"]
for command in restore_ask:
    print("  %-7s %s" % ("asks" if denied(ask, command) else "runs", command))
missing = [c for c in restore_ask if not denied(ask, c)]
if missing:
    print("these restores neither ask nor are refused: %s" % missing)
    sys.exit(1)
if [c for c in restore_ask if denied([r for r in ask if r != "Bash(git restore *)"], c)]:
    print("a restore asks without the restore ask rule, so the check does not need it")
    sys.exit(1)
print("  ok: a restore of one file, or an unstage, asks first rather than being refused")


# Reading another tool's stored login.
def read_matches(rule, path):
    m = re.fullmatch(r"Read\((.*)\)", rule)
    if not m:
        return False
    body = m.group(1)
    if body.startswith("//"):
        body, target = body[2:], path.lstrip("/")
    elif body.startswith("~/"):
        # The home folder of the person in these examples.
        if not path.startswith(HOME + "/"):
            return False
        body, target = body[2:], path[len(HOME) + 1:]
    else:
        return False
    regex = ""
    i = 0
    while i < len(body):
        if body.startswith("**/", i):
            regex += "(?:.*/)?"
            i += 3
        elif body[i] == "*":
            regex += "[^/]*"
            i += 1
        else:
            regex += re.escape(body[i])
            i += 1
    return re.fullmatch(regex, target) is not None


HOME = "/Users/sam"
# The documentation's own examples for a rule anchored at the filesystem root,
# and for one anchored at the home folder.
assert read_matches("Read(~/Documents/*.pdf)", "/Users/sam/Documents/a.pdf")
assert not read_matches("Read(~/Documents/*.pdf)", "/Users/sam/project/Documents/a.pdf")
assert read_matches("Read(//**/.env)", "/Users/alice/project/.env")
assert read_matches("Read(//**/.env)", "/.env")
assert not read_matches("Read(//**/.env)", "/Users/alice/project/.env.local")
print("  ok: the path matcher agrees with the documentation's examples")

secret_files = [
    "/Users/sam/.config/gh/hosts.yml",
    "/home/sam/.config/gh/hosts.yml",
    "/c/Users/sam/AppData/Roaming/GitHub CLI/hosts.yml",
    "/Users/sam/Library/Application Support/com.vercel.cli/auth.json",
    "/home/sam/.local/share/com.vercel.cli/auth.json",
    "/Users/sam/.vercel/auth.json",
    "/home/sam/.vercel/auth.json",
    "/Users/sam/.vercel/config.json",
    "/Users/sam/.supabase/access-token",
    "/home/sam/.supabase/access-token",
    "/Users/sam/.supabase/profile",
    "/Users/sam/Library/Application Support/supabase/access-token",
    "/Users/sam/.docker/config.json",
]
ordinary_files = [
    "/Users/sam/project/.env.example",
    "/Users/sam/project/hosts.yml",
    "/Users/sam/project/.vercel/project.json",
    "/Users/sam/project/supabase/config.toml",
    "/Users/sam/project/supabase/.temp/pooler-url",
    "/Users/sam/project/Dockerfile",
    "/Users/sam/.config/gh/config.yml",
]
login_commands = [
    "security find-generic-password -s gh:github.com -w",
    "security find-internet-password -s github.com",
    "security dump-keychain",
    "gh auth token",
    "gh auth token --hostname github.com",
    "gh auth status --show-token",
    "gh auth status -t",
    "gh auth status --hostname github.com -t",
    "git credential fill",
    "git credential-osxkeychain get",
    "git credential-manager get",
    "less ~/.config/gh/hosts.yml",
    "head '/c/Users/sam/AppData/Roaming/GitHub CLI/hosts.yml'",
    "python3 -c \"print(open('/Users/sam/Library/Application Support/com.vercel.cli/auth.json').read())\"",
    "jq .token ~/.vercel/auth.json",
    "cat ~/.supabase/access-token",
    "cat \"$HOME/Library/Application Support/supabase/access-token\"",
    "jq .auths ~/.docker/config.json",
]
login_allowed = ["gh auth status", "gh auth status --hostname github.com", "gh auth status --active",
                 "gh auth login", "security list-keychains", "cat .env.example",
                 "cat supabase/config.toml", "cat .vercel/project.json",
                 "cat .claude/settings.json", "cat .claude/settings.local.json"]
login_rules = [r for r in rules if not r.startswith(("Bash(* > .claude/settings", "Bash(* >> .claude/settings", "Bash(tee .claude/settings")) and r.startswith(("Read(", "Bash(security", "Bash(gh auth token",
                                                 "Bash(gh auth status", "Bash(git credential",
                                                 "Bash(*")) and not r.startswith(("Read(**/.env", "Read(!**/.env"))]


def login_problems(group):
    found = ["reading %s is not refused" % p for p in secret_files
             if not any(read_matches(r, p) for r in group)]
    found += ["reading %s is refused" % p for p in ordinary_files
              if any(read_matches(r, p) for r in group)]
    found += ["%r is not refused" % c for c in login_commands if not denied(group, c)]
    found += ["%r is refused" % c for c in login_allowed if denied(group, c)]
    return found


if login_problems(login_rules):
    print("\n".join(login_problems(login_rules)))
    sys.exit(1)
print("  ok: every stored login named is refused, on each system's path, and the project's own files are not")
leave_out_each(login_rules, login_problems, "stored-login rules")


# A box before each command that changes a live service.
live_ask = [
    "supabase config push",
    "supabase db push",
    "supabase db push --linked",
    "supabase db push --dry-run",
    "supabase --workdir /tmp/signup config push --project-ref abc --yes",
    "vercel api /v9/projects/prj_1 -X PATCH --input body.json --silent",
    "vercel api /v9/projects/prj_1 -X patch --input body.json --silent",
    # Reading through Vercel's sign-in makes a lasting key the first time.
    "vercel curl /api/health --deployment https://kit-log.vercel.app --yes",
    "GATE_READ=yes sh .agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/scripts/live-check.sh --only health",
    'GATE_READ="yes" sh .agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/scripts/live-check.sh --only health',
    "GATE_READ='yes' sh .agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/scripts/live-check.sh --only health",
    "PREVIEW_HEALTH=yes sh .agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/scripts/preview.sh",
    'PREVIEW_HEALTH="yes" sh .agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/scripts/preview.sh',
    "PREVIEW_HEALTH='yes' sh .agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/scripts/preview.sh",
    "vercel project protection enable kit-log --sso",
    "vercel project protection disable kit-log --sso",
    "sh .agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/scripts/set-access.sh public",
    "sh .agents/skills/setup-hosting/recipes/parts/scripts/set-signup.sh open",
    # Recording the person's yes opens every gated online step, so it asks too.
    'python3 .agents/skills/records/scripts/approval.py yes "promote dpl_1 abc" --words "go ahead"',
    'python3 /abs/path/.agents/skills/records/scripts/approval.py yes "merge pull request 4" --words "merge it"',
    "vercel --prod",
    "vercel --prod --yes",
    "vercel deploy --prod",
    "vercel deploy --prebuilt --prod",
    "vercel --target production",
    "vercel deploy --target=production",
    "vercel rollback dpl_123 --yes",
    "vercel promote dpl_456 --yes",
    "gh repo archive someone/kit-log --yes",
    "gh repo edit --visibility public --accept-visibility-change-consequences",
    "gh repo edit someone/kit-log --visibility private",
    "gh api -X DELETE repos/someone/kit-log/git/refs/heads/old",
    "gh api --method DELETE repos/someone/kit-log",
    "gh api -XDELETE repos/someone/kit-log/hooks/1",
    "gh api --method=DELETE repos/someone/kit-log/hooks/1",
    "gh api -X=DELETE repos/someone/kit-log/hooks/1",
    "gh api repos/someone/kit-log/hooks/1 -X DELETE",
    # A branch written through the API never meets the push guard.
    "gh api repos/someone/kit-log/git/refs -f ref=refs/heads/main -f sha=abc",
    "gh api -X PATCH repos/someone/kit-log/git/refs/heads/main -f sha=abc -F force=true",
    "gh api --method POST repos/someone/kit-log/git/refs -f ref=refs/heads/x -f sha=abc",
    "gh api graphql -f query='mutation { createRef(input: {name: \"refs/heads/main\"}) { ref { id } } }'",
    "gh api graphql -f query='mutation { updateRef(input: {refId: \"x\", oid: \"abc\", force: true}) { ref { id } } }'",
    "gh api graphql -f query='mutation { deleteRef(input: {refId: \"x\"}) { clientMutationId } }'",
]
live_runs = [
    "python3 .agents/skills/records/scripts/approval.py list",
    "supabase start",
    "supabase db dump --linked -f schema.sql",
    "supabase link --project-ref abc",
    "vercel",
    "vercel deploy",
    "vercel link",
    "vercel env ls production",
    "vercel logs --environment production --level error --since 1h --no-branch --json",
    "vercel inspect https://kit-log-git-sign-out.vercel.app",
    "vercel project protection --format json",
    "vercel api /v9/projects/prj_1",
    "sh .agents/skills/setup-hosting/recipes/nextjs-supabase-on-vercel/scripts/access.sh",
    "sh .agents/skills/setup-hosting/recipes/parts/scripts/signup.sh",
    "vercel git connect --yes",
    "gh repo view --json visibility",
    "gh repo edit someone/kit-log --default-branch main",
    "gh api -X PATCH repos/someone/kit-log -F delete_branch_on_merge=true",
    "gh api repos/someone/kit-log/git/ref/heads/main",
    "gh api graphql -f query='{ repository(owner: \"someone\", name: \"kit-log\") { defaultBranchRef { name } } }'",
    "gh pr view 12",
]
live_rules = [r for r in ask if not any(word in r for word in ("merge", "Merge", "git restore"))]


def live_problems(group):
    found = ["%r does not ask" % c for c in live_ask if not denied(group, c)]
    found += ["%r asks" % c for c in live_runs if denied(group, c)]
    return found


for command in live_ask + live_runs:
    print("  %-7s %s" % ("asks" if denied(ask, command) else "runs", command))
if live_problems(live_rules):
    print("\n".join(live_problems(live_rules)))
    sys.exit(1)
print("  ok: every live-service change asks first, and reading or a preview deploy does not")
leave_out_each(live_rules, live_problems, "live-service ask rules")
if not live_problems(ask + ["Bash(vercel *)"]):
    print("an over-broad rule that asks before every vercel command went unnoticed")
    sys.exit(1)
print("  ok: an over-broad rule that asks before reading the host is caught")
PY
  cat "$work/matcher.out"
  fail "the deny or ask rules refuse the wrong commands"
}
cat "$work/matcher.out"

# Apply and decline on the frozen settings, keeping the person's entries.
  python3 - "$ROOT" "$work" <<'PY'
import json, os, pathlib, shutil, subprocess, sys
root, work = map(pathlib.Path, sys.argv[1:])
script=root/'.agents/skills/maintain/scripts/settings-rules.py'
p=work/'settings-project'; (p/'.claude').mkdir(parents=True)
settings=p/'.claude/settings.json'
shutil.copy2(root/'.agents/tests/fixtures/upgrade-v0.19.3/claude-settings.json',settings)
old=json.loads(settings.read_text()); old['my-setting']={'keep':True}
retired=set(json.loads((work/'retired.json').read_text()))
# Every retired rule is exercised, including projects founded after the frozen fixture.
old['permissions']['deny'] += sorted(retired - set(old['permissions']['deny']))
old['permissions']['deny'] += ['Bash(git push origin personal-main)', 'Bash(my own command:*)']
settings.write_text(json.dumps(old,indent=2)+'\n')
def run(flag=None,code=0):
    command=[sys.executable,str(script)]+([flag] if flag else [])+[str(p)]
    result=subprocess.run(command,capture_output=True,text=True)
    assert result.returncode==code,(command,result.returncode,result.stdout,result.stderr)
    return result.stdout
# The whole retired set stays while the guard is off, including on apply.
offer=run(code=1)
assert 'remove-deny' not in offer and 'guard must be switched on' in offer
subprocess.run(['git', 'init', '-q', str(p)], check=True)
setup=root/'.agents/skills/setup-ai-build-kit'
(p/'.agents/hooks/git').mkdir(parents=True)
shutil.copy2(setup/'templates/foundation/pre-push', p/'.agents/hooks/git/pre-push')
subprocess.run(['sh', str(setup/'scripts/use-push-guard.sh'), str(p)], check=True)
# Inactive files, unrelated executable hooks and a .husky chain are distinguished.
for mode in ('missing', 'not-executable', 'unrelated'):
    hook=p/'.agents/hooks/git/pre-push'
    original=hook.read_bytes()
    if mode=='missing': hook.unlink()
    elif mode=='not-executable': hook.chmod(0o644)
    else: hook.write_text('#!/bin/sh\nexit 0\n')
    assert 'remove-deny' not in run(code=1)
    run('--apply')
    assert retired.issubset(json.loads(settings.read_text())['permissions']['deny'])
    settings.write_text(json.dumps(old,indent=2)+'\n')
    hook.write_bytes(original); hook.chmod(0o755)
subprocess.run(['git', '-C', str(p), 'config', 'core.hooksPath', '.husky'], check=True)
assert 'remove-deny' not in run(code=1)
subprocess.run(['sh', str(setup/'scripts/use-push-guard.sh'), str(p)], check=True)
# A single matching personal rule stays even with an active guard.
single=json.loads(settings.read_text())
single['permissions']['deny']=[r for r in single['permissions']['deny'] if r not in retired]+['Bash(git push * main)']
settings.write_text(json.dumps(single))
assert 'remove-deny' not in run(code=1)
run('--apply')
assert 'Bash(git push * main)' in json.loads(settings.read_text())['permissions']['deny']
settings.write_text(json.dumps(old,indent=2)+'\n')
first_offer='\n'+run(code=1)
assert '\ndeny\tBash(gh pr merge:*)' in first_offer
for rule in retired: assert '\nremove-deny\t'+rule+'\n' in first_offer+'\n'
assert '\nask\tBash(*merge.py*--approved*)' in first_offer
assert '\nask\tBash(*merge.py*--resume*)' in first_offer
import fnmatch
merge_rule = "*merge.py*--approved*"
for command in (
    'python3 ".../merge.py" --approved 12',
    'python merge.py --approved 12',
    './merge.py --approved 12',
    'python3 path/to/merge.py --approved 12',
):
    assert fnmatch.fnmatchcase(command, merge_rule), command
# The rules added after that release reach an older project too, and only
# through the offer: nothing in the file changes until --apply.
template=json.loads((root/'.agents/skills/setup-ai-build-kit/templates/foundation/claude-settings.json').read_text())
newer_deny=[r for r in template['permissions']['deny'] if r.startswith(('Edit(.claude/settings','Edit(**/.claude/settings','Write(.claude/settings','Write(**/.claude/settings','Read(','Bash(security','Bash(gh auth token','Bash(git checkout','Bash(git restore','Bash(git stash','Bash(git push --no-verify','Bash(git push * --no-verify','Bash(git switch','Bash(git clean -*','Bash(git clean * ','Bash(git reset * ','Bash(git *core.hooks','Bash(gh auth status','Bash(git credential','Bash(gh pr merge','Bash(gh api *pulls/*/merge','Bash(gh api *merges','Bash(gh api graphql *mergePullRequest','Bash(* > .claude/settings','Bash(* >> .claude/settings','Bash(tee .claude/settings','Bash(*')) and not r.startswith(('Read(**/.env','Read(!**/.env'))]
newer_ask=[r for r in template['permissions']['ask'] if 'merge' not in r.lower()]
assert len(newer_deny)>=16 and len(newer_ask)>=13,(newer_deny,newer_ask)
assert 'Edit(**/.claude/settings.json)' in newer_deny
assert 'Write(**/.claude/settings.json)' in newer_deny
assert 'Edit(**/.claude/settings.local.json)' in newer_deny
assert 'Write(**/.claude/settings.local.json)' in newer_deny
assert not any(r.startswith(('Read(.claude/settings.json', 'Read(.claude/settings.local.json')) for r in newer_deny)
assert 'Bash(*PREVIEW_HEALTH=yes*)' in newer_ask
assert 'Bash(*PREVIEW_HEALTH="yes"*)' in newer_ask
assert "Bash(*PREVIEW_HEALTH='yes'*)" in newer_ask
assert 'Bash(*GATE_READ="yes"*)' in newer_ask
assert "Bash(*GATE_READ='yes'*)" in newer_ask
for rule in newer_deny: assert '\ndeny\t'+rule+'\n' in first_offer+'\n',(rule,first_offer)
for rule in newer_ask: assert '\nask\t'+rule+'\n' in first_offer+'\n',(rule,first_offer)
assert json.loads(settings.read_text())==old
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
    if key in ('ask','deny'):
        kept=[r for r in value if key!='deny' or r not in retired]
        assert current['permissions'][key][:len(kept)]==kept
        if key=='deny': assert not retired.intersection(current['permissions'][key])
    else: assert current['permissions'][key]==value
assert not run()
assert all(r in current['permissions']['deny'] for r in newer_deny)
assert all(r in current['permissions']['ask'] for r in newer_ask)
assert 'Bash(*merge.py*--resume*)' in current['permissions']['ask']
second=settings.read_bytes(); run('--apply'); assert second==settings.read_bytes()
# Removed broad force/delete rules stay removed; asks and hook rules still offered.
old['permissions']['deny']=[r for r in old['permissions']['deny'] if r not in ('Bash(git push --force:*)','Bash(rm -rf:*)')]
settings.write_text(json.dumps(old))
(p/'.ai-build-kit-maintenance').unlink()
offer=run(code=1)
assert not any(l.startswith('deny\tBash(rm ') or l.startswith('deny\tBash(git push') and 'main' not in l and '--no-verify' not in l for l in offer.splitlines()),offer
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
print('  ok: settings apply, declines, merge confirmation offers and linked paths preserve the project')
PY

echo
echo "push-to-main-rules.sh: all checks passed"
