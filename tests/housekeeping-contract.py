#!/usr/bin/env python3
"""Validate public pins, locked graphs, documentation boundaries and fallbacks."""

import re
import shlex
import tomllib
from pathlib import Path
from urllib.parse import unquote, urlsplit

root = Path(__file__).resolve().parents[1]
config = tomllib.loads((root / "mise.toml").read_text())
locked = tomllib.loads((root / "mise.lock").read_text())["tools"]
tools = config["tools"]
versions = {
    name: spec["version"] if isinstance(spec, dict) else spec
    for name, spec in tools.items()
}
assert locked.keys() == versions.keys(), "lockfile tools must match public pins"
private_python = {
    spec["python"]
    for name, spec in tools.items()
    if name.startswith("pypi:") and isinstance(spec, dict) and "python" in spec
}
for name, pin in versions.items():
    expected = {pin} | (private_python if name == "python" else set())
    actual = [entry["version"] for entry in locked[name]]
    assert len(actual) == len(expected) and set(actual) == expected, name
browser_helper = tools["pypi:browser-use"]
assert browser_helper["python"] == "3.13.17"
# Every locked replay must reapply quarantine, using only the selected prefix.
assert shlex.split(browser_helper["postinstall"]) == [
    "python3",
    "-I",
    "-S",
    "$HOME/Developer/dotfiles/scripts/quarantine-browser-use.py",
    "$MISE_TOOL_INSTALL_PATH",
], "browser helper installs must fail closed through the quarantine hook"
assert (root / "scripts/quarantine-browser-use.py").is_file()

# Retain exact, hashed artifacts for the complete Python graph, including all
# direct requirements and the explicitly reviewed packaging-trust fixes.
requirements = (root / "config/python/requirements.txt").read_text()
logical_requirements = requirements.replace("\\\n", " ").splitlines()
package_pins = {}
for line in logical_requirements:
    if not line.strip() or line.startswith("#"):
        continue
    match = re.fullmatch(
        r"([A-Za-z0-9_.-]+)==([^\s]+)(?:\s+--hash=sha256:[0-9a-f]{64})+\s*",
        line,
    )
    assert match, "Python requirements must be exact pins with SHA-256 hashes"
    name, version = match.groups()
    assert name not in package_pins, f"duplicate Python requirement: {name}"
    package_pins[name] = version
for line in (root / "config/python/requirements.in").read_text().splitlines():
    if not line.strip() or line.startswith("#"):
        continue
    name, version = line.split("==")
    assert package_pins.get(name) == version, f"direct Python pin drift: {name}"
assert package_pins["pip"] == "26.2.2"
assert package_pins["certifi"] == "2026.10.19"
assert tomllib.loads((root / "mise.lock").read_text())["lockfile_version"] == 3
for name, kind in (
    ("npm:ctx7", "aube"),
    ("npm:@earendil-works/pi-coding-agent", "aube"),
    ("pypi:browser-use", "uv"),
    ("git-filter-repo", "uv"),
):
    graph = locked[name][0][kind]
    sidecar = root / graph["path"]
    assert sidecar.is_dir() and graph["digest"].startswith("sha256:"), name
    assert (sidecar / ("aube-lock.yaml" if kind == "aube" else "uv.lock")).is_file(), (
        name
    )

minimum = config["min_version"]["hard"]
readme = (root / "README.md").read_text()
maintenance = (root / "docs/maintenance.md").read_text()
assert f"mise {minimum} or newer" in readme, "README minimum mise version drift"
assert "--generate-hashes" in maintenance, "document hash-preserving Python lock refresh"
assert "mise --cd /tmp lock --global" in maintenance, "document safe lock refresh"
assert "--require-hashes" in (root / "scripts/setup-jupyter.sh").read_text()
bootstrap = (root / "scripts/test-bootstrap.sh").read_text()
assert '["min_version"]["hard"]' in bootstrap, "bootstrap must derive the minimum"
workflow = (root / ".github/workflows/validate.yml").read_text()
assert '["min_version"]["hard"]' in workflow, "CI must derive the minimum"

# Operational records are private; public docs describe reusable configuration.
for name in (
    "security-review-2026-10-23.md", "housekeeping-2026-10.md",
    "pi-1.2-upgrade-review.md", "migration-candidates.md",
):
    assert not (root / "docs" / name).exists(), f"operational note must stay private: {name}"

# Keep public navigation valid after moving historical records out of this tree.
for document in [root / "README.md", *sorted((root / "docs").glob("*.md"))]:
    for target in re.findall(r"(?<!!)\[[^\]]+\]\(([^)\s]+)\)", document.read_text()):
        parsed = urlsplit(target)
        if parsed.scheme or parsed.netloc or not parsed.path:
            continue
        destination = (document.parent / unquote(parsed.path)).resolve()
        assert destination.is_relative_to(root) and destination.exists(), (
            f"broken/non-public local documentation link in {document.name}: {target}"
        )
assert config["settings"]["minimum_release_age"] == "7d", (
    "security exception must not weaken release-age policy"
)
assert locked["git-filter-repo"][0]["backend"] == "pypi:git-filter-repo"

# Rex is an experiment: retain the stable terminal owners and their dotfiles.
assert "herdr" in tools, "retain Herdr as a fallback"
assert config["bootstrap"]["packages"]["brew-cask:ghostty"] == "latest"
assert config["dotfiles"]["~/.config/herdr/config.toml"]["source"].endswith(
    "/dotfiles/herdr/config.toml"
)
assert config["dotfiles"]["~/Library/Application Support/com.mitchellh.ghostty/config"][
    "source"
].endswith("/dotfiles/ghostty/config")
assert config["dotfiles"]["~/.config/rex/init.lua"]["source"].endswith(
    "/dotfiles/rex/init.lua"
)
assert "~/.config/rex" not in config["dotfiles"], (
    "do not replace Rex's personal config directory"
)
assert "experimental" in readme.lower() and "fallbacks" in readme.lower()

assert config["tasks"]["bootstrap"]["depends"] == ["bootstrap:public"]
public_steps = config["tasks"]["bootstrap:public"]["run"]
assert any("install-vscode-extensions.sh" in step for step in public_steps)
assert any("setup-jupyter.sh" in step for step in public_steps)
assert config["bootstrap"]["packages"]["brew:ripgrep"] == "latest"
assert (
    "/opt/homebrew/opt/postgresql@18/bin"
    in (root / "dotfiles/zsh/.zprofile").read_text()
)

lock_preview = config["tasks"]["tools:lock:dry-run"]["run"]
assert "mise --cd /tmp lock --global --dry-run --platform macos-arm64" in lock_preview
assert "MISE_LOCKED=0" in lock_preview
assert "--dry-run-code --locked" in config["tasks"]["tools:dry-run"]["run"]
print(f"Public pin/lock/documentation contract passed for {len(versions)} tools.")
