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
# Ignore ambient user-site packages and pip configuration: otherwise pip can
# report success while required packages live outside this mise installation.
prefix="$("$PYTHON" -I -c 'import sys; print(sys.prefix)')"
PIP_CONFIG_FILE=/dev/null "$PYTHON" -I -m pip --isolated install --require-hashes --only-binary=:all: --prefix "$prefix" --disable-pip-version-check --requirement "$ROOT/config/python/requirements.txt"
PIP_CONFIG_FILE=/dev/null "$PYTHON" -I -m pip --isolated check
"$PYTHON" -I -c 'import nbformat, nbclient, numpy, pandas, matplotlib'
version="$("$PYTHON" -I -c 'import platform; print(platform.python_version())')"
"$PYTHON" -I -m ipykernel install --user --name mise-python --display-name "Python $version (mise)"

# Versioned kernels from earlier installs are intentionally left alone so saved
# notebooks can continue using their original interpreter until migrated.
echo "Jupyter is ready with Python $version (mise)."
