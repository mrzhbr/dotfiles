#!/usr/bin/env python3
"""Synthetic program-only quarantine regression; no browser/profile access."""

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

# Keep the source checkout inert even when invoked with Python -I (ignores env).
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "quarantine", ROOT / "scripts/quarantine-browser-use.py"
)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class QuarantineContract(unittest.TestCase):
    def fixture(self, root):
        site = root / ".mise-uv/.venv/lib/python3.13/site-packages"
        for name, version in (
            ("browser_use", "0.13.11"),
            ("browser_harness", "0.1.13"),
        ):
            (site / f"{name}-{version}.dist-info").mkdir(parents=True)
            (site / name).mkdir()
            (site / name / "__init__.py").write_text("ORIGINAL = True\n")
        return site

    def test_blocks_both_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            site = self.fixture(root)
            module.quarantine(root)
            module.quarantine(root)
            for name in ("browser_use", "browser_harness"):
                target = site / name / "__init__.py"
                result = subprocess.run(
                    [sys.executable, "-I", "-S", str(target)],
                    capture_output=True,
                    text=True,
                    check=False,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("quarantined", result.stderr)
                self.assertEqual(
                    target.with_name(
                        "__init__.py.security-disabled-original"
                    ).read_text(),
                    "ORIGINAL = True\n",
                )
            self.assertTrue((root / ".security-quarantine.json").exists())

    def test_refuses_unknown_version_without_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            site = self.fixture(root)
            (site / "browser_harness-0.1.13.dist-info").rename(
                site / "browser_harness-0.2.0.dist-info"
            )
            with self.assertRaisesRegex(RuntimeError, "versions"):
                module.quarantine(root)
            self.assertEqual(
                (site / "browser_use/__init__.py").read_text(), "ORIGINAL = True\n"
            )

    def test_refuses_symlinked_namespace_without_partial_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            site = self.fixture(root)
            namespace = site / "browser_harness"
            namespace.rename(root / "external")
            namespace.symlink_to(root / "external", target_is_directory=True)
            with self.assertRaisesRegex(RuntimeError, "entrypoint"):
                module.quarantine(root)
            self.assertEqual(
                (site / "browser_use/__init__.py").read_text(), "ORIGINAL = True\n"
            )
            self.assertEqual(
                (root / "external/__init__.py").read_text(), "ORIGINAL = True\n"
            )

    def test_refuses_marker_symlink_before_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "selected-tool"
            root.mkdir()
            site = self.fixture(root)
            outside = Path(tmp) / "outside.txt"
            outside.write_text("PRESERVE\n")
            (root / ".security-quarantine.json").symlink_to(outside)
            with self.assertRaisesRegex(RuntimeError, "marker"):
                module.quarantine(root)
            self.assertEqual(outside.read_text(), "PRESERVE\n")
            for namespace in ("browser_use", "browser_harness"):
                self.assertEqual(
                    (site / namespace / "__init__.py").read_text(), "ORIGINAL = True\n"
                )

    def test_refuses_namespace_symlink_even_inside_site(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            site = self.fixture(root)
            namespace = site / "browser_harness"
            namespace.rename(site / "original_harness")
            namespace.symlink_to(site / "original_harness", target_is_directory=True)
            with self.assertRaisesRegex(RuntimeError, "entrypoint"):
                module.quarantine(root)
            self.assertEqual(
                (site / "browser_use/__init__.py").read_text(), "ORIGINAL = True\n"
            )
            self.assertEqual(
                (site / "original_harness/__init__.py").read_text(), "ORIGINAL = True\n"
            )


if __name__ == "__main__":
    unittest.main()
