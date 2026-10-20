#!/usr/bin/env python3
"""Read-only ownership inventory. Never installs, upgrades, removes, or sources RC files."""

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MISE_IDS = {
    "pi": "npm:@earendil-works/pi-coding-agent",
    "tectonic": "github:tectonic-typesetting/tectonic",
    "ctx7": "npm:ctx7",
    "browser-use": "pypi:browser-use",
}
BREW_NAMES = {"openjdk": "java", "tree-sitter-cli": "tree-sitter"}


def display_path(path, home):
    """Keep local inventory useful without printing the home directory's identity."""
    if not path:
        return None
    path = Path(path)
    try:
        return "~/" + str(path.relative_to(home))
    except ValueError:
        return str(path)


def belongs_to(path, directory):
    if not path or not directory:
        return False
    # Both lexical paths and resolved symlinks matter (npm bins and JDK bundles).
    path, directory = Path(path), Path(directory)
    return path.is_relative_to(directory) or path.resolve().is_relative_to(
        directory.resolve()
    )


def installed_consumers(formulae):
    """Use installed receipts, not just today's possibly different formula recipe."""
    consumers = {}
    for formula in formulae:
        receipts = formula.get("installed", [])
        recorded = [entry for entry in receipts if "runtime_dependencies" in entry]
        if recorded:
            dependencies = {
                dep["full_name"]
                for entry in recorded
                for dep in entry["runtime_dependencies"]
            }
            # Be conservative about older receipts lacking dependency metadata.
            if len(recorded) != len(receipts):
                dependencies.update(formula.get("dependencies", []))
        else:
            dependencies = set(formula.get("dependencies", []))
        for dependency in dependencies:
            consumers.setdefault(dependency, set()).add(formula["name"])
    return consumers


def make_report(ownership, mise, brew, *, which=shutil.which, home=None):
    home = Path.home() if home is None else Path(home)
    commands = []
    for package, names in ownership["mise"].items():
        candidates = mise.get(MISE_IDS.get(package, package), [])
        selected = next(
            (x for x in candidates if x.get("active") and x.get("installed")), None
        )
        for name in names:
            executable = which(name)
            if selected is None:
                status = "owner-not-installed"
            elif not executable:
                status = "missing-command"
            elif belongs_to(executable, selected.get("install_path")):
                status = "mise"
            else:
                status = "outside-selected-install"
            commands.append(
                {
                    "command": name,
                    "owner": f"mise:{package}",
                    "version": selected.get("version") if selected else None,
                    "path": display_path(executable, home),
                    "status": status,
                }
            )

    formulae = brew.get("formulae", [])
    consumers = installed_consumers(formulae)
    duplicates = []
    for formula in formulae:
        name = formula["name"]
        base = name.split("@", 1)[0]
        owner = BREW_NAMES.get(base, base)
        if owner not in ownership["mise"]:
            continue
        users = sorted(consumers.get(formula.get("full_name", name), set()))
        duplicates.append(
            {
                "formula": name,
                "intended_owner": f"mise:{owner}",
                "installed_versions": [
                    x["version"] for x in formula.get("installed", [])
                ],
                "brew_consumers": users,
                "classification": "retained-dependency"
                if users
                else "review-for-removal",
            }
        )

    declared_roots = set(ownership["brew"]) | set(ownership["mise"])
    declared_roots |= set(BREW_NAMES)
    extra_formulae = sorted(
        f["name"]
        for f in formulae
        if f["name"] not in declared_roots
        and any(x.get("installed_on_request") for x in f.get("installed", []))
    )
    extra_casks = sorted(
        c.get("token", c.get("full_token", "unknown"))
        for c in brew.get("casks", [])
        if c.get("token", c.get("full_token")) not in ownership["brew-cask"]
    )
    legacy_locations = (
        ".nvm",
        ".pyenv",
        ".rbenv",
        ".rustup",
        ".cargo/bin",
        "miniconda3",
        "anaconda3",
        ".local/pipx/venvs",
        ".local/share/pipx/venvs",
    )
    return {
        "commands": commands,
        "brew_duplicates": sorted(duplicates, key=lambda x: x["formula"]),
        "additional_requested_formulae": extra_formulae,
        "additional_casks": extra_casks,
        "legacy_locations_present": [
            display_path(home / name, home)
            for name in legacy_locations
            if (home / name).is_dir()
        ],
        "limitations": [
            "PATH inventory only: shell aliases/functions and private RC files are not inspected.",
            "No Brew consumers does not prove no project, script, venv or external app uses a tool.",
            "Legacy directories may be in use; their contents and credentials are not read.",
            "Additional apps/packages are decisions to reconcile, not automatic removal targets.",
        ],
    }


def metadata(argv):
    try:
        result = subprocess.run(
            argv, capture_output=True, text=True, check=True, timeout=90
        )
        return json.loads(result.stdout)
    except FileNotFoundError as exc:
        raise ValueError(f"required inventory command unavailable: {argv[0]}") from exc
    except (subprocess.SubprocessError, ValueError) as exc:
        # Do not echo raw subprocess output: it may include private configuration.
        raise ValueError(
            f"could not collect valid {argv[0]} inventory; no changes applied"
        ) from exc


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--json",
        action="store_true",
        help="print metadata only; do not write a report file",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="exit 1 for missing/shadowed mise-owned commands",
    )
    args = parser.parse_args(argv)
    try:
        ownership = json.loads((ROOT / "docs/tool-ownership.json").read_text())
        mise = metadata(["mise", "--cd", str(ROOT), "ls", "--current", "--json"])
        # info --installed is a query, not an upgrade/update/install command.
        brew = metadata(["brew", "info", "--json=v2", "--installed"])
        if not isinstance(mise, dict) or not isinstance(brew, dict):
            raise ValueError("inventory must contain JSON objects")
        report = make_report(ownership, mise, brew)
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as exc:
        print(f"Ownership audit failed: {exc}", file=sys.stderr)
        return 2
    attention = [x for x in report["commands"] if x["status"] != "mise"]
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print("Read-only ownership audit; no installations or configuration changed.")
        print(
            f"Mise commands: {len(report['commands']) - len(attention)}/{len(report['commands'])} resolve inside their selected installation."
        )
        for command in attention:
            print(
                f"  CHECK {command['command']}: {command['status']} ({command['path'] or 'not on PATH'})"
            )
        print("\nHomebrew duplicates of mise-owned tools:")
        for item in report["brew_duplicates"]:
            consumers = (
                ", ".join(item["brew_consumers"])
                or "none recorded; external use still needs review"
            )
            print(
                f"  {item['formula']}: {item['classification']}; consumers: {consumers}"
            )
        print(
            "\nAdditional requested formulae: "
            + (", ".join(report["additional_requested_formulae"]) or "none")
        )
        print("Additional casks: " + (", ".join(report["additional_casks"]) or "none"))
        print(
            "Legacy locations present: "
            + (", ".join(report["legacy_locations_present"]) or "none")
        )
        for limitation in report["limitations"]:
            print(f"  Note: {limitation}")
    return 1 if args.strict and attention else 0


if __name__ == "__main__":
    sys.exit(main())
