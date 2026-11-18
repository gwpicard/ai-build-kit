#!/usr/bin/env python3
"""Exercise the maintainer runner without Docker or an agent service."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[3]
RUNNER = ROOT / '.agents/tools/agent-run-queue.py'

DOCKER = r'''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
p = Path(os.environ['FAKE_STATE'])
s = json.loads(p.read_text())
a = sys.argv[1:]
with open(os.environ['FAKE_LOG'], 'a') as log: log.write(' '.join(a) + '\n')
if a == ['info']:
    calls = Path(os.environ['FAKE_LOG']).read_text().splitlines().count('info')
    sys.exit(1 if s.get('down') or (os.environ.get('FAKE_DOWN_FINAL') and calls == 3) else 0)
if s.get('down'): sys.exit(1)
if a[:2] == ['system', 'df']:
    print(json.dumps({'Type':'Images', 'Size':s.get('size', '1 GB')})); sys.exit()
if a[:2] == ['context', 'inspect']:
    if os.environ.get('FAKE_CONTEXT_FAIL'): sys.exit(1)
    print('unix:///tmp/fake-docker.sock'); sys.exit()
if len(a) >= 2 and a[0] in ('container','image','volume','network'):
    kind, action = a[:2]
    if action == 'ls':
        print('\n'.join(k for k,v in s['items'].items() if v['kind'] == kind)); sys.exit()
    if action == 'inspect':
        item = s['items'].get(a[-1]);
        if item is None: sys.exit(1)
        print(json.dumps([item])); sys.exit()
    if action == 'rm':
        item = s['items'][a[-1]]
        assert item['Labels'].get('ai-build-kit.run'), 'unlabelled removal'
        del s['items'][a[-1]]; p.write_text(json.dumps(s)); sys.exit()
sys.exit(1)
'''
AGENT = r'''#!/usr/bin/env python3
import json, os, signal, sys, time
from pathlib import Path
sys.stdin.read()
if os.environ.get('FAKE_HOLD'):
    with open(os.environ['FAKE_STARTED_FILE'], 'a') as marker: marker.write('started\n')
    while True: time.sleep(1)
p = Path(os.environ['FAKE_STATE']); s=json.loads(p.read_text())
for kind in ('container','image','volume','network'):
    for suffix, labels in [('labelled', {'ai-build-kit.run':os.environ['CODEX_RUN_ID'], 'ai-build-kit.scope':os.environ['ABK_DOCKER_SCOPE']}), ('run-only', {'ai-build-kit.run':os.environ['CODEX_RUN_ID']}), ('unlabelled', {})]:
        name=kind+'-'+suffix
        s['items'][name]={'kind':kind, 'Id':name, 'Name':name, 'Labels':labels, 'Config':{'Labels':labels}}
if os.environ.get('FAKE_DOWN_END'): s['down']=True
p.write_text(json.dumps(s))
print('FAKE_STARTED', flush=True)
if os.environ.get('FAKE_WAIT'):
    while True: time.sleep(1)
sys.exit(int(os.environ.get('FAKE_EXIT', '0')))
'''
PS = '''#!/bin/sh
[ "$1" = -axww ] || exit 1
if [ "${FAKE_REAL_PS:-}" = 1 ]; then /bin/ps "$@" | /usr/bin/awk '/agent-run-queue.py/'; exit; fi
printf '%s\\n' "$FAKE_PS"
'''


def main():
    with tempfile.TemporaryDirectory(prefix='abk-runner-test-') as tmp:
        work = Path(tmp)
        for name, data in [('docker', DOCKER), ('agent', AGENT), ('ps', PS)]:
            path = work / name; path.write_text(data); path.chmod(0o755)
        state = work / 'state.json'; log = work / 'docker.log'; brief = work / 'brief.md'
        brief.write_text('test brief')
        env = {**os.environ, 'PATH':str(work)+os.pathsep+os.environ['PATH'], 'FAKE_STATE':str(state),
               'FAKE_LOG':str(log), 'FAKE_PS':'', 'TMPDIR':str(work), 'ABK_AGENT_QUEUE_DIR':str(work)}
        cmd = [sys.executable, str(RUNNER), '--agent', str(work/'agent'), '--poll-seconds', '0.05', '--wait-seconds', '0.1', str(brief), str(work)]
        def init(**values):
            state.write_text(json.dumps({'items':{}, **values})); log.write_text('')
        def run(**values):
            return subprocess.run(cmd, env={**env, **values}, capture_output=True, text=True, timeout=20)
        for code in (0, 7):
            init(); result=run(FAKE_EXIT=str(code)); assert result.returncode == code, (result.stdout, result.stderr)
            data=json.loads(state.read_text())['items']
            assert set(data) == {k+'-unlabelled' for k in ('container','image','volume','network')}, data
            for identity in data: assert identity in result.stdout
            assert 'Started ' in result.stdout
            assert 'prune' not in log.read_text()
        print('ok: passing and failing runs remove scoped resources, report unlabelled resources and never prune')
        init(down=True); result=run(); assert result.returncode and 'nothing removed' in result.stderr
        assert ' rm ' not in log.read_text()
        init(); result=run(FAKE_DOWN_END='1'); assert result.returncode and 'not reachable' in result.stderr
        assert ' rm ' not in log.read_text()
        init(); result=run(FAKE_DOWN_FINAL='1'); assert result.returncode and 'nothing removed' in result.stderr, (result.stdout, result.stderr)
        assert ' rm ' not in log.read_text(), log.read_text()
        assert 'container-labelled' in json.loads(state.read_text())['items']
        print('ok: Docker unreachable at either boundary removes nothing')
        init(size='100 GB'); result=run(); assert result.returncode and '100 GB' in result.stdout and 'above the limit' in result.stderr
        assert 'Started ' not in result.stdout
        print('ok: storage guard reports use and refuses to start')
        init(); result=run(FAKE_CONTEXT_FAIL='1')
        assert result.returncode and 'Started ' not in result.stdout, (result.stdout, result.stderr)
        invalid = work / 'invalid'; invalid.write_text('invalid executable format'); invalid.chmod(0o755)
        init(); bad_cmd = cmd.copy(); bad_cmd[bad_cmd.index(str(work/'agent'))] = str(invalid)
        result = subprocess.run(bad_cmd, env=env, capture_output=True, text=True, timeout=20)
        assert result.returncode and 'Started ' not in result.stdout and 'Could not start agent' in result.stderr, (result.stdout, result.stderr)
        print('ok: executable format failure is not reported as a start')
        manifest=(ROOT / 'release-manifest.txt').read_text()
        assert '.agents/tools/agent-run-queue.py|' not in manifest
        print('ok: proxy failure is not reported as a start; the runner is outside the release')
        init(); proc=subprocess.Popen(cmd, env={**env,'FAKE_WAIT':'1'}, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        deadline=time.monotonic()+10
        while time.monotonic() < deadline:
            if json.loads(state.read_text())['items']: break
            time.sleep(.05)
        else: raise AssertionError('agent did not start')
        proc.send_signal(signal.SIGTERM); out, err=proc.communicate(timeout=20)
        assert proc.returncode != 0, (out,err)
        assert all(x.endswith('unlabelled') for x in json.loads(state.read_text())['items']), (out,err)
        print('ok: interruption removes scoped resources')
        init(); shell="123 1 sh sh -c 'echo codex exec " + ('x'*1000) + "'"
        result=run(FAKE_PS=shell+'\n'+shell.replace('123 1 sh', '124 1 sh', 1)); assert result.returncode == 0, (result.stdout,result.stderr)
        init(); wrapper='123 1 node /usr/local/bin/node /long/path/codex --no-daemon --disable shell_snapshot exec ' + ('x'*1000) + " don't"
        result=run(FAKE_PS=wrapper); assert result.returncode == 0, (result.stdout,result.stderr)
        init(); descendant='124 123 codex /usr/local/bin/codex exec ' + ('x'*1000)
        result=run(FAKE_PS=wrapper+'\n'+descendant); assert result.returncode == 0 and 'Started ' in result.stdout, (result.stdout, result.stderr)
        print('ok: wrapper and descendant count as one agent run')
        init(); second=wrapper.replace('123 1 node','124 1 node',1)
        proc=subprocess.Popen(cmd, env={**env,'FAKE_PS':wrapper+'\n'+second}, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        time.sleep(3); proc.send_signal(signal.SIGTERM); out,err=proc.communicate(timeout=10)
        assert 'Still waiting:' in out and 'Started ' not in out, (out,err)
        print('ok: shell mentions do not count; long wrapper-form agent processes do count and waiting is reported')
        init(); marker=work/'started'; marker.write_text('')
        queue_env={**env, 'FAKE_REAL_PS':'1', 'FAKE_HOLD':'1', 'FAKE_STARTED_FILE':str(marker)}
        procs=[subprocess.Popen(cmd, env=queue_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True) for _ in range(3)]
        try:
            deadline=time.monotonic()+30
            while time.monotonic()<deadline and len(marker.read_text().splitlines()) < 2: time.sleep(.1)
            time.sleep(1)
            assert len(marker.read_text().splitlines()) == 2, marker.read_text()
            print('ok: cooperating queues admit at most two agents')
        finally:
            for process in procs:
                if process.poll() is None: process.send_signal(signal.SIGTERM)
            for process in procs: process.communicate(timeout=30)


if __name__ == '__main__': main()
