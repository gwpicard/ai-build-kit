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
(project / '.gitignore').write_text('.agents/\nbuild/\n')
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
    for n in range(1, 7)]})
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
    saved=read(state)
    next(p for p in saved['pieces'] if p['number']==number)['start_commit']=git('rev-parse','HEAD',cwd=path)
    write(state,saved)
    (path / name).write_text(name)
    (path / 'changes').mkdir(exist_ok=True)
    (path / ('changes/'+str(number)+'.md')).write_text('Feature '+name+'\n')
    git('add', '.', cwd=path); git('commit','-qm','Feature '+name,cwd=path)
    git('push','-q','origin','HEAD',cwd=path)
    pr(number,'feature-'+str(number))
    return path

call('init', '--source', integration, '--check', 'python3 check.py && mkdir -p build && printf generated > build/output')
mode = os.environ.get('INTEGRATION_CASE')
if mode == 'shared':
    path = feature(1, 'a')
    saved = read(state)
    saved['pieces'][1]['start_commit'] = start
    saved['pieces'][1]['flags'] = ['Sibling needs human review']
    saved['pieces'][2]['state'] = 'parked'
    write(state, saved)
    (path/'b').write_text('b')
    git('add', '.', cwd=path); git('commit', '-qm', 'Second completed parent part', cwd=path)
    git('push', '-q', 'origin', 'HEAD', cwd=path)
    for number in (1,2):
        call('check', '--piece', number, '--source', path, '--check', 'test -f '+('a' if number==1 else 'b'))
    # Unsuccessful membership is refused before any remote write.
    call('merge-feature', '--piece', 1, '--include-piece', 2, '--include-piece', 3,
         '--source', path, '--pr', 1, code=2)
    assert not (fixture/'merges.log').exists()
    # Interrupt immediately after the remote write; pending must contain both parts.
    gh_path = bin_dir/'gh'
    gh_path.write_text(gh_path.read_text().replace("pr['state']='MERGED'", "pr['state']='MERGED'"))
    original = gh_path.read_text()
    gh_path.write_text(original.replace("else: sys.exit(9)",
        " if (f/'interrupt').exists(): sys.exit(7)\nelse: sys.exit(9)"))
    (fixture/'interrupt').touch()
    call('merge-feature', '--piece', 1, '--include-piece', 2, '--source', path, '--pr', 1, code=2)
    pending = read(state)['integration']['pending']
    assert pending['pieces'] == [1,2]
    assert read(state)['integration']['included'] == []
    (fixture/'interrupt').unlink()
    call('reconcile', '--source', integration, '--check', 'python3 check.py')
    call('reconcile', '--source', integration, '--check', 'python3 check.py')
    saved = read(state)
    assert saved['integration']['included'] == [1,2]
    assert [p['state'] for p in saved['pieces'][:3]] == ['merged','merged','parked']
    assert all(p['verification']['passed'] for p in saved['pieces'][:2])
    assert (fixture/'merges.log').read_text().splitlines() == ['integration/test']
    pr(10, 'integration/test', 'main'); call('final', '--pr', 10)
    record = state.parent/'human.json'
    human = {'pr':10,'head':git('rev-parse','HEAD',cwd=integration),'base':start,
             'reviewed':True,'review_words':'Reviewed both parts and flags',
             'merge_approved':True,'yes_words':'Yes, merge this result'}
    write(record, human); call('review', '--record', record)
    saved['pieces'][1]['flags'].append('New sibling observation'); write(state,saved)
    call('merge-final', '--pr', 10, '--record', record, code=2)
    assert git('--git-dir',remote,'rev-parse','main') == start
    call('check', '--source', integration, '--check', 'python3 check.py')
    call('review', '--record', record); call('merge-final', '--pr', 10, '--record', record)
    assert read(state)['integration']['included'] == [1,2]
    print('Shared parent: atomic membership, individual evidence, interruption, failed exclusion and sibling flags held.')
    print('Fixture retained at',fixture)
    sys.exit(0)
if mode == 'moving':
    bad = feature(3,'bad')
    call('check','--piece',3,'--source',bad,'--check','python3 check.py')
    original_start = read(state)['pieces'][2]['start_commit']
    path = feature(1,'a')
    call('check','--piece',1,'--source',path,'--check','python3 check.py')
    call('merge-feature','--piece',1,'--source',path,'--pr',1)
    baseline = read(state)['integration']['checked_commit']
    assert baseline != original_start
    update = root/'.agents/skills/section-builder/scripts/bring-up-to-date.sh'
    run('sh',update,'--base','integration/test',bad)
    head = git('rev-parse','HEAD',cwd=bad)
    before = {p.relative_to(bad).as_posix():p.read_bytes() for p in bad.rglob('*') if p.is_file() and p.name!='.git'}
    call('check','--piece',3,'--source',bad,'--check','python3 check.py',code=2)
    saved = read(state); piece = saved['pieces'][2]
    assert piece['start_commit'] == original_start
    assert piece['integration_candidate']['base'] == baseline
    evidence = Path(piece['verification']['evidence'])
    recovery = root/'.agents/skills/implement/scripts/recovery.py'
    def recover(command,*args,code=0):
        return run('python3',recovery,command,'--state',state,'--piece',3,*args,code=code)
    # An arbitrary ancestor cannot replace the recorded candidate boundary.
    recover('preserve','--source',bad,'--base',head,'--evidence',evidence,code=2)
    recover('preserve','--source',bad,'--base',baseline,'--evidence',evidence)
    recover('baseline','--check','python3 check.py')
    rec = read(state)['pieces'][2]['recovery']
    assert rec['requested_base'] == baseline
    assert rec['original_start_commit'] == original_start
    assert git('rev-parse',rec['retained_ref'],cwd=bad) == head
    assert before == {p.relative_to(bad).as_posix():p.read_bytes() for p in bad.rglob('*') if p.is_file() and p.name!='.git'}
    assert git('rev-parse','HEAD',cwd=bad) == head
    import datetime
    observed = datetime.datetime.now(datetime.timezone.utc).isoformat()
    issues = state.parent/'issues.json'; impact = state.parent/'impact.json'
    write(issues, {'observed_at':observed,'issues':[
        {'number':n,'state':'open','labels':['ready'],'blocked_by':[3] if n==4 else []} for n in range(1,6)]})
    write(impact, {'observed_at':observed,'base_commit':baseline,'tasks':{
        '4':{'independent':True,'reason':'separate files'},'5':{'independent':True,'reason':'separate files'}}})
    recover('eligible','--candidate',4,'--issues',issues,'--impact',impact,code=2)
    recover('eligible','--candidate',5,'--issues',issues,'--impact',impact)
    independent = feature(5,'independent')
    call('check','--piece',5,'--source',independent,'--check','python3 check.py')
    call('merge-feature','--piece',5,'--source',independent,'--pr',5)
    assert read(state)['integration']['included'] == [1,5]
    print('Moving target: earlier start, combined failure, original boundary, retained bytes/history and checked independent continuation held.')
    print('Fixture retained at',fixture)
    sys.exit(0)
for number, name in ((1,'a'),(2,'b')):
    path=feature(number,name)
    update=root / '.agents/skills/section-builder/scripts/bring-up-to-date.sh'
    run('sh',update,'--base','integration/test',path)
    assert (path / ('changes/'+str(number)+'.md')).exists()
    call('check','--piece',number,'--source',path,'--check','python3 check.py')
    pr(number,'feature-'+str(number),'main')
    call('merge-feature','--piece',number,'--source',path,'--pr',number,code=2)
    pr(number,'feature-'+str(number))
    call('merge-feature','--piece',number,'--source',path,'--pr',number)
assert git('--git-dir',remote,'rev-parse','main') == start
assert read(state)['integration']['included'] == [1,2]
assert read(state)['pieces'][0]['flags'] == ['Phone layout still needs your review']
assert (fixture / 'merges.log').read_text().splitlines() == ['integration/test']*2

# A combined failure stays on its feature branch and goes through existing recovery.
bad=feature(3,'bad')
# The feature's own acceptance passes; the combined baseline check detects it.
run('python3','-c',"from pathlib import Path; assert Path('bad').read_text() == 'bad'",cwd=bad)
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
human=read(record); human['yes_words']='No, leave it open'; human['merge_approved']=False; write(record,human)
call('merge-final','--pr',10,'--record',record,code=2)
human['yes_words']='Yes, merge the combined pull request'; human['merge_approved']=True; write(record,human)

# Shared verification failure invalidates old green and old review.
call('check','--source',integration,'--check','false',code=2)
next_piece=feature(6,'next')
call('check','--piece',6,'--source',next_piece,'--check','test -f next')
call('merge-feature','--piece',6,'--source',next_piece,'--pr',6,code=2)
assert 6 not in read(state)['integration']['included']
(integration/'shared-failure').write_text('failed shared base')
git('add','.',cwd=integration); git('commit','-qm','Shared failure',cwd=integration)
git('push','-q','origin','HEAD',cwd=integration)
call('check','--source',integration,'--check','python3 check.py',code=2)
assert read(state)['integration']['verification']['passed'] is False
call('merge-feature','--piece',6,'--source',next_piece,'--pr',6,code=2)
assert 6 not in read(state)['integration']['included']
call('merge-final','--pr',10,'--record',record,code=2)
assert git('--git-dir',remote,'rev-parse','main')==start

# A new verified result needs new review, and then the separate yes permits it.
git('revert','--no-edit','HEAD',cwd=integration)
git('push','-q','origin','HEAD',cwd=integration)
call('check','--source',integration,'--check','python3 check.py')
call('merge-final','--pr',10,'--record',record,code=2)
human['head']=git('rev-parse','HEAD',cwd=integration)
human['yes_words']=''; write(record,human)
call('review','--record',record)
changed=read(state)
changed['pieces'][0]['flags'].append('Another human observation remains owed')
write(state,changed)
human['yes_words']='Yes, merge the combined pull request'; write(record,human)
call('merge-final','--pr',10,'--record',record,code=2)
changed['pieces'][0]['flags'].pop(); write(state,changed)
call('merge-final','--pr',10,'--record',record)
assert read(state)['integration']['final_merged'] is True
assert git('--git-dir',remote,'rev-parse','main') != start
assert (fixture/'merges.log').read_text().splitlines()==['integration/test']*3+['main']
assert read(state)['pieces'][0]['flags']==['Phone layout still needs your review']
saved=read(state); saved['integration'].pop('final_merged'); write(state,saved)
call('reconcile','--source',integration)
assert read(state)['integration']['final_merged'] is True
assert (fixture/'merges.log').read_text().splitlines()==['integration/test']*3+['main']
print('Integration run: passing pieces, real targets, retained combined failure, independent continuation, dependent refusal, resume, flags and final consent held.')
print('Fixture retained at',fixture)
PY

if [ -z "${INTEGRATION_CASE:-}" ]; then
  INTEGRATION_CASE=shared sh "$0"
  INTEGRATION_CASE=moving sh "$0"
fi
