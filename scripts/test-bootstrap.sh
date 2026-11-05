#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
required="$(
	python3 - "$ROOT/mise.toml" <<'PY'
import sys
import tomllib
from pathlib import Path

print(tomllib.loads(Path(sys.argv[1]).read_text())["min_version"]["hard"])
PY
)"

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
checkout="$tmp/Developer/dotfiles"
mkdir -p "$checkout" "$tmp/.config/mise/conf.d" "$tmp/.local/share/mise" "$tmp/.cache/mise"
# A copy, not a checkout symlink: mise canonicalizes the working directory and
# would otherwise discover real-HOME ancestor configs. Copy only public inputs.
cp -R "$ROOT/mise.toml" "$ROOT/mise.lock" "$ROOT/dotfiles" "$ROOT/scripts" \
	"$ROOT/config" "$ROOT/tests" "$ROOT/docs" "$checkout/"
if [[ -d "$ROOT/.mise/locks" ]]; then
	mkdir -p "$checkout/.mise"
	cp -R "$ROOT/.mise/locks" "$checkout/.mise/locks"
fi
# Model the public global composition before trusting its layered config. A
# dry-run previews links; it does not create them. Never load the private overlay.
ln -s "$checkout/mise.toml" "$tmp/.config/mise/conf.d/10-public.toml"
ln -s "$checkout/mise.lock" "$tmp/.config/mise/mise.lock"

# Discard inherited mise/XDG overrides and credentials. Trust only the two
# concrete public config paths, recording that trust in the temporary data dir.
mise_env=(
	env -i
	PATH="$(dirname "$(command -v mise)"):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
	HOME="$tmp"
	XDG_CONFIG_HOME="$tmp/.config"
	XDG_DATA_HOME="$tmp/.local/share"
	XDG_CACHE_HOME="$tmp/.cache"
	XDG_STATE_HOME="$tmp/.local/state"
	MISE_CONFIG_DIR="$tmp/.config/mise"
	MISE_DATA_DIR="$tmp/.local/share/mise"
	MISE_CACHE_DIR="$tmp/.cache/mise"
	MISE_STATE_DIR="$tmp/.local/state/mise"
	MISE_SYSTEM_CONFIG_DIR="$tmp/system-mise"
	MISE_PARANOID=1
)
"${mise_env[@]}" mise trust "$checkout/mise.toml" >/dev/null
"${mise_env[@]}" mise trust "$tmp/.config/mise/conf.d/10-public.toml" >/dev/null
# mise 2026.10.15 validates missing PyPI dependencies even during --dry-run.
# Preview tool selection with the read-only metadata API instead; never fake an
# installed dependency or populate this HOME with real tools to hide that bug.
echo "Tool metadata preview (no installations):"
"${mise_env[@]}" mise --cd "$checkout" ls --current --json
"${mise_env[@]}" mise --cd "$checkout" bootstrap --dry-run --skip repos,tools --verbose

# Bootstrap must not have applied any dotfiles, hooks, or tool installs.
for target in .zshrc .local/bin .ssh/config .local/share/mise/installs; do
	if [[ -e "$tmp/$target" || -L "$tmp/$target" ]]; then
		echo "Dry-run unexpectedly created $target" >&2
		exit 1
	fi
done

echo "Isolated HOME public bootstrap dry-run plus tool metadata preview passed; tool installer dry-run excluded for the documented mise PyPI issue. No real HOME paths were changed."
