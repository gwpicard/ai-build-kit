#!/usr/bin/env sh
# merged-tree-rehearsal.sh: prove starter changes and stale reviews cannot escape the clean-copy rehearsal.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM GIT_IMPLICIT_WORK_TREE GIT_GRAFT_FILE GIT_PREFIX GIT_SHALLOW_FILE GIT_REPLACE_REF_BASE GIT_NO_REPLACE_OBJECTS GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'rm -R "$WORK"' EXIT INT TERM
python3 - "$ROOT" "$WORK" <<'PY'
from pathlib import Path
import os
import re
import subprocess
import sys

root, work = (Path(arg).resolve() for arg in sys.argv[1:])
source = work / 'source'
source.mkdir()

def write(name, text):
    target = source / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)
    target.chmod(0o755)

def git(*args):
    return subprocess.check_output(['git', '-C', str(source), *args], text=True).strip()

script = '.agents/tools/rehearse-merged-tree.sh'
write(script, (root / script).read_text())
for name in ('build-adapters.sh', 'validate-kit.sh'):
    write('.agents/tools/' + name, '#!/bin/sh\necho source-check >> "$CALLS"\n')
write('.agents/tests/run-all.sh', '#!/bin/sh\necho suite >> "$CALLS"\n')
write('templates/nextjs-postgres/package.json', '{}\n')
write('templates/nextjs-postgres/reviews/sign-in.json', 'pass\n')
write('templates/nextjs-postgres/scripts/test-database.mjs', '// fixture\n')
write('templates/nextjs-postgres/scripts/docker-run.sh', '''#!/bin/sh
echo "database $*" >> "$CALLS"
[ "$1" = -- ]
shift
exec "$@"
''')
git('init', '--quiet')
git('add', '.')
git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
    'commit', '--quiet', '-m', 'Baseline')
git('update-ref', 'refs/remotes/origin/main', 'HEAD')
bin_dir = work / 'bin'
bin_dir.mkdir()
for name, text in {
    'npm': '''#!/bin/sh
echo "npm $* $PWD" >> "$CALLS"
if [ "$*" = 'run check:sign-in-review' ]; then
  test "$(cat reviews/sign-in.json)" = pass
fi
''',
    'npx': '#!/bin/sh\necho "npx $*" >> "$CALLS"\n',
    'docker': '''#!/bin/sh
echo "docker $*" >> "$CALLS"
[ "$1" != info ] || [ "${DOCKER_DOWN:-0}" = 0 ]
''',
    'node': '#!/bin/sh\necho "node $*" >> "$CALLS"\nshift\nexec "$@"\n',
}.items():
    target = bin_dir / name
    target.write_text(text)
    target.chmod(0o755)

def run(name, expected, down=False):
    calls = work / (name + '.calls')
    env = {**os.environ, 'PATH': str(bin_dir) + os.pathsep + os.environ['PATH'],
           'CALLS': str(calls), 'CODEX_RUN_ID': 'fixture-run', 'DOCKER_DOWN': str(int(down))}
    tree = work / (name + '-tree')
    result = subprocess.run(['sh', str(source / script), '--allow-dirty', str(tree)],
                            env=env, capture_output=True, text=True)
    assert result.returncode == expected, result.stdout + result.stderr
    log = calls.read_text()
    assert 'npm ci ' + str(tree / 'templates/nextjs-postgres') in log
    assert 'npm run check:sign-in-review ' in log
    assert 'source-check' in log and 'suite' in log
    assert str(source / 'templates/nextjs-postgres') not in log
    return result.stdout, log

out, calls = run('unchanged', 0)
assert 'Skipped the full Postgres starter job:' in out
assert 'docker info' not in calls and 'npx ' not in calls
print('ok: unchanged starter checks its review in the clean copy and skips the full job')

write('templates/nextjs-postgres/reviews/sign-in.json', 'stale\n')
out, calls = run('stale', 1)
assert 'FAILED: postgres-starter/sign-in-review' in out
print('ok: a stale review fails the rehearsal')

write('templates/nextjs-postgres/reviews/sign-in.json', 'pass\n')
write('templates/nextjs-postgres/package.json', '{"changed":true}\n')
out, calls = run('changed', 0)
# Execute the workflow's run steps with the same stand-ins and compare every
# command, its arguments and order, including the locked install in the review step.
workflow = (root / '.github/workflows/postgres-starter.yml').read_text()
steps = re.findall(r'^        run: (.+(?:\n          .*)*)',
                   workflow, re.MULTILINE)
assert steps, 'the starter workflow has no run steps'
expected_calls = work / 'workflow.calls'
env = {**os.environ, 'PATH': str(bin_dir) + os.pathsep + os.environ['PATH'],
       'CALLS': str(expected_calls), 'CI': 'true', 'NEXT_TELEMETRY_DISABLED': '1'}
for step in steps:
    command = step if not step.startswith('|') else '\n'.join(
        line[10:] for line in step.splitlines()[1:])
    subprocess.run(['sh', '-eu', '-c', command],
                   cwd=work / 'changed-tree/templates/nextjs-postgres', env=env, check=True)
actual = '\n'.join(line for line in calls.splitlines()
                   if line not in ('source-check', 'suite', 'docker info')
                   and not line.startswith('npm run check:sign-in-review ')) + '\n'
assert actual == expected_calls.read_text(), actual
assert 'Skipped the full' not in out
print('ok: a changed starter runs the workflow commands with identical arguments and order')

out, calls = run('docker-down', 1, down=True)
assert 'could not run: postgres-starter/build-check: Docker' in out
assert 'npx ' not in calls
print('ok: unavailable Docker makes a required full job exit non-zero')

git('update-ref', '-d', 'refs/remotes/origin/main')
out, calls = run('no-upstream', 0)
assert 'origin/main is unavailable' in out and 'npm run test:image ' in calls
print('ok: missing upstream history requires the full job')
PY
