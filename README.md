# dotfiles

Public-safe macOS developer workstation configuration managed by
[mise](https://mise.jdx.dev/). This repository is the reusable baseline; a
separate private overlay supplies identities, host mappings, private metadata,
and machine-specific preferences.

## Status

The runtime baseline was refreshed on 20 October 2026 with mise 2026.10.15.
Jupyter Notebook and JupyterLab use mise Python and the `mise-python` kernel.
Reviewed version changes, breaking changes, and temporary holds are recorded in
[`docs/housekeeping-2026-10.md`](docs/housekeeping-2026-10.md).
The 23 October approved security updates retain the general `7d` policy;
[applied status and remaining risks](docs/security-review-2026-10-23.md) are
tracked separately. Browser-use remains quarantined: the latest upstream helper
exact-pins vulnerable dependencies, so normal CLI and SDK imports are blocked.
Pi Harness retains host/model ownership opt-outs. Private machine metadata
remains in the separate private overlay repository; native services and macOS
preferences are not changed by runtime housekeeping.

Requirements:

- macOS on Apple Silicon
- mise 2026.10.15 or newer
- Git

Existing targets were backed up before the initial forced cutover. Public
configuration checks and runtime smoke tests are rerun when pins change.

## Ownership

- mise: runtimes, versioned developer CLIs, AI CLIs, tasks, and dotfiles
- mise bootstrap packages: native Homebrew formulae and casks
- Pi Harness: Pi packages, extensions, skills, settings, and sandbox
- private overlay: identity, hosts, private metadata, and personal macOS setup
- Keychain/application login: secrets and authentication

See `docs/tool-ownership.md`, `docs/architecture.md`, and
`docs/cutover.md`.

## Terminal workspaces

Rex is an **experimental, opt-in trial**, not a replacement for the existing
terminal setup. Its [Herdr-compatible workflow](docs/rex-workflow.md) keeps the
Ctrl-S navigation keys and adds direct local/remote session shortcuts. Native
Rex shortcuts remain available. **Ghostty and Herdr remain installed and managed
as supported fallbacks**, with their configurations unchanged.
Rex itself is installed separately during its beta; no app/server restart is
part of applying this configuration. Personal endpoints stay outside git in
`~/.config/rex/local.lua` (only `init.lua` is managed by the public layer).

## Validation

These checks are safe and do not apply configuration. The Rex contract test
uses Lua/LuaJIT or the already-managed Neovim's isolated Lua runtime (CI installs
Lua alongside ShellCheck and Gitleaks):

```bash
./scripts/check-safety.sh
./scripts/validate.sh
./scripts/test-bootstrap.sh
```

Validation includes pin/lock/documentation drift and mocked bootstrap safety
regressions. The bootstrap test copies only public inputs into a temporary HOME,
creates the public layered-config and lock symlinks, copies dependency sidecars,
and trusts only the isolated public config. It executes the real mise dry-run
for non-tool phases and queries tool metadata separately. Mise 2026.10.15
incorrectly rejects missing PyPI prerequisites even in tool installer dry-run;
the test reports that exclusion rather than faking installed dependencies.
Actual empty-data locked graph installs are verified separately. The test never
loads the private overlay or applies hooks. CI runs both scripts on macOS
without installing the full runtime/tool set.

Safety checks include untracked/ignored source and reject forbidden filenames
before reading content. Only the exact generated roots `.pi/subagents/` and
`.ruff_cache/` are excluded from content scans; any tracked file there fails.
Gitleaks scans the same reviewed public-source export, never runtime transcripts.
Keep agent artifacts outside the checkout whenever possible.

Exercise the live notebook environment without personal notebooks, configuration
or Python user-site dependencies:

```bash
mise run jupyter:check
```

This launches a temporary Unix-IPC kernel and checks computation/rendering.
It is separate from the configuration-only validation above. To repair the
pinned environment, use `mise run jupyter:setup`. Its complete requirements
have exact versions and artifact hashes; setup requires hashes and binary wheels.
Regenerate only with `--generate-hashes` and review the resulting version/hash
diff (see the housekeeping procedure).

Check that all locked tools are already installed (nonzero if any are missing):

```bash
mise run tools:dry-run
```

To preview a lock refresh, use `mise run tools:lock:dry-run`, not `mise lock`
from this checkout: the project and global lock are the same physical file.
See the [safe refresh procedure](docs/housekeeping-2026-10.md#safe-lockfile-refresh)
before applying a reviewed update; do not refresh concurrently with other lanes.
The format-3 lock now includes native dependency graphs in `.mise/locks/`; keep
those files with the config/lock when copying or reviewing this repository.

Preview bootstrap convergence without applying changes:

```bash
mise trust
mise run bootstrap:status
mise run bootstrap:dry-run
```

## Consolidation and legacy cleanup

Mise-first consolidation is ongoing, not complete just because mise wins PATH.
Check actual command ownership, duplicate Brew installations, retained dependency
chains and optional application inventory without changing the machine:

```bash
mise run tools:audit
mise run tools:audit -- --json
```

See [`docs/consolidation-plan.md`](docs/consolidation-plan.md) for the target
architecture and staged migration/retirement process. Standalone helper CLIs
should converge on mise too; native dependencies and macOS apps remain deliberate
exceptions controlled through mise bootstrap.

NVM, Conda, PostgreSQL 14 and other legacy installations remain untouched.
Exact uninstall batches and database migration require separate approval; the
audit never removes programs, application data, credentials or environments.
