#!/usr/bin/env python3
"""Fail closed for the currently unfixable upstream browser helper graph.

Only mise-owned program packages are touched, never browser profiles or settings.
Remove this hook only after a supported corrected graph has passed security review.
"""

import json
import os
import sys
import tempfile
from pathlib import Path

REASON = (
    "Browser automation is quarantined: browser-use 0.13.11 / browser-harness "
    "0.1.13 pin vulnerable dependencies. No force/no-deps workaround is permitted. "
    "Use a reviewed corrected release before re-enabling this helper."
)
STUB = (
    "# Managed security quarantine; original program source retained alongside.\nraise RuntimeError("
    + repr(REASON)
    + ")\n"
)


def quarantine(prefix: Path) -> None:
    prefix = prefix.resolve(strict=True)
    sites = list((prefix / ".mise-uv").glob("**/site-packages"))
    if len(sites) != 1:
        raise RuntimeError("Refusing unexpected browser-helper environment layout")
    site = sites[0].resolve(strict=True)
    if not site.is_relative_to(prefix):
        raise RuntimeError("Refusing package directory outside the selected tool")
    expected = ("browser_use-0.13.11.dist-info", "browser_harness-0.1.13.dist-info")
    if not all((site / name).is_dir() for name in expected):
        raise RuntimeError(
            "Unexpected helper versions: review security status before installation"
        )
    marker_path = prefix / ".security-quarantine.json"
    if marker_path.is_symlink() or (marker_path.exists() and not marker_path.is_file()):
        raise RuntimeError("Refusing unexpected quarantine marker")
    targets = [
        site / namespace / "__init__.py"
        for namespace in ("browser_use", "browser_harness")
    ]
    # Preflight both packages before changing either; never follow a namespace symlink.
    for target in targets:
        if (
            target.parent.is_symlink()
            or target.is_symlink()
            or not target.is_file()
            or not target.resolve().is_relative_to(site)
        ):
            raise RuntimeError("Refusing unexpected package entrypoint")
        backup = target.with_name("__init__.py.security-disabled-original")
        if target.read_text() != STUB and backup.exists():
            raise RuntimeError(
                "Original backup exists but quarantine changed; refusing overwrite"
            )
    for target in targets:
        if target.read_text() != STUB:
            target.replace(target.with_name("__init__.py.security-disabled-original"))
            target.write_text(STUB)
    marker = {
        "status": "quarantined",
        "reason": REASON,
        "packages": ["browser-use==0.13.11", "browser-harness==0.1.13"],
    }
    # Atomic replacement never follows a late marker symlink or modifies a
    # pre-existing hard-linked inode outside the selected program prefix.
    with tempfile.NamedTemporaryFile(mode="w", dir=prefix, delete=False) as handle:
        temporary = Path(handle.name)
        handle.write(json.dumps(marker, indent=2) + "\n")
    try:
        os.replace(temporary, marker_path)
    finally:
        temporary.unlink(missing_ok=True)
    print(
        "Browser helper quarantined; CLI and normal SDK imports fail closed. Profiles/settings untouched."
    )


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: quarantine-browser-use.py MISE_TOOL_INSTALL_PATH")
    quarantine(Path(sys.argv[1]))
