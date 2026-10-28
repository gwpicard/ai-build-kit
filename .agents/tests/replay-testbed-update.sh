#!/usr/bin/env sh
# replay-testbed-update.sh: guard copied test-bed history and unfinished work, report names and failure continuation without a model.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 - "$ROOT" <<'PY'
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
harness = root / '.agents/tests/replay'

def call(args, code=0, env=None, cwd=None):
    r = subprocess.run(list(map(str, args)), capture_output=True, text=True, env=env, cwd=cwd)
    assert r.returncode == code, (args, r.returncode, r.stdout, r.stderr)
    return r.stdout


def tree(folder):
    return {str(p.relative_to(folder)): ('link', os.readlink(p)) if p.is_symlink()
            else ('file', hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mode)
            for p in folder.rglob('*') if p.is_file() or p.is_symlink()}


with tempfile.TemporaryDirectory(prefix='testbed-update-check-') as tmp:
    tmp = Path(tmp)
    repo = tmp / 'source'
    replay = repo / '.agents/tests/replay'
    replay.mkdir(parents=True)
    for name in ('testbed-update.sh', 'testbed-update-run.py', 'testbed-update-data.py'):
        shutil.copy2(harness / name, replay / name)
    version = repo / '.agents/skills/maintain/VERSION'
    version.parent.mkdir(parents=True)
    version.write_text('v1.2.1\n')
    inputs = tmp / 'input with spaces'
    inputs.mkdir()
    for name in ('tb-first', 'tb-second'):
        p = inputs / name
        p.mkdir()
        call(['git', 'init', '-q', '-b', 'main', p])
        (p / '.env.example').write_text('original\n')
        call(['git', '-C', p, 'add', '.'])
        call(['git', '-C', p, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
              '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Founded'])
        call(['git', '-C', p, 'config', 'url./old run/founding-run.git.insteadOf', 'https://github.com/rehearsal/reading-list.git'])
        (p / '.env.example').write_text('unfinished\n')
        (p / 'notes.txt').write_text('untracked\n')
        Path(str(p) + '.gh.json').write_text('{"repo":"rehearsal/reading-list","issues":[{"number":1}]}')
        Path(str(p) + '.founding.md').write_text('Tag: v1.0.0\nRecipe: nextjs-supabase-on-vercel\n')
    before = tree(inputs)
    kit = tmp / 'kit'
    shutil.copytree(repo / '.agents/skills', kit / '.agents/skills')
    spec = importlib.util.spec_from_file_location('data', harness / 'testbed-update-data.py')
    data = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(data)
    scripts = kit / '.agents/skills/maintain/scripts'
    scripts.mkdir()
    for name in ('kit-leftovers.py', 'upgrade-check.py'):
        (scripts / name).write_text("print('fixture report')\n")
    p = tmp / 'copy'
    p.mkdir()
    original = inputs / 'tb-first'
    data.seed(original, p, kit)
    assert (p / '.env.example').read_text() == 'unfinished\n'
    assert (p / 'notes.txt').read_text() == 'untracked\n'
    assert call(['git', '-C', p, 'show', 'HEAD:.env.example']) == 'original\n'
    assert call(['git', '-C', p, 'rev-parse', 'HEAD']) == call(['git', '-C', original, 'rev-parse', 'HEAD'])
    assert json.loads(Path(str(p) + '.gh-start.json').read_text())['issues'] == [{'number': 1}]
    assert json.loads(Path(str(p) + '.person-work.json').read_text())['files'].keys() == {'.env.example', 'notes.txt'}
    assert call(['git', '-C', str(p) + '.git', 'for-each-ref']) == ''
    call(['git', '-C', p, 'config', '--get-regexp', '^url\\.'], code=1)
    address = 'https://github.com/rehearsal/reading-list.git'
    call(['git', '-C', p, 'remote', 'set-url', 'origin', address])
    call(['git', '-C', p, 'config', 'url.' + str(p) + '.git.insteadOf', address])
    assert call(['git', '-C', p, 'remote', 'get-url', 'origin']).strip() == str(p) + '.git'
    assert tree(inputs) == before
    # Claude Code's own copy of each skill is refreshed too, as the real installer does.
    assert (p / '.claude/skills/maintain').is_symlink()
    assert (p / '.claude/skills/maintain').resolve() == (p / '.agents/skills/maintain').resolve()
    call(['git', '-C', p, 'add', '.agents', 'skills-lock.json'])
    call(['git', '-C', p, 'commit', '-qm', 'Save installed skills'])
    assert all(v['verdict'] == 'hit' for v in data.checks(p).values())
    skill = p / '.agents/skills/maintain/VERSION'
    skill.write_text('changed')
    assert data.checks(p)['current-skills']['verdict'] == 'miss'
    skill.write_text('v1.2.1\n')
    Path(str(p) + '-host.log').write_text('CALL\tvercel deploy --prod\tturn=2\n')
    assert data.checks(p)['no-upload']['verdict'] == 'miss'
    Path(str(p) + '-host.log').write_text('')
    Path(str(p) + '-gh.log').write_text('PUSH\trefs/heads/main\n')
    assert data.checks(p)['no-upload']['verdict'] == 'miss'
    Path(str(p) + '-gh.log').write_text('')
    call(['git', '-C', p, 'add', '.env.example'])
    call(['git', '-C', p, 'commit', '-qm', 'Swept unfinished work'])
    assert data.checks(p)['person-work']['verdict'] == 'miss'
    assert tree(inputs) == before
    installer_env = dict(os.environ, REPLAY_TESTBED_KIT=str(kit), FAKE_GH_LOG=str(p) + '-gh.log')
    call([harness / 'testbed-tools/npx', 'skills', 'add', 'gwpicard/ai-build-kit', '-y'], env=installer_env, cwd=p)
    assert (p / '.env.example').read_text() == 'unfinished\n'
    assert json.loads((p / 'skills-lock.json').read_text())['skills']['maintain']['source'] == 'gwpicard/ai-build-kit'
    call([harness / 'testbed-tools/npx', 'skills', 'update'], code=1, env=installer_env, cwd=p)
    latest_env = dict(os.environ, FAKE_GH_STATE=str(p) + '.gh-start.json', FAKE_GH_LOG=str(p) + '-gh.log', REPLAY_TESTBED_VERSION='v1.2.1')
    assert call([harness / 'fake-github/gh', 'api', 'repos/gwpicard/ai-build-kit/releases/latest', '--jq', '.tag_name'], env=latest_env) == 'v1.2.1\n'
    assert tree(inputs) == before
    # The stub stands in for the paid conversation, not its seeding.
    (replay / 'run.sh').write_text('''#!/bin/sh
set -eu
[ "$1" = 85 ]
[ "$REPEATS" = 1 ]
mkdir -p "$REPLAY_RESULTS" "$REPLAY_WORK/s85-r1"
printf '%s\\n' "$REPLAY_TESTBED_SOURCE" >> "$STUB_CALLS"
case "$REPLAY_TESTBED_SOURCE" in *tb-first) [ "${STUB_FAIL:-no}" != yes ] || exit 2 ;; esac
printf '{"held":true,"state_held":true,"verdicts":{"Read update offer":{"verdict":"hit"},"Read second visit":{"verdict":"hit"},"Read live evidence":{"verdict":"hit"}}}\\n' > "$REPLAY_RESULTS/s85-r1.json"
printf '### user turn 1\\n/maintain\\n### kit reply 1\\nUpdate offer as stated.\\n### user turn 4\\n/maintain Make a second visit\\n### kit reply 4\\nNothing repeated.\\n' > "$REPLAY_RESULTS/s85-r1.transcript"
for phase in after-install first-visit second-visit; do
  printf '{"project_check":{"exit":0},"leftovers":{"stdout":"leftovers evidence"}}\\n' > "$REPLAY_WORK/s85-r1.$phase.json"
done
''')
    runner = replay / 'testbed-update.sh'
    env = dict(os.environ, REPLAY_RESULTS=str(tmp / 'reports'), REPLAY_WORK=str(tmp / 'work'),
               KIT_SRC=str(repo), STUB_CALLS=str(tmp / 'calls'))
    env.pop('VERSION', None)
    args = [runner, '--input', inputs]
    listed = call(args + ['--list'], env=env)
    assert len(listed.splitlines()) == 2 and 'kit v1.2.1 | case 85' in listed
    assert not (tmp / 'calls').exists() and not (tmp / 'reports').exists()
    for bad in (['--unknown'], ['--input'], ['bad'], ['../tb-first'], ['tb-first', 'tb-first']):
        call(args + bad, code=2, env=env)
    call(args, code=2, env=dict(env, VERSION='v0.0.0-replay'))
    call(args, env=env)
    reports = list((tmp / 'reports').glob('*/*.update.md'))
    assert len(reports) == 2
    for report in reports:
        text = report.read_text()
        assert report.name in ('tb-first.update.md', 'tb-second.update.md')
        for value in ('Tag: v1.0.0', 'Recipe:', 'Held: True', 'State check: True', '"exit": 0',
                      'leftovers evidence', 'Update offer as stated.', 'Nothing repeated.', 'Transcript:'):
            assert value in text, (value, text)
    call(args, code=2, env=dict(env, STUB_FAIL='yes'))
    assert (tmp / 'calls').read_text().splitlines()[-1] == str((inputs / 'tb-second').resolve()), (tmp / 'calls').read_text()
    failed = [p for p in (tmp / 'reports').glob('*/*.update.md') if 'Result: FAILED' in p.read_text()]
    assert len(failed) == 1 and 'Run exit: 2' in failed[0].read_text(), [(str(p), p.read_text()) for p in failed]
    stub = replay / 'run.sh'
    stub.write_text(stub.read_text().replace('"Read second visit":{"verdict":"hit"}', '"Read second visit":{"verdict":"miss"}'))
    call(args + ['tb-second'], code=2, env=env)
    assert tree(inputs) == before
print('replay-testbed-update: arguments, source preservation, history, work, issues, naming and failure continuation passed')
PY
