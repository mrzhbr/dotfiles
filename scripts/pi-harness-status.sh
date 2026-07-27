#!/usr/bin/env bash
set -euo pipefail

harness="$HOME/Developer/pi-harness-kit"
if [[ ! -d "$harness/.git" ]]; then
  echo "Pi Harness is not cloned at $harness. mise bootstrap repos will provide it."
  exit 0
fi

if [[ ! -x "$harness/bootstrap.sh" ]]; then
  echo "Pi Harness exists but bootstrap.sh is not executable." >&2
  exit 1
fi

echo "Pi Harness checkout is present."
if ! grep -Fq 'PI_HARNESS_INSTALL_HOST_TOOLS' "$harness/scripts/install-stack.sh" ||
   ! grep -Fq 'PI_HARNESS_INSTALL_MODELS' "$harness/scripts/install-stack.sh"; then
  echo "Pi Harness is missing required host-tool/model opt-outs." >&2
  exit 1
fi
if grep -Eq '100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.' "$harness/templates/models.json"; then
  echo "Pi Harness public model template still contains a private endpoint." >&2
  exit 1
fi
echo "Pi Harness host-tool/model opt-outs and public model template are ready."
echo "Harness application remains an explicit cutover step."
