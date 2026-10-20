#!/usr/bin/env python3
"""Synthetic inventory tests only: no package manager or real HOME access."""

import importlib.util
import io
import subprocess
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "tool_audit",
    Path(__file__).resolve().parents[1] / "scripts/audit-tool-ownership.py",
)
assert spec is not None and spec.loader is not None
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class AuditContract(unittest.TestCase):
    def test_selected_path_and_missing_or_shadowed_commands(self):
        ownership = {
            "mise": {"node": ["node", "npm", "npx"]},
            "brew": {},
            "brew-cask": {},
        }
        mise = {
            "node": [
                {
                    "version": "24.21.0",
                    "active": True,
                    "installed": True,
                    "install_path": "/synthetic/mise/node/24.21.0",
                }
            ]
        }
        paths = {
            "node": "/synthetic/mise/node/24.21.0/bin/node",
            "npm": "/synthetic/brew/bin/npm",
        }
        report = audit.make_report(
            ownership, mise, {}, which=paths.get, home="/synthetic/home"
        )
        self.assertEqual(
            [x["status"] for x in report["commands"]],
            ["mise", "outside-selected-install", "missing-command"],
        )

    def test_expected_owner_must_be_actually_installed(self):
        ownership = {"mise": {"node": ["node"]}, "brew": {}, "brew-cask": {}}
        mise = {"node": [{"active": True, "installed": False, "version": "24"}]}
        report = audit.make_report(
            ownership,
            mise,
            {},
            which=lambda _: "/synthetic/brew/bin/node",
            home="/synthetic/home",
        )
        self.assertEqual(report["commands"][0]["status"], "owner-not-installed")

    def test_explicit_backend_names_and_bin_symlinks(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            install = home / "mise/pi"
            install.mkdir(parents=True)
            binary = install / "pi"
            binary.write_text("synthetic")
            link = home / "bin/pi"
            link.parent.mkdir()
            link.symlink_to(binary)
            ownership = {"mise": {"pi": ["pi"]}, "brew": {}, "brew-cask": {}}
            mise = {
                "npm:@earendil-works/pi-coding-agent": [
                    {
                        "active": True,
                        "installed": True,
                        "version": "1.3.0",
                        "install_path": str(install),
                    }
                ]
            }
            report = audit.make_report(
                ownership, mise, {}, which=lambda _: str(link), home=home
            )
            self.assertEqual(report["commands"][0]["status"], "mise")
            self.assertEqual(report["commands"][0]["path"], "~/bin/pi")

    def test_installed_receipts_override_new_recipe_python_dependency(self):
        formulae = [
            {
                "name": "consumer",
                "dependencies": ["python@3.15"],
                "installed": [
                    {
                        "version": "1",
                        "runtime_dependencies": [{"full_name": "python@3.14"}],
                    }
                ],
            },
            {
                "name": "older-receipt",
                "dependencies": ["node"],
                "installed": [{"version": "1"}],
            },
        ]
        consumers = audit.installed_consumers(formulae)
        self.assertEqual(consumers["python@3.14"], {"consumer"})
        self.assertNotIn("python@3.15", consumers)
        self.assertEqual(consumers["node"], {"older-receipt"})

    def test_dependency_duplicates_and_optional_apps_are_not_removal_proofs(self):
        ownership = {
            "mise": {"python": [], "gh": []},
            "brew": {},
            "brew-cask": {"ghostty": []},
        }
        brew = {
            "formulae": [
                {"name": "python@3.14", "installed": [{"version": "3.14.3"}]},
                {
                    "name": "consumer",
                    "dependencies": ["python@3.14"],
                    "installed": [{"version": "1"}],
                },
                {"name": "gh", "installed": [{"version": "2"}]},
            ],
            "casks": [{"token": "ghostty"}, {"token": "anaconda"}],
        }
        report = audit.make_report(
            ownership, {}, brew, which=lambda _: None, home="/synthetic/home"
        )
        rows = {x["formula"]: x for x in report["brew_duplicates"]}
        self.assertEqual(rows["python@3.14"]["classification"], "retained-dependency")
        self.assertEqual(rows["gh"]["classification"], "review-for-removal")
        self.assertEqual(report["additional_casks"], ["anaconda"])
        self.assertTrue(any("does not prove" in x for x in report["limitations"]))

    def test_inventory_subprocesses_are_queries_only(self):
        with patch.object(
            audit.subprocess, "run", return_value=SimpleNamespace(stdout="{}")
        ) as run:
            audit.metadata(["brew", "info", "--json=v2", "--installed"])
            self.assertEqual(
                run.call_args.args[0], ["brew", "info", "--json=v2", "--installed"]
            )
            self.assertTrue(run.call_args.kwargs["capture_output"])
        with (
            tempfile.TemporaryDirectory() as tmp,
            patch.object(audit.Path, "home", return_value=Path(tmp)),
            patch.object(audit, "metadata", return_value={}) as collect,
            patch("sys.stdout", new_callable=io.StringIO),
        ):
            self.assertEqual(audit.main(["--json"]), 0)
            self.assertEqual(
                collect.call_args_list[0].args[0],
                ["mise", "--cd", str(audit.ROOT), "ls", "--current", "--json"],
            )
            self.assertEqual(
                collect.call_args_list[1].args[0],
                ["brew", "info", "--json=v2", "--installed"],
            )

    def test_strict_mode_fails_when_owner_is_missing(self):
        with (
            tempfile.TemporaryDirectory() as tmp,
            patch.object(audit.Path, "home", return_value=Path(tmp)),
            patch.object(audit, "metadata", return_value={}),
            patch("sys.stdout", new_callable=io.StringIO),
        ):
            self.assertEqual(audit.main(["--strict"]), 1)

    def test_legacy_directory_presence_does_not_read_contents(self):
        with tempfile.TemporaryDirectory() as tmp:
            (Path(tmp) / ".nvm").mkdir()
            ownership = {"mise": {}, "brew": {}, "brew-cask": {}}
            with patch.object(
                audit.Path,
                "read_text",
                side_effect=AssertionError("unexpected file read"),
            ):
                report = audit.make_report(ownership, {}, {}, home=tmp)
            self.assertEqual(report["legacy_locations_present"], ["~/.nvm"])

    def test_failures_do_not_dump_private_subprocess_diagnostics(self):
        failure = subprocess.CalledProcessError(
            2, ["mise"], stderr="private diagnostic"
        )
        with (
            patch.object(audit.subprocess, "run", side_effect=failure),
            self.assertRaisesRegex(ValueError, "no changes applied") as caught,
        ):
            audit.metadata(["mise", "ls", "--json"])
        self.assertNotIn("private diagnostic", str(caught.exception))


if __name__ == "__main__":
    unittest.main()
