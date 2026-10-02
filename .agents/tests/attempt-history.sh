#!/usr/bin/env sh
# Exercise attempt publication and recovery reads using a local GitHub stand-in.
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
helper = root / '.agents/skills/implement/scripts/attempt-history.py'
fixture = Path(tempfile.mkdtemp(prefix='kit-attempt-history-'))
project = fixture / 'project'
project.mkdir()
subprocess.run(['git','init','-q',str(project)],check=True)
bin_dir = fixture / 'bin'
bin_dir.mkdir()
remote = fixture / 'issue.json'
url = 'https://github.com/example/project/issues/12'
original = '## Done when\nThe promised result.\n\n<details><summary>Original report</summary>\nUnchanged words.\n</details>\n'
remote.write_text(json.dumps({'url':url,'body':original,'reads':0,'writes':0}))
fake = bin_dir / 'gh'
fake.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
p = Path(os.environ['ATTEMPT_REMOTE'])
d = json.loads(p.read_text())
a = sys.argv[1:]
assert a[0] == 'issue' and a[2] == d['url'], a
if a[1] == 'view':
    assert a[3:] == ['--json','body,url'], a
    d['reads'] += 1
    if d.get('addition') and d['reads'] == d.get('add_on_read'):
        d['body'] = d['body'].replace('<!-- /attempt-history -->', d['addition'] + '\\n<!-- /attempt-history -->')
    p.write_text(json.dumps(d))
    if d.get('read_fail'): sys.exit(1)
    print(json.dumps({'body':d['body'],'url':d['url']}))
elif a[1] == 'edit':
    assert a[3:] == ['--body-file','-'], a
    body = sys.stdin.read()
    d['writes'] += 1
    if not d.get('fail'):
        d['body'] = body if not d.get('mismatch') else body.replace('Try cache', 'Different cache')
    p.write_text(json.dumps(d))
    if d.get('fail') or d.get('ambiguous'): sys.exit(1)
else: raise AssertionError(a)
''')
fake.chmod(0o755)
env = dict(os.environ, PATH=str(bin_dir) + os.pathsep + os.environ['PATH'], ATTEMPT_REMOTE=str(remote))
state = project / '.agents/runs/test/state.json'
state.parent.mkdir(parents=True)
state.write_text(json.dumps({'run':'test','pieces':[{'number':12,'state':'building','attempts':3}]}))

def load(p=remote): return json.loads(p.read_text())
def change(**values):
    d = load()
    d.update(values)
    remote.write_text(json.dumps(d))
def call(command, *args, code=0, use_state=True):
    argv = ['python3',str(helper),command,'--project',str(project),'--issue',url]
    if use_state: argv += ['--state',str(state)]
    result = subprocess.run(argv + list(args),capture_output=True,text=True,env=env)
    assert result.returncode == code, (argv,result.returncode,result.stdout,result.stderr)
    return result.stdout
def stage(number, approach):
    work = project / 'kept' / str(number)
    work.mkdir(parents=True)
    (work / 'failed.txt').write_text(approach)
    record = fixture / ('record-' + str(number) + '.json')
    record.write_text(json.dumps({'id':'test-' + str(number),'approach':approach,
        'result':'Still fails the focused check','branch':'failed-' + str(number),'location':str(work)}))
    call('stage','--record',str(record),'--reviewed')
    return work

assert helper.exists(), 'The shipped attempt-history helper is missing.'
# A staged summary survives an interruption before the first issue write.
locations = [stage(1,'Try cache')]
assert load()['writes'] == 0
assert load(state)['pieces'][0]['attempt_history']['pending']
assert 'Pending' in call('read') and 'Try cache' in call('read')
# A failed issue write remains pending; retry reuses the same attempt identity.
change(fail=True)
call('publish',code=2)
assert load()['body'] == original
assert load(state)['pieces'][0]['attempt_history']['pending']
change(fail=False)
call('publish')
assert load()['body'].count('Try cache') == 1
assert not load(state)['pieces'][0]['attempt_history']['pending']
locations += [stage(2,'Try polling'),stage(3,'Try ordered updates')]
call('publish')
body = load()['body']
assert body.startswith(original)
for n, approach in enumerate(['Try cache','Try polling','Try ordered updates'],1):
    assert body.count(approach) == 1
    assert 'failed-' + str(n) in body and str(locations[n-1]) in body
assert body.index('Try cache') < body.index('Try polling') < body.index('Try ordered updates')
assert all((path / 'failed.txt').exists() for path in locations)
# Both a later run and /fix read live history even without the old run state.
for consumer in ('later run','fix'):
    history = call('read',use_state=False)
    assert all(approach in history for approach in ['Try cache','Try polling','Try ordered updates']), consumer
    assert not load(state)['pieces'][0]['attempt_history'].get('approaches')
assert load(state)['pieces'][0]['attempt_history']['issue'] == url + '#attempt-history'
# An observed concurrent addition before writing survives the fresh-read merge.
stage(4,'Try isolated writes')
other = '- Other run tried a queue; still failed; kept elsewhere. <!-- attempt:other-1 -->'
change(addition=other,add_on_read=load()['reads'] + 2)
call('publish')
assert other in load()['body'] and 'Try isolated writes' in load()['body']
# A write that succeeded but returned failure is uncertain until a retry reads it.
stage(5,'Try bounded waits')
change(ambiguous=True)
call('publish',code=2)
assert load(state)['pieces'][0]['attempt_history']['pending']
change(ambiguous=False)
call('publish')
assert load()['body'].count('Try bounded waits') == 1
# A read-back mismatch never clears pending, and the retry does not erase it.
stage(6,'Try cache invalidation')
change(mismatch=True)
call('publish',code=2)
assert load(state)['pieces'][0]['attempt_history']['pending']
assert 'Pending' in call('read')
change(mismatch=False)
call('publish',code=2)  # The same identity now has contradictory text.
# Pending files outlive removal of the run state and remain readable when offline.
state.unlink()
change(read_fail=True)
out = call('read',code=2,use_state=False)
assert 'Pending' in out and 'Try cache invalidation' in out
print('Attempt history: three failed approaches, ordered reads, pending writes and retries passed.')
PY
