#!/usr/bin/env bash
set -euo pipefail

config="$HOME/.config/mise/conf.d/10-public.toml"
if [[ -L "$config" ]]; then
  mise trust "$config" >/dev/null
  echo "Trusted layered mise config: $config"
else
  echo "Layered mise config is not linked yet: $config" >&2
fi
