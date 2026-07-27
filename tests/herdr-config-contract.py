#!/usr/bin/env python3
from pathlib import Path
import json
import tomllib

root = Path(__file__).resolve().parents[1]
actual_path = root / "dotfiles/herdr/config.toml"
expected_path = root / "tests/fixtures/herdr-keys.json"

try:
    with actual_path.open("rb") as handle:
        actual = tomllib.load(handle)
    expected = json.loads(expected_path.read_text())
except (OSError, ValueError, tomllib.TOMLDecodeError) as exc:
    raise SystemExit(f"cannot load Herdr contract fixtures: {exc}") from exc

for section, expected_value in expected.items():
    actual_value = actual.get(section)
    if actual_value != expected_value:
        raise SystemExit(
            f"Herdr contract changed in [{section}]\n"
            f"expected: {expected_value!r}\nactual:   {actual_value!r}"
        )

if actual.get("onboarding") != bool(0):
    raise SystemExit("Herdr onboarding must remain disabled")

print("Herdr Ctrl-s configuration contract passed.")
