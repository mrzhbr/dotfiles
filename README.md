# dotfiles

macOS developer configuration managed by [mise](https://mise.jdx.dev/).
This is the reusable public baseline: tool pins, dependency locks, shell/editor
configuration and validation contracts. A separate private overlay owns identity,
host mappings and machine-specific preferences. Credentials and application
state belong in neither repository.

## Requirements

- macOS on Apple Silicon
- mise 2026.10.15 or newer
- Git

Exact tool selections live in [`mise.toml`](mise.toml), [`mise.lock`](mise.lock)
and [dependency sidecars](.mise/locks/). Check configuration and compatibility
before applying it to another machine; a successful validation is not a security
certification of a workstation or every project.

## Configuration boundaries

| Owner | Responsibility |
| --- | --- |
| mise | Runtimes, versioned developer CLIs, tasks and dotfiles |
| Homebrew through mise bootstrap | Native libraries, services and GUI applications |
| Pi Harness | Pi packages, extensions, skills and sandbox integration |
| Private overlay | Identity, host mappings and machine-specific configuration |
| Keychain/application login | Credentials and authentication state |

See [architecture](docs/architecture.md), [tool ownership](docs/tool-ownership.md)
and the [cutover checklist](docs/cutover.md). Existing databases, project
environments and legacy managers are not removal targets of bootstrap.

## Terminal workflows

Ghostty and Herdr remain managed fallbacks, with tmux available independently.
Rex is an **experimental, opt-in trial**, not a replacement for them. Its
[Herdr-compatible workflow](docs/rex-workflow.md) adds local/remote navigation
without removing native Rex shortcuts.

Rex itself is installed separately during its beta. Only
`~/.config/rex/init.lua` is managed here; personal endpoints remain outside Git
in `~/.config/rex/local.lua`. No app/server restart, agent-hook setup or default
terminal change is part of repository validation.

## Validate before applying

```bash
./scripts/check-safety.sh
./scripts/validate.sh
./scripts/test-bootstrap.sh
```

Validation covers ownership, pins/locks, terminal behavior, public-document
boundaries and isolated bootstrap contracts. The Rex tests mock the runtime and
personal configuration, using Lua/LuaJIT or clean Neovim; no live Rex host is
contacted. CI installs only its validation tools, not the full workstation stack.

Bootstrap previews use a temporary HOME and copy only declared source inputs.
The preview separates tool metadata from non-tool dry-run phases because the
supported mise version may require installed Python prerequisites even for a
PyPI installer dry-run. This is not a complete fresh-Mac installation test.

## Preview and apply

```bash
mise trust
mise run bootstrap:status
mise run bootstrap:dry-run
mise run tools:dry-run
```

Review the [cutover checklist](docs/cutover.md) before applying dotfiles or
installing tools. Back up managed targets first. Do not run forced replacement,
service starts or legacy cleanup as an implicit part of a preview.

## Maintenance

- [Safe pin, lock and Python environment updates](docs/maintenance.md)
- [Tool ownership and staged consolidation](docs/consolidation-plan.md)
- [Pi Harness integration](docs/pi-harness.md)
- [Public repository security boundaries](docs/security.md)

Read-only ownership checks:

```bash
mise run tools:audit
mise run tools:audit -- --json
mise run tools:lock:dry-run
```

Notebook tasks use the pinned mise Python environment:

```bash
mise run jupyter:setup
mise run jupyter:check
```

The latter runs a synthetic notebook over Unix IPC with temporary state, not
personal notebooks or user-site packages. Browser automation is deliberately
quarantined; do not remove its guards or force incompatible dependencies to
make a check pass.

Machine inventories, audit findings, rollout histories and remediation status
are maintained privately, not in these public configuration docs.
