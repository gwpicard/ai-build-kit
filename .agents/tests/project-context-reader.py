"""Actual retrieval boundary; no stand-in decision or permission function."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
READER = Path(os.environ.get("ABK_CONTEXT_READER", ROOT / ".agents/skills/project-context/scripts/read-context.py"))

class ContextReader(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.write("masterplan.md", "<!-- ai-build-kit:records:v1 -->\n# Lending\nAn equipment desk.\n")
        self.write("docs/README.md", "[Access](access.md) owns permissions.\n[Identity](identity.md) owns active accounts.\n[Reports](reports.md) owns reporting.\n")
        self.write("docs/access.md", "# Access\n## Retirement\nOnly the custodian may retire equipment. Require [active identity](identity.md#active-accounts).\n## Other action\nUNRELATED_ACTION\n")
        self.write("docs/identity.md", "# Identity\n## Active accounts\nA suspended custodian may not act. See [retirement](access.md#retirement).\n## Profile\nUNRELATED_PROFILE\n")
        self.write("docs/reports.md", "# Reports\nUNRELATED_REPORT\n")

    def write(self, path, body):
        file = self.root / path
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(body)

    def run_reader(self, *sections):
        result = subprocess.run(["python3", str(READER), "--root", str(self.root), *sections], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def gap(self, *sections):
        result = subprocess.run(["python3", str(READER), "--root", str(self.root), *sections], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Context gap:", result.stderr)
        self.assertEqual(result.stdout, "", "partial context must not appear successful")
        return result.stderr

    def test_permission_and_required_cross_reference_only(self):
        result = self.run_reader("docs/access.md#retirement")
        self.assertEqual([s["source"] for s in result["sections"]], ["docs/access.md#retirement", "docs/identity.md#active-accounts"])
        body = "\n".join(s["text"] for s in result["sections"])
        self.assertIn("Only the custodian", body)
        self.assertIn("suspended custodian", body)
        self.assertNotIn("UNRELATED", body)
        self.assertEqual(result["opened"], ["docs/access.md", "docs/identity.md"])

    def test_architecture_selection_and_current_resume(self):
        self.write("docs/architecture.md", "# Architecture\n## Retirement boundary\nThe queue enforces [retirement access](access.md#retirement).\n## Reporting\nUNRELATED_ARCHITECTURE\n")
        first = self.run_reader("docs/architecture.md#retirement-boundary")
        self.assertEqual(len(first["sections"]), 3)
        self.write("docs/identity.md", "# Identity\n## Active accounts\nA custodian must also have a current desk assignment.\n")
        resumed = self.run_reader("docs/architecture.md#retirement-boundary")
        self.assertIn("current desk assignment", json.dumps(resumed))
        self.assertNotIn("suspended custodian", json.dumps(resumed))
        self.assertNotIn("UNRELATED", json.dumps(resumed))

    def test_missing_rule_and_broken_cross_reference(self):
        self.assertIn("missing.md", self.gap("docs/missing.md#retirement"))
        self.assertIn("no-such-rule", self.gap("docs/access.md#no-such-rule"))
        self.write("docs/identity.md", "# Identity\n## Renamed\nActive.\n")
        self.assertIn("active-accounts", self.gap("docs/access.md#retirement"))

    def test_conflicting_rules_are_returned_without_adjudication(self):
        self.write("docs/identity.md", "# Identity\n## Active accounts\nAny borrower may retire equipment, even when suspended.\n")
        result = self.run_reader("docs/access.md#retirement")
        self.assertIn("Only the custodian", json.dumps(result))
        self.assertIn("Any borrower", json.dumps(result))
        self.assertNotIn("decision", result)
        self.assertEqual((self.root / "docs/identity.md").read_text(), "# Identity\n## Active accounts\nAny borrower may retire equipment, even when suspended.\n")

    def test_legacy_section_is_read_without_rewriting(self):
        legacy = "# Masterplan\n## Permissions\nOnly the custodian acts.\n## Unrelated\nUNRELATED_LEGACY\n"
        self.write("masterplan.md", legacy)
        result = self.run_reader("masterplan.md#permissions")
        self.assertIn("Only the custodian", json.dumps(result))
        self.assertNotIn("UNRELATED", json.dumps(result))
        self.assertEqual((self.root / "masterplan.md").read_text(), legacy)

    def test_explicit_whole_document_and_fenced_examples(self):
        self.write("docs/identity.md", "# Identity\nFull rule.\n```md\n[Example](missing.md)\n```\n")
        self.write("docs/access.md", "# Access\n## Retirement\nRead [identity](identity.md).\n")
        result = self.run_reader("docs/access.md#retirement")
        self.assertEqual(result["sections"][1]["source"], "docs/identity.md")
        self.assertIn("Full rule", json.dumps(result))

    def test_escape_and_redirected_documents_are_gaps(self):
        self.write("outside.md", "# Outside\n")
        self.assertIn("outside", self.gap("../outside.md"))
        (self.root / "docs/link.md").symlink_to(self.root / "outside.md")
        self.assertIn("link", self.gap("docs/link.md"))

if __name__ == "__main__":
    unittest.main()
