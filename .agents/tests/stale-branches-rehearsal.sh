#!/usr/bin/env sh
# stale-branches-rehearsal.sh: run the shipped branch list against a throwaway
# project and a stand-in for GitHub, and read back what it named and what it
# left alone.
#
# The project has one branch of every kind the monthly step sorts: merged with
# a merge commit, merged by squashing, merged by squashing and then given more
# work, protected on GitHub, covered only by a rule that is not about deletion,
# with an open pull request, checked out in another working copy, named by the
# project as one that stays, and not merged at all. The script must give the
# right command for each branch that can go, keep this computer and GitHub
# apart, name the ones it set aside, and remove nothing: every branch on both
# sides is still there afterwards. Signed out of GitHub, it must not offer the
# squash group's command, since nothing can confirm it.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT="$ROOT/.agents/skills/maintain/scripts/stale-branches.py"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

command -v node >/dev/null 2>&1 || fail "node is needed to run this rehearsal"
command -v python3 >/dev/null 2>&1 || fail "python3 is needed to run this rehearsal"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

node - "$SCRIPT" "$WORK" <<'NODE'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync, spawnSync } = require('node:child_process');

const [script, work] = process.argv.slice(2);
const env = { ...process.env, GIT_AUTHOR_NAME: 'R', GIT_AUTHOR_EMAIL: 'r@example.invalid',
  GIT_COMMITTER_NAME: 'R', GIT_COMMITTER_EMAIL: 'r@example.invalid' };

// --- a stand-in for the GitHub tool, answering from a state file ---------------------

const bin = path.join(work, 'bin');
fs.mkdirSync(bin);
const state = path.join(work, 'gh-state.json');
const log = path.join(work, 'gh-log');
fs.writeFileSync(path.join(bin, 'gh'), `#!/usr/bin/env python3
import json, sys
args = sys.argv[1:]
with open(${JSON.stringify(log)}, "a") as handle:
    handle.write(" ".join(args) + "\\n")
state = json.load(open(${JSON.stringify(state)}))
def value(flag):
    return args[args.index(flag) + 1] if flag in args else None
if args[:2] == ["auth", "status"]:
    sys.exit(0 if state["signed_in"] else 1)
if not state["signed_in"]:
    sys.exit(1)
if args[:2] == ["repo", "view"]:
    print(state["default"]); sys.exit(0)
if args[:2] == ["pr", "list"] and value("--state") == "open":
    print(json.dumps([{"headRefName": n} for n in state["open"]])); sys.exit(0)
if args[:2] == ["pr", "list"] and value("--state") == "merged":
    print(json.dumps(state["merged"].get(value("--head"), []))); sys.exit(0)
if args[0] == "api" and "/rules/branches/" in args[1]:
    print(json.dumps(state["rules"].get(args[1].rsplit("/", 1)[1], []))); sys.exit(0)
if args[0] == "api" and "/branches/" in args[1]:
    print("true" if args[1].rsplit("/", 1)[1] in state["protected"] else "false"); sys.exit(0)
sys.exit(1)
`, { mode: 0o755 });

// --- the project and its copy on GitHub ----------------------------------------------

const remote = path.join(work, 'remote.git');
const project = path.join(work, 'project');
const git = (args, cwd = project) => execFileSync('git', args, { cwd, env, encoding: 'utf8' }).trim();
git(['init', '-q', '--bare', '-b', 'main', remote], work);
git(['init', '-q', '-b', 'main', project], work);
const commit = (file, text, message) => {
  fs.writeFileSync(path.join(project, file), text);
  git(['add', '-A']);
  git(['commit', '-q', '-m', message]);
  return git(['rev-parse', 'HEAD']);
};
commit('readme.md', 'start\n', 'Start');
git(['remote', 'add', 'origin', remote]);
git(['push', '-q', '-u', 'origin', 'main']);

const branch = (name, file, text) => {
  git(['switch', '-q', '-c', name, 'main']);
  const sha = commit(file, text, `Work on ${name}`);
  git(['push', '-q', 'origin', name]);
  git(['switch', '-q', 'main']);
  return sha;
};

// Merged with a merge commit, and others merged the same way.
for (const name of ['fix-login', 'release', 'rules-only', 'open-pr', 'in-other-copy', 'keep-me']) {
  branch(name, `${name}.txt`, `${name}\n`);
  git(['merge', '-q', '--no-ff', '-m', `Merge ${name}`, name]);
}
// Merged by squashing: main gets one new commit, the branch keeps its own.
const reportTip = branch('new-report', 'report.txt', 'report\n');
git(['merge', '-q', '--squash', 'new-report']);
git(['commit', '-q', '-m', 'Add the report']);
// Merged by squashing, then given more work.
const exportTip = branch('export-fix', 'export.txt', 'export\n');
git(['merge', '-q', '--squash', 'export-fix']);
git(['commit', '-q', '-m', 'Fix the export']);
git(['switch', '-q', 'export-fix']);
commit('export.txt', 'export, more\n', 'More export work');
git(['push', '-q', 'origin', 'export-fix']);
git(['switch', '-q', 'main']);
// Never merged.
branch('wip', 'wip.txt', 'wip\n');
git(['push', '-q', 'origin', 'main']);
git(['worktree', 'add', '-q', path.join(work, 'other-copy'), 'in-other-copy']);

fs.writeFileSync(state, JSON.stringify({
  signed_in: true, default: 'main', open: ['open-pr'], protected: ['release'],
  rules: { 'rules-only': [{ type: 'required_signatures' }] },
  merged: { 'new-report': [{ number: 4, headRefOid: reportTip }], 'export-fix': [{ number: 5, headRefOid: exportTip }] },
}));

const branches = () => git(['for-each-ref', '--format=%(refname)', 'refs/heads']) + '\n' +
  git(['ls-remote', '--heads', 'origin']);

function list(args = [], cwd = project) {
  const before = branches();
  const result = spawnSync('python3', [script, ...args], { cwd, encoding: 'utf8', timeout: 120000,
    env: { ...env, PATH: `${bin}:${process.env.PATH}` } });
  assert.ifError(result.error);
  assert.equal(branches(), before, 'a branch was removed or changed');
  return result;
}

// --- signed in -----------------------------------------------------------------------

const full = list(['--keep', 'keep-me']);
console.log(full.stdout.split('\n').map(l => `    ${l}`).join('\n'));
assert.equal(full.status, 1, 'a report was printed but the exit code was not 1');
const out = full.stdout;
const has = text => out.split('\n').some(l => l.includes(text));
assert.ok(has('git branch -d fix-login') && has('git push origin --delete fix-login'), 'the merged branch has no command on both sides');
assert.ok(has('git push origin --delete rules-only'), 'a rule that is not about deletion set a branch aside');
console.log('  ok: a branch Git confirms gets the careful command on this computer and the delete command on GitHub');
assert.ok(has('git branch -D new-report') && has('on GitHub: git push origin --delete new-report'), 'the squash-merged branch has no command');
assert.ok(!has('git branch -d new-report'), 'the squash-merged branch got the careful command, which Git would refuse');
console.log('  ok: a branch only GitHub records as merged gets the forceful command, kept apart from the first group');
for (const name of ['export-fix', 'release']) {
  assert.ok(out.split('\n').some(l => l.trim() === name), `${name} is not named as set aside`);
  assert.ok(!new RegExp(`(-d|-D|--delete) ${name}\\b`).test(out), `${name} was given a command`);
}
console.log('  ok: a branch with work after its merge, and a protected branch, are named and given no command');
for (const name of ['open-pr', 'in-other-copy', 'keep-me', 'wip', 'main']) {
  assert.ok(!new RegExp(`\\b${name}\\b`).test(out.replace(/in main|reached main|confirmed in main|already in main/g, '')),
    `${name} should never be listed`);
}
console.log('  ok: the default branch, an open pull request, a checked-out branch, a kept branch and unmerged work are never listed');
const calls = fs.readFileSync(log, 'utf8');
assert.ok(!/DELETE|delete|merge |close/.test(calls), `the script asked GitHub to change something:\n${calls}`);
console.log('  ok: nothing was removed, on this computer or on GitHub, and GitHub was only read');

// --- signed out ----------------------------------------------------------------------

fs.writeFileSync(state, JSON.stringify({ ...JSON.parse(fs.readFileSync(state, 'utf8')), signed_in: false }));
const out2 = list(['--keep', 'keep-me']);
assert.equal(out2.status, 1);
assert.ok(!/new-report/.test(out2.stdout), 'signed out, the squash-merged branch was still offered');
assert.ok(/git branch -d fix-login/.test(out2.stdout), 'signed out, the branch Git confirms was lost');
console.log('  ok: signed out, only what Git confirms is offered');

// --- nothing to say ------------------------------------------------------------------

const quiet = path.join(work, 'quiet');
git(['clone', '-q', remote, quiet], work);
fs.writeFileSync(state, JSON.stringify({ signed_in: true, default: 'main', open: [], protected: [], rules: {}, merged: {} }));
git(['push', '-q', 'origin', '--delete', 'fix-login', 'release', 'rules-only', 'open-pr', 'in-other-copy', 'keep-me', 'new-report', 'export-fix'], quiet);
git(['fetch', '-q', '--prune'], quiet);
const silent = spawnSync('python3', [script], { cwd: quiet, encoding: 'utf8', env: { ...env, PATH: `${bin}:${process.env.PATH}` } });
assert.equal(silent.status, 0, `nothing to remove should exit 0:\n${silent.stdout}`);
assert.equal(silent.stdout, '', 'nothing to remove should print nothing');
console.log('  ok: with no branch to remove and nothing set aside, it prints nothing and exits 0');

const outside = spawnSync('python3', [script], { cwd: work, encoding: 'utf8' });
assert.equal(outside.status, 2, 'outside a Git project it did not exit 2');
console.log('  ok: outside a project under Git it exits 2');

console.log('\nstale-branches-rehearsal.sh: the right command for each branch, and nothing removed');
NODE
