# Tool ownership

The machine-readable contract is [`tool-ownership.json`](tool-ownership.json).
It declares intended owners, not a claim about every installed application.
`tests/ownership.py` checks duplicate command ownership and excluded declarations.

```bash
mise run tools:audit
mise run tools:audit -- --strict
```

The audit reads package metadata and executable paths, not private profiles or
credentials. Review actual consumers before removing a duplicate; see the
[consolidation workflow](consolidation-plan.md).

## Mise-managed tools

Mise owns runtimes, version-sensitive developer/AI CLIs, Herdr and Neovim.
Exact versions and graphs live in `mise.toml`, `mise.lock` and `.mise/locks/`.
Projects may select separate runtimes without changing the workstation baseline.

Jupyter/IPython, scientific libraries and the Python development CLIs belong to
the pinned mise Python environment. Its complete requirements have exact
versions and artifact hashes. Setup enforces isolated pip, binary wheels and an
explicit prefix, then verifies imports before registering the main kernel.
Helper-specific Python installations skip notebook setup. Existing project
and user-site environments are not implicitly migrated or removed.

`mise run jupyter:check` runs a synthetic computation/rendering notebook using
a temporary HOME and test-owned Unix-IPC kernel. It does not read personal
notebooks or configuration. See [maintenance](maintenance.md) for refresh steps.

## Browser quarantine

The declared browser helper is not an enabled automation service. Its
postinstall hook blocks normal CLI/SDK imports and retains original program
source. Do not treat a Python update, working PATH entry or successful ownership
check as dependency remediation. A supported corrected graph and explicit
review are required before re-enabling; see [security boundaries](security.md).

## Native packages and applications

Native libraries, services and GUI applications stay in `[bootstrap.packages]`.
Ripgrep supports editor/live-grep and shell search. The PostgreSQL client path
is configured without starting a database. Docker and Ollama remain on-demand.
Exclusions in the ownership contract are clean-bootstrap decisions, not an
instruction to remove programs already installed by a user.

Ghostty and Herdr remain managed fallback workflows. Rex is an experimental,
separately installed app: the public layer manages only its main configuration,
not personal hosts or its entire config directory.
