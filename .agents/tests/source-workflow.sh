#!/usr/bin/env sh
# source-workflow.sh: reject a bypass of the starter gate or a duplicate pull-request run.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
python3 - "$ROOT" <<'PY'
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
validator = (root / '.agents/tools/validate-kit.sh').read_text()
contract = validator.split("cat > \"$py_script\" <<'PYEOF'\nimport os, sys, yaml\nerrors = []\n", 1)[1].split('\nPYEOF', 1)[0]
contract = 'import os, sys, yaml\nerrors = []\n' + contract

def read_yaml(path):
    return json.loads(subprocess.check_output(['ruby', '-ryaml', '-rjson', '-e',
        'puts JSON.generate(YAML.load_file(ARGV[0]))', str(path)], text=True))

source = read_yaml(root / '.github/workflows/source-checks.yml')
starter = read_yaml(root / '.github/workflows/postgres-starter.yml')
foundation = read_yaml(root / '.agents/skills/setup-ai-build-kit/templates/foundation/checks.yml')
# Ruby's YAML reader, like PyYAML, may treat the on key as a boolean.
for doc in (source, starter):
    if 'true' in doc:
        doc['on'] = doc.pop('true')
with tempfile.TemporaryDirectory() as folder:
    work = Path(folder)
    # JSON is a YAML subset. This keeps the contract test available without PyYAML.
    (work / 'yaml.py').write_text('import json\nsafe_load = json.load\n')
    (work / 'contract.py').write_text(contract)
    (work / 'foundation.json').write_text(json.dumps(foundation))
    def run(label, src, template, expected):
        (work / 'source.json').write_text(json.dumps(src))
        (work / 'postgres-starter.yml').write_text(json.dumps(template))
        ran = subprocess.run([sys.executable, str(work / 'contract.py'), str(work / 'source.json'),
            str(work / 'foundation.json'), str(root / '.agents/tests')], capture_output=True, text=True)
        assert (ran.returncode == 0) == expected, (label, ran.stdout, ran.stderr)
        print('ok: ' + label)
    run('the source and starter workflows satisfy the gate', source, starter, True)
    faults = [
        ('missing dependency', lambda d: d['jobs']['source-kit-validation'].pop('needs')),
        ('skipped required check', lambda d: d['jobs']['source-kit-validation'].update({'if': "github.repository == 'gwpicard/ai-build-kit'"})),
        ('path-filtered source', lambda d: d['on'].update({'pull_request': {'paths': ['docs/**']}})),
        ('missing pull-request trigger', lambda d: d['on'].pop('pull_request')),
        ('optional starter', lambda d: d['jobs']['postgres-starter'].update({'if': 'false'})),
        ('longer timeout', lambda d: d['jobs']['rehearsal'].update({'timeout-minutes': 40})),
        ('non-blocking gate', lambda d: next(s for s in d['jobs']['source-kit-validation']['steps'] if s.get('name') == 'Require the starter checks').update({'continue-on-error': True})),
    ]
    for label, mutate in faults:
        changed = copy.deepcopy(source)
        mutate(changed)
        run(label, changed, starter, False)
    changed = copy.deepcopy(starter)
    changed['on']['pull_request'] = None
    run('duplicate starter pull-request trigger', source, changed, False)
    changed = copy.deepcopy(starter)
    changed['on'].pop('workflow_call')
    run('uncallable starter', source, changed, False)
    gate = next(s for s in source['jobs']['source-kit-validation']['steps'] if s.get('name') == 'Require the starter checks')
    for result in ('success', 'failure', 'cancelled', 'skipped', ''):
        ran = subprocess.run(['sh', '-c', gate['run']], env=dict(os.environ, STARTER_RESULT=result))
        assert (ran.returncode == 0) == (result == 'success')
    print('ok: the actual gate command accepts only success')
PY
