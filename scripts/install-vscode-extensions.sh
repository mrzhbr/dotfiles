#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$ROOT/dotfiles/vscode/extensions.txt"

if ! command -v code >/dev/null 2>&1; then
  echo "VS Code CLI is not available yet; extension installation is a follow-up."
  exit 0
fi

while IFS= read -r extension; do
  [[ -n "$extension" && "$extension" != \#* ]] || continue
  code --install-extension "$extension" >/dev/null
  echo "VS Code extension ready: $extension"
done <"$manifest"
