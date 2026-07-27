#!/usr/bin/env bash
set -euo pipefail

harness="$HOME/Developer/pi-harness-kit"
canonical="https://github.com/mrzhbr/pi-harness-kit.git"

if [[ ! -e "$harness" ]]; then
  mkdir -p "$(dirname "$harness")"
  git clone "$canonical" "$harness"
  echo "Cloned Pi Harness without applying it."
  exit 0
fi

if [[ ! -d "$harness/.git" ]]; then
  echo "Pi Harness target exists but is not a Git checkout: $harness" >&2
  exit 1
fi

origin="$(git -C "$harness" remote get-url origin 2>/dev/null || true)"
case "$origin" in
  "$canonical"|git@github.com:mrzhbr/pi-harness-kit.git|ssh://git@github.com/mrzhbr/pi-harness-kit.git)
    ;;
  *)
    echo "Pi Harness origin does not match the canonical repository." >&2
    exit 1
    ;;
esac

echo "Pi Harness checkout exists; local changes and branch state were left untouched."
