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
`config/python/requirements.txt` also preserves the existing scientific packages
and Python development CLIs. The Python postinstall hook restores it after a
runtime update; `mise run jupyter:setup` repairs an existing installation.
Existing versioned kernels and legacy Homebrew installations are not removed.

## Native package layer

Native libraries, services, terminal infrastructure, and GUI applications stay
in `[bootstrap.packages]`. PostgreSQL 18 is installed on new machines but is not
started automatically. Docker Desktop and Ollama remain on-demand. Spotifyd,
Anaconda, R/RStudio, Solana, and Anchor/AVM are excluded.

The machine-readable contract is `tool-ownership.json`; `tests/ownership.py`
rejects duplicate command ownership and excluded package declarations.
