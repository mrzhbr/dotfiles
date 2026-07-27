# dotfiles

Public-safe macOS developer workstation configuration managed by
[mise](https://mise.jdx.dev/). This repository is the reusable baseline; a
separate private overlay supplies identities, host mappings, private metadata,
and machine-specific preferences.

## Status

This is an **unapplied dotfile scaffold**. mise 2026.7.14, all locked developer
tools, and PostgreSQL 18 are installed, but dotfiles, private overlays, Pi
Harness, macOS defaults, services, and Git remotes have not been applied.
PostgreSQL 14 remains linked and both PostgreSQL services remain stopped.

Requirements:

- macOS on Apple Silicon
- mise 2026.7.4 or newer
- Git

Both repositories pass mise status and isolated-home dry-run validation on
mise 2026.7.14. Do not run `mise bootstrap --force-dotfiles` until every
conflict has been reviewed and backed up.

## Ownership

- mise: runtimes, versioned developer CLIs, AI CLIs, tasks, and dotfiles
- mise bootstrap packages: native Homebrew formulae and casks
- Pi Harness: Pi packages, extensions, skills, settings, and sandbox
- private overlay: identity, hosts, private metadata, and personal macOS setup
- Keychain/application login: secrets and authentication

See `docs/tool-ownership.md`, `docs/architecture.md`, and
`docs/cutover.md`.

## Validation

These checks are safe and do not apply configuration:

```bash
./scripts/check-safety.sh
./scripts/validate.sh
```

After upgrading mise, preview only:

```bash
mise trust
mise run bootstrap:status
mise run bootstrap:dry-run
```

## Applying later

A real-machine cutover is deliberately deferred. It requires reviewed backups,
an isolated test-home run, successful dry-runs, and explicit approval. Legacy
NVM, Conda, PostgreSQL 14, and other installations stay in place until their
mise-managed replacements have been verified.
