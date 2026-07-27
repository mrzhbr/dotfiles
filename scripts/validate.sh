#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import json
import tomllib
import sys

root = Path(sys.argv[1])
with (root / "mise.toml").open("rb") as handle:
    tomllib.load(handle)
with (root / "dotfiles/herdr/config.toml").open("rb") as handle:
    tomllib.load(handle)
for path in [
    root / "docs/tool-ownership.json",
    root / "dotfiles/vscode/settings.json",
    root / "tests/fixtures/herdr-keys.json",
]:
    json.loads(path.read_text())
print("TOML and JSON parsing passed.")
PY

zsh -n "$ROOT/dotfiles/zsh/.zshenv"
zsh -n "$ROOT/dotfiles/zsh/.zprofile"
zsh -n "$ROOT/dotfiles/zsh/.zshrc"

while IFS= read -r script; do
  bash -n "$script"
done < <(find "$ROOT/scripts" "$ROOT/dotfiles/bin" "$ROOT/tests" -type f -name '*.sh' -print)

if command -v shellcheck >/dev/null 2>&1; then
  mapfile=()
  while IFS= read -r script; do mapfile+=("$script"); done < <(
    find "$ROOT/scripts" "$ROOT/dotfiles/bin" "$ROOT/tests" -type f -name '*.sh' -print
  )
  shellcheck "${mapfile[@]}"
else
  echo "warning: shellcheck unavailable outside mise; syntax checks still ran." >&2
fi

"$ROOT/tests/herdr-config-contract.py"
"$ROOT/tests/tmux-config-contract.py"
"$ROOT/tests/ownership.py"
"$ROOT/tests/safety-test.sh"
"$ROOT/scripts/check-safety.sh"

echo "Public dotfiles validation passed."
