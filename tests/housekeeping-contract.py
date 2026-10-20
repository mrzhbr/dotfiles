#!/usr/bin/env python3
"""Keep public pins, lock entries, minimum version and reviewed documentation aligned."""

import tomllib
from pathlib import Path

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
assert config["tools"]["pypi:browser-use"]["python"] == "3.13.16"
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
review = (root / "docs/housekeeping-2026-10.md").read_text()
assert f"mise {minimum} or newer" in readme, "README minimum mise version drift"
assert f"with mise {minimum}." in readme, "README runtime baseline version drift"
assert f"**{minimum}**" in review, "reviewed mise minimum version drift"
bootstrap = (root / "scripts/test-bootstrap.sh").read_text()
assert '["min_version"]["hard"]' in bootstrap, "bootstrap must derive the minimum"
workflow = (root / ".github/workflows/validate.yml").read_text()
assert '["min_version"]["hard"]' in workflow, "CI must derive the minimum"

labels = {
    "Node (24 LTS)": "node",
    "Python (3.14)": "python",
    "uv": "uv",
    "Bun": "bun",
    "Temurin (25 LTS)": "java",
    "Maven (3.9)": "maven",
    "AWS CLI": "awscli",
    "Bazelisk": "bazelisk",
    "GitHub CLI": "gh",
    "Hadolint": "hadolint",
    "Neovim": "neovim",
    "tree-sitter CLI": "tree-sitter",
    "Tectonic": "github:tectonic-typesetting/tectonic",
    "Herdr": "herdr",
    "Codex": "codex",
    "OpenCode (V1)": "opencode",
    "Pi": "npm:@earendil-works/pi-coding-agent",
    "Claude Code": "claude-code",
}
rows = {
    cells[0]: cells[2]
    for line in review.splitlines()
    if line.startswith("| ")
    and len(cells := [part.strip() for part in line.split("|")[1:-1]]) == 3
}
for label, name in labels.items():
    # The Java table omits the vendor prefix for readability.
    expected = (
        versions[name].removeprefix("temurin-") if name == "java" else versions[name]
    )
    assert rows.get(label) == expected, f"reviewed pin drift: {name}"
for label, name in (("Rust remains", "rust"), ("Zig remains", "zig")):
    assert f"**{label} {versions[name]}:**" in review, (
        f"hold documentation drift: {name}"
    )
unchanged = (
    f"Git-filter-repo {versions['git-filter-repo']}, Gitleaks {versions['gitleaks']}, "
    f"and ShellCheck {versions['shellcheck']}"
)
assert unchanged in " ".join(review.split()), "unchanged tool documentation drift"
for label, name in (
    ("Neovim", "neovim"),
    ("Herdr", "herdr"),
    ("Pi advances to", "npm:@earendil-works/pi-coding-agent"),
):
    assert f"**{label} {versions[name]}:**" in review, (
        f"migration note version drift: {name}"
    )
assert f"**Claude Code advances to {versions['claude-code']}:**" in review
assert config["settings"]["minimum_release_age"] == "7d", (
    "security exception must not weaken release-age policy"
)
assert locked["git-filter-repo"][0]["backend"] == "pypi:git-filter-repo"

lock_preview = config["tasks"]["tools:lock:dry-run"]["run"]
assert "mise --cd /tmp lock --global --dry-run --platform macos-arm64" in lock_preview
assert "MISE_LOCKED=0" in lock_preview
assert "--dry-run-code --locked" in config["tasks"]["tools:dry-run"]["run"]
print(f"Public housekeeping pin/lock/docs contract passed for {len(versions)} tools.")
