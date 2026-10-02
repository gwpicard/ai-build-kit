#!/usr/bin/env sh
# Inspect real disposable refs at the run's integration and final-review boundary.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 - "$ROOT" <<'PY'
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
helper = root / '.agents/skills/implement/scripts/integration.py'
fixture = Path(tempfile.mkdtemp(prefix='kit-integration-'))
project = fixture / 'project'
remote = fixture / 'remote.git'
bin_dir = fixture / 'bin'
bin_dir.mkdir()
os.environ['PATH'] = str(bin_dir) + os.pathsep + os.environ['PATH']
os.environ['INTEGRATION_FIXTURE'] = str(fixture)

def run(*args, cwd=project, code=0):
    p = subprocess.run([str(a) for a in args], cwd=cwd, text=True, capture_output=True)
    assert p.returncode == code, (args, p.returncode, p.stdout, p.stderr)
    return p.stdout.strip()

def git(*args, cwd=project):
    return run('git', *args, cwd=cwd)

def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data))

def read(path):
    return json.loads(path.read_text())

project.mkdir()
git('init', '-qb', 'main')
git('config', 'user.name', 'Fixture')
git('config', 'user.email', 'fixture@example.invalid')
(project / '.gitignore').write_text('.agents/\n')
(project / 'check.py').write_text("from pathlib import Path\nassert not (Path('a').exists() and Path('bad').exists())\nassert not Path('shared-failure').exists()\n")
git('add', '.')
git('commit', '-qm', 'Checked start')
start = git('rev-parse', 'HEAD')
git('init', '-q', '--bare', remote, cwd=fixture)
git('remote', 'add', 'origin', remote)
git('push', '-q', 'origin', 'main')
state = project / '.agents/runs/test/state.json'
write(state, {'run':'test', 'merge_preapproved':True, 'pieces':[
    {'number':n, 'state':'to check', 'flags':['Phone layout still needs your review'] if n == 1 else []}
    for n in range(1, 6)]})
integration = project / '.agents/worktrees/integration'
git('worktree', 'add', '-qb', 'integration/test', integration, start)
git('push', '-q', 'origin', 'integration/test', cwd=integration)
write(fixture / 'prs.json', {})

# Only these modelled commands are allowed; every merge records its real target.
(bin_dir / 'gh').write_text('''#!/usr/bin/env python3
import json, os, pathlib, subprocess, sys, tempfile
f=pathlib.Path(os.environ['INTEGRATION_FIXTURE']); a=sys.argv[1:]
p=f/'prs.json'; prs=json.loads(p.read_text()); pr=prs[a[2]]
def git(*args):
 r=subprocess.run(['git',*args],capture_output=True,text=True)
 if r.returncode: sys.exit(r.returncode)
 return r.stdout.strip()
remote=str(f/'remote.git')
head=git('--git-dir',remote,'rev-parse',pr['headRefName'])
if a[:2]==['pr','view']:
 pr['headRefOid']=head; print(json.dumps(pr))
elif a[:2]==['pr','checks']:
 print(json.dumps([{'name':'project-check','state':'SUCCESS'}]))
elif a[:2]==['pr','merge']:
 assert a[3:]==['--merge','--match-head-commit',head]
 folder=tempfile.mkdtemp(prefix='fake-merge-',dir=f)
 git('--git-dir',remote,'worktree','add','--detach',folder,pr['baseRefName'])
 git('-C',folder,'-c','user.name=Fixture','-c','user.email=fixture@example.invalid','merge','--no-ff','--no-edit',head)
 new=git('-C',folder,'rev-parse','HEAD')
 git('--git-dir',remote,'update-ref','refs/heads/'+pr['baseRefName'],new)
 pr['state']='MERGED'; prs[a[2]]=pr; p.write_text(json.dumps(prs))
 with (f/'merges.log').open('a') as s: s.write(pr['baseRefName']+'\\n')
else: sys.exit(9)
''')
(bin_dir / 'gh').chmod(0o755)

def call(command, *args, code=0):
    return run('python3', helper, command, '--state', state, *args, code=code)

def pr(number, head, base='integration/test'):
    prs=read(fixture / 'prs.json')
    prs[str(number)]={'number':number,'headRefName':head,'baseRefName':base,'state':'OPEN'}
    write(fixture / 'prs.json', prs)

def feature(number, name):
    path=project / ('.agents/worktrees/feature-' + str(number))
    git('fetch', '-q', 'origin')
    git('worktree','add','-qb','feature-'+str(number),path,'origin/integration/test')
    (path / name).write_text(name)
    git('add', '.', cwd=path); git('commit','-qm','Feature '+name,cwd=path)
    git('push','-q','origin','HEAD',cwd=path)
    pr(number,'feature-'+str(number))
    return path

call('init', '--source', integration, '--check', 'python3 check.py')
for number, name in ((1,'a'),(2,'b')):
    path=feature(number,name)
    call('check','--piece',number,'--source',path,'--check','python3 check.py')
    call('merge-feature','--piece',number,'--source',path,'--pr',number)
assert git('--git-dir',remote,'rev-parse','main') == start
assert read(state)['integration']['included'] == [1,2]
assert read(state)['pieces'][0]['flags'] == ['Phone layout still needs your review']
assert (fixture / 'merges.log').read_text().splitlines() == ['integration/test']*2

# A combined failure stays on its feature branch and goes through existing recovery.
bad=feature(3,'bad')
call('check','--piece',3,'--source',bad,'--check','python3 check.py',code=2)
call('merge-feature','--piece',3,'--source',bad,'--pr',3,code=2)
bad_head=git('rev-parse','HEAD',cwd=bad)
baseline=read(state)['integration']['checked_commit']
evidence=state.parent / 'failed-checks.json'
write(evidence,[{'command':'python3 check.py','exit_code':1}])
recovery=root / '.agents/skills/implement/scripts/recovery.py'
def recover(command,*args,code=0):
    return run('python3',recovery,command,'--state',state,'--piece',3,*args,code=code)
recover('preserve','--source',bad,'--base',baseline,'--evidence',evidence)
recover('baseline','--check','python3 check.py')
import datetime
observed=datetime.datetime.now(datetime.timezone.utc).isoformat()
issues=state.parent/'issues.json'; impact=state.parent/'impact.json'
write(issues,{'observed_at':observed,'issues':[
    {'number':n,'state':'open','labels':['ready'],'blocked_by':[3] if n==4 else []} for n in range(1,6)]})
write(impact,{'observed_at':observed,'base_commit':baseline,'tasks':{
    '4':{'independent':True,'reason':'separate files'},'5':{'independent':True,'reason':'separate code and checks'}}})
recover('eligible','--candidate',4,'--issues',issues,'--impact',impact,code=2)
recover('eligible','--candidate',5,'--issues',issues,'--impact',impact)
path=feature(5,'independent')
call('check','--piece',5,'--source',path,'--check','python3 check.py')
call('merge-feature','--piece',5,'--source',path,'--pr',5)
assert git('rev-parse','HEAD',cwd=bad)==bad_head
assert read(state)['integration']['included']==[1,2,5]

# Resume reconstructs a merge whose GitHub write landed before the local record.
saved=read(state); saved['integration']['included'].remove(5)
saved['integration']['pending']={'piece':5,'pr':5,'head':git('rev-parse','HEAD',cwd=path),'base':baseline}
write(state,saved)
call('reconcile','--source',integration,'--check','python3 check.py')
assert read(state)['integration']['included']==[1,2,5]
call('reconcile','--source',integration,'--check','python3 check.py')
assert read(state)['integration']['included']==[1,2,5]

# Final-main permission needs human review and a separate result-bound yes.
pr(10,'integration/test','main')
call('final','--pr',10)
call('merge-final','--pr',10,code=2)
call('check','--source',integration,'--check','python3 check.py')
record=state.parent/'human.json'
write(record,{'pr':10,'head':git('rev-parse','HEAD',cwd=integration),'base':start,
              'reviewed':True,'review_words':'I reviewed the combined result and the phone flag',
              'yes_words':''})
call('review','--record',record)
call('merge-final','--pr',10,'--record',record,code=2)
human=read(record); human['yes_words']='Yes, merge the combined pull request'; write(record,human)

# Shared verification failure invalidates old green and old review.
(integration/'shared-failure').write_text('failed shared base')
git('add','.',cwd=integration); git('commit','-qm','Shared failure',cwd=integration)
git('push','-q','origin','HEAD',cwd=integration)
call('check','--source',integration,'--check','python3 check.py',code=2)
assert read(state)['integration']['verification']['passed'] is False
call('merge-final','--pr',10,'--record',record,code=2)
assert git('--git-dir',remote,'rev-parse','main')==start
print('Integration run: passing pieces, real targets, retained combined failure, independent continuation, dependent refusal, resume, flags and final consent held.')
print('Fixture retained at',fixture)
PY
