# dotfiles

Public-safe macOS developer workstation configuration managed by
[mise](https://mise.jdx.dev/). This repository is the reusable baseline; a
separate private overlay supplies identities, host mappings, private metadata,
and machine-specific preferences.

## Status

The baseline and private overlay are **applied and verified** on the current
machine with mise 2026.7.14. All locked tools and native packages are present,
Pi Harness is installed with host/model ownership opt-outs, and every declared
bootstrap state reports current. PostgreSQL 14 remains linked; PostgreSQL 18 is
installed separately; both services remain stopped. The repositories have no
remotes.

Requirements:

- macOS on Apple Silicon
- mise 2026.7.4 or newer
- Git

Both repositories pass aggregate mise status, isolated-home dry-runs, safety
checks, and runtime verification on mise 2026.7.14. Existing targets were
backed up before the initial forced cutover.

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

Preview bootstrap convergence without applying changes:

```bash
mise trust
mise run bootstrap:status
mise run bootstrap:dry-run
```

## Legacy cleanup

The initial cutover is complete, but NVM, Conda, PostgreSQL 14, and other legacy
installations remain intentionally untouched. Removal and PostgreSQL data
migration require a separate approval after an observation period.
