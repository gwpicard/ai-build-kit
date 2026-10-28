#!/usr/bin/env sh
# replay-testbed.sh: guard naming, replacement boundaries and worktree removal without a model.
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
harness = root / '.agents/tests/replay'


def call(args, ok=0, env=None):
    ran = subprocess.run([str(a) for a in args], capture_output=True, text=True, env=env)
    assert ran.returncode == ok, (args, ran.returncode, ran.stdout, ran.stderr)
    return ran.stdout


with tempfile.TemporaryDirectory(prefix='testbed-check-') as tmp:
    tmp = Path(tmp)
    repo = tmp / 'source'
    replay = repo / '.agents/tests/replay'
    replay.mkdir(parents=True)
    for name in ('testbed.sh', 'testbed-export.py'):
        shutil.copy2(harness / name, replay / name)
    builder = repo / '.agents/tools/build-release.sh'
    builder.parent.mkdir(parents=True)
    builder.write_text('#!/bin/sh\nexit 0\n')
    builder.chmod(0o755)
    # Stand in for the whole paid replay, keeping its output layout and variables.
    stub = replay / 'run.sh'
    stub.write_text('''#!/bin/sh
set -eu
[ "$REPEATS" = 1 ]
[ "$(git -C "$KIT_SRC" rev-parse HEAD)" = "$(git -C "$KIT_SRC" rev-parse "$VERSION")" ]
[ "${STUB_FAIL:-no}" != yes ] || exit 2
mkdir -p "$REPLAY_WORK/s$1-r1" "$REPLAY_RESULTS"
p="$REPLAY_WORK/s$1-r1"
git -C "$p" init -q
git -C "$p" config user.name Test
git -C "$p" config user.email test@example.invalid
printf 'Founded with %s\\n' "$VERSION" > "$p/masterplan.md"
git -C "$p" add masterplan.md
git -C "$p" -c commit.gpgsign=false commit -qm Founded
git -C "$p" remote add origin https://github.com/rehearsal/project.git
printf '{"held":true,"state_held":%s}\\n' "${STUB_STATE:-true}" > "$REPLAY_RESULTS/s$1-r1.json"
printf 'transcript\\n' > "$REPLAY_RESULTS/s$1-r1.transcript"
printf 'stand-in state\\n' > "$p.gh.json"
''')
    call(['git', 'init', '-q', repo])
    call(['git', '-C', repo, 'add', '.'])
    call(['git', '-C', repo, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
          '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Fixture'])
    for tag in ('v1.0.0', 'v1.1.2'):
        call(['git', '-C', repo, 'tag', tag])
    runner = replay / 'testbed.sh'
    out = tmp / 'output with spaces'
    args = [runner, '--output', out]
    before = call(['git', '-C', repo, 'worktree', 'list', '--porcelain'])
    listed = call(args + ['--list'])
    names = ['tb-%s-%s' % (tag, recipe) for tag in ('v1.0.0', 'v1.1.2')
             for recipe in ('vercel', 'coolify')]
    assert len(listed.splitlines()) == 4
    for name in names:
        assert str(out / name) in listed
    assert not out.exists()
    for bad in (['--unknown'], ['--output'], ['nonsense'], ['v9.9.9'], ['v1.0.0', 'v1.0.0']):
        call([runner] + bad, ok=2)
    call(args)
    for name in names:
        project = out / name
        assert (project / 'masterplan.md').is_file()
        assert not (project / 'run.log').exists()
        assert not (project / (name + '.gh.json')).exists()
        assert call(['git', '-C', project, 'remote']) == ''
        report = (out / (name + '.founding.md')).read_text()
        for field in ('Tag:', 'Recipe:', 'Case:', 'Held: True', 'State check: True', 'Transcript:', 'Date:'):
            assert field in report
        transcript = report.split('Transcript: ', 1)[1].splitlines()[0]
        assert Path(transcript).is_file()
    assert call(['git', '-C', repo, 'worktree', 'list', '--porcelain']) == before
    sentinel = out / names[0] / 'unfinished.txt'
    sentinel.write_text('keep my work')
    call(args, ok=2)
    assert sentinel.read_text() == 'keep my work'
    call(args + ['--replace', 'v1.0.0'])
    backups = list((out / '.runs').glob('*/previous-*/unfinished.txt'))
    assert len(backups) == 1 and backups[0].read_text() == 'keep my work'
    assert call(['git', '-C', repo, 'worktree', 'list', '--porcelain']) == before
    for key, value in [('STUB_FAIL', 'yes'), ('STUB_STATE', 'false')]:
        failed = tmp / key
        env = dict(os.environ, **{key: value})
        call([runner, '--output', failed, 'v1.0.0'], ok=2, env=env)
        assert not (failed / names[0]).exists()
        assert list((failed / '.runs').glob('*/founding.md'))
        assert call(['git', '-C', repo, 'worktree', 'list', '--porcelain']) == before
    # A release without the builder fails before a replay and leaves no worktree.
    builder.unlink()
    call(['git', '-C', repo, 'add', '-u'])
    call(['git', '-C', repo, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
          '-c', 'commit.gpgsign=false', 'commit', '-qm', 'No release builder'])
    call(['git', '-C', repo, 'tag', 'v9.0.0'])
    before = call(['git', '-C', repo, 'worktree', 'list', '--porcelain'])
    call([runner, '--output', tmp / 'unsupported', 'v9.0.0'], ok=2)
    assert call(['git', '-C', repo, 'worktree', 'list', '--porcelain']) == before

    # Exercise the real disk checks with saved states, then break each promise.
    project = tmp / 'disk-project'
    project.mkdir()
    call(['git', 'init', '-q', project])
    call(['git', '-C', project, 'config', 'user.name', 'Test'])
    call(['git', '-C', project, 'config', 'user.email', 'test@example.invalid'])
    call(['git', '-C', project, '-c', 'commit.gpgsign=false', 'commit', '--allow-empty', '-qm', 'Before'])
    helper = project / '.agents/skills/records/scripts/trued-mark.sh'
    helper.parent.mkdir(parents=True)
    shutil.copy2(root / '.agents/skills/records/scripts/trued-mark.sh', helper)
    for recipe in ('vercel', 'coolify'):
        folder = project / ('.agents/skills/setup-hosting/recipes/nextjs-supabase-on-' + recipe)
        folder.mkdir(parents=True)
        (folder / 'recipe.md').write_text('Recipe fixture')
    plan = project / 'masterplan.md'
    plan.write_text('# Shared reading list\nTrued against: ' +
                    call(['git', '-C', project, 'rev-parse', 'HEAD']).strip() + '\n')
    upkeep = project / '.ai-build-kit-maintenance'
    upkeep.write_text('founding-menu|2026-10-28|nextjs-supabase-on-vercel,nextjs-supabase-on-coolify\n')
    agents = project / 'AGENTS.md'
    state = Path(str(project) + '.gh.json')
    state.write_text(json.dumps({'repo': 'rehearsal/project', 'issues': [
        {'number': 1, 'body': '## Done when\nMembers add a link'},
        {'number': 2, 'body': '## Done when\nMembers mark items read'}]}))
    for number, recipe in [(83, 'vercel'), (84, 'coolify')]:
        agents.write_text('Recipe: nextjs-supabase-on-' + recipe + '\n')
        call(['git', '-C', project, 'add', '.'])
        call(['git', '-C', project, '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Founding records'])
        def check():
            return json.loads(call([harness / 'state-check.sh', str(number), project]))
        result = check()
        assert result['state_held'], result
        for file, broken, verdict in [
            (plan, '# Unsaved replacement\n', 'masterplan-saved'),
            (agents, 'Recipe: none\n', 'recipe-record'),
            (state, '{"issues": []}', 'pieces-saved'),
        ]:
            original = file.read_text()
            file.write_text(broken)
            result = check()
            assert result['state_held'] is False, result
            assert result['state_verdicts'][verdict]['verdict'] == 'miss', result
            file.write_text(original)
        original = plan.read_text()
        plan.write_text('# Reading list\nTrued against: not yet checked\n')
        result = check()
        assert result['state_verdicts']['founding-checkpoint']['verdict'] == 'miss', result
        plan.write_text(original)

    # The normal pass excludes builders, but every previous case still runs.
    env = dict(os.environ, REPLAY_DIR=str(harness))
    defaults = call(['sh', '-c', '. "$REPLAY_DIR/lib.sh"; default_cases'], env=env).split()
    expected = sorted(int(p.stem) for p in (harness / 'cases').glob('*.txt') if int(p.stem) < 83)
    assert sorted(map(int, defaults)) == expected
print('replay-testbed: argument, naming, export, replacement and cleanup checks passed')
PY
