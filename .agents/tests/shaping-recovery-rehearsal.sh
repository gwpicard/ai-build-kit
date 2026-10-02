#!/usr/bin/env sh
# Exercise the written state commands on real Git and disposable fake PRs.
# The operator supplies review verdicts and requirements; no model is called.
# Merge eligibility is an instruction guarded by shaping-recovery.sh, not an
# enforcement feature of the fake GitHub service used here.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 - "$ROOT" <<'PY'
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
shape = (root / '.agents/skills/shape/SKILL.md').read_text()
gh = root / '.agents/tests/replay/fake-github/gh'
refresh = root / '.agents/skills/setup-ai-build-kit/templates/foundation/plan-refresh.sh'
work = Path(tempfile.mkdtemp(prefix='shaping-recovery-'))
project = work / 'project'
env = dict(os.environ, FAKE_GH_STATE=str(work / 'state.json'),
           FAKE_GH_LOG=str(work / 'gh.log'))
(work / 'bin').mkdir()
(work / 'bin/gh').symlink_to(gh)
env['PATH'] = str(work / 'bin') + os.pathsep + env['PATH']

def run(*args, good=True):
    result = subprocess.run(args, cwd=project, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if good:
        assert result.returncode == 0, (args, result.stdout, result.stderr)
    return result

def api(*args):
    return run(str(gh), *args).stdout

def state():
    return json.loads((work / 'state.json').read_text())

def move(pattern, number, old, reason='needs-clarification'):
    # Run the command published in the skill, including its paired removal.
    command = re.search(pattern, shape).group(1)
    command = command.replace('<number>', str(number)).replace('<old state>',
               shlex.quote(old)).replace('<its needs- label>', reason)
    words = shlex.split(command)
    run(str(gh), *words[1:])

full = r'`(gh issue edit <number> --add-label shaping --add-label needs-clarification --remove-label <old state>)`'
gap = r'`(gh issue edit <number> --add-label shaping --add-label <its needs- label> --remove-label <old state>)`'

project.mkdir()
run('git', 'init', '-q', '-b', 'main')
run('git', 'config', 'user.name', 'Rehearsal')
run('git', 'config', 'user.email', 'rehearsal@example.com')
(project / 'header.txt').write_text('Notes\n')
run('git', 'add', 'header.txt')
run('git', 'commit', '-qm', 'Start notes')
run('git', 'init', '-q', '--bare', str(work / 'remote.git'))
run('git', 'remote', 'add', 'origin', str(work / 'remote.git'))
run('git', 'push', '-q', 'origin', 'main')
run('git', 'checkout', '-qb', 'notes')
(project / 'header.txt').write_text('Team notes\n')
run('git', 'add', 'header.txt')
run('git', 'commit', '-qm', 'Write team header')
run('git', 'push', '-q', 'origin', 'notes')
head = run('git', 'rev-parse', 'HEAD').stdout.strip()
api('issue', 'create', '--title', 'Team header', '--body', 'Make notes clearer',
    '--label', 'to check')
api('pr', 'create', '--base', 'main', '--head', 'notes', '--title', 'Team header',
    '--body', 'Existing work for the team header')
original_pr = api('pr', 'view', '1', '--json', 'state,headRefName,body,url')
original_bytes = (project / 'header.txt').read_bytes()

def preserved():
    assert run('git', 'rev-parse', 'notes').stdout.strip() == head
    assert run('git', 'rev-parse', 'refs/remotes/origin/notes').stdout.strip() == head
    assert (project / 'header.txt').read_bytes() == original_bytes
    assert api('pr', 'view', '1', '--json', 'state,headRefName,body,url') == original_pr

def labels(number):
    return next(i['labels'] for i in state()['issues'] if i['number'] == number)

run('sh', str(refresh))
assert 'never shaped' in (project / 'plan.local.md').read_text()
assert labels(1) == ['to check']
preserved()
print('ok: actual printout detects missing Done when and changes no state or work')

move(full, 1, 'to check')
assert labels(1) == ['shaping', 'needs-clarification']
preserved()
print('ok: full recovery command returns to shaping and keeps branch, head and open PR')

# Old verification really passes; agreed acceptance really fails on that head.
assert 'notes' in (project / 'header.txt').read_text().lower()
requirements = '## Done when\nThe header reads Shared notes.\n'
review = '\n## Readiness\n2026-10-02, checked by a session that did not shape it: Ready\n'
record = ('\n## Shaping recovery\nPreserved branch: notes; pull request: ' +
          api('pr', 'view', '1', '--json', 'url').strip() + '\nHead: ' + head +
          '\nMerge waits for verification against agreed requirements.\n')
body = work / 'body.md'
body.write_text(requirements + review + record)
api('issue', 'edit', '1', '--body-file', str(body))
ready = re.search(r'`(gh issue edit <number> --add-label ready --remove-label shaping --remove-label <its needs- label>)`', shape).group(1)
run(str(gh), *shlex.split(ready.replace('<number>', '1').replace('<its needs- label>', 'needs-clarification'))[1:])
assert labels(1) == ['ready']
acceptance = run(sys.executable, '-c', "from pathlib import Path; assert Path('header.txt').read_text().strip() == 'Shared notes'", good=False)
assert acceptance.returncode != 0
body.write_text(body.read_text() + '\nVerification: FAIL, agreed header acceptance at ' + head +
                '; earlier notes check passed against incomplete requirements. Merge still waits.\n')
api('issue', 'edit', '1', '--body-file', str(body))
api('pr', 'edit', '1', '--body-file', str(body))
saved = api('issue', 'view', '1', '--json', 'body')
assert 'Verification: FAIL' in saved and head in saved
assert 'Merge still waits' in api('pr', 'view', '1', '--json', 'body')
# The recovery record changes the PR body, so compare identity and OPEN state.
pr = json.loads(api('pr', 'view', '1', '--json', 'state,headRefName'))
assert pr['state'] == 'OPEN' and pr['headRefName'] == 'notes'
assert run('git', 'rev-parse', 'notes').stdout.strip() == head
print('ok: readiness completion reaches ready; new acceptance fails preserved work and records why merge waits')

api('issue', 'create', '--title', 'Complete requirements', '--body', requirements,
    '--label', 'building')
api('issue', 'create', '--title', 'Review finds a gap', '--body', requirements,
    '--label', 'to check')
run('sh', str(refresh))
assert 'Readiness' in (project / 'plan.local.md').read_text()
body.write_text(requirements + review)
api('issue', 'edit', '2', '--body-file', str(body))
assert labels(2) == ['building']
print('ok: readiness-only success retains building without interview or label move')
body.write_text(requirements + '\n## Readiness\n2026-10-02, checked by a session that did not shape it: Not ready\n- BLOCKING: empty header behaviour is undecided\n')
api('issue', 'edit', '3', '--body-file', str(body))
move(gap, 3, 'to check')
assert labels(3) == ['shaping', 'needs-clarification']
print('ok: readiness gap command removes to check and returns to shaping with its reason')
assert json.loads(api('pr', 'view', '1', '--json', 'state'))['state'] == 'OPEN'
assert run('git', 'rev-parse', 'notes').stdout.strip() == head
print('All disposable Git/state checks passed; conversation and merge-gate obedience remain guided checks.')
print('Fixture retained at ' + str(work))
PY
