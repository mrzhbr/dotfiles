#!/usr/bin/env python3
"""Check Jupyter bootstrap wiring without installing packages or changing HOME."""

import json
import os
import re
import subprocess
import tempfile
import tomllib
from pathlib import Path


def recorded_calls(path: Path) -> list[list[str]]:
    try:
        return [json.loads(line) for line in path.read_text().splitlines()]
    except (OSError, ValueError) as exc:
        raise AssertionError(
            "Synthetic interpreter output is missing or invalid JSON"
        ) from exc


root = Path(__file__).resolve().parents[1]
config = tomllib.loads((root / "mise.toml").read_text())
python = config["tools"]["python"]
assert "setup-jupyter.sh" in python["postinstall"]
assert "$MISE_TOOL_INSTALL_PATH/bin/python" in python["postinstall"]
assert any("setup-jupyter.sh" in run for run in config["tasks"]["bootstrap"]["run"])
assert "setup-jupyter.sh" in config["tasks"]["jupyter:setup"]["run"]
assert "python -I" in config["tasks"]["jupyter:check"]["run"]
assert "check-jupyter.py" in config["tasks"]["jupyter:check"]["run"]

requirements = (root / "config/python/requirements.txt").read_text().splitlines()
for package in ("ipykernel", "notebook", "jupyterlab", "numpy", "pandas", "matplotlib"):
    assert any(line.startswith(f"{package}==") for line in requirements), package
logical = []
continuation = ""
for line in requirements:
    if not line.strip() or line.startswith("#"):
        continue
    continuation += " " + line.strip().removesuffix("\\").strip()
    if not line.rstrip().endswith("\\"):
        logical.append(continuation.strip())
        continuation = ""
assert not continuation, "unterminated hash-locked requirement"
assert logical and all(
    re.fullmatch(r"[A-Za-z0-9_.-]+==[^\s]+(?: --hash=sha256:[0-9a-f]{64})+", line)
    for line in logical
), "every package must have an exact version and artifact hashes"

with tempfile.TemporaryDirectory() as tmp:
    directory = Path(tmp)
    log = directory / "calls.jsonl"
    runtime = directory / "runtime with spaces"
    interpreter = runtime / "bin/python"
    interpreter.parent.mkdir(parents=True)
    interpreter.write_text("""#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
with Path(os.environ["JUPYTER_TEST_LOG"]).open("a") as handle:
    handle.write(json.dumps(sys.argv[1:]) + "\\n")
args = sys.argv[1:]
assert args[:1] == ["-I"], "interpreter must ignore user-site and PYTHONPATH"
args = args[1:]
if args[:2] == ["-m", "pip"]:
    assert args[2] == "--isolated"
    assert os.environ.get("PIP_CONFIG_FILE") == "/dev/null"
    if os.environ.get("JUPYTER_TEST_FAIL_PIP"):
        sys.exit(1)
if args[:1] == ["-c"]:
    if "sys.prefix" in args[1]:
        print(Path(sys.argv[0]).parent.parent)
    elif "platform" in args[1]:
        print(os.environ["JUPYTER_TEST_VERSION"])
    elif os.environ.get("JUPYTER_TEST_FAIL_IMPORT"):
        sys.exit(1)
""")
    interpreter.chmod(0o755)
    env = {
        "PATH": os.environ.get("PATH", os.defpath),
        "HOME": str(directory),
        "JUPYTER_TEST_CONFIG_ROOT": str(root),
        "JUPYTER_TEST_LOG": str(log),
        "JUPYTER_TEST_VERSION": python["version"],
    }
    expected = [
        ["-I", "-c", "import sys; print(sys.prefix)"],
        [
            "-I",
            "-m",
            "pip",
            "--isolated",
            "install",
            "--require-hashes",
            "--only-binary=:all:",
            "--prefix",
            str(runtime),
            "--disable-pip-version-check",
            "--requirement",
            str(root / "config/python/requirements.txt"),
        ],
        ["-I", "-m", "pip", "--isolated", "check"],
        ["-I", "-c", "import nbformat, nbclient, numpy, pandas, matplotlib"],
        ["-I", "-c", "import platform; print(platform.python_version())"],
        [
            "-I",
            "-m",
            "ipykernel",
            "install",
            "--user",
            "--name",
            "mise-python",
            "--display-name",
            f"Python {python['version']} (mise)",
        ],
    ]
    script = str(root / "scripts/setup-jupyter.sh")
    subprocess.run([script, str(interpreter)], env=env, check=True, capture_output=True)
    assert recorded_calls(log) == expected

    # Bootstrap resolves the workstation interpreter, not a caller's project Python.
    fake_mise = directory / "mise"
    fake_mise.write_text(
        '#!/bin/sh\n[ "$1" = --cd ] && [ "$2" = "$JUPYTER_TEST_CONFIG_ROOT" ] || exit 1\nshift 2\n'
        'case "$1:$2" in\nwhere:python) printf "%s\\n" "$JUPYTER_TEST_RUNTIME" ;;\n'
        'current:python) printf "%s\\n" "$JUPYTER_TEST_VERSION" ;;\n*) exit 1 ;;\nesac\n'
    )
    fake_mise.chmod(0o755)
    log.unlink()
    subprocess.run(
        [script],
        env={
            **env,
            "PATH": f"{directory}:{env['PATH']}",
            "JUPYTER_TEST_RUNTIME": str(runtime),
        },
        check=True,
        capture_output=True,
    )
    assert recorded_calls(log) == expected

    # Private CLI Python installs must not modify the main notebook environment;
    # a real main-interpreter hook must still perform the complete setup.
    for hook_version in (
        config["tools"]["pypi:browser-use"]["python"],
        python["version"],
    ):
        log.unlink(missing_ok=True)
        subprocess.run(
            [script, str(interpreter)],
            env={
                **env,
                "PATH": f"{directory}:{env['PATH']}",
                "MISE_TOOL_VERSION": hook_version,
            },
            check=True,
            capture_output=True,
        )
        if hook_version != python["version"]:
            assert not log.exists(), "private Python ran notebook/pip operations"
        else:
            assert recorded_calls(log) == expected

    # Failed installation must not replace the working kernelspec.
    log.unlink()
    result = subprocess.run(
        [script, str(interpreter)],
        env={**env, "JUPYTER_TEST_FAIL_PIP": "1"},
        check=False,
        capture_output=True,
    )
    assert result.returncode != 0
    assert len(recorded_calls(log)) == 2

    # Dependency metadata is not enough: an actual isolated import failure must
    # also prevent changing the registered kernel.
    log.unlink()
    result = subprocess.run(
        [script, str(interpreter)],
        env={**env, "JUPYTER_TEST_FAIL_IMPORT": "1"},
        check=False,
        capture_output=True,
    )
    assert result.returncode != 0
    assert len(recorded_calls(log)) == 4
    assert not any("ipykernel" in call for call in recorded_calls(log))

# Reloading the public interactive config must remove a stale Homebrew alias.
# Use only a disposable HOME and stub activation; never load private shell files.
with tempfile.TemporaryDirectory() as tmp:
    directory = Path(tmp)
    bin_dir = directory / "bin"
    bin_dir.mkdir()
    for name, body in {"mise": "printf ':\\n'", "jupyter": "exit 0"}.items():
        executable = bin_dir / name
        executable.write_text(f"#!/bin/sh\n{body}\n")
        executable.chmod(0o755)
    subprocess.run(
        [
            "zsh",
            "-f",
            "-c",
            'alias jupyter=/opt/homebrew/bin/jupyter; source "$1"; '
            '[[ -z "${aliases[jupyter]}" ]] && [[ "$(whence -p jupyter)" == "$2" ]]',
            "jupyter-shell-contract",
            str(root / "dotfiles/zsh/.zshrc"),
            str(bin_dir / "jupyter"),
        ],
        cwd=directory,
        env={
            "HOME": str(directory),
            "PATH": f"{bin_dir}:/usr/bin:/bin:/usr/sbin:/sbin",
        },
        check=True,
        capture_output=True,
    )

print("Jupyter setup and interactive ownership contracts passed.")
