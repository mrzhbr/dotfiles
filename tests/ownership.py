#!/usr/bin/env python3
from pathlib import Path
import json
import tomllib

root = Path(__file__).resolve().parents[1]
try:
    ownership = json.loads((root / "docs/tool-ownership.json").read_text())
    with (root / "mise.toml").open("rb") as handle:
        config = tomllib.load(handle)
except (OSError, ValueError, tomllib.TOMLDecodeError) as exc:
    raise SystemExit(f"cannot load ownership configuration: {exc}") from exc

seen: dict[str, str] = {}
for owner in ("mise", "brew", "brew-cask"):
    for package, commands in ownership[owner].items():
        for command in commands:
            previous = seen.get(command)
            if previous:
                raise SystemExit(f"duplicate command owner for {command}: {previous} and {owner}:{package}")
            seen[command] = f"{owner}:{package}"

serialized = (root / "mise.toml").read_text().lower()
for excluded in ownership["excluded"]:
    if f'"brew:{excluded}"' in serialized or f'"brew-cask:{excluded}"' in serialized:
        raise SystemExit(f"excluded package is declared: {excluded}")

packages = config.get("bootstrap", {}).get("packages", {})
for package in ownership["brew"]:
    if f"brew:{package}" not in packages:
        raise SystemExit(f"brew ownership is undocumented in mise.toml: {package}")
for package in ownership["brew-cask"]:
    if f"brew-cask:{package}" not in packages:
        raise SystemExit(f"cask ownership is undocumented in mise.toml: {package}")

print(f"Tool ownership contract passed for {len(seen)} commands.")
