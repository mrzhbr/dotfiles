#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Mise also installs private Python dependencies for isolated CLI applications.
# Only the workstation's declared main interpreter owns the notebook environment.
if [[ -n "${MISE_TOOL_VERSION:-}" ]]; then
	main_version="$(mise --cd "$ROOT" current python)"
	if [[ "$MISE_TOOL_VERSION" != "$main_version" ]]; then
		echo "Skipping notebook setup for private Python $MISE_TOOL_VERSION (main: $main_version)."
		exit 0
	fi
fi
PYTHON="${1:-$(mise --cd "$ROOT" where python)/bin/python}"

# Use the new interpreter explicitly: PATH can still contain the previous Python
# while mise is running a postinstall hook.
"$PYTHON" -m pip install --disable-pip-version-check --requirement "$ROOT/config/python/requirements.txt"
"$PYTHON" -m pip check
version="$("$PYTHON" -c 'import platform; print(platform.python_version())')"
"$PYTHON" -m ipykernel install --user --name mise-python --display-name "Python $version (mise)"

# Versioned kernels from earlier installs are intentionally left alone so saved
# notebooks can continue using their original interpreter until migrated.
echo "Jupyter is ready with Python $version (mise)."
