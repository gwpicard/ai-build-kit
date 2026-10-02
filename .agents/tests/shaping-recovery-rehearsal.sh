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

# Reuse the same Git, issue service and printout for a later run's answers.
# Classifications and review verdicts are supplied by the operator, not inferred
# by this shell test. Execute the published transitions and inspect their saves.
longer = (root / '.agents/skills/implement/references/running-longer.md').read_text()
wait_move = re.search(r'`(gh issue edit <number> --add-label shaping --add-label <its needs- label> --remove-label <old state> --remove-assignee @me)`', longer)
assert wait_move, 'runner needs a classified same-issue waiting transition'
spec = ('## So that\nThe team sees a settled header.\n\n' + requirements +
        'Empty notes are shown.\n' +
        '\n## Decided\nUse Shared notes.\n\nTouches: header\n')
waiting = ('\n## Waiting on you\nQuestion: Which header?\n'
           'First recorded: 2026-09-30T08:00:00Z\n'
           'Evidence: Both names were requested.\n'
           'Action: Reply here or edit this issue.\n'
           'Result needed: Choose the header and whether empty notes are shown.\n')

def issue(number):
    return next(i for i in state()['issues'] if i['number'] == number)

def save(number, text):
    body.write_text(text)
    api('issue', 'edit', str(number), '--body-file', str(body))
    assert json.loads(api('issue', 'view', str(number), '--json', 'body'))['body'] == text

def printed():
    before = state()
    run('sh', str(refresh))
    assert state() == before, 'printout must remain read-only'
    return (project / 'plan.local.md').read_text()

def group(text, heading):
    match = re.search(r'^' + re.escape(heading) + r'\n(.*?)(?=^\S|\Z)', text, re.M | re.S)
    return match.group(1) if match else ''

def waiting_move(number, reason):
    command = wait_move.group(1).replace('<number>', str(number)).replace(
        '<its needs- label>', reason).replace('<old state>', 'ready')
    run(str(gh), *shlex.split(command)[1:])
    assert labels(number) == ['shaping', reason]

api('issue', 'create', '--title', 'Independent header', '--body', spec + review, '--label', 'ready')
independent = state()['issues'][-1]['number']
for mode in ('comment', 'body edit', 'prototype', 'incomplete', 'unrelated', 'ambiguous',
             'empty form', 'review fails', 'review unavailable', 'fact', 'human choice',
             'insufficient evidence'):
    api('issue', 'create', '--title', 'Waiting header ' + mode,
        '--body', spec + review, '--label', 'ready')
    n = state()['issues'][-1]['number']
    api('issue', 'create', '--title', 'Dependent ' + mode, '--body', spec + review, '--label', 'ready')
    dependent = state()['issues'][-1]['number']
    api('api', '-X', 'POST', 'repos/rehearsal/project/issues/' + str(dependent) +
        '/dependencies/blocked_by', '-F', 'issue_id=' + str(n))
    api('issue', 'create', '--title', 'Transitive dependent ' + mode, '--body', spec + review, '--label', 'ready')
    transitive = state()['issues'][-1]['number']
    api('api', '-X', 'POST', 'repos/rehearsal/project/issues/' + str(transitive) +
        '/dependencies/blocked_by', '-F', 'issue_id=' + str(dependent))
    reason = 'needs-research' if mode in ('fact', 'human choice', 'insufficient evidence') else 'needs-clarification'
    if mode == 'prototype':
        reason = 'needs-prototype'
    followup = waiting
    if reason == 'needs-research':
        followup = ('\n## Research gap\nQuestion: What does the current header contain?\n'
                    'Evidence: Read header.txt and record its contents.\n')
    # No old Ready survives a newly uncovered gap. One authoritative section.
    save(n, spec + followup)
    waiting_move(n, reason)
    plan = printed()
    assert issue(n)['title'] not in group(plan, 'To build')
    assert issue(dependent)['title'] not in group(plan, 'To build')
    assert issue(transitive)['title'] not in group(plan, 'To build')
    assert issue(independent)['title'] in group(plan, 'To build')
    assert not issue(n).get('comments', []), 'no claim before answers or readiness'
    original = issue(n)['body']
    if mode in ('incomplete', 'unrelated', 'ambiguous', 'empty form'):
        reply = {'incomplete': 'Shared notes.', 'unrelated': 'Change the footer.',
                 'ambiguous': 'Either one.', 'empty form': 'No option selected.'}[mode]
        api('issue', 'comment', str(n), '--body', reply)
        printed()
        assert issue(n)['body'] == original and labels(n) == ['shaping', reason]
        assert not any('Claimed by run' in str(c) for c in issue(n).get('comments', []))
        continue
    if mode == 'insufficient evidence':
        save(n, original + '\nResearch: source could not establish empty notes behaviour.\n')
        assert labels(n) == ['shaping', 'needs-research']
        continue
    if mode == 'human choice':
        save(n, original + '\nResearch: both formats work; the team must choose.\n')
        api('issue', 'edit', str(n), '--add-label', 'needs-clarification', '--remove-label', 'needs-research')
        assert labels(n) == ['shaping', 'needs-clarification']
        continue
    answer = 'Use Shared notes and show empty notes.'
    if mode == 'body edit':
        save(n, original + '\nAnswer: ' + answer + '\n')
    elif mode == 'fact':
        answer = 'Current header.txt contains Team notes, confirmed by reading the local source.'
        # Genuine local source evidence, not an invented external citation.
        assert (project / 'header.txt').read_text().strip() == 'Team notes'
        save(n, original + '\nResearch: ' + answer + '\n')
    else:
        api('issue', 'comment', str(n), '--body', answer)
    assert labels(n) == ['shaping', reason], 'answer alone cannot grant readiness'
    # Operator reconciles all acceptance and decisions; waiting history remains.
    if mode == 'fact':
        reconciled_spec = spec + '\nSource evidence: ' + answer + '\n'
    else:
        reconciled_spec = spec.replace('Use Shared notes.', answer)
    reconciled = (reconciled_spec +
                  '\n## Answer history\n' + followup.replace('## Waiting on you\n', '').replace('## Research gap\n', '') +
                  '\nAnswer: ' + answer + '\n')
    save(n, reconciled)
    api('issue', 'edit', str(n), '--remove-label', reason)
    assert labels(n) == ['shaping']
    if mode == 'review unavailable':
        save(n, reconciled + '\nIndependent readiness unavailable: /shape ' + str(n) + ' check readiness\n')
        assert issue(n)['title'] not in group(printed(), 'To build')
        assert not any('Claimed by run' in str(c) for c in issue(n).get('comments', []))
        continue
    verdict = review if mode != 'review fails' else '\n## Readiness\nNot ready\n- BLOCKING: empty notes behaviour is incomplete\n'
    save(n, reconciled + verdict)
    if mode == 'review fails':
        api('issue', 'edit', str(n), '--add-label', 'needs-clarification')
        assert labels(n) == ['shaping', 'needs-clarification']
        assert issue(n)['title'] not in group(printed(), 'To build')
        continue
    run(str(gh), *shlex.split(ready.replace('<number>', str(n)).replace('<its needs- label>', reason))[1:])
    plan = printed()
    assert labels(n) == ['ready'] and issue(n)['title'] in group(plan, 'To build')
    assert issue(dependent)['title'] not in group(plan, 'To build'), 'open dependency still governs'
    assert issue(n)['body'].count('## Waiting on you') == 0
    assert 'Question:' in issue(n)['body'], 'waiting history survives'
    if mode != 'fact':
        assert 'First recorded: 2026-09-30T08:00:00Z' in issue(n)['body']
    api('issue', 'edit', str(n), '--add-label', 'building', '--remove-label', 'ready')
    api('issue', 'comment', str(n), '--body', 'Claimed by run disposable-answer-reentry')
    assert labels(n) == ['building']
    assert any('Claimed by run' in str(c) for c in issue(n).get('comments', []))
    # Retain these fixtures without closing anything or creating more PRs.
    api('issue', 'edit', str(n), '--add-label', 'to check', '--remove-label', 'building')
# The independent fixture's already-built Git work passes its existing check
# and moves through the same state commands. No agent build is measured here.
assert (project / 'header.txt').read_text().strip() == 'Team notes'
api('issue', 'edit', str(independent), '--add-label', 'building', '--remove-label', 'ready')
api('issue', 'comment', str(independent), '--body', 'Claimed by run disposable-independent')
api('issue', 'edit', str(independent), '--add-label', 'to check', '--remove-label', 'building')
assert labels(independent) == ['to check']
print('ok: classified waits, later comment/body answers, failed/unavailable review and factual/human research keep real issue records and queue boundaries')
print('All disposable Git/state checks passed; conversation and merge-gate obedience remain guided checks.')
print('Fixture retained at ' + str(work))
PY
