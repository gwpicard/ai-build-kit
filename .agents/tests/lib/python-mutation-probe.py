#!/usr/bin/env python3
"""Check that the local Python mutation tool can run independently of the kit."""

from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def probe(tool):
    executable = shutil.which(tool)
    if not executable:
        return f"{tool} is not installed or is not executable"
    with tempfile.TemporaryDirectory() as folder:
        root = Path(folder)
        (root / "shop").mkdir()
        (root / "shop/__init__.py").write_text("")
        (root / "shop/value.py").write_text("def value(n):\n    return n + 1\n")
        (root / "tests").mkdir()
        (root / "tests/test_value.py").write_text(
            "from shop.value import value\n\ndef test_value():\n    assert value(1) == 2\n")
        (root / "pyproject.toml").write_text(
            '[project]\nname = "shop"\nversion = "0.1.0"\n'
            '\n[tool.mutmut]\nsource_paths = ["shop"]\npaths_to_mutate = ["shop"]\n')
        (root / "setup.cfg").write_text(
            '[mutmut]\nsource_paths = shop\npaths_to_mutate = shop\n')
        try:
            result = subprocess.run([executable, "run", "shop.value.x_value__mutmut_*"], cwd=root, capture_output=True,
                                    text=True, timeout=120)
        except (OSError, subprocess.TimeoutExpired) as error:
            return f"mutmut could not start or finish its independent baseline: {error}"
        if result.returncode:
            lines = (result.stderr or result.stdout).strip().splitlines()
            detail = ": " + lines[-1][:200] if lines else " (no diagnostic output)"
            return f"mutmut's independent baseline exited {result.returncode}{detail}"
    return None


if __name__ == "__main__":
    reason = probe(sys.argv[1] if len(sys.argv) > 1 else "mutmut")
    if reason:
        print(f"could-not-run: Python mutation checks could not run here: {reason}")
        sys.exit(2)
