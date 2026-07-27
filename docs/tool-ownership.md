# Tool ownership

Every executable has one package owner. The machine starts with exact migration
versions; reviewed updates change `mise.lock` intentionally.

## mise

mise owns language runtimes, version-sensitive CLIs, Herdr, Neovim, and the four
selected AI CLIs. Node starts at 23.3.0, Python at 3.14.3, Rust at 1.93.1, and
Java at Temurin 25 LTS. Projects may override these versions, including Java 17.

## Native package layer

Native libraries, services, terminal infrastructure, and GUI applications stay
in `[bootstrap.packages]`. PostgreSQL 18 is installed on new machines but is not
started automatically. Docker Desktop and Ollama remain on-demand. Spotifyd,
Anaconda, R/RStudio, Solana, and Anchor/AVM are excluded.

The machine-readable contract is `tool-ownership.json`; `tests/ownership.py`
rejects duplicate command ownership and excluded package declarations.
