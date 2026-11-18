#!/usr/bin/env sh
# git-variable-isolation.sh: keep inherited Git repository settings out of check entry points.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -R "$WORK"' EXIT INT TERM
python3 - "$ROOT" "$WORK" <<'PY'
from pathlib import Path
import hashlib
import os
import subprocess
import sys

root, work = map(Path, sys.argv[1:])
canary = work / 'canary'
canary.mkdir()
def git(*args):
    subprocess.run(['git', '-C', str(canary), *args], check=True, stdout=subprocess.DEVNULL)
git('init', '-q')
(canary / 'file').write_text('canary\n')
git('add', 'file')
git('-c', 'user.name=Canary', '-c', 'user.email=canary@example.invalid', 'commit', '-qm', 'Canary')
gitdir = canary / '.git'
variables = {
    'GIT_DIR': str(gitdir), 'GIT_WORK_TREE': str(canary),
    'GIT_INDEX_FILE': str(gitdir / 'index'), 'GIT_COMMON_DIR': str(gitdir),
    'GIT_OBJECT_DIRECTORY': str(gitdir / 'objects'),
    'GIT_ALTERNATE_OBJECT_DIRECTORIES': str(gitdir / 'objects'),
    'GIT_CEILING_DIRECTORIES': str(work), 'GIT_DISCOVERY_ACROSS_FILESYSTEM': '1',
    'GIT_IMPLICIT_WORK_TREE': '0', 'GIT_GRAFT_FILE': str(work / 'grafts'),
    'GIT_PREFIX': 'canary/', 'GIT_SHALLOW_FILE': str(work / 'shallow'),
    'GIT_REPLACE_REF_BASE': 'refs/replace/', 'GIT_NO_REPLACE_OBJECTS': '1',
    'GIT_CONFIG': str(gitdir / 'config'), 'GIT_CONFIG_PARAMETERS': "'test.canary=value'",
    'GIT_CONFIG_COUNT': '1', 'GIT_CONFIG_KEY_0': 'test.canary', 'GIT_CONFIG_VALUE_0': 'value',
}
def snapshot():
    return {str(p.relative_to(gitdir)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in gitdir.rglob('*') if p.is_file() and
            (p.name in ('config', 'index', 'packed-refs', 'HEAD') or 'refs' in p.relative_to(gitdir).parts)}

# Run the entry point's real prologue, then exercise Git before its normal work.
# This avoids running the suite recursively or launching the merged-tree jobs.
probe = '''\nfor name in ''' + ' '.join(variables) + '''; do
  case "$name" in GIT_CONFIG_KEY_0|GIT_CONFIG_VALUE_0) continue ;; esac
  eval 'present=${'"$name"'+yes}'
  [ "${present:-}" != yes ] || exit 91
done
git init -q "$PROBE_REPO"
git -C "$PROBE_REPO" -c user.name=Probe -c user.email=probe@example.invalid commit --allow-empty -qm probe
exit 0
'''
entrypoints = sorted((root / '.agents/tests').glob('*.sh')) + [
    root / '.agents/tests/replay/run.sh', root / '.agents/tests/replay/testbed.sh',
    root / '.agents/tests/seeded/run.sh', root / '.agents/tools/validate-kit.sh',
    root / '.agents/tools/rehearse-merged-tree.sh']

def run(path, broken=False):
    lines = path.read_text().splitlines(keepends=True)
    boundary = next((i for i, line in enumerate(lines) if line.startswith('unset GIT_DIR ')), None)
    if boundary is None:
        raise RuntimeError(f'{path.relative_to(root)} has no isolation prologue')
    if broken:
        lines[boundary] = ':\n'
    script = work / 'probe.sh'
    script.write_text(''.join(lines[:boundary + 1]) + probe)
    fixture = work / 'fixture'
    if fixture.exists():
        import shutil
        shutil.rmtree(fixture)
    before = snapshot()
    result = subprocess.run(['sh', str(script)], env={**os.environ, **variables, 'PROBE_REPO': str(fixture)},
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return result.returncode == 0 and snapshot() == before

for entry in entrypoints:
    if not run(entry):
        raise SystemExit(f'FAIL: {entry.relative_to(root)} inherited Git settings or changed the canary')
if run(root / '.agents/tools/rehearse-merged-tree.sh', broken=True):
    raise SystemExit('FAIL: removing the isolation was not detected')
print(f'Git isolation passed for {len(entrypoints)} entry points; removing it was detected.')
PY
