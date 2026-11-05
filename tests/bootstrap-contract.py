#!/usr/bin/env python3
"""Check CI platform, isolation, trust ordering, version floor and failures."""

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
workflow = (root / ".github/workflows/validate.yml").read_text()
# Old runner images lose Homebrew bottles. Never hide source/checksum failures
# by skipping package previews: exercise the supported native platform instead.
assert re.search(r"(?m)^    runs-on: macos-26$", workflow), (
    "bootstrap CI requires the supported macOS 26 Apple Silicon runner"
)
with tempfile.TemporaryDirectory() as tmp:
    directory = Path(tmp)
    home = directory / "real-home"
    home.mkdir()
    marker = home / ".zshrc"
    marker.write_text("leave this alone\n")
    calls = directory / "calls.jsonl"
    mise = directory / "mise"
    # Use the test interpreter explicitly; the isolated child has a minimal PATH.
    template = """#!INTERPRETER
import json, os, sys, tomllib
from pathlib import Path
args = sys.argv[1:]
if args == ["--version"]:
    print(VERSION)
    raise SystemExit(0)
home = Path(os.environ["HOME"])
assert home != Path(REAL_HOME)
assert "MISE_TEST_INHERITED" not in os.environ
assert "MISE_TRUSTED_CONFIG_PATHS" not in os.environ
assert os.environ["MISE_PARANOID"] == "1"
assert Path(os.environ["MISE_CONFIG_DIR"]) == home / ".config/mise"
for name in ("MISE_DATA_DIR", "MISE_CACHE_DIR", "MISE_STATE_DIR", "XDG_CONFIG_HOME"):
    assert Path(os.environ[name]).is_relative_to(home), name
checkout = home / "Developer/dotfiles"
assert checkout.is_dir() and not checkout.is_symlink()
assert not (home / "Developer/dotfiles-private").exists()
layer = home / ".config/mise/conf.d/10-public.toml"
assert layer.is_symlink() and layer.resolve() == (checkout / "mise.toml").resolve()
assert (home / ".config/mise/mise.lock").resolve() == (checkout / "mise.lock").resolve()
locked = tomllib.loads((checkout / "mise.lock").read_text())
for entries in locked["tools"].values():
    for entry in entries:
        for kind in ("aube", "uv"):
            if kind in entry:
                relative = entry[kind]["path"]
                copied = checkout / relative
                assert copied.is_dir() and not copied.is_symlink(), relative
                for original in (Path(SOURCE_ROOT) / relative).iterdir():
                    assert (copied / original.name).read_bytes() == original.read_bytes()
if args[0] == "trust":
    assert Path(args[1]).is_file(), "trust must follow link creation"
    assert Path(args[1]).resolve() == (checkout / "mise.toml").resolve()
elif args[2] == "ls":
    assert args == ["--cd", str(checkout), "ls", "--current", "--json"]
    print("{}")
else:
    assert args == ["--cd", str(checkout), "bootstrap", "--dry-run", "--skip", "repos,tools", "--verbose"]
with Path(CALLS).open("a") as handle:
    handle.write(json.dumps(args) + "\\n")
if args[0] != "trust" and args[2] == "bootstrap":
    raise SystemExit(BOOTSTRAP_EXIT)
"""

    def run(version: str, bootstrap_exit: int = 0) -> subprocess.CompletedProcess:
        mise.write_text(
            template.replace("INTERPRETER", sys.executable)
            .replace("VERSION", repr(version))
            .replace("REAL_HOME", repr(str(home)))
            .replace("SOURCE_ROOT", repr(str(root)))
            .replace("CALLS", repr(str(calls)))
            .replace("BOOTSTRAP_EXIT", str(bootstrap_exit))
        )
        mise.chmod(0o755)
        calls.unlink(missing_ok=True)
        return subprocess.run(
            [str(root / "scripts/test-bootstrap.sh")],
            env={
                "PATH": f"{directory}:{os.environ['PATH']}",
                "HOME": str(home),
                "MISE_CONFIG_DIR": str(directory / "wrong-config"),
                "MISE_TRUSTED_CONFIG_PATHS": "/",
                "XDG_CONFIG_HOME": str(directory / "wrong-xdg"),
                "MISE_TEST_INHERITED": "must-not-leak",
            },
            text=True,
            capture_output=True,
            check=False,
        )

    result = run("9999.1.1")
    assert result.returncode == 0, result.stderr
    recorded = [json.loads(line) for line in calls.read_text().splitlines()]
    assert len(recorded) == 4 and all(call[0] == "trust" for call in recorded[:2])
    assert recorded[2][2:] == ["ls", "--current", "--json"]
    assert recorded[3][2:] == [
        "bootstrap",
        "--dry-run",
        "--skip",
        "repos,tools",
        "--verbose",
    ]
    assert "tool metadata preview passed" in result.stdout
    assert marker.read_text() == "leave this alone\n"
    assert sorted(path.name for path in home.iterdir()) == [".zshrc"]

    result = run("0.1.0")
    assert result.returncode != 0 and "or newer is required" in result.stderr
    assert not calls.exists(), "old mise must fail before trusting or bootstrap"

    result = run("9999.1.1", bootstrap_exit=42)
    assert result.returncode == 42, result.stderr
    assert "tool metadata preview passed" not in result.stdout

print("Bootstrap isolation/trust/version/failure contract passed.")
