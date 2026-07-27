#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
required="2026.7.4"

python3 - "$required" "$(mise --version 2>/dev/null | awk '{print $1}')" <<'PY'
import re
import sys

def version(value: str) -> tuple[int, ...]:
    match = re.match(r"(\d+)\.(\d+)\.(\d+)", value)
    if not match:
        raise SystemExit(f"cannot parse mise version: {value!r}")
    return tuple(map(int, match.groups()))

if version(sys.argv[2]) < version(sys.argv[1]):
    raise SystemExit(f"mise {sys.argv[1]} or newer is required; found {sys.argv[2]}")
PY

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/Developer" "$tmp/.config/mise/conf.d" "$tmp/.local/share/mise" "$tmp/.cache/mise"
ln -s "$ROOT" "$tmp/Developer/dotfiles"
if [[ -d "$HOME/Developer/dotfiles-private" ]]; then
  ln -s "$HOME/Developer/dotfiles-private" "$tmp/Developer/dotfiles-private"
fi

mise_env=(
  env
  HOME="$tmp"
  MISE_DATA_DIR="$tmp/.local/share/mise"
  MISE_CACHE_DIR="$tmp/.cache/mise"
  MISE_IGNORED_CONFIG_PATHS="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
  MISE_TRUSTED_CONFIG_PATHS="${XDG_CONFIG_HOME:-$HOME/.config}/mise:$HOME/Developer/dotfiles:$HOME/Developer/dotfiles-private"
)
"${mise_env[@]}" mise trust "$ROOT/mise.toml" >/dev/null
"${mise_env[@]}" mise trust "$tmp/.config/mise/conf.d/10-public.toml" >/dev/null
"${mise_env[@]}" mise --cd "$ROOT" bootstrap --dry-run --skip repos --verbose

echo "Isolated HOME public bootstrap dry-run passed; no real HOME paths were changed."
