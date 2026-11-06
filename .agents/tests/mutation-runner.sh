#!/usr/bin/env sh
# mutation-runner.sh: distinguish detections, unavailable checks and failed baselines in the real runner.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 - "$ROOT" <<'PY'
import csv
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

source = Path(sys.argv[1]) / '.agents/tests/mutate.sh'
with tempfile.TemporaryDirectory(prefix='abk-mutation-runner-') as temporary:
    root = Path(temporary)
    repo = root / 'source'
    tests = repo / '.agents/tests'
    tests.mkdir(parents=True)
    shutil.copy2(source, tests / 'mutate.sh')
    target = repo / '.agents/skills/setup-ai-build-kit/scripts/bootstrap-project.sh'
    target.parent.mkdir(parents=True)
    target.write_text('[ ! -L "$current_parent" ] || exit 1\n')
    check = tests / 'starter-rehearsal.sh'
    check.write_text('''#!/bin/sh
cd "$(dirname "$0")/../.." || exit 99
if git diff --cached --quiet; then
  exit "$BASELINE_STATUS"
fi
exit "$CHECK_STATUS"
''')
    check.chmod(0o755)
    def git(*args):
        subprocess.run(['git', '-C', str(repo), *args], check=True, capture_output=True)
    git('init', '-q')
    git('add', '.')
    git('-c', 'user.name=Guillaume Picard', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'Prepare runner fixture')
    for baseline, status, expected, exit_code in ((0, 0, 'none', 0), (0, 1, 'starter-rehearsal', 0),
                                                (0, 2, 'NOT-RUN', 2), (0, 124, 'NOT-RUN', 2),
                                                (0, 127, 'NOT-RUN', 2), (0, 139, 'NOT-RUN', 2),
                                                (2, 1, 'NOT-RUN', 2), (1, 1, None, 1)):
        work = root / f'run-{baseline}-{status}'
        result = subprocess.run(['sh', str(tests / 'mutate.sh'), 'bootstrap-escape'], capture_output=True, text=True,
                                env={**os.environ, 'MUTATE_WORK': str(work), 'BASELINE_STATUS': str(baseline),
                                     'CHECK_STATUS': str(status)})
        assert result.returncode == exit_code, result.stdout + result.stderr
        with (work / 'report.tsv').open() as report:
            rows = list(csv.DictReader(report, delimiter='\t'))
        if expected is None:
            assert not rows, rows
        else:
            assert len(rows) == 1 and rows[0]['caught_by'] == expected, rows
            assert rows[0]['could_not_run'] == ('starter-rehearsal' if expected == 'NOT-RUN' else ''), rows
        if baseline == 2:
            assert not (work / 'bootstrap-escape-starter-rehearsal.log').exists(), 'unavailable baseline was retried'
print('PASS: only exit 1 detects; unavailable, timeout, missing runner and crash are separate; failed baseline stops')
PY
