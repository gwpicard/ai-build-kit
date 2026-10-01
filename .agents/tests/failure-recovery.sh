#!/usr/bin/env sh
# Run recovery in a disposable project and inspect the work it retained.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 - "$ROOT" <<'PY'
import datetime
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile

root = Path(sys.argv[1])
helper = root / '.agents/skills/implement/scripts/recovery.py'
fixture = Path(tempfile.mkdtemp(prefix='kit-failure-recovery-'))

def run(*args, cwd=None, code=0):
    result = subprocess.run([str(a) for a in args], cwd=cwd, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    assert result.returncode == code, (args, result.returncode, result.stdout, result.stderr)
    return result.stdout.strip()

def git(project, *args):
    return run('git', '-C', project, *args)

def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value))

def load(path):
    return json.loads(path.read_text())

def call(state, command, *args, code=0):
    return run('python3', helper, command, '--state', state, '--piece', 1, *args, code=code)

def project(name, broken_base=False, parent=False, in_worktree=False):
    p = fixture / name
    p.mkdir()
    git(p, 'init', '-q', '-b', 'main')
    git(p, 'config', 'user.name', 'Fixture')
    git(p, 'config', 'user.email', 'fixture@example.invalid')
    (p / '.gitignore').write_text('.agents/runs/\n.agents/worktrees/\nprivate/\n')
    (p / 'shared.txt').write_text('broken' if broken_base else 'works')
    (p / 'dependent.txt').write_text('untouched')
    (p / 'check.py').write_text("from pathlib import Path\nassert Path('shared.txt').read_text() == 'works'\nassert not Path('failed.txt').exists()\n")
    git(p, 'add', '.')
    git(p, 'commit', '-qm', 'Working project')
    if parent:
        (p / 'successful.txt').write_text('earlier successful part')
        git(p, 'add', '.')
        git(p, 'commit', '-qm', 'Successful parent part')
    base = git(p, 'rev-parse', 'HEAD')
    main = p
    if in_worktree:
        p = main / '.agents/worktrees/failed'
        p.parent.mkdir(parents=True)
        git(main, 'worktree', 'add', '-qb', 'failed-piece', str(p), base)
    else:
        git(p, 'switch', '-qc', 'failed-piece')
    (p / 'failed.txt').write_text('failed committed work')
    git(p, 'add', '.')
    git(p, 'commit', '-qm', 'Unsuccessful work')
    failed_head = git(p, 'rev-parse', 'HEAD')
    (p / 'shared.txt').write_text('failed staged work')
    git(p, 'add', 'shared.txt')
    (p / 'shared.txt').write_text('failed unstaged work')
    (p / 'untracked.txt').write_text('new work')
    (p / 'private').mkdir()
    (p / 'private/ignored.txt').write_text('ignored evidence')
    os.symlink('ignored.txt', p / 'private/link')
    state = main / '.agents/runs/test/state.json'
    write(state, {'run':'test', 'merge_preapproved':False, 'pieces':[
        {'number':1,'state':'building','attempts':3,'branch':'failed-piece','worktree':str(p),'start_commit':base},
        {'number':2,'state':'waiting'}, {'number':3,'state':'waiting'},
        {'number':4,'state':'waiting'}, {'number':5,'state':'waiting'}]})
    evidence = state.parent / 'failed-checks.json'
    write(evidence, [{'command':'python3 check.py','exit_code':1}])
    return p, state, base, failed_head, evidence

def preserved(state, head):
    rec = load(state)['pieces'][0]['recovery']
    assert rec['stage'] == 'preserved'
    assert load(state)['pieces'][0]['state'] == 'building'
    assert git(Path(rec['source']), 'rev-parse', rec['retained_ref']) == head
    with tarfile.open(rec['archive']) as archive:
        assert archive.extractfile('failed.txt').read() == b'failed committed work'
        assert archive.extractfile('shared.txt').read() == b'failed unstaged work'
        assert archive.extractfile('untracked.txt').read() == b'new work'
        assert archive.extractfile('private/ignored.txt').read() == b'ignored evidence'
        assert archive.getmember('private/link').linkname == 'ignored.txt'
    assert 'failed staged work' in Path(rec['index_patch']).read_text()
    assert load(Path(rec['evidence']))[0]['exit_code'] == 1
    assert Path(rec['archive']).stat().st_mode & 0o077 == 0
    return rec

def refresh(state, base, direct_blocker=True, impact=True):
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    issues = state.parent / 'current-issues.json'
    write(issues, {'observed_at':now,'issues':[
        {'number':1,'state':'open','labels':['parked'],'blocked_by':[]},
        {'number':2,'state':'open','labels':['ready'],'blocked_by':[1] if direct_blocker else []},
        {'number':3,'state':'open','labels':['ready'],'blocked_by':[]},
        {'number':4,'state':'open','labels':['ready'],'blocked_by':[2]},
        {'number':5,'state':'open','labels':['ready'],'blocked_by':[]}]})
    reach = state.parent / 'current-impact.json'
    write(reach, {'observed_at':now, 'base_commit':base, 'tasks':{
        '2':{'independent':True,'reason':'separate area'},
        '3':{'independent':impact,'reason':'current code and checks read'},
        '4':{'independent':True,'reason':'separate area'},
        '5':{'independent':True,'reason':'other independent area'}}})
    return issues, reach

def eligible(state, task, issues, impact, code=0):
    return run('python3', helper, 'eligible', '--state',state,'--piece',1,
               '--candidate',task,'--issues',issues,'--impact',impact,code=code)

# Interrupt after preservation. Resume cannot claim anything until checks ran.
p, state, base, head, evidence = project('single')
# A current failed head is never accepted in place of the checked task boundary.
call(state, 'preserve', '--source',p,'--base',head,'--evidence',evidence,code=2)
assert 'recovery' not in load(state)['pieces'][0]
call(state, 'preserve', '--source',p,'--base',base,'--evidence',evidence)
rec = preserved(state, head)
issues, impact = refresh(state, base)
eligible(state,3,issues,impact,code=2)
call(state,'preserve','--source',p,'--base',base,'--evidence',evidence)
assert load(state)['pieces'][0]['recovery']['archive'] == rec['archive']
call(state,'baseline','--check','python3 check.py')
rec = load(state)['pieces'][0]['recovery']
assert rec['stage'] == 'checked' and rec['baseline_commit'] == base
assert rec['checks'][0]['exit_code'] == 0
assert load(state)['pieces'][0]['state'] == 'parked'
assert 'unfinished' not in load(state)['pieces'][0]['reason'].lower()
baseline = Path(rec['baseline_worktree'])
assert git(baseline,'rev-parse','HEAD') == base
assert not (baseline/'failed.txt').exists()
assert (p/'failed.txt').exists() and (p/'private/ignored.txt').exists()
issues, impact = refresh(state, base)
eligible(state,2,issues,impact,code=2)
eligible(state,4,issues,impact,code=2)
eligible(state,3,issues,impact)
(baseline/'independent.txt').write_text('completed independent task')
run('python3','check.py',cwd=baseline)
git(baseline,'add','independent.txt')
git(baseline,'commit','-qm','Independent task complete')
assert (baseline/'dependent.txt').read_text() == 'untouched'
assert load(issues)['issues'][1]['labels'] == ['ready']
assert load(state)['pieces'][1]['state'] == 'waiting'
# The ordinary coordinator save marks only the independently built task to check.
data = load(state)
data['pieces'][2]['state'] = 'to check'
write(state,data)
data = load(issues)
data['issues'][2]['labels'] = ['to check']
write(issues,data)
assert load(state)['pieces'][2]['state'] == 'to check'
assert load(issues)['issues'][2]['labels'] == ['to check']
assert load(issues)['issues'][1]['labels'] == ['ready']
assert load(state)['pieces'][0]['state'] == 'parked'
assert git(p,'rev-parse','HEAD') == head
# A changed checkout invalidates a prior green baseline, even for another task.
eligible(state,5,issues,impact,code=2)
advanced = git(baseline,'rev-parse','HEAD')
# A commit alone cannot move the checked base; its successful task must name it.
call(state,'baseline','--base',advanced,'--check','python3 check.py',code=2)
data = load(state)
data['pieces'][2]['checked_commit'] = advanced
write(state,data)
call(state,'baseline','--base',advanced,'--check','python3 check.py')
issues, impact = refresh(state,advanced)
eligible(state,5,issues,impact)
assert (baseline/'independent.txt').read_text() == 'completed independent task'
assert not (baseline/'failed.txt').exists()
assert load(state)['pieces'][1]['state'] == 'waiting'

# Restore pointers from the durable local record even when state lost its field.
data = load(state)
del data['pieces'][0]['recovery']
write(state,data)
call(state,'preserve','--source',p,'--base',base,'--evidence',evidence)
assert load(state)['pieces'][0]['recovery']['failed_commit'] == head

# Earlier successful parts survive; the unsuccessful part never reaches them.
p, state, base, head, evidence = project('parent', parent=True, in_worktree=True)
call(state,'preserve','--source',p,'--base',base,'--evidence',evidence,'--final-state','shaping')
preserved(state,head)
call(state,'baseline','--check','python3 check.py')
rec = load(state)['pieces'][0]['recovery']
baseline = Path(rec['baseline_worktree'])
assert (baseline/'successful.txt').read_text() == 'earlier successful part'
assert not (baseline/'failed.txt').exists()
assert load(state)['pieces'][0]['state'] == 'shaping'
assert git(p,'rev-parse','HEAD') == head
issues, impact = refresh(state,base,impact=False)
eligible(state,3,issues,impact,code=2)
issues, impact = refresh(state,base)
eligible(state,3,issues,impact)
# Stale observations and absent blocker records fail closed.
data = load(issues)
data['observed_at'] = '2000-01-01T00:00:00+00:00'
write(issues,data)
eligible(state,3,issues,impact,code=2)
issues, impact = refresh(state,base)
data = load(issues)
data['issues'][2]['blocked_by'] = [99]
write(issues,data)
eligible(state,3,issues,impact,code=2)
issues, impact = refresh(state,base)
# An ignored edit after checks invalidates the checked copy.
(baseline/'private').mkdir()
(baseline/'private/new.txt').write_text('new ignored input')
eligible(state,3,issues,impact,code=2)
# Preserve the changed copy and verify it again rather than deleting the input.
call(state,'baseline','--check','python3 check.py')
issues, impact = refresh(state,base)
eligible(state,3,issues,impact)
# Retention prevents cleanup even after the run state has become final.
worktrees = root / '.agents/skills/implement/scripts/worktree.sh'
assert 'Kept' in run('sh',worktrees,'remove',baseline,cwd=p,code=1)
assert baseline.exists()
assert 'Kept' in run('sh',worktrees,'remove',p,cwd=p,code=1)
assert p.exists() and (p/'failed.txt').exists()
# A partially checked recovery is still unfinished until the checks rerun.
data = load(state)
data['pieces'][0]['recovery']['stage'] = 'checking'
data['pieces'][0]['state'] = 'building'
write(state,data)
eligible(state,3,issues,impact,code=2)
call(state,'baseline','--check','python3 check.py')
issues, impact = refresh(state,base)
# Re-reading current blockers catches a newly introduced transitive dependency.
data = load(issues)
data['issues'][2]['blocked_by'] = [4]
write(issues,data)
eligible(state,3,issues,impact,code=2)

# A shared-base check failure blocks every candidate relying on this base.
p, state, base, head, evidence = project('shared-failure',broken_base=True)
call(state,'preserve','--source',p,'--base',base,'--evidence',evidence)
call(state,'baseline','--check','python3 check.py',code=2)
rec = load(state)['pieces'][0]['recovery']
assert rec['stage'] == 'blocked' and rec['checks'][0]['exit_code'] != 0
issues,impact = refresh(state,base)
eligible(state,3,issues,impact,code=2)
assert not (Path(rec['baseline_worktree'])/'independent.txt').exists()
assert load(state)['pieces'][1]['state'] == 'waiting'
# No check and a verification gap cannot be presented as passing.
call(state,'baseline',code=2)
call(state,'baseline','--check','true','--gap','Smoke check unavailable',code=2)
assert load(state)['pieces'][0]['recovery']['stage'] == 'blocked'
assert load(state)['pieces'][0]['recovery']['gaps'] == ['Smoke check unavailable']

print('Failure recovery passed: retained files and commits, checked independent work, blocked dependants, successful parent parts, shared failure and interrupted recovery.')
print('Disposable artifacts:', fixture)
PY
