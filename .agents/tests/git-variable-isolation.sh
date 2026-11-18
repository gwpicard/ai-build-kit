#!/usr/bin/env sh
# git-variable-isolation.sh: check canary repositories survive inherited Git settings.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_NOSYSTEM
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 - "$ROOT" <<'PY'
from pathlib import Path
import os, shutil, subprocess, sys, tempfile

root = Path(sys.argv[1])
with tempfile.TemporaryDirectory() as tmp:
    work = Path(tmp)
    canary = work / 'canary'
    canary.mkdir()
    clean = os.environ.copy()
    for k in list(clean):
        if k.startswith('GIT_'):
            clean.pop(k)
    clean.update(HOME=str(work / 'home'), GIT_CONFIG_NOSYSTEM='1',
                 GIT_AUTHOR_NAME='Fixture', GIT_AUTHOR_EMAIL='fixture@example.invalid',
                 GIT_COMMITTER_NAME='Fixture', GIT_COMMITTER_EMAIL='fixture@example.invalid')
    (work / 'home').mkdir()
    def git(where, *args):
        return subprocess.run(['git', '-C', str(where), *args], env=clean, check=True,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    git(canary, 'init', '-q')
    (canary / 'file').write_text('canary\n')
    git(canary, 'add', 'file')
    git(canary, 'commit', '-qm', 'canary')
    gd = canary / '.git'
    variables = {'GIT_DIR': str(gd), 'GIT_WORK_TREE': str(canary),
                 'GIT_INDEX_FILE': str(gd / 'index'), 'GIT_COMMON_DIR': str(gd),
                 'GIT_OBJECT_DIRECTORY': str(gd / 'objects'),
                 'GIT_ALTERNATE_OBJECT_DIRECTORIES': str(gd / 'objects'),
                 'GIT_CEILING_DIRECTORIES': str(work), 'GIT_DISCOVERY_ACROSS_FILESYSTEM': '1',
                 'GIT_IMPLICIT_WORK_TREE': '0', 'GIT_GRAFT_FILE': str(work / 'grafts'),
                 'GIT_PREFIX': 'canary/', 'GIT_SHALLOW_FILE': str(work / 'shallow'),
                 'GIT_REPLACE_REF_BASE': 'refs/replace/', 'GIT_NO_REPLACE_OBJECTS': '1',
                 'GIT_CONFIG': str(gd / 'config'), 'GIT_CONFIG_PARAMETERS': "'test.canary=value'",
                 'GIT_CONFIG_GLOBAL': str(gd / 'config'), 'GIT_CONFIG_SYSTEM': str(gd / 'config'),
                 'GIT_CONFIG_NOSYSTEM': '0', 'GIT_CONFIG_COUNT': '1',
                 'GIT_CONFIG_KEY_0': 'core.bare', 'GIT_CONFIG_VALUE_0': 'true'}
    def snapshot():
        return {str(p.relative_to(gd)): p.read_bytes() for p in gd.rglob('*') if p.is_file()
                and (p.name in ('config', 'index', 'packed-refs', 'HEAD') or 'refs' in p.relative_to(gd).parts)}
    def run(script, args=(), env=None, require_success=True):
        before = snapshot()
        result = subprocess.run(['sh', str(script), *map(str, args)], env=env or {**clean, **variables},
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        unchanged = before == snapshot()
        if require_success and result.returncode:
            raise RuntimeError(f'{script.name} exited {result.returncode}:\n{result.stdout[-4000:]}')
        return unchanged, result
    # Run the validator's normal work with the canary configured.
    ok, _ = run(root / '.agents/tools/validate-kit.sh')
    assert ok, 'validator changed the canary'
    print('ok: validator leaves canary unchanged', flush=True)
    # The standalone check writes global configuration during its real work.
    ok, _ = run(root / '.agents/tests/push-guard.sh')
    assert ok, 'standalone check changed the canary'
    print('ok: standalone check leaves canary unchanged', flush=True)
    # A real runner in a small tree runs a test that writes to its own repository.
    source = work / 'source'
    for folder in ('.agents/tests', '.agents/tools', 'templates/nextjs-postgres'):
        (source / folder).mkdir(parents=True, exist_ok=True)
    shutil.copy2(root / '.agents/tests/run-all.sh', source / '.agents/tests/run-all.sh')
    (source / '.agents/tests/probe.sh').write_text('#!/bin/sh\nset -eu\ngit init -q "$FIXTURE_REPO"\ngit -C "$FIXTURE_REPO" add .\ngit -C "$FIXTURE_REPO" commit -qm fixture\n')
    (source / '.agents/tests/probe.sh').chmod(0o755)
    fixture = work / 'runner-project'
    fixture.mkdir()
    (fixture / 'file').write_text('fixture\n')
    ok, _ = run(source / '.agents/tests/run-all.sh', env={**clean, **variables, 'FIXTURE_REPO': str(fixture), 'REHEARSAL_JOBS': '1'})
    assert ok, 'runner changed the canary'
    print('ok: real runner executes a fixture and leaves canary unchanged', flush=True)
    # The real assembly runs in a disposable source repository with nested jobs stubbed.
    shutil.copy2(root / '.agents/tools/rehearse-merged-tree.sh', source / '.agents/tools/rehearse-merged-tree.sh')
    for name in ('build-adapters.sh', 'validate-kit.sh'):
        (source / '.agents/tools' / name).write_text('#!/bin/sh\nexit 0\n')
        (source / '.agents/tools' / name).chmod(0o755)
    (source / '.agents/tests/run-all.sh').write_text('#!/bin/sh\nexit 0\n')
    (source / 'templates/nextjs-postgres/package.json').write_text('{}\n')
    # The rehearsal also builds the site; npm is stubbed below, so a manifest and a stub link check suffice.
    (source / 'site').mkdir(exist_ok=True)
    (source / 'site/package.json').write_text('{}\n')
    (source / '.agents/tests/site-links.sh').write_text('#!/bin/sh\nexit 0\n')
    (source / '.agents/tests/site-links.sh').chmod(0o755)
    git(source, 'init', '-q')
    git(source, 'add', '.')
    git(source, 'commit', '-qm', 'fixture')
    git(source, 'update-ref', 'refs/remotes/origin/main', 'HEAD')
    bindir = work / 'bin'
    bindir.mkdir()
    for name in ('npm', 'docker', 'npx'):
        p = bindir / name
        p.write_text('#!/bin/sh\nexit 0\n')
        p.chmod(0o755)
    assembly_env = {**clean, **variables, 'PATH': str(bindir) + os.pathsep + clean['PATH']}
    ok, result = run(source / '.agents/tools/rehearse-merged-tree.sh', ['--allow-dirty', work / 'assembled'], assembly_env)
    assert ok and 'Committed ' in result.stdout and (work / 'assembled/.git/index').exists(), 'assembly did not complete safely'
    print('ok: real merged-tree assembly leaves canary unchanged', flush=True)
    # Run each preparation against a fresh local project and local bare remote.
    prepare = root / '.agents/tests/replay/prepare'
    for index, script in enumerate(sorted(prepare.glob('*.sh'))):
        project = work / f'project-{index}'
        project.mkdir()
        (project / 'app').mkdir()
        (project / 'app/overdue-list.txt').write_text('fixture\n')
        (project / 'CHANGELOG.md').write_text('# Changes\n')
        git(project, 'init', '-q')
        git(project, 'add', '.')
        git(project, 'commit', '-qm', 'fixture')
        remote = work / f'remote-{index}.git'
        git(work, 'init', '-q', '--bare', str(remote))
        git(project, 'remote', 'add', 'origin', str(remote))
        ok, result = run(script, [project, root], require_success=False)
        assert ok, f'{script.name} changed the canary'
        if script.name == 'unattended-opt-in.after-commit.sh':
            assert result.returncode == 0, result.stdout
    masterplan = work / 'legacy-masterplan.md'
    masterplan.write_text('## Build path\n')
    before = snapshot()
    result = subprocess.run(['python3', str(prepare / 'legacy-masterplan.py'), str(masterplan)],
                            env={**clean, **variables}, capture_output=True, text=True)
    assert result.returncode == 0 and before == snapshot(), 'legacy preparation changed the canary or failed'
    print('ok: replay preparation entry points leave canary unchanged (fixture prerequisites vary)', flush=True)
    # Exercise mutations against a real check that writes global configuration.
    skills = source / '.agents/skills'
    skills.symlink_to(root / '.agents/skills', target_is_directory=True)
    original = (root / '.agents/tests/push-guard.sh').read_text()
    line = next(line for line in original.splitlines() if line.startswith('unset GIT_DIR '))
    config_before = (gd / 'config').read_bytes()
    for name, replacement in [('missing', ':'), ('reassigned', line + '\nexport GIT_CONFIG_GLOBAL="$CANARY_CONFIG"')]:
        (gd / 'config').write_bytes(config_before)
        target = source / '.agents/tests/push-guard.sh'
        target.write_text(original.replace(line, replacement, 1))
        env = {**clean, 'GIT_CONFIG_GLOBAL': str(gd / 'config'), 'CANARY_CONFIG': str(gd / 'config')}
        ok, _ = run(target, env=env, require_success=False)
        assert not ok, f'{name} mutation was not detected'
    print('ok: missing isolation and later reassignment change the canary', flush=True)
PY
