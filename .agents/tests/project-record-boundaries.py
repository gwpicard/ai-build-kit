"""Regression cases against the shipped record readers and local Git histories."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
FOUNDATION = ROOT / '.agents/skills/setup-ai-build-kit/templates/foundation'
spec = importlib.util.spec_from_file_location('records', FOUNDATION / 'project-records.py')
records = importlib.util.module_from_spec(spec)
spec.loader.exec_module(records)


class RecordBoundaries(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.p = Path(self.temp.name)
        (self.p / 'docs').mkdir()
        (self.p / '.agents/tools').mkdir(parents=True)
        self.normal = records.MARKER + '\n# Lending\nStaff borrow equipment. [Rules](docs/README.md) names the owner.\n'
        (self.p / 'masterplan.md').write_text(self.normal)
        (self.p / 'docs/README.md').write_text('[Permissions](permissions.md): who may retire items.\n')
        (self.p / 'docs/permissions.md').write_text('Only the custodian may retire items.\n')
        (self.p / 'docs/working-rules.md').write_text('Path: Build with care\n')
        (self.p / 'docs/operations.md').write_text('Goes live: on every merge\n')
        self.sensitive = self.p / '.agents/tools/check-sensitive-areas.sh'
        self.sensitive.write_text((FOUNDATION / 'check-sensitive-areas.sh').read_text())

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.p), *args], text=True).strip()

    def repository(self):
        self.git('init', '-q', '-b', 'main')
        self.git('config', 'user.name', 'Record rehearsal')
        self.git('config', 'user.email', 'record@example.invalid')
        self.git('config', 'commit.gpgsign', 'false')
        self.git('add', '.')
        self.git('commit', '-qm', 'Initial saved state')
        records.save_review(self.p, self.git('rev-parse', 'HEAD'), True)
        self.git('add', '.')
        self.git('commit', '-qm', 'Completed record review')

    def test_behavioral_markdown_is_work(self):
        skill = self.p / '.agents/skills/permission/SKILL.md'
        skill.parent.mkdir(parents=True)
        skill.write_text('Ask before permission changes.\n')
        self.repository()
        skill.write_text('Change permissions without asking.\n')
        with self.assertRaises(ValueError):
            records.save_review(self.p, self.git('rev-parse', 'HEAD'), True)
        self.git('add', '.')
        self.git('commit', '-qm', 'Change permission behaviour')
        self.assertEqual(records.review_gap(self.p)['changes'], 1)

    def test_only_known_records_are_corrections(self):
        self.repository()
        (self.p / 'docs/permissions.md').write_text('The custodian retires items after return.\n')
        records.save_review(self.p, self.git('rev-parse', 'HEAD'), True)
        self.git('add', '.')
        self.git('commit', '-qm', 'Correct indexed permission owner')
        self.assertEqual(records.review_gap(self.p)['changes'], 0)
        (self.p / 'notes.md').write_text('An unrelated change.\n')
        with self.assertRaises(ValueError):
            records.save_review(self.p, self.git('rev-parse', 'HEAD'), True)
        self.git('add', '.')
        self.git('commit', '-qm', 'Unrelated Markdown work')
        self.assertEqual(records.review_gap(self.p)['changes'], 1)

    def test_namespace_never_falls_back(self):
        for marker in ('<!-- ai-build-kit:records:v2-->', '<!-- ai-build-kit:records:v1-->',
                       records.MARKER + records.MARKER, records.MARKER + '\n' + records.MARKER,
                       'ai-build-kit:records:', '<!--ai-build-kit:records:v1 -->'):
            with self.subTest(marker=marker):
                (self.p / 'masterplan.md').write_text(marker + '\nPath: Explore privately\nGoes live: not hosted\n' + 'word ' * 510)
                for call in (lambda: records.field(self.p, 'Path'), lambda: records.field(self.p, 'Goes live'), lambda: records.validate(self.p)):
                    with self.assertRaises(ValueError):
                        call()
                self.assertNotEqual(subprocess.run(['sh', str(self.sensitive)], capture_output=True).returncode, 0)
        legacy = 'Path: Explore privately\nGoes live: not hosted\n'
        (self.p / 'masterplan.md').write_text(legacy)
        self.assertEqual(records.field(self.p, 'Path'), 'Explore privately')
        self.assertEqual(records.field(self.p, 'Goes live'), 'not hosted')
        self.assertEqual(subprocess.run(['sh', str(self.sensitive)], capture_output=True).returncode, 0)
        self.assertEqual((self.p / 'masterplan.md').read_text(), legacy)

    def test_retry_and_record_path_with_spaces(self):
        (self.p / 'docs/permission rules.md').write_text('A named owner.\n')
        (self.p / 'docs/README.md').write_text('[Rules](<permission rules.md>): access owner.\n')
        self.repository()
        current = self.git('rev-parse', 'HEAD')
        records.save_review(self.p, current, True)
        records.save_review(self.p, current, True)
        (self.p / 'docs/permission rules.md').write_text('A corrected named owner.\n')
        records.save_review(self.p, current, True)
        self.assertEqual(records.checkpoint(self.p), current)

    def test_link_labels_count_uniformly(self):
        for label in ('[Permission rule](docs/permissions.md)', '[Permission rule][permissions]\n\n[permissions]: docs/permissions.md', '[Permission rule][]\n\n[Permission rule]: docs/permissions.md', '[Permission rule]\n\n[Permission rule]: docs/permissions.md'):
            with self.subTest(label=label):
                (self.p / 'masterplan.md').write_text(records.MARKER + '\n' + 'word ' * 498 + label)
                self.assertEqual(records.validate(self.p), 500)
                (self.p / 'masterplan.md').write_text(records.MARKER + '\n' + 'word ' * 499 + label)
                with self.assertRaisesRegex(ValueError, '501'):
                    records.validate(self.p)

    def test_acceptance_reads_actual_owner(self):
        block = '# Working rules\nPath: Build with care\nSensitive areas:\n  Personal details; access review; done 2026-10-02\nAccepted: 2026-10-02, Owner, access review skipped\n'
        for mode in ('legacy', 'new'):
            with self.subTest(mode=mode):
                (self.p / 'masterplan.md').write_text(block if mode == 'legacy' else self.normal)
                (self.p / 'docs/working-rules.md').write_text(block)
                result = json.loads(subprocess.check_output([str(ROOT / '.agents/tests/replay/state-check.sh'), '3', str(self.p)], text=True))
                self.assertEqual(result['state_verdicts']['acceptance-record']['verdict'], 'hit')
                self.assertEqual(result['state_verdicts']['accepted-not-done']['verdict'], 'miss')

    def test_record_paths_are_local_and_not_redirected(self):
        self.repository()
        outside = self.p.parent / (self.p.name + '-outside.md')
        outside.write_text('Outside the project.\n')
        self.addCleanup(outside.unlink)
        for target in ('../' + outside.name, '/tmp/outside.md', 'https://example.invalid/rules.md'):
            (self.p / 'docs/README.md').write_text('[Rules](' + target + ') owns access.\n')
            with self.assertRaises(ValueError):
                records.save_review(self.p, self.git('rev-parse', 'HEAD'), True)
        (self.p / 'docs/README.md').write_text('[Rules](permissions.md) owns access.\n')
        (self.p / 'docs/permissions.md').unlink()
        (self.p / 'docs/permissions.md').symlink_to(outside)
        with self.assertRaises(ValueError):
            records.save_review(self.p, self.git('rev-parse', 'HEAD'), True)


if __name__ == '__main__':
    unittest.main()
