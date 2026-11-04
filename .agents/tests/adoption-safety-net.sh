#!/usr/bin/env sh
# adoption-safety-net.sh: guards adoption baselines, permission regressions, coverage reports and fault-key isolation.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
. "$ROOT/.agents/tests/lib/could-not-run.sh"
command -v node >/dev/null 2>&1 || { could_not_run 'Node is needed for the adopted notebook'; finish_rehearsal; }
command -v python3 >/dev/null 2>&1 || { could_not_run 'Python is needed for adoption checks'; finish_rehearsal; }
python3 - "$ROOT" <<'PY'
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

root = Path(sys.argv.pop())
runner = root / '.agents/skills/quality-checks/scripts/adoption-safety-net.py'
seeded = root / '.agents/tests/seeded'
key = seeded / 'keys/adoption-permissions'


class Adoption(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name)
        shutil.copytree(seeded / 'adoption/project', self.project, dirs_exist_ok=True)
        self.source = (self.project / 'notes.mjs').read_bytes()
        (self.project / 'tests').mkdir()
        self.assertEqual(self.call('snapshot', 'notes.mjs').returncode, 0)
        # Only after the snapshot, add the tests a kit adoption would write.
        shutil.copytree(seeded / 'adoption/safety-net', self.project / 'tests', dirs_exist_ok=True)
        self.data = json.loads((self.project / 'adoption.json').read_text())
        for kind in ('permissions', 'journeys'):
            path = 'tests/' + kind + '.test.mjs'
            self.data[kind] = [{'behaviour': 'Notebook ' + kind,
                                'tests': [path], 'command': ['node', '--test', path]}]
        self.data['uncovered'] = ['Browser sign-in and session expiry', 'Persistent storage and outside connections']
        self.save()

    def save(self):
        (self.project / 'adoption.json').write_text(json.dumps(self.data))

    def call(self, action, *args):
        return subprocess.run([sys.executable, str(runner), action, 'adoption.json', *args],
                              cwd=self.project, text=True, capture_output=True)

    def test_baseline_passes_without_changing_original_code(self):
        result = self.call('baseline')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('# pass 5', result.stderr)
        self.assertIn('# pass 2', result.stderr)
        self.assertLess(result.stderr.index('anonymous people'), result.stderr.index('a member adds'))
        self.assertEqual((self.project / 'notes.mjs').read_bytes(), self.source)
        self.assertEqual(self.data['sources']['notes.mjs'], hashlib.sha256(self.source).hexdigest())

    def test_report_names_actual_gaps_and_does_not_approve_the_baseline(self):
        result = self.call('baseline')
        self.assertEqual(result.returncode, 0)
        for gap in self.data['uncovered']:
            self.assertIn(gap, result.stdout)
        self.assertIn('cannot vouch for code or behaviour these tests do not cover', result.stdout)
        self.assertIn('Recorded behaviour is not approved behaviour', result.stdout)
        self.assertIn('A test may be recording a fault', result.stdout)

    def test_planted_permission_change_fails_existing_tests(self):
        self.assertEqual(self.call('baseline').returncode, 0)
        subprocess.run([sys.executable, str(key / 'plant.py'), str(self.project)], check=True)
        result = self.call('check')
        self.assertEqual(result.returncode, 1)
        self.assertIn("not ok 2 - members see only their own team", result.stderr)
        self.assertIn("not ok 3 - members cannot change another team's note", result.stderr)
        self.assertIn('permissions: failed', result.stdout)
        self.assertIn('journeys: failed', result.stdout)
        self.assertIn(self.data['uncovered'][0], result.stdout)

    def test_changed_source_cannot_be_recorded_as_the_unchanged_baseline(self):
        subprocess.run([sys.executable, str(key / 'plant.py'), str(self.project)], check=True)
        result = self.call('baseline')
        self.assertEqual(result.returncode, 1)
        self.assertIn('existing code changed: notes.mjs', result.stdout)
        self.assertNotIn('TAP version', result.stderr)

    def test_a_test_that_changes_source_invalidates_the_baseline(self):
        self.data['permissions'][0]['command'] = [sys.executable, '-c',
            "from pathlib import Path; p=Path('notes.mjs'); p.write_text(p.read_text()+'\\n')"]
        self.save()
        result = self.call('baseline')
        self.assertEqual(result.returncode, 1)
        self.assertIn('existing code changed: notes.mjs', result.stdout)

    def test_missing_tests_or_permission_inventory_cannot_pass(self):
        for field in ('permissions', 'journeys'):
            original = self.data[field]
            self.data[field] = []
            self.save()
            self.assertEqual(self.call('baseline').returncode, 2)
            self.data[field] = original
        self.data['permissions'][0]['tests'] = ['tests/absent.mjs']
        self.save()
        self.assertEqual(self.call('baseline').returncode, 2)

    def test_unavailable_command_is_reported_and_never_passes(self):
        self.data['permissions'][0]['command'] = ['abk-command-that-does-not-exist']
        self.save()
        result = self.call('baseline')
        self.assertEqual(result.returncode, 2)
        self.assertIn('permissions: could not run', result.stdout)
        self.assertIn('journeys: passed', result.stdout)
        self.assertIn(self.data['uncovered'][0], result.stdout)

    def test_snapshot_cannot_overwrite_an_existing_record(self):
        before = (self.project / 'adoption.json').read_bytes()
        self.assertEqual(self.call('snapshot', 'notes.mjs').returncode, 2)
        self.assertEqual((self.project / 'adoption.json').read_bytes(), before)

    def test_fault_key_and_plant_never_reach_the_project(self):
        canary = next(line.split(': ', 1)[1] for line in (key / 'key.md').read_text().splitlines()
                      if line.startswith('canary:'))
        for folder in (self.project, seeded / 'adoption'):
            for path in folder.rglob('*'):
                if path.is_file():
                    self.assertNotIn(canary.encode(), path.read_bytes())
        self.assertFalse((self.project / 'keys').exists())
        self.assertFalse((self.project / 'plant.py').exists())
        self.assertFalse((self.project / 'key.md').exists())

    def test_no_known_gaps_does_not_claim_complete_coverage(self):
        self.data['uncovered'] = []
        self.save()
        result = self.call('baseline')
        self.assertEqual(result.returncode, 0)
        self.assertIn('not proof of complete coverage', result.stdout)


unittest.main(verbosity=2)
PY
