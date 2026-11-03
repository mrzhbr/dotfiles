# Tool ownership

The target is one intentional owner per executable. The contract below declares
that target; it does not prove legacy installations or PATH conflicts are gone.
The machine starts with exact migration versions; reviewed updates change
`mise.lock` intentionally.

Run `mise run tools:audit` to compare the intended mise owners with actual command
paths and installed Homebrew receipts. See [the consolidation plan](consolidation-plan.md)
for helper migration, duplicate retirement and the approval boundary. Native
runtime dependencies are not obsolete merely because the shell uses mise.

## mise

mise owns language runtimes, version-sensitive CLIs, Herdr, Neovim, and the four
selected AI CLIs. Node stays on 24 LTS, Python on 3.14, and Java on Temurin 25
LTS. Exact versions live in `mise.toml`; projects may override them, including
Java 17. See `housekeeping-2026-10.md` for reviewed updates and temporary holds.

Jupyter Notebook, JupyterLab, IPython, and the `mise-python` kernel belong to
the mise Python installation, not Homebrew or Conda. The pinned environment in
`config/python/requirements.txt` also preserves the scientific packages and
Python development CLIs. All 113 distributions have exact versions and artifact
hashes; setup enforces `--require-hashes --only-binary=:all:`. Regenerate with
`--generate-hashes`, review version/hash changes, and retain the general `7d`
policy except for explicitly approved security fixes. The Python postinstall
hook restores it after a runtime update; `mise run jupyter:setup` repairs an
existing installation. Setup installs into the selected interpreter's prefix
without relying on Python
user-site packages or ambient pip configuration, then checks isolated imports
before registering the main kernel. Private Python dependencies skip notebook
setup. Existing versioned kernels and project environments remain intact.

`mise run jupyter:check` executes a synthetic notebook with an isolated HOME,
test-owned Unix-IPC kernel, NumPy/Pandas computation and Matplotlib rendering.
This is a live check, separate from configuration validation. Brew JupyterLab
was retired after this check and extension/consumer verification; its underlying
Brew Python remains because other applications and projects still use it.

Jedi language server, Ruff and yamllint currently belong to the pinned shared
Python environment and are included in the command ownership audit. They are
not separate mise application-backend installations yet.

## Quarantined browser helper

Mise owns browser-use 0.13.11 and its private Python 3.13.17, not an active
browser automation service. The latest upstream helper still exact-pins a
vulnerable dependency graph, including browser-harness 0.1.13. Its postinstall
hook quarantines both package namespaces on every install: normal CLI and SDK
imports fail closed. Original program source is retained; browser profiles and
settings are untouched. A Python update is not dependency remediation. Do not
force conflicting versions or use `--no-deps`; re-enabling requires a reviewed,
supported corrected graph. Earlier functional smokes are historical, not
security clearance. See [the security follow-up](security-review-2026-10-23.md).

## Native package layer

Native libraries, services, terminal infrastructure, and GUI applications stay
in `[bootstrap.packages]`. Ripgrep supplies Telescope's configured live-grep
command and shell search. PostgreSQL 18 is installed on new machines but is not
started automatically; its keg-only client directory is on the login-shell
PATH. Docker Desktop and Ollama remain on-demand. Spotifyd,
Anaconda, R/RStudio, Solana, and Anchor/AVM are excluded.

The machine-readable contract is `tool-ownership.json`; `tests/ownership.py`
rejects duplicate command ownership and excluded package declarations.
