#!/usr/bin/env sh
# upload-piece.sh: guard branch uploads, one pull request, intact bodies and honest refusals.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 - "$ROOT" <<'PY'
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
script = root / '.agents/skills/merge/scripts/upload-piece.py'
foundation = root / '.agents/skills/setup-ai-build-kit/templates/foundation'
fake = root / '.agents/tests/replay/fake-github/gh'
with tempfile.TemporaryDirectory(prefix='kit-upload-test-') as folder:
    work = Path(folder)
    (work / 'bin').mkdir()
    # Normal calls reach the replay stand-in. Failures carry a canary to prove
    # raw tool errors cannot leak a credential into the upload report.
    wrapper = work / 'bin/gh'
    wrapper.write_text('''#!/usr/bin/env python3
import json, os, runpy, sys
report = os.environ.get('UPLOAD_TEST_REPORT', '')
if report and sys.argv[1:3] == ['pr', report]:
    url = 'https://github.com/rehearsal/project/pull/' + os.environ['UPLOAD_TEST_CANARY']
    print(json.dumps([{'url': url}]) if report == 'list' else url)
    sys.exit(0)
mode = os.environ.get('UPLOAD_TEST_FAILURE', '')
if mode and (mode != 'create' or sys.argv[1:3] == ['pr', 'create']):
    print(('gh auth login' if mode == 'auth' else 'HTTP 503 GitHub unavailable')
          + ' ' + os.environ['UPLOAD_TEST_CANARY'], file=sys.stderr)
    sys.exit(4 if mode == 'auth' else 1)
runpy.run_path(os.environ['UPLOAD_TEST_GH'], run_name='__main__')
''')
    wrapper.chmod(0o755)
    git_wrapper = work / 'bin/git'
    git_wrapper.write_text('''#!/usr/bin/env python3
import os, sys
mode = os.environ.get('UPLOAD_TEST_GIT_FAILURE', '')
if (mode == 'password' and sys.argv[1] == 'ls-remote') or (mode == 'access' and sys.argv[1] == 'push'):
    print(('unable to get password from user' if mode == 'password' else
           'remote: Permission to rehearsal/project denied to someone.')
          + ' ' + os.environ['UPLOAD_TEST_CANARY'], file=sys.stderr)
    sys.exit(128)
os.execv(os.environ['UPLOAD_TEST_REAL_GIT'], [os.environ['UPLOAD_TEST_REAL_GIT']] + sys.argv[1:])
''')
    git_wrapper.chmod(0o755)
    env = dict(os.environ, PATH=str(work / 'bin') + os.pathsep + os.environ['PATH'],
               GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=str(work / 'gitconfig'),
               UPLOAD_TEST_GH=str(fake), UPLOAD_TEST_CANARY='ghp_' + 'a' * 40,
               UPLOAD_TEST_REAL_GIT=shutil.which('git'))
    env.pop('GIT_CONFIG_COUNT', None)

    def run(*args, cwd=None, code=0, extra=None):
        result = subprocess.run(args, cwd=cwd, env=dict(env, **(extra or {})),
                                capture_output=True, text=True)
        if args[:2] == (sys.executable, str(script)):
            assert env['UPLOAD_TEST_CANARY'] not in result.stderr
        assert result.returncode == code, (args, result.returncode, result.stdout, result.stderr)
        return result.stdout

    def setup(label, remote_main=True, guard=True):
        project, remote = work / label, work / (label + '.git')
        run('git', 'init', '-q', '-b', 'main', str(project))
        run('git', 'init', '-q', '--bare', str(remote))
        for key, value in (('user.name', 'Rehearsal'), ('user.email', 'test@example.invalid'),
                           ('commit.gpgsign', 'false')):
            run('git', 'config', key, value, cwd=project)
        if guard:
            run('git', 'config', 'core.hooksPath', '.agents/hooks/git', cwd=project)
        run('git', 'commit', '-q', '--allow-empty', '-m', 'Founding', cwd=project)
        # Seed the bare remote before the guard is installed, as the first
        # upload's API would. This test makes no change to the first upload.
        if remote_main:
            run('git', 'push', '-q', str(remote), 'main', cwd=project)
        if guard:
            hooks = project / '.agents/hooks'
            (hooks / 'git').mkdir(parents=True)
            for source, dest in (('pre-push', hooks / 'git/pre-push'),
                                 ('scan-secrets.sh', hooks / 'scan-secrets.sh'),
                                 ('scan-secrets.py', hooks / 'scan-secrets.py')):
                shutil.copy2(foundation / source, dest)
            (hooks / 'git/pre-push').chmod(0o755)
        run('git', 'remote', 'add', 'origin', 'https://github.com/rehearsal/project.git', cwd=project)
        run('git', 'config', 'url.' + str(remote) + '.insteadOf',
            'https://github.com/rehearsal/project.git', cwd=project)
        run('git', 'checkout', '-q', '-b', 'piece', cwd=project)
        run('git', 'commit', '-q', '--allow-empty', '-m', 'Piece', cwd=project)
        state = work / (label + '.json')
        state.write_text(json.dumps({'repo': 'rehearsal/project', 'issues': [],
                                     'pull_requests': [{'number': 1, 'head': 'other', 'base': 'main',
                                                        'state': 'OPEN', 'body': 'Keep this'}]}))
        env['FAKE_GH_STATE'] = str(state)
        env['FAKE_GH_LOG'] = str(work / (label + '.log'))
        return project, remote, state

    body = 'A + b\n-f stays literal; --force and main too.\n\nLast line.\n'
    body_file = work / 'body.md'
    body_file.write_text(body)
    title_file = work / 'title.txt'
    title_file.write_text('Piece + main -f --force\n')

    def upload(project, code=0, extra=None, files=True):
        args = (['--title-file', str(title_file), '--body-file', str(body_file)] if files else
                ['--title', 'Piece', '--body', body])
        out = run(sys.executable, str(script), *args, str(project), code=code, extra=extra)
        assert env['UPLOAD_TEST_CANARY'] not in out
        assert 'declined' not in out.lower()
        return out

    p, remote, state = setup('older-project', guard=False)
    run('sh', str(foundation.parent.parent / 'scripts/use-push-guard.sh'), str(p))
    assert 'opened\t' in upload(p)
    prs = json.loads(state.read_text())['pull_requests']
    assert len(prs) == 2 and prs[-1]['base'] == 'main' and prs[-1]['head'] == 'piece'
    assert run('git', 'rev-parse', 'piece', cwd=remote) == run('git', 'rev-parse', 'HEAD', cwd=p)
    print('ok: a project with no guard or hooks path can install the guard, upload and open a pull request')

    p, remote, state = setup('normal')
    # A personal push mapping must not redirect the upload to main.
    run('git', 'config', 'remote.origin.push', 'HEAD:main', cwd=p)
    out = upload(p)
    prs = json.loads(state.read_text())['pull_requests']
    assert len(prs) == 2 and prs[1]['base'] == 'main' and prs[1]['head'] == 'piece', prs
    assert prs[1]['body'] == body and prs[1]['title'] == title_file.read_text().strip()
    assert run('git', 'rev-parse', 'piece', cwd=remote) == run('git', 'rev-parse', 'HEAD', cwd=p)
    assert run('git', 'rev-parse', '--abbrev-ref', 'piece@{upstream}', cwd=p).strip() == 'origin/piece'
    print('ok: uploads the branch with upstream, opens one pull request against main and keeps the body intact')
    before = state.read_bytes()
    online = run('git', 'rev-parse', 'piece', cwd=remote)
    run('git', 'commit', '-q', '--allow-empty', '-m', 'Fix review finding', cwd=p)
    assert 'existing\t' in upload(p)
    assert state.read_bytes() == before
    assert run('git', 'rev-parse', 'piece', cwd=remote) == run('git', 'rev-parse', 'HEAD', cwd=p) != online
    assert len([pr for pr in json.loads(state.read_text())['pull_requests']
                if pr['head'] == 'piece' and pr['base'] == 'main']) == 1
    print('ok: a later commit uploads to the same branch and keeps one pull request')

    p, remote, state = setup('arguments')
    upload(p, files=False)
    assert json.loads(state.read_text())['pull_requests'][-1]['body'] == body
    print('ok: title and body arguments also pass without shell interpretation')

    p, remote, state = setup('ambiguous-branch')
    run('git', 'tag', 'piece', cwd=p)
    assert 'pushed\tpiece' in upload(p)
    assert run('git', 'rev-parse', 'refs/heads/piece', cwd=remote) == run('git', 'rev-parse', 'HEAD', cwd=p)
    assert not run('git', 'for-each-ref', '--format=%(refname)', 'refs/heads/heads/piece', cwd=remote)
    assert json.loads(state.read_text())['pull_requests'][-1]['head'] == 'piece'
    run('git', 'checkout', '-q', 'main', cwd=p)
    run('git', 'tag', 'main', cwd=p)
    assert 'main cannot be uploaded' in upload(p, code=2)
    print('ok: a tag sharing the branch name neither changes the upload branch nor hides main')

    p, remote, state = setup('secret-branch')
    branch = env['UPLOAD_TEST_CANARY']
    run('git', 'branch', '-m', branch, cwd=p)
    out = upload(p)
    assert 'output hidden' in out and 'opened\t' in out
    assert run('git', 'rev-parse', 'refs/heads/' + branch, cwd=remote) == run('git', 'rev-parse', 'HEAD', cwd=p)
    assert json.loads(state.read_text())['pull_requests'][-1]['head'] == branch
    for operation in ('list', 'create'):
        p, remote, state = setup('secret-url-' + operation)
        assert 'output hidden' in upload(p, extra={'UPLOAD_TEST_REPORT': operation})
    print('ok: token-shaped branch names and returned pull request URLs stay out of the report')

    p, remote, state = setup('main')
    run('git', 'checkout', '-q', 'main', cwd=p)
    assert 'main cannot be uploaded' in upload(p, code=2)
    p, remote, state = setup('empty', remote_main=False)
    run('git', 'config', '--unset', 'core.hooksPath', cwd=p)
    hook = p / '.git/hooks/pre-push'
    hook.write_text('#!/bin/sh\nexit 0\n')
    hook.chmod(0o755)
    assert 'use first-upload.py' in upload(p, code=3)
    run('sh', str(foundation.parent.parent / 'scripts/use-push-guard.sh'), '--check', str(p))
    assert not run('git', 'for-each-ref', '--format=%(refname)', cwd=remote)
    print('ok: refuses main and restores the guard before handing an empty remote to first-upload')

    p, remote, state = setup('guard')
    run('git', 'branch', 'piece', 'main', cwd=remote)
    run('git', 'fetch', '-q', 'origin', cwd=p)
    run('git', 'update-ref', 'refs/heads/piece', run('git', 'rev-parse', 'main', cwd=p).strip(), cwd=p)
    # Give the remote a different descendant, so this upload replaces work.
    other = work / 'other'
    run('git', 'clone', '-q', str(remote), str(other))
    run('git', 'checkout', '-q', 'piece', cwd=other)
    run('git', '-c', 'user.name=Rehearsal', '-c', 'user.email=test@example.invalid',
        '-c', 'commit.gpgsign=false', 'commit', '-q', '--allow-empty', '-m', 'Other work', cwd=other)
    run('git', 'push', '-q', 'origin', 'piece', cwd=other)
    run('git', 'commit', '-q', '--allow-empty', '-m', 'Local work', cwd=p)
    assert 'push guard' in upload(p, code=4)
    assert len(json.loads(state.read_text())['pull_requests']) == 1
    print('ok: a hook refusal names the push guard without blaming the person')

    for label, change in (
        ('unset', lambda p: run('git', 'config', '--unset', 'core.hooksPath', cwd=p)),
        ('missing', lambda p: (p / '.agents/hooks/git/pre-push').unlink()),
        ('not-executable', lambda p: (p / '.agents/hooks/git/pre-push').chmod(0o644)),
    ):
        p, remote, state = setup(label)
        change(p)
        assert 'opened\t' in upload(p)
        assert run('git', 'rev-parse', 'piece', cwd=remote) == run('git', 'rev-parse', 'HEAD', cwd=p)
    print('ok: upload restores an unset, missing or non-executable guard before pushing')

    p, remote, state = setup('rewritten-hook')
    use_guard = str(foundation.parent.parent / 'scripts/use-push-guard.sh')
    hook = p / '.git/hooks/pre-push'
    installer = work / 'install-hooks.py'
    installer.write_text('''from pathlib import Path
hook = Path('.git/hooks/pre-push')
hook.write_text('#!/bin/sh\\ncat > own-input\\nprintf "%s\\\\n" "$@" > own-args\\nexit 0\\n')
hook.chmod(0o755)
''')
    run('git', 'config', '--unset', 'core.hooksPath', cwd=p)
    run(sys.executable, str(installer), cwd=p)
    original = hook.read_text()
    run('sh', use_guard, str(p))
    run('sh', use_guard, '--check', str(p))
    # Reinstalling a tool such as simple-git-hooks replaces the whole hook.
    run(sys.executable, str(installer), cwd=p)
    assert hook.read_text() == original
    run('sh', use_guard, '--check', str(p), code=1)
    assert 'opened\t' in upload(p)
    assert hook.read_text().endswith(original.partition('\n')[2])
    assert run('git', 'rev-parse', 'piece', cwd=remote) == run('git', 'rev-parse', 'HEAD', cwd=p)
    assert 'refs/heads/piece' in (p / 'own-input').read_text()
    assert (p / 'own-args').read_text().splitlines()[0] == 'origin'
    assert len(json.loads(state.read_text())['pull_requests']) == 2
    before = state.read_bytes()
    online = run('git', 'rev-parse', 'piece', cwd=remote)
    run(sys.executable, str(installer), cwd=p)
    run('sh', use_guard, '--check', str(p), code=1)
    assert 'existing\t' in upload(p)
    run('sh', use_guard, '--check', str(p))
    assert hook.read_text().endswith(original.partition('\n')[2])
    assert state.read_bytes() == before and run('git', 'rev-parse', 'piece', cwd=remote) == online
    refused = subprocess.run(['git', 'push', 'origin', 'HEAD:main'], cwd=p, env=env,
                             capture_output=True, text=True)
    assert refused.returncode and 'would change main directly' in refused.stderr
    assert run('git', 'rev-parse', 'main', cwd=remote) == run('git', 'rev-parse', 'main', cwd=p)
    print('ok: new and existing pull requests restore a rewritten hook, keep its work and refuse main')

    p, remote, state = setup('changed-guard')
    guard = p / '.agents/hooks/git/pre-push'
    guard.write_text('#!/bin/sh\nexit 23\n')
    before = guard.read_bytes()
    assert 'push guard is not on' in upload(p, code=10)
    assert guard.read_bytes() == before
    assert not run('git', 'for-each-ref', '--format=%(refname)', 'refs/heads/piece', cwd=remote)
    assert len(json.loads(state.read_text())['pull_requests']) == 1
    print('ok: a changed guard stays intact and stops the upload before pushing')

    for field in ('body', 'title'):
        p, remote, state = setup('secret-' + field)
        target = body_file if field == 'body' else title_file
        before = target.read_bytes()
        target.write_text(env['UPLOAD_TEST_CANARY'])
        assert 'secret scan found a secret in the pull request ' + field in upload(p, code=7)
        target.write_bytes(before)
        assert not Path(env['FAKE_GH_LOG']).exists()
        assert not run('git', 'for-each-ref', '--format=%(refname)', 'refs/heads/piece', cwd=remote)
    print('ok: a secret in either title or body never reaches GitHub or a push')

    p, remote, state = setup('other-base')
    data = json.loads(state.read_text())
    data['pull_requests'].append({'number': 2, 'head': 'piece', 'base': 'develop', 'state': 'OPEN'})
    state.write_text(json.dumps(data))
    assert 'opened\t' in upload(p)
    prs = json.loads(state.read_text())['pull_requests']
    assert len(prs) == 3 and prs[-1]['base'] == 'main'
    print('ok: an open pull request against another base does not replace the one to main')

    p, remote, state = setup('secret')
    (p / 'key.txt').write_text(env['UPLOAD_TEST_CANARY'])
    run('git', 'add', 'key.txt', cwd=p)
    run('git', 'commit', '-q', '-m', 'Planted key', cwd=p)
    assert 'secret scan found a secret' in upload(p, code=7)
    (p / '.agents/hooks/scan-secrets.sh').unlink()
    assert 'secret scan could not run' in upload(p, code=9)
    print('ok: secret findings and a missing scanner have distinct reports and hide the key')

    for mode, code in (('auth', 5), ('unavailable', 6), ('create', 6)):
        p, remote, state = setup(mode)
        out = upload(p, code=code, extra={'UPLOAD_TEST_FAILURE': mode})
        assert ('sign-in' if mode == 'auth' else 'GitHub is unavailable') in out
        if mode != 'create':
            assert run('git', 'for-each-ref', '--format=%(refname)', 'refs/heads/piece', cwd=remote) == ''
        else:
            assert 'pushed\tpiece' in out
            upload(p)
            assert len(json.loads(state.read_text())['pull_requests']) == 2
    print('ok: sign-in and GitHub failures are distinct; a failed creation can be retried')
    p, remote, state = setup('git-access')
    assert 'repository access was refused' in upload(p, code=5, extra={'UPLOAD_TEST_GIT_FAILURE': 'access'})
    out = upload(p, code=5, extra={'UPLOAD_TEST_GIT_FAILURE': 'password'})
    helper = foundation / 'codex-github-check.py'
    message = run(sys.executable, str(helper), '--message', cwd=p).strip()
    assert message in out and 'stop without signing in or retrying' in out
    assert not Path(env['FAKE_GH_LOG']).exists() or 'auth login' not in Path(env['FAKE_GH_LOG']).read_text()
    print('ok: Git access refusals are named and a Codex password failure gives the installed helper message')
print('upload-piece.sh: all checks passed')
PY
