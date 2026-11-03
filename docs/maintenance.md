# Configuration maintenance

`mise.toml` and its lockfile are the source of truth for selected versions.
Keep pin changes scoped and review compatibility, provenance and upstream
security information before installing. The general seven-day release-age
policy remains enabled; explicit security exceptions do not disable it globally.
Record machine-specific findings and rollout outcomes privately.

## Safe lockfile refresh

Layered configuration may link the global lockfile back to this checkout.
Do not regenerate that same physical file through overlapping project/global
scopes or run concurrent lock writers.

Preview without writing:

```bash
mise run tools:lock:dry-run
```

After backing up the lockfile outside the repository and reviewing intended pin
changes, regenerate from outside the checkout:

```bash
MISE_LOCKED=0 mise --cd /tmp lock --global --platform macos-arm64
./scripts/validate.sh
mise install --dry-run-code --locked
```

Review the generated diff, including `.mise/locks/` sidecars. A missing tool in
the preview is not permission to install an unreviewed version. Only after
approval should `mise install --locked` and `mise reshim` apply the selection.
Keep the config, lock and referenced sidecars in the same commit.

## Python requirements and notebooks

Direct requirements are in `config/python/requirements.in`; the complete graph
in `requirements.txt` has exact versions and artifact hashes. Preserve those
hashes when refreshing:

```bash
mise exec -- uv pip compile config/python/requirements.in --python-version 3.14 \
  --exclude-newer 7d --generate-hashes --no-header --no-annotate \
  --output-file config/python/requirements.txt
```

Review all version/hash changes before applying. Do not force dependency
conflicts, omit dependencies or relax hash verification as a workaround.
Setup uses isolated pip, binary wheels and the explicit interpreter prefix;
isolated imports must succeed before registering the main notebook kernel.

```bash
mise run jupyter:setup
mise run jupyter:check
```

The functional check uses a temporary HOME and test-owned Unix-IPC kernel.
Existing project environments, user-site packages and versioned kernels are
not silently deleted or migrated. Helper-specific Python runtimes remain
independent of the notebook interpreter.

## Runtime and native-library changes

- Confirm the actual executable/version, not just the requested pin or exit code.
- A selection change does not patch an already-running process. Relaunch
  consumers deliberately after saving their work.
- Check native linkage and relevant APIs before changing ABI branches. A formula
  name or absent package-manager consumer does not prove external compatibility.
- Back up program code separately from application data. Do not inspect auth,
  models, notebooks, private profiles or database contents for an ownership audit.
- Do not start services, reset applications, migrate databases, reboot or prune
  legacy managers as incidental maintenance.

## Verification scope

Run configuration/safety checks, isolated bootstrap previews and targeted
functional checks appropriate to the change. Distinguish code review, advisory
queries, artifact verification and runtime tests; none establishes universal
workstation security. Keep operational inventories, unresolved findings and
host-specific acceptance records outside this public repository.
